#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 341a6be78d7fc1701b0b120fc9df1c913a12948c
git checkout 341a6be78d7fc1701b0b120fc9df1c913a12948c

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout ea04e0048dbb3b63f876aad7020e1de8eee9f362 -- test/integration/targets/module_utils_Ansible.Basic/library/ansible_basic_tests.ps1 test/lib/ansible_test/_data/sanity/pylint/plugins/deprecated.py test/lib/ansible_test/_data/sanity/validate-modules/validate_modules/main.py test/lib/ansible_test/_data/sanity/validate-modules/validate_modules/ps_argspec.ps1 test/lib/ansible_test/_data/sanity/validate-modules/validate_modules/schema.py test/lib/ansible_test/_data/sanity/validate-modules/validate_modules/utils.py test/lib/ansible_test/_internal/sanity/pylint.py test/lib/ansible_test/_internal/sanity/validate_modules.py test/units/module_utils/basic/test_deprecate_warn.py
fi

# Run tests
bash /workspace/run_script.sh test/lib/ansible_test/_data/sanity/validate-modules/validate_modules/main.py,test/units/module_utils/basic/test_deprecate_warn.py,test/lib/ansible_test/_internal/sanity/validate_modules.py,test/lib/ansible_test/_internal/sanity/pylint.py,test/lib/ansible_test/_data/sanity/pylint/plugins/deprecated.py,test/lib/ansible_test/_data/sanity/validate-modules/validate_modules/schema.py,test/lib/ansible_test/_data/sanity/validate-modules/validate_modules/utils.py > /workspace/stdout.log 2> /workspace/stderr.log

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
