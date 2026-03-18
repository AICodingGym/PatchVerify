#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 6fd0f9e2587f14ac1fdd1c229f0bcae0468c8daa
git checkout 6fd0f9e2587f14ac1fdd1c229f0bcae0468c8daa

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout e5fe37c379e1eec2dd3492c5737c0be761050b26 -- internal/storage/fs/git/source_test.go internal/storage/fs/local/source_test.go internal/storage/fs/oci/source_test.go internal/storage/fs/s3/source_test.go internal/storage/fs/store_test.go
fi

# Run tests
bash /workspace/run_script.sh TestCountNamespaces,TestFS_Invalid_VariantFlag_Distribution,Test_SourceSubscribe,TestGetEvaluationRollouts,TestFS_Invalid_BooleanFlag_Segment,TestListRollouts,TestListNamespaces,TestFS_YAML_Stream,Test_SourceGet,Test_SourceString,TestListFlags,TestCountSegments,TestCountFlags,TestListRules,TestFSWithIndex,TestCountRules,TestCountRollouts,TestFS_Empty_Features_File,TestGetEvaluationDistributions,TestFS_Invalid_VariantFlag_Segment,TestListSegments,TestFSWithoutIndex,Test_Store > /workspace/stdout.log 2> /workspace/stderr.log
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
