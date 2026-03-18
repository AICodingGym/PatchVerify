#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 8ee8122b10b3a0a53cb369503ed64d25a6ad1f34
git checkout 8ee8122b10b3a0a53cb369503ed64d25a6ad1f34

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 0415e422f12454db0c22316cf3eaa5088d6b6322 -- lib/auth/auth_test.go
fi

# Run tests
bash /workspace/run_script.sh TestUpsertServer/auth,TestMFADeviceManagement/add_a_U2F_device,TestUpsertServer,TestMFADeviceManagement/add_initial_TOTP_device,TestMFADeviceManagement/fail_TOTP_auth_challenge,TestMiddlewareGetUser/local_system_role,TestRemoteClusterStatus,TestMiddlewareGetUser/local_user_no_teleport_cluster_in_cert_subject,TestMFADeviceManagement,TestMFADeviceManagement/delete_last_U2F_device_by_ID,TestMiddlewareGetUser,TestU2FSignChallengeCompat,TestMiddlewareGetUser/no_client_cert,TestU2FSignChallengeCompat/new_client,_old_server,TestMiddlewareGetUser/remote_system_role,TestMFADeviceManagement/fail_a_U2F_auth_challenge,TestMFADeviceManagement/fail_a_TOTP_registration_challenge,TestMFADeviceManagement/fail_a_TOTP_auth_challenge,TestMiddlewareGetUser/remote_user,TestMiddlewareGetUser/local_user,TestMFADeviceManagement/fail_a_U2F_registration_challenge,TestMFADeviceManagement/delete_TOTP_device_by_name,TestMigrateMFADevices,TestUpsertServer/node,TestUpsertServer/unknown,TestU2FSignChallengeCompat/old_client,_new_server,TestMFADeviceManagement/fail_to_delete_an_unknown_device,TestUpsertServer/proxy,TestMiddlewareGetUser/remote_user_no_teleport_cluster_in_cert_subject,TestMFADeviceManagement/fail_U2F_auth_challenge > /workspace/stdout.log 2> /workspace/stderr.log
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
