#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PIP_BREAK_SYSTEM_PACKAGES=1
export SETUP='{ "url": "http://127.0.0.1:4567/forum", "secret": "abcdef", "admin:username": "admin", "admin:email": "test@example.org", "admin:password": "hAN3Eg8W", "admin:password:confirm": "hAN3Eg8W", "database": "redis", "redis:host": "127.0.0.1", "redis:port": 6379, "redis:password": "", "redis:database": 0 }'
export CI='{ "host": "127.0.0.1", "database": 1, "port": 6379 }'
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard ae3fa85f40db0dca83d19dda1afb96064dffcc83
git checkout ae3fa85f40db0dca83d19dda1afb96064dffcc83

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 00c70ce7b0541cfc94afe567921d7668cdc8f4ac -- test/mocks/databasemock.js test/socket.io.js test/user.js
fi

# Run tests
bash /workspace/run_script.sh test/mocks/databasemock.js,test/translator.js,test/user.js,test/socket.io.js,test/database.js,test/meta.js > /workspace/stdout.log 2> /workspace/stderr.log

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
