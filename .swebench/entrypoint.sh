#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard f4502a8f1ce71d88cc90f4b4f6c2899943441ebf
git checkout f4502a8f1ce71d88cc90f4b4f6c2899943441ebf

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 622a493ae03bd5e5cf517d336fc426e9d12208c7 -- test/units/modules/network/icx/fixtures/icx_ping_ping_10.255.255.250_count_2 test/units/modules/network/icx/fixtures/icx_ping_ping_10.255.255.250_count_2_timeout_45 test/units/modules/network/icx/fixtures/icx_ping_ping_8.8.8.8_count_2 test/units/modules/network/icx/fixtures/icx_ping_ping_8.8.8.8_count_5_ttl_70 test/units/modules/network/icx/fixtures/icx_ping_ping_8.8.8.8_size_10001 test/units/modules/network/icx/fixtures/icx_ping_ping_8.8.8.8_ttl_300 test/units/modules/network/icx/test_icx_ping.py
fi

# Run tests
bash /workspace/run_script.sh test/units/modules/network/icx/test_icx_ping.py > /workspace/stdout.log 2> /workspace/stderr.log

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
