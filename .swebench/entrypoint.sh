#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 42beccb27e0e5797a10db05bf126e529273d2d95
git checkout 42beccb27e0e5797a10db05bf126e529273d2d95

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 0ac7334939981cf85b9591ac295c3816954e287e -- lib/srv/db/access_test.go lib/srv/db/ha_test.go
fi

# Run tests
bash /workspace/run_script.sh TestAccessMySQL/has_access_to_nothing,TestProxyProtocolPostgres,TestAccessPostgres/has_access_to_nothing,TestAuthTokens/correct_Postgres_Cloud_SQL_IAM_auth_token,TestAuthTokens/correct_Postgres_Redshift_IAM_auth_token,TestAccessPostgres,TestAuthTokens/incorrect_MySQL_RDS_IAM_auth_token,TestAccessMySQL/access_allowed_to_specific_user,TestHA,TestAuthTokens/incorrect_Postgres_Redshift_IAM_auth_token,TestAuditMySQL,TestAccessDisabled,TestAccessMySQL,TestAccessMySQL/has_access_to_all_database_users,TestAccessPostgres/access_allowed_to_specific_user/database,TestAuthTokens/incorrect_Postgres_RDS_IAM_auth_token,TestAuthTokens/correct_MySQL_RDS_IAM_auth_token,TestAccessPostgres/no_access_to_users,TestProxyClientDisconnectDueToIdleConnection,TestAuthTokens/incorrect_Postgres_Cloud_SQL_IAM_auth_token,TestDatabaseServerStart,TestProxyClientDisconnectDueToCertExpiration,TestAccessMySQL/access_denied_to_specific_user,TestAccessPostgres/has_access_to_all_database_names_and_users,TestAuthTokens,TestAccessPostgres/no_access_to_databases,TestAuditPostgres,TestAccessPostgres/access_denied_to_specific_user/database,TestProxyProtocolMySQL,TestAuthTokens/correct_Postgres_RDS_IAM_auth_token > /workspace/stdout.log 2> /workspace/stderr.log
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
