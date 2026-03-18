#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 820f90fd26c5f8651217f2edee0e5770d5f5f011
git checkout 820f90fd26c5f8651217f2edee0e5770d5f5f011

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout f743945d599b178293e89e784b3b2374b1026430 -- config/schema_test.go internal/config/config_test.go
fi

# Run tests
bash /workspace/run_script.sh Test_mustBindEnv,TestJSONSchema,TestCacheBackend,TestScheme,TestLogEncoding,TestServeHTTP,TestTracingExporter,TestLoad,TestDatabaseProtocol,Test_CUE,Test_JSONSchema > /workspace/stdout.log 2> /workspace/stderr.log
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
