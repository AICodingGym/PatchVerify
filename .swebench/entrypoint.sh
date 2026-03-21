#!/bin/bash
set -x

# ENV exports from Dockerfiles
export DEBIAN_FRONTEND=noninteractive
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 7ff95b70115415f47b89c81a40e90b60bcf3dbd8
git checkout 7ff95b70115415f47b89c81a40e90b60bcf3dbd8

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup (checkout gold test files)
git checkout 8afd9ce04c8dde9e150e1c2b50d32e7ee2efa3e7 -- applications/drive/src/app/components/FileBrowser/hooks/useSelectionControls.test.ts

# Run tests
bash /workspace/run_script.sh src/app/components/FileBrowser/hooks/useSelectionControls.test.ts,applications/drive/src/app/components/FileBrowser/hooks/useSelectionControls.test.ts > /workspace/stdout.log 2> /workspace/stderr.log

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
