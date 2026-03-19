#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard cc3c38d7805e007b25afe751d3690f4e51ba0a0f
git checkout cc3c38d7805e007b25afe751d3690f4e51ba0a0f

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore\|problem_statement\.md\|hints_text\.md" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout c335534e02de143508ebebc7341021d7f8656e8f -- tool/tsh/proxy_test.go
fi

# Run tests
bash /workspace/run_script.sh TestOptions/Forward_Agent_Yes,TestProxySSHDial,TestFormatConnectCommand/default_database_is_specified,TestEnvFlags/cluster_env/TELEPORT_SITE_and_TELEPORT_CLUSTER_set,_prefer_TELEPORT_CLUSTER,TestEnvFlags/teleport_home_env/TELEPORT_HOME_set,TestEnvFlags/kube_cluster_env/nothing_set,TestOptions,TestEnvFlags/kube_cluster_env/TELEPORT_KUBE_CLUSTER_set,TestOptions/Equals_Sign_Delimited,TestEnvFlags/teleport_home_env/CLI_flag_is_set,TestKubeConfigUpdate/invalid_selected_cluster,TestOptions/Forward_Agent_InvalidValue,TestEnvFlags/cluster_env/TELEPORT_SITE_set,TestEnvFlags/cluster_env/TELEPORT_CLUSTER_set,TestLoginIdentityOut,TestResolveDefaultAddr,TestResolveDefaultAddrTimeoutBeforeAllRacersLaunched,TestIdentityRead,TestOptions/Invalid_key,TestEnvFlags/cluster_env,TestKubeConfigUpdate/selected_cluster,TestFailedLogin,TestOIDCLogin,TestFormatConnectCommand/default_user_is_specified,TestKubeConfigUpdate,TestResolveUndeliveredBodyDoesNotBlockForever,TestEnvFlags/cluster_env/nothing_set,TestEnvFlags/cluster_env/CLI_flag_is_set,TestEnvFlags/kube_cluster_env/CLI_flag_is_set,TestFormatConnectCommand,TestFormatConnectCommand/default_user/database_are_specified,TestRelogin,TestEnvFlags/teleport_home_env/TELEPORT_HOME_and_CLI_flag_is_set,_prefer_env,TestMakeClient,TestKubeConfigUpdate/no_kube_clusters,TestOptions/Incomplete_option,TestOptions/Forward_Agent_Local,TestEnvFlags/kube_cluster_env,TestResolveDefaultAddrSingleCandidate,TestEnvFlags/cluster_env/TELEPORT_SITE_and_TELEPORT_CLUSTER_and_CLI_flag_is_set,_prefer_CLI,TestEnvFlags/teleport_home_env/nothing_set,TestOptions/Space_Delimited,TestResolveNonOKResponseIsAnError,TestFormatConnectCommand/no_default_user/database_are_specified,TestKubeConfigUpdate/no_selected_cluster,TestEnvFlags/teleport_home_env,TestOptions/Forward_Agent_No,TestOptions/AddKeysToAgent_Invalid_Value,TestResolveDefaultAddrNoCandidates,TestResolveDefaultAddrTimeout,TestKubeConfigUpdate/no_tsh_path,TestEnvFlags,TestEnvFlags/kube_cluster_env/TELEPORT_KUBE_CLUSTER_and_CLI_flag_is_set,_prefer_CLI > /workspace/stdout.log 2> /workspace/stderr.log

# Parse results
python /workspace/parser.py /workspace/stdout.log /workspace/stderr.log /workspace/output.json || true

# Print outputs for GHA log
echo '=== STDOUT ==='
cat /workspace/stdout.log 2>/dev/null || true
echo '=== STDERR ==='
cat /workspace/stderr.log 2>/dev/null || true
echo '=== PARSED OUTPUT ==='
cat /workspace/output.json 2>/dev/null || true

# Exit non-zero if any test failed
python -c "
import json, sys
try:
    with open('/workspace/output.json') as f:
        data = json.load(f)
    failed = [t for t in data.get('tests', []) if t.get('status') == 'FAILED']
    if failed:
        print(f'{len(failed)} test(s) FAILED')
        sys.exit(1)
    print('All tests passed')
except Exception as e:
    print(f'Could not check results: {e}')
    sys.exit(1)
"
