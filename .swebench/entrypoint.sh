#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 247986f00311d9ee34009b0bb02d0d3bd7497ebd
git checkout 247986f00311d9ee34009b0bb02d0d3bd7497ebd

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup (checkout gold test files)
git checkout 630221ab686c64e75a2ce253c893c033e4814b2e -- openlibrary/plugins/openlibrary/tests/test_bestbookapi.py

# Run tests
bash /workspace/run_script.sh openlibrary/plugins/openlibrary/tests/test_bestbookapi.py > /workspace/stdout.log 2> /workspace/stderr.log
RUN_SCRIPT_EXIT=$?

# Parse results
python /workspace/parser.py /workspace/stdout.log /workspace/stderr.log /workspace/output.json || true

# Print outputs for GHA log
echo '=== STDOUT ==='
cat /workspace/stdout.log 2>/dev/null || true
echo '=== STDERR ==='
cat /workspace/stderr.log 2>/dev/null || true
echo '=== PARSED OUTPUT ==='
cat /workspace/output.json 2>/dev/null || true

# Exit with the test runner's exit code (non-zero = build failure or test failures)
exit $RUN_SCRIPT_EXIT
