#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 47499077ce785f0eee0e3940ef6c074e29a664fc
git checkout 47499077ce785f0eee0e3940ef6c074e29a664fc

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup (checkout gold test files)
git checkout c188284ff0c094a4ee281afebebd849555ebee59 -- internal/config/config_test.go internal/oci/ecr/ecr_test.go internal/oci/options_test.go

# Run tests
bash /workspace/run_script.sh TestCredentialFunc,TestWithCredentials,TestStore_Fetch,TestECRCredential,TestScheme,TestLogEncoding,TestCacheBackend,TestTracingExporter,TestParseReference,TestDefaultDatabaseRoot,TestFile,TestMarshalYAML,Test_mustBindEnv,TestAnalyticsClickhouseConfiguration,TestStore_List,TestServeHTTP,TestJSONSchema,TestLoad,TestStore_Fetch_InvalidMediaType,TestWithManifestVersion,TestDatabaseProtocol,TestStore_Build,TestAuthenicationTypeIsValid,TestStore_Copy > /workspace/stdout.log 2> /workspace/stderr.log
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
