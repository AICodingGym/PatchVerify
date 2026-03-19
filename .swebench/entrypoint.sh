#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 4f6f52f86d65f506d1884a9f56bcd919a8744734
git checkout 4f6f52f86d65f506d1884a9f56bcd919a8744734

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore\|problem_statement\.md\|hints_text\.md\|CLAUDE\.md\|AGENTS\.md\|\.claudeignore\|\.copilotignore\|\.cursorignore\|\.cursorrules\|\.devcontainer\|\.vscode" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout eda668c30d9d3b56d9c69197b120b01013611186 -- lib/kube/proxy/forwarder_test.go
fi

# Run tests
bash /workspace/run_script.sh TestAuthenticate/local_user_and_cluster,_no_tunnel,TestParseResourcePath//,TestGetKubeCreds/proxy_service,_no_kube_creds,TestAuthenticate/local_user_and_remote_cluster,_no_local_kube_users_or_groups,TestGetServerInfo/GetServerInfo_gets_correct_public_addr_with_PublicAddr_set,TestParseResourcePath//apis/,TestMTLSClientCAs,TestAuthenticate/custom_kubernetes_cluster_in_local_cluster,TestParseResourcePath,TestParseResourcePath//api/v1/namespaces/kube-system/pods/foo/exec,TestParseResourcePath//apis,TestGetKubeCreds/kubernetes_service,_with_kube_creds,TestParseResourcePath//api/v1/namespaces/kube-system,TestAuthenticate/remote_user_and_local_cluster,TestParseResourcePath//apis/apps/v1,TestParseResourcePath//apis/rbac.authorization.k8s.io/v1/clusterroles/foo,TestAuthenticate/local_user_and_remote_cluster,_no_kubeconfig,TestGetKubeCreds/legacy_proxy_service,_with_kube_creds,TestParseResourcePath//api/v1/watch/namespaces/kube-system/pods/foo,TestAuthenticate/unsupported_user_type,TestNewClusterSessionLocal,TestClusterSessionDial,TestParseResourcePath//api/v1,TestParseResourcePath//apis/rbac.authorization.k8s.io/v1/clusterroles,TestParseResourcePath//apis/rbac.authorization.k8s.io/v1/watch/clusterroles/foo,TestParseResourcePath//apis/apps/,TestGetServerInfo/GetServerInfo_gets_listener_addr_with_PublicAddr_unset,TestParseResourcePath//api/v1/namespaces/kube-system/pods,TestParseResourcePath//apis/rbac.authorization.k8s.io/v1/watch/clusterroles,TestAuthenticate/remote_user_and_remote_cluster,TestNewClusterSessionRemote,TestParseResourcePath//api/v1/watch/namespaces/kube-system,TestParseResourcePath//api/v1/,TestParseResourcePath//api/v1/namespaces/kube-system/pods/foo,TestParseResourcePath//api/,TestParseResourcePath//api/v1/pods,TestGetKubeCreds/legacy_proxy_service,_no_kube_creds,TestParseResourcePath//api/v1/watch/namespaces/kube-system/pods,TestAuthenticate/local_user_and_remote_cluster,TestParseResourcePath//apis/apiregistration.k8s.io/v1/apiservices/foo/status,TestGetKubeCreds/Missing_cluster_does_not_fail_operation,TestParseResourcePath//apis/apps/v1/,TestParseResourcePath//apis/apps,TestGetKubeCreds/proxy_service,_with_kube_creds,TestGetKubeCreds,TestAuthenticate/authorization_failure,TestParseResourcePath/#00,TestMTLSClientCAs/1_CA,TestNewClusterSessionDirect,TestParseResourcePath//api,TestGetKubeCreds/kubernetes_service,_no_kube_creds,TestAuthenticate/local_user_and_cluster,TestAuthenticate/kube_users_passed_in_request,TestAuthenticate,TestParseResourcePath//api/v1/watch/pods,TestAuthenticate/local_user_and_cluster,_no_kubeconfig,TestAuthenticate/local_user_and_remote_cluster,_no_tunnel,TestGetServerInfo,TestMTLSClientCAs/100_CAs,TestParseResourcePath//api/v1/nodes/foo/proxy/bar,TestAuthenticate/custom_kubernetes_cluster_in_remote_cluster,TestMTLSClientCAs/1000_CAs,TestAuthenticate/unknown_kubernetes_cluster_in_local_cluster > /workspace/stdout.log 2> /workspace/stderr.log
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
