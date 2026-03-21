#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard ba3abfb6af6e722185d3715929ab0f3e5a134eed
git checkout ba3abfb6af6e722185d3715929ab0f3e5a134eed

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup (checkout gold test files)
git checkout f0341c0ba81c790241b782f5103ce5c9a6edf8e3 -- openlibrary/catalog/add_book/tests/test_add_book.py openlibrary/tests/catalog/test_utils.py

# Run tests
bash /workspace/run_script.sh openlibrary/tests/catalog/test_utils.py,openlibrary/catalog/add_book/tests/test_add_book.py > /workspace/stdout.log 2> /workspace/stderr.log
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
