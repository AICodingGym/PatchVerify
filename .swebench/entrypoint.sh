#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 16e240cc4b24e051ff7c1cb0b430cca67768f4bb
git checkout 16e240cc4b24e051ff7c1cb0b430cca67768f4bb

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout d966559200183b713cdf3ea5007a7e0ba86a5afb -- internal/config/config_test.go
fi

# Run tests
bash /workspace/run_script.sh TestTracingExporter,TestLoad,TestLogEncoding,TestServeHTTP,TestDefaultDatabaseRoot,TestMarshalYAML,TestDatabaseProtocol,TestCacheBackend,TestGetConfigFile,TestStructTags,TestScheme,TestJSONSchema,Test_mustBindEnv,TestAnalyticsClickhouseConfiguration > /workspace/stdout.log 2> /workspace/stderr.log
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
