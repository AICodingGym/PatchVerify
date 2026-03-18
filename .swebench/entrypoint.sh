#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 879520526664656ad9f93925cd0b1f2220c0c3f2
git checkout 879520526664656ad9f93925cd0b1f2220c0c3f2

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout dae029cba7cdb98dfb1a6b416c00d324241e6063 -- internal/ext/importer_fuzz_test.go internal/ext/importer_test.go internal/storage/sql/evaluation_test.go
fi

# Run tests
bash /workspace/run_script.sh TestImport,TestImport_Export,TestImport_Namespaces_Mix_And_Match,TestOpen,TestJSONField_Scan,TestImport_FlagType_LTVersion1_1,TestParse,TestNullableTimestamp_Value,TestImport_Rollouts_LTVersion1_1,TestMigratorRun,TestTimestamp_Value,TestMigratorRun_NoChange,TestDBTestSuite,TestNullableTimestamp_Scan,TestAdaptedDriver,TestTimestamp_Scan,TestImport_InvalidVersion,TestJSONField_Value,Test_AdaptError,FuzzImport,TestMigratorExpectedVersions,TestAdaptedConnectorConnect,TestExport > /workspace/stdout.log 2> /workspace/stderr.log
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
