#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 1879807d3c30626ec02a730133ac5592cece310c
git checkout 1879807d3c30626ec02a730133ac5592cece310c

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 769b4b5eec7286b7b14e179f2cc52e6b15d2d9f3 -- tool/tsh/tsh_test.go
fi

# Run tests
bash /workspace/run_script.sh TestMakeClient,TestReadClusterFlag,TestOptions/Incomplete_option,TestReadClusterFlag/nothing_set,TestFormatConnectCommand/no_default_user/database_are_specified,TestOptions/Forward_Agent_Local,TestFormatConnectCommand/unsupported_database_protocol,TestReadClusterFlag/TELEPORT_SITE_and_TELEPORT_CLUSTER_and_CLI_flag_is_set,_prefer_CLI,TestFetchDatabaseCreds,TestFormatConnectCommand/default_user_is_specified,TestOptions/Forward_Agent_No,TestOptions/Forward_Agent_InvalidValue,TestFormatConnectCommand/default_database_is_specified,TestReadClusterFlag/TELEPORT_SITE_set,TestOIDCLogin,TestRelogin,TestOptions/AddKeysToAgent_Invalid_Value,TestFormatConnectCommand/default_user/database_are_specified,TestOptions/Forward_Agent_Yes,TestFormatConnectCommand,TestOptions/Equals_Sign_Delimited,TestReadClusterFlag/TELEPORT_SITE_and_TELEPORT_CLUSTER_set,_prefer_TELEPORT_CLUSTER,TestOptions/Invalid_key,TestIdentityRead,TestOptions/Space_Delimited,TestReadClusterFlag/TELEPORT_CLUSTER_set,TestFailedLogin,TestOptions > /workspace/stdout.log 2> /workspace/stderr.log
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
