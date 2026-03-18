#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 254de2a43487c61adf3cdc9e35d8a9aa58a186a3
git checkout 254de2a43487c61adf3cdc9e35d8a9aa58a186a3

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 811093f0225caa4dd33890933150a81c6a6d5226 -- test/integration/targets/blocks/72725.yml test/integration/targets/blocks/72781.yml test/integration/targets/blocks/runme.sh test/integration/targets/handlers/46447.yml test/integration/targets/handlers/52561.yml test/integration/targets/handlers/54991.yml test/integration/targets/handlers/include_handlers_fail_force-handlers.yml test/integration/targets/handlers/include_handlers_fail_force.yml test/integration/targets/handlers/order.yml test/integration/targets/handlers/runme.sh test/integration/targets/handlers/test_flush_handlers_as_handler.yml test/integration/targets/handlers/test_flush_handlers_rescue_always.yml test/integration/targets/handlers/test_flush_in_rescue_always.yml test/integration/targets/handlers/test_handlers_infinite_loop.yml test/integration/targets/handlers/test_handlers_meta.yml test/integration/targets/handlers/test_skip_flush.yml test/units/plugins/strategy/test_linear.py test/units/plugins/strategy/test_strategy.py
fi

# Run tests
bash /workspace/run_script.sh test/units/plugins/strategy/test_linear.py,test/units/plugins/strategy/test_strategy.py > /workspace/stdout.log 2> /workspace/stderr.log

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
