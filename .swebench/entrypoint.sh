#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 040ec6d3b264d152a674718eb5a0864debb68470
git checkout 040ec6d3b264d152a674718eb5a0864debb68470

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup (checkout gold test files)
git checkout 2bb3bbbd8aff1164a2353381cb79e1dc93b90d28 -- lib/backend/dynamo/dynamodbbk_test.go

# Run tests
bash /workspace/run_script.sh TestCreateTable/read/write_capacity_units_are_ignored_if_on_demand_is_on,TestCreateTable/bad_parameter_when_the_incorrect_billing_mode_is_set,TestCreateTable/table_creation_succeeds,TestCreateTable/bad_parameter_when_provisioned_throughput_is_set,TestCreateTable,TestCreateTable/create_table_succeeds > /workspace/stdout.log 2> /workspace/stderr.log
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
