#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard fa093d8adf03c88908caa38fe70e0db2711e801c
git checkout fa093d8adf03c88908caa38fe70e0db2711e801c

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout b8025ac160146319d2b875be3366b60c852dd35d -- test/integration/targets/get_url/tasks/ciphers.yml test/integration/targets/get_url/tasks/main.yml test/integration/targets/lookup_url/tasks/main.yml test/integration/targets/uri/tasks/ciphers.yml test/integration/targets/uri/tasks/main.yml test/units/module_utils/urls/test_Request.py test/units/module_utils/urls/test_fetch_url.py
fi

# Run tests
bash /workspace/run_script.sh test/units/module_utils/urls/test_fetch_url.py,test/units/module_utils/urls/test_Request.py > /workspace/stdout.log 2> /workspace/stderr.log

# Parse results
python /workspace/parser.py /workspace/stdout.log /workspace/stderr.log /workspace/output.json || true

# Print outputs for GHA log
echo '=== STDOUT ==='
cat /workspace/stdout.log 2>/dev/null || true
echo '=== STDERR ==='
cat /workspace/stderr.log 2>/dev/null || true
echo '=== PARSED OUTPUT ==='
cat /workspace/output.json 2>/dev/null || true

# Exit non-zero if any test failed
python -c "
import json, sys
try:
    with open('/workspace/output.json') as f:
        data = json.load(f)
    failed = [t for t in data.get('tests', []) if t.get('status') == 'FAILED']
    if failed:
        print(f'{len(failed)} test(s) FAILED')
        sys.exit(1)
    print('All tests passed')
except Exception as e:
    print(f'Could not check results: {e}')
    sys.exit(1)
"
