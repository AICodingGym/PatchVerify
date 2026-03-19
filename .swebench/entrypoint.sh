#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 0b9ec05181360e3fdb4a314152927f6f3ccb746d
git checkout 0b9ec05181360e3fdb4a314152927f6f3ccb746d

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore\|problem_statement\.md\|hints_text\.md\|CLAUDE\.md\|AGENTS\.md\|\.claudeignore\|\.copilotignore\|\.cursorignore\|\.cursorrules\|\.devcontainer\|\.vscode" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout f0b3a8b1db98eb1bd32685f1c36c41a99c3452ed -- models/vulninfos_test.go
fi

# Run tests
bash /workspace/run_script.sh TestLibraryScanners_Find/miss,TestRemoveRaspbianPackFromResult,TestScanResult_Sort/already_asc,TestVulnInfos_FilterUnfixed/filter_ok,Test_NewPortStat/asterisk,TestVulnInfos_FilterIgnoreCves/filter_ignored,TestVulnInfo_AttackVector/2.0:A,Test_IsRaspbianPackage/debianPackage,TestVulnInfos_FilterUnfixed,TestMaxCvss2Scores,TestScanResult_Sort/sort,TestVulnInfos_FilterByCvssOver/over_7.0,TestPackage_FormatVersionFromTo/nfy,TestLibraryScanners_Find/single_file,TestVulnInfos_FilterByCvssOver/over_high,Test_IsRaspbianPackage/nameRegExp,TestLibraryScanners_Find,TestPackage_FormatVersionFromTo/nfy3,TestSortPackageStatues,TestDistroAdvisories_AppendIfMissing,TestExcept,TestScanResult_Sort,TestVulnInfo_AttackVector/2.0:L,TestVulnInfo_AttackVector/2.0:N,TestFindByBinName,TestSortByConfident,TestVulnInfo_AttackVector/3.0:N,TestVulnInfos_FilterIgnorePkgs,TestCvss2Scores,TestDistroAdvisories_AppendIfMissing/duplicate_no_append,TestVulnInfos_FilterIgnorePkgs/filter_pkgs_3,Test_IsRaspbianPackage,TestPackage_FormatVersionFromTo,TestMaxCvss3Scores,TestPackage_FormatVersionFromTo/nfy2,TestIsDisplayUpdatableNum,TestPackage_FormatVersionFromTo/nfy#01,TestTitles,TestDistroAdvisories_AppendIfMissing/append,Test_NewPortStat/normal,TestCvss3Scores,TestVulnInfos_FilterIgnorePkgs/filter_pkgs_1,TestToSortedSlice,TestStorePackageStatuses,TestMerge,TestMergeNewVersion,Test_NewPortStat,TestVulnInfos_FilterByCvssOver,TestVulnInfos_FilterIgnorePkgs/filter_pkgs_2,Test_NewPortStat/empty,TestPackage_FormatVersionFromTo/fixed,TestVulnInfo_AttackVector,TestVulnInfo_AttackVector/3.1:N,TestSourceLinks,Test_NewPortStat/ipv6_loopback,TestCountGroupBySeverity,TestSummaries,Test_IsRaspbianPackage/verRegExp,TestAppendIfMissing,TestFormatMaxCvssScore,TestLibraryScanners_Find/multi_file,TestVulnInfos_FilterIgnoreCves,Test_IsRaspbianPackage/nameList,TestMaxCvssScores,TestAddBinaryName > /workspace/stdout.log 2> /workspace/stderr.log
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
