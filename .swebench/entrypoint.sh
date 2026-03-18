#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard fe3f1b99245266e848f7b8f240f1f81ae3ff04df
git checkout fe3f1b99245266e848f7b8f240f1f81ae3ff04df

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 9aa0d87a21bede91c2b45c32187456bb69455e92 -- config/tomlloader_test.go
fi

# Run tests
bash /workspace/run_script.sh TestMajorVersion,TestIsValidImage/no_image_name_with_digest,TestToCpeURI,TestIsValidImage/ok_with_tag,TestIsValidImage,TestIsValidImage/no_tag_and_digest,TestSyslogConfValidate,TestIsValidImage/no_image_name_with_tag,TestIsValidImage/ok_with_digest > /workspace/stdout.log 2> /workspace/stderr.log
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
