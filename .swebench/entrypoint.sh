#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 12cdaed68d9445f88a540778d2e13443e0011ebb
git checkout 12cdaed68d9445f88a540778d2e13443e0011ebb

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 3a5c1e26394df2cb4fb3f01147fb9979662972c5 -- lib/backend/kubernetes/kubernetes_test.go
fi

# Run tests
bash /workspace/run_script.sh TestBackend_Exists/secret_exists,TestBackend_Put/secret_exists_and_has_keys,TestBackend_Get/secret_exists_and_key_is_present_but_empty,TestBackend_Get/secret_exists_but_key_not_present,TestBackend_Put,TestBackend_Exists/secret_exists_but_generates_an_error_because_TELEPORT_REPLICA_NAME_is_not_set,TestBackend_Put/secret_does_not_exist_and_should_be_created,TestBackend_Get/secret_exists_and_key_is_present,TestBackend_Exists/secret_exists_but_generates_an_error_because_KUBE_NAMESPACE_is_not_set,TestBackend_Get/secret_does_not_exist,TestBackend_Exists,TestBackend_Exists/secret_does_not_exist,TestBackend_Get > /workspace/stdout.log 2> /workspace/stderr.log
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
