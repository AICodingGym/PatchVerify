#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard ea164fdde79a3e624c28f90c74f57f06360d2333
git checkout ea164fdde79a3e624c28f90c74f57f06360d2333

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout d72025be751c894673ba85caa063d835a0ad3a8c -- test/integration/targets/nxos_interfaces/tasks/main.yaml test/integration/targets/nxos_interfaces/tests/cli/deleted.yaml test/integration/targets/nxos_interfaces/tests/cli/merged.yaml test/integration/targets/nxos_interfaces/tests/cli/overridden.yaml test/integration/targets/nxos_interfaces/tests/cli/replaced.yaml test/units/modules/network/nxos/test_nxos_interfaces.py
fi

# Run tests
bash /workspace/run_script.sh test/units/modules/network/nxos/test_nxos_interfaces.py > /workspace/stdout.log 2> /workspace/stderr.log

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
