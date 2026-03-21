#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 827f2cb8d86509c4455b2df2fe79b9d59533d3b0
git checkout 827f2cb8d86509c4455b2df2fe79b9d59533d3b0

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup (checkout gold test files)
git checkout ef2be3d6ea4c0a13674aaab08b182eca4e2b9a17 -- gost/gost_test.go oval/util_test.go

# Run tests
bash /workspace/run_script.sh Test_rhelDownStreamOSVersionToRHEL,TestPackNamesOfUpdate,TestUpsert,Test_ovalResult_Sort,TestIsOvalDefAffected,TestParseCvss2,Test_lessThan,TestParseCvss3,TestDefpacksToPackStatuses,TestSUSE_convertToModel > /workspace/stdout.log 2> /workspace/stderr.log
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
