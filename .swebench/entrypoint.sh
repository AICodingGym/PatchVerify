#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 31b8f1571759ebf5fe082a18a2efd1e8ee6148e7
git checkout 31b8f1571759ebf5fe082a18a2efd1e8ee6148e7

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 73cc189b0e9636d418c4470ecce0d9af5dae2f02 -- lib/tlsca/ca_test.go
fi

# Run tests
bash /workspace/run_script.sh TestPrincipals/FromCertAndSigner,TestPrincipals,TestIdentity_ToFromSubject,TestPrincipals/FromTLSCertificate,TestKubeExtensions,TestIdentity_ToFromSubject/device_extensions,TestAzureExtensions,TestGCPExtensions,TestPrincipals/FromKeys,TestRenewableIdentity > /workspace/stdout.log 2> /workspace/stderr.log
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
