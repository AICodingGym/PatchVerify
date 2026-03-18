#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 29d3f9db40c83434d0e3cc082af8baec64c391a9
git checkout 29d3f9db40c83434d0e3cc082af8baec64c391a9

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout c8d71ad7ea98d97546f01cce4ccb451dbcf37d3b -- internal/cue/validate_fuzz_test.go internal/cue/validate_test.go internal/storage/fs/snapshot_test.go
fi

# Run tests
bash /workspace/run_script.sh FuzzValidate,TestFSWithIndex,TestFS_Invalid_VariantFlag_Distribution,TestFSWithoutIndex,TestValidate_Failure,TestFS_Invalid_VariantFlag_Segment,Test_Store,TestFS_Invalid_BooleanFlag_Segment,TestValidate_Latest_Segments_V2,TestValidate_V1_Success,TestValidate_Latest_Success > /workspace/stdout.log 2> /workspace/stderr.log
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
