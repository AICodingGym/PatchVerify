#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard dafcf377a004506ff840d713bfd7359848ef7b8b
git checkout dafcf377a004506ff840d713bfd7359848ef7b8b

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 288c5519ce0dec9622361a5e5d6cd36aa2d9e348 -- tool/tctl/common/auth_command_test.go
fi

# Run tests
bash /workspace/run_script.sh TestAuthSignKubeconfig/k8s_proxy_running_locally_without_public_addr,TestAuthSignKubeconfig/--kube-cluster_specified_with_invalid_cluster,TestDatabaseServerResource/get_specific_database_server,TestAuthSignKubeconfig/--kube-cluster_specified_with_valid_cluster,TestGenerateDatabaseKeys/database_certificate,TestCheckKubeCluster/local_cluster,_empty_kube_cluster,TestCheckKubeCluster/remote_cluster,_empty_kube_cluster,TestTrimDurationSuffix/trim_minutes/seconds,TestCheckKubeCluster/local_cluster,_invalid_kube_cluster,TestAuthSignKubeconfig/k8s_proxy_running_locally_with_public_addr,TestTrimDurationSuffix,TestDatabaseResource,TestTrimDurationSuffix/trim_seconds,TestTrimDurationSuffix/does_not_trim_non-zero_suffix,TestGenerateDatabaseKeys/mongodb_certificate,TestAppResource,TestDatabaseServerResource/get_all_database_servers,TestCheckKubeCluster/local_cluster,_valid_kube_cluster,TestCheckKubeCluster/local_cluster,_empty_kube_cluster,_no_registered_kube_clusters,TestAuthSignKubeconfig/--proxy_specified,TestCheckKubeCluster,TestGenerateDatabaseKeys/database_certificate_multiple_SANs,TestAuthSignKubeconfig/k8s_proxy_from_cluster_info,TestCheckKubeCluster/non-k8s_output_format,TestGenerateDatabaseKeys,TestCheckKubeCluster/remote_cluster,_non-empty_kube_cluster,TestDatabaseServerResource,TestTrimDurationSuffix/does_not_trim_zero_in_the_middle,TestAuthSignKubeconfig,TestDatabaseServerResource/remove_database_server > /workspace/stdout.log 2> /workspace/stderr.log
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
