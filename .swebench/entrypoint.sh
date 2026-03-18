#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 358e13bf5748bba4418ffdcdd913bcbfdedc9d3f
git checkout 358e13bf5748bba4418ffdcdd913bcbfdedc9d3f

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 86906cbfc3a5d3629a583f98e6301142f5f14bdb -- internal/config/config_test.go
fi

# Run tests
bash /workspace/run_script.sh TestDefaultDatabaseRoot,TestGetConfigFile,TestAnalyticsClickhouseConfiguration,TestFindDatabaseRoot,TestDatabaseProtocol,TestTracingExporter,TestIsReadOnly,TestScheme,TestWithForwardPrefix,TestLoad,TestAuditEnabled,TestServeHTTP,TestStorageConfigInfo,TestRequiresDatabase,TestCacheBackend,TestMarshalYAML,Test_mustBindEnv,TestStructTags,TestAnalyticsPrometheusConfiguration,TestJSONSchema,TestLogEncoding > /workspace/stdout.log 2> /workspace/stderr.log
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
