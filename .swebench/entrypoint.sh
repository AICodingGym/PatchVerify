#!/bin/bash
set -x

# ENV exports from Dockerfiles
export DEBIAN_FRONTEND=noninteractive
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 4aeaf4a64578fe82cdee4a01636121ba0c03ac97
git checkout 4aeaf4a64578fe82cdee4a01636121ba0c03ac97

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore\|problem_statement\.md\|hints_text\.md\|CLAUDE\.md\|AGENTS\.md\|\.claudeignore\|\.copilotignore\|\.cursorignore\|\.cursorrules\|\.devcontainer\|\.vscode" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout c6f65d205c401350a226bb005f42fac1754b0b5b -- applications/mail/src/app/components/eo/message/tests/ViewEOMessage.attachments.test.tsx applications/mail/src/app/components/eo/reply/tests/EOReply.attachments.test.tsx applications/mail/src/app/components/message/recipients/tests/MailRecipientItemSingle.blockSender.test.tsx applications/mail/src/app/components/message/recipients/tests/MailRecipientItemSingle.test.tsx applications/mail/src/app/components/message/tests/Message.attachments.test.tsx applications/mail/src/app/components/message/tests/Message.banners.test.tsx applications/mail/src/app/components/message/tests/Message.modes.test.tsx
fi

# Run tests
bash /workspace/run_script.sh applications/mail/src/app/components/message/tests/Message.modes.test.tsx,src/app/components/eo/message/tests/ViewEOMessage.attachments.test.ts,applications/mail/src/app/components/eo/message/tests/ViewEOMessage.attachments.test.tsx,applications/mail/src/app/components/eo/reply/tests/EOReply.attachments.test.tsx,applications/mail/src/app/components/message/tests/Message.attachments.test.tsx,applications/mail/src/app/components/message/recipients/tests/MailRecipientItemSingle.test.tsx,applications/mail/src/app/components/message/tests/Message.banners.test.tsx,src/app/components/message/tests/Message.banners.test.ts,src/app/components/message/tests/Message.attachments.test.ts,src/app/components/message/tests/Message.modes.test.ts,applications/mail/src/app/components/message/recipients/tests/MailRecipientItemSingle.blockSender.test.tsx,src/app/components/eo/reply/tests/EOReply.attachments.test.ts,src/app/components/message/recipients/tests/MailRecipientItemSingle.test.ts,src/app/components/message/recipients/tests/MailRecipientItemSingle.blockSender.test.ts > /workspace/stdout.log 2> /workspace/stderr.log

# Parse results
python /workspace/parser.py /workspace/stdout.log /workspace/stderr.log /workspace/output.json || true

# Print outputs for GHA log
echo '=== STDOUT ==='
cat /workspace/stdout.log 2>/dev/null || true
echo '=== STDERR ==='
cat /workspace/stderr.log 2>/dev/null || true
echo '=== PARSED OUTPUT ==='
cat /workspace/output.json 2>/dev/null || true

# Exit non-zero if any test failed or errored
python -c "
import json, sys
try:
    with open('/workspace/output.json') as f:
        data = json.load(f)
    tests = data.get('tests', [])
    failed = [t for t in tests if t.get('status') in ('FAILED', 'ERROR')]
    if failed:
        print(f'{len(failed)} test(s) FAILED/ERROR')
        sys.exit(1)
    if not tests:
        print('No tests found')
        sys.exit(1)
    print('All tests passed')
except Exception as e:
    print(f'Could not check results: {e}')
    sys.exit(1)
"
