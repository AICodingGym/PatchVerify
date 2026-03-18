#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 481158d6310e36e3c1115e25ab3fdf1c1ed45e60
git checkout 481158d6310e36e3c1115e25ab3fdf1c1ed45e60

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 3fa6904377c006497169945428e8197158667910 -- lib/kube/proxy/forwarder_test.go
fi

# Run tests
bash /workspace/run_script.sh TestParseResourcePath//api/v1/watch/namespaces/kube-system/pods/foo,TestParseResourcePath,TestParseResourcePath//apis,TestParseResourcePath//api/v1/pods,TestParseResourcePath/#00,TestParseResourcePath//api/v1/namespaces/kube-system/pods,TestAuthenticate/unsupported_user_type,TestParseResourcePath//apis/apps/v1/,TestAuthenticate/local_user_and_cluster,_no_tunnel,TestParseResourcePath//apis/apps,TestParseResourcePath//api/v1/,TestParseResourcePath//api/v1/watch/pods,TestParseResourcePath//api/v1/nodes/foo/proxy/bar,TestParseResourcePath//apis/apiregistration.k8s.io/v1/apiservices/foo/status,TestAuthenticate/remote_user_and_local_cluster,TestParseResourcePath//apis/,TestAuthenticate/unknown_kubernetes_cluster_in_local_cluster,TestAuthenticate/custom_kubernetes_cluster_in_remote_cluster,TestGetKubeCreds/proxy_service,_no_kube_creds,TestParseResourcePath//apis/apps/v1,TestGetKubeCreds/kubernetes_service,_no_kube_creds,TestGetKubeCreds/proxy_service,_with_kube_creds,TestAuthenticate/local_user_and_cluster,_no_kubeconfig,TestParseResourcePath//api/v1/namespaces/kube-system/pods/foo/exec,TestParseResourcePath//,TestAuthenticate/local_user_and_remote_cluster,TestParseResourcePath//apis/apps/,TestParseResourcePath//api/v1/namespaces/kube-system,TestAuthenticate/remote_user_and_remote_cluster,TestParseResourcePath//api/,TestParseResourcePath//api,TestAuthenticate/authorization_failure,TestAuthenticate/custom_kubernetes_cluster_in_local_cluster,TestAuthenticate/local_user_and_remote_cluster,_no_tunnel,TestParseResourcePath//apis/rbac.authorization.k8s.io/v1/watch/clusterroles,TestAuthenticate/local_user_and_cluster,TestParseResourcePath//apis/rbac.authorization.k8s.io/v1/clusterroles/foo,TestParseResourcePath//api/v1/watch/namespaces/kube-system/pods,TestAuthenticate/kube_users_passed_in_request,TestParseResourcePath//api/v1,TestAuthenticate/local_user_and_remote_cluster,_no_kubeconfig,TestParseResourcePath//apis/rbac.authorization.k8s.io/v1/watch/clusterroles/foo,TestAuthenticate,TestGetKubeCreds,TestParseResourcePath//api/v1/namespaces/kube-system/pods/foo,TestGetKubeCreds/kubernetes_service,_with_kube_creds,TestParseResourcePath//apis/rbac.authorization.k8s.io/v1/clusterroles,TestParseResourcePath//api/v1/watch/namespaces/kube-system > /workspace/stdout.log 2> /workspace/stderr.log
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
