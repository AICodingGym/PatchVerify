#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard dce837950529084d34c6815fa66e59a4f68fa8e4
git checkout dce837950529084d34c6815fa66e59a4f68fa8e4

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore\|problem_statement\.md\|hints_text\.md" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout e049df50fa1eecdccc5348e27845b5c783ed7c76 -- models/scanresults_test.go
fi

# Run tests
bash /workspace/run_script.sh TestCveContents_PatchURLs,TestCveContents_UniqCweIDs,TestNewCveContentType,TestFormatMaxCvssScore,TestCveContents_SSVC,TestToSortedSlice,TestCveContents_Except,TestVulnInfos_FilterByCvssOver,TestRenameKernelSourcePackageName,Test_IsRaspbianPackage,TestAppendIfMissing,TestCveContents_Cpes,TestRemoveRaspbianPackFromResult,TestSourceLinks,TestIsDisplayUpdatableNum,TestMergeNewVersion,TestVulnInfos_FilterIgnoreCves,Test_NewPortStat,TestVulnInfos_FilterIgnorePkgs,TestScanResult_Sort,TestAddBinaryName,TestCvss3Scores,TestVulnInfo_Cvss40Scores,TestVulnInfos_FilterByConfidenceOver,TestIsKernelSourcePackage,TestVulnInfos_FilterUnfixed,TestFindByBinName,TestTitles,TestCveContents_CweIDs,TestCveContents_Sort,TestCveContent_Empty,TestCveContentTypes_Except,TestMaxCvssScores,TestCvss2Scores,TestSummaries,TestSortByConfident,TestVulnInfo_AttackVector,TestGetCveContentTypes,TestMaxCvss3Scores,TestVulnInfo_PatchStatus,TestMerge,TestMaxCvss2Scores,TestCveContents_References,TestSortPackageStatues,TestStorePackageStatuses,TestCountGroupBySeverity,TestLibraryScanners_Find,TestDistroAdvisories_AppendIfMissing,TestVulnInfo_MaxCvss40Score,TestPackage_FormatVersionFromTo > /workspace/stdout.log 2> /workspace/stderr.log
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
