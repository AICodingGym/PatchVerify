#!/bin/bash
set -x

# ENV exports from Dockerfiles
export DEBIAN_FRONTEND=noninteractive
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard bf70473d724be9664974c0bc6b04458f6123ead2
git checkout bf70473d724be9664974c0bc6b04458f6123ead2

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup (checkout gold test files)
git checkout 5e815cfa518b223a088fa9bb232a5fc90ab15691 -- packages/components/containers/payments/RenewToggle.test.tsx packages/components/hooks/helpers/test/useSubscription.ts

# Run tests
bash /workspace/run_script.sh packages/components/hooks/helpers/test/useSubscription.ts,containers/payments/RenewToggle.test.ts,packages/components/containers/payments/RenewToggle.test.tsx > /workspace/stdout.log 2> /workspace/stderr.log

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
