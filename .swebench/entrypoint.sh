#!/bin/bash
set -x

# ENV exports from Dockerfiles
export DEBIAN_FRONTEND=noninteractive
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 78e30c07b399db1aac8608275fe101e9d349534f
git checkout 78e30c07b399db1aac8608275fe101e9d349534f

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 1917e37f5d9941a3459ce4b0177e201e2d94a622 -- applications/mail/src/app/components/message/tests/Message.images.test.tsx applications/mail/src/app/helpers/message/messageImages.test.ts applications/mail/src/app/helpers/test/helper.ts applications/mail/src/app/helpers/test/render.tsx
fi

# Run tests
bash /workspace/run_script.sh applications/mail/src/app/helpers/test/render.tsx,src/app/helpers/message/messageImages.test.ts,applications/mail/src/app/helpers/test/helper.ts,src/app/components/message/tests/Message.images.test.ts,applications/mail/src/app/helpers/message/messageImages.test.ts,applications/mail/src/app/components/message/tests/Message.images.test.tsx > /workspace/stdout.log 2> /workspace/stderr.log

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
