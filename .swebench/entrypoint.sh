#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 2534098509025989abe9b69bebb6fba6e9c5488b
git checkout 2534098509025989abe9b69bebb6fba6e9c5488b

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore\|problem_statement\.md\|hints_text\.md" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 9a32a94806b54141b7ff12503c48da680ebcf199 -- gost/debian_test.go models/vulninfos_test.go oval/util_test.go
fi

# Run tests
bash /workspace/run_script.sh TestDebian_Supported/9_is_supported,TestDebian_Supported/empty_string_is_not_supported_yet,TestDebian_Supported/10_is_supported,TestDebian_Supported/11_is_not_supported_yet,TestDebian_Supported/8_is_supported,TestParseCwe,TestSetPackageStates,TestDebian_Supported > /workspace/stdout.log 2> /workspace/stderr.log
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
