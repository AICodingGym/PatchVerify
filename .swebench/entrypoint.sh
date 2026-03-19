#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 43b46cb324f64076e4d9e807c0b60c4b9ce11a82
git checkout 43b46cb324f64076e4d9e807c0b60c4b9ce11a82

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore\|problem_statement\.md\|hints_text\.md" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout b8db2e0b74f60cb7d45f710f255e061f054b6afc -- models/scanresults_test.go
fi

# Run tests
bash /workspace/run_script.sh TestDistroAdvisories_AppendIfMissing/append,TestMaxCvssScores,TestPackage_FormatVersionFromTo/nfy2,TestDistroAdvisories_AppendIfMissing/duplicate_no_append,TestVulnInfos_FilterUnfixed/filter_ok,Test_NewPortStat/empty,TestMergeNewVersion,TestScanResult_Sort/sort,Test_IsRaspbianPackage/nameList,TestTitles,TestToSortedSlice,TestVulnInfos_FilterUnfixed,TestVulnInfos_FilterIgnorePkgs/filter_pkgs_3,TestVulnInfos_FilterIgnorePkgs/filter_pkgs_1,TestExcept,TestAddBinaryName,TestSummaries,TestVulnInfos_FilterByCvssOver,TestCvss3Scores,TestSortByConfident,TestLibraryScanners_Find/multi_file,TestFormatMaxCvssScore,TestVulnInfos_FilterIgnorePkgs,TestIsDisplayUpdatableNum,TestPackage_FormatVersionFromTo/nfy3,TestScanResult_Sort/already_asc,TestPackage_FormatVersionFromTo,TestVulnInfos_FilterIgnoreCves,TestLibraryScanners_Find,TestVulnInfos_FilterIgnorePkgs/filter_pkgs_2,TestMerge,TestVulnInfos_FilterIgnoreCves/filter_ignored,TestVulnInfo_AttackVector/3.0:N,TestVulnInfo_AttackVector/2.0:A,TestAppendIfMissing,Test_NewPortStat/ipv6_loopback,TestPackage_FormatVersionFromTo/fixed,TestScanResult_Sort,TestVulnInfos_FilterByCvssOver/over_high,Test_NewPortStat/normal,TestMaxCvss3Scores,Test_IsRaspbianPackage/nameRegExp,TestStorePackageStatuses,TestMaxCvss2Scores,TestFindByBinName,TestRemoveRaspbianPackFromResult,TestVulnInfo_AttackVector/3.1:N,TestSourceLinks,TestSortPackageStatues,Test_NewPortStat,TestPackage_FormatVersionFromTo/nfy,TestVulnInfo_AttackVector/2.0:N,Test_IsRaspbianPackage/verRegExp,TestDistroAdvisories_AppendIfMissing,Test_NewPortStat/asterisk,Test_IsRaspbianPackage/debianPackage,TestCountGroupBySeverity,TestCvss2Scores,TestVulnInfo_AttackVector,TestVulnInfo_AttackVector/2.0:L,TestVulnInfos_FilterByCvssOver/over_7.0,TestPackage_FormatVersionFromTo/nfy#01,Test_IsRaspbianPackage,TestLibraryScanners_Find/miss,TestLibraryScanners_Find/single_file > /workspace/stdout.log 2> /workspace/stderr.log
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
