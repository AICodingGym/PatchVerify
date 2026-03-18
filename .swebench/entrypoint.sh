#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 8a611f9ba6d470cbaa3b781c92c96f5fc9f0b3ba
git checkout 8a611f9ba6d470cbaa3b781c92c96f5fc9f0b3ba

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout c11ba27509f733d7d280bdf661cbbe2e7a99df4c -- models/library_test.go
fi

# Run tests
bash /workspace/run_script.sh TestFormatMaxCvssScore,TestSummaries,TestExcept,TestFilterIgnorePkgsContainer,TestLibraryScanners_Find/miss,TestCvss3Scores,TestDistroAdvisories_AppendIfMissing/duplicate_no_append,TestStorePackageStatueses,TestVulnInfo_AttackVector/3.1:N,TestPackage_FormatVersionFromTo/nfy2,TestToSortedSlice,TestCvss2Scores,TestFilterByCvssOver,TestVulnInfo_AttackVector/2.0:L,TestPackage_FormatVersionFromTo,TestMerge,TestDistroAdvisories_AppendIfMissing/append,TestVendorLink,TestPackage_FormatVersionFromTo/nfy3,TestTitles,TestPackage_FormatVersionFromTo/nfy,TestCountGroupBySeverity,TestPackage_FormatVersionFromTo/fixed,TestVulnInfo_AttackVector/3.0:N,TestLibraryScanners_Find,TestVulnInfo_AttackVector,TestSortPackageStatues,TestPackage_FormatVersionFromTo/nfy#01,TestFilterIgnoreCveIDsContainer,TestFilterIgnoreCveIDs,TestVulnInfo_AttackVector/2.0:N,TestAppendIfMissing,TestMergeNewVersion,TestFilterUnfixed,TestIsDisplayUpdatableNum,TestSourceLinks,TestLibraryScanners_Find/multi_file,TestAddBinaryName,TestMaxCvssScores,TestFindByBinName,TestSortByConfiden,TestFilterIgnorePkgs,TestMaxCvss2Scores,TestDistroAdvisories_AppendIfMissing,TestVulnInfo_AttackVector/2.0:A,TestMaxCvss3Scores,TestLibraryScanners_Find/single_file > /workspace/stdout.log 2> /workspace/stderr.log
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
