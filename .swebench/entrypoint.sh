#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 43fc9f6de6e22bf617b9973ffac6097c5d16982f
git checkout 43fc9f6de6e22bf617b9973ffac6097c5d16982f

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 10123c046e21e1826098e485a4c2212865a49d9f -- tool/tsh/tsh_test.go
fi

# Run tests
bash /workspace/run_script.sh TestFormatConnectCommand/default_user/database_are_specified,TestTshMain,TestFormatConnectCommand,TestFormatConnectCommand/default_user_is_specified,TestFormatConnectCommand/unsupported_database_protocol,TestReadClusterFlag,TestFormatConnectCommand/no_default_user/database_are_specified,TestFormatConnectCommand/default_database_is_specified,TestReadClusterFlag/TELEPORT_CLUSTER_set,TestReadClusterFlag/TELEPORT_SITE_and_TELEPORT_CLUSTER_set,_prefer_TELEPORT_CLUSTER,TestReadClusterFlag/TELEPORT_SITE_and_TELEPORT_CLUSTER_and_CLI_flag_is_set,_prefer_CLI,TestReadClusterFlag/TELEPORT_SITE_set,TestFetchDatabaseCreds,TestReadClusterFlag/nothing_set > /workspace/stdout.log 2> /workspace/stderr.log
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
