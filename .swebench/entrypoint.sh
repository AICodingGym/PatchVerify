#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 8dd44097778951eaa6976631d35bc418590d1555
git checkout 8dd44097778951eaa6976631d35bc418590d1555

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 96820c3ad10b0b2305e8877b6b303f7fafdf815f -- internal/oci/ecr/credentials_store_test.go internal/oci/ecr/ecr_test.go internal/oci/ecr/mock_Client_test.go internal/oci/ecr/mock_PrivateClient_test.go internal/oci/ecr/mock_PublicClient_test.go internal/oci/file_test.go
fi

# Run tests
bash /workspace/run_script.sh TestStore_List,TestFile,TestWithCredentials,TestStore_Fetch_InvalidMediaType,TestStore_FetchWithECR,TestAuthenicationTypeIsValid,TestParseReference,TestStore_Fetch,TestECRCredential,TestStore_Copy,TestPrivateClient,TestDefaultClientFunc,TestWithManifestVersion,TestCredential,TestPublicClient,TestStore_Build > /workspace/stdout.log 2> /workspace/stderr.log
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
