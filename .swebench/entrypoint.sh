#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 7c209cc9dc71e30bf762677d6a380ddc93d551ec
git checkout 7c209cc9dc71e30bf762677d6a380ddc93d551ec

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 2923cbc645fbc7a37d50398eb2ab8febda8c3264 -- oval/util_test.go
fi

# Run tests
bash /workspace/run_script.sh Test_lessThan/newVer_and_ovalmodels.Package_both_have_underscoreMinorversion.,Test_rhelDownStreamOSVersionToRHEL/remove_rocky.,Test_rhelDownStreamOSVersionToRHEL/noop,TestPackNamesOfUpdateDebian,Test_lessThan/neither_newVer_nor_ovalmodels.Package_have_underscoreMinorversion.,TestParseCvss2,TestParseCvss3,Test_ovalResult_Sort,TestPackNamesOfUpdate,Test_ovalResult_Sort/already_sorted,Test_rhelDownStreamOSVersionToRHEL/remove_minor,Test_rhelDownStreamOSVersionToRHEL,TestUpsert,Test_lessThan/only_ovalmodels.Package_has_underscoreMinorversion.,Test_lessThan,Test_lessThan/only_newVer_has_underscoreMinorversion.,Test_ovalResult_Sort/sort,TestDefpacksToPackStatuses,TestIsOvalDefAffected,Test_rhelDownStreamOSVersionToRHEL/remove_centos. > /workspace/stdout.log 2> /workspace/stderr.log
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
