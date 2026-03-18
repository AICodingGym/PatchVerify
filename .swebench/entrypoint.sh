#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 563a8c4593610e431f0c3db55e88a679c4386991
git checkout 563a8c4593610e431f0c3db55e88a679c4386991

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 6fd0f9e2587f14ac1fdd1c229f0bcae0468c8daa -- internal/config/config_test.go internal/oci/file_test.go
fi

# Run tests
bash /workspace/run_script.sh TestLogEncoding,TestMarshalYAML,TestNewStore,TestStore_Fetch,TestLoad,TestServeHTTP,TestTracingExporter,Test_mustBindEnv,TestDatabaseProtocol,TestScheme,TestJSONSchema,TestStore_Fetch_InvalidMediaType,TestCacheBackend > /workspace/stdout.log 2> /workspace/stderr.log
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
