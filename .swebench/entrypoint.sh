#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 1d550f0c0d693844b6f4b44fd7859254ef3569c0
git checkout 1d550f0c0d693844b6f4b44fd7859254ef3569c0

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout aebaecd026f752b187f11328b0d464761b15d2ab -- internal/storage/fs/cache_test.go
fi

# Run tests
bash /workspace/run_script.sh TestCountFlags,TestListRollouts,TestFS_Empty_Features_File,TestListSegments,TestCountSegments,TestSnapshotFromFS_Invalid,TestListRules,TestGetVersion,TestParseFliptIndexParsingError,Test_SnapshotCache_Delete,TestFSWithoutIndex,TestCountNamespaces,TestFSWithIndex,TestWalkDocuments,TestCountRollouts,Test_SnapshotCache_Concurrently,TestListNamespaces,TestCountRules,Test_SnapshotCache,TestParseFliptIndex,TestFS_YAML_Stream > /workspace/stdout.log 2> /workspace/stderr.log
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
