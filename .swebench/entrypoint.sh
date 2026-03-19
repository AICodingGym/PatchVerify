#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard bf14b5f61f7a65cb64cf762c71885a413a9fcb66
git checkout bf14b5f61f7a65cb64cf762c71885a413a9fcb66

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore\|problem_statement\.md\|hints_text\.md\|CLAUDE\.md\|AGENTS\.md\|\.claudeignore\|\.copilotignore\|\.cursorignore\|\.cursorrules\|\.devcontainer\|\.vscode" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout be7b9114cc9545e68fb0ee7bc63d7ec53d1a00ad -- contrib/trivy/parser/v2/parser_test.go models/library_test.go
fi

# Run tests
bash /workspace/run_script.sh TestCveContents_Sort/sorted,TestScanResult_Sort/sort_JVN_by_cvss3,_cvss2,_sourceLink,TestDistroAdvisories_AppendIfMissing/append,TestVulnInfo_AttackVector/3.1:N,TestPackage_FormatVersionFromTo/nfy2,TestIsDisplayUpdatableNum,TestScanResult_Sort/sort_JVN_by_cvss3,_cvss2,TestVulnInfos_FilterByConfidenceOver/over_20,TestCvss3Scores,TestPackage_FormatVersionFromTo/nfy,Test_NewPortStat/normal,TestLibraryScanners_Find/multi_file,TestVulnInfos_FilterIgnoreCves,TestFindByBinName,TestFormatMaxCvssScore,TestScanResult_Sort/sort,TestPackage_FormatVersionFromTo/nfy3,TestAddBinaryName,TestTitles,TestPackage_FormatVersionFromTo,Test_NewPortStat,TestExcept,TestCveContents_Sort/sort_JVN_by_cvss3,_cvss2,_sourceLink,TestParse,TestVulnInfos_FilterIgnorePkgs/filter_pkgs_3,TestLibraryScanners_Find,TestNewCveContentType/redhat,TestVulnInfo_PatchStatus/windows_unfixed,TestGetCveContentTypes/freebsd,TestMergeNewVersion,TestScanResult_Sort/sort_JVN_by_cvss_v3,TestVulnInfos_FilterByCvssOver/over_high,TestCveContents_Sort/sort_JVN_by_cvss3,_cvss2,TestNewCveContentType,TestNewCveContentType/centos,TestVulnInfos_FilterByConfidenceOver,TestSortByConfident,TestVulnInfos_FilterIgnorePkgs/filter_pkgs_2,Test_IsRaspbianPackage/verRegExp,Test_IsRaspbianPackage/nameList,TestGetCveContentTypes/debian,TestCvss2Scores,Test_IsRaspbianPackage,TestCveContents_Sort,TestCountGroupBySeverity,TestMaxCvss3Scores,TestSourceLinks,TestVulnInfos_FilterUnfixed,TestMaxCvss2Scores,TestPackage_FormatVersionFromTo/fixed,TestNewCveContentType/unknown,TestVulnInfo_PatchStatus/package_fixed,TestVulnInfos_FilterUnfixed/filter_ok,Test_IsRaspbianPackage/debianPackage,TestParseError,TestVulnInfos_FilterByConfidenceOver/over_100,TestVulnInfo_PatchStatus/package_unknown,TestAppendIfMissing,TestMerge,TestScanResult_Sort,TestDistroAdvisories_AppendIfMissing,Test_NewPortStat/empty,TestSummaries,TestDistroAdvisories_AppendIfMissing/duplicate_no_append,TestLibraryScanners_Find/single_file,TestVulnInfo_AttackVector/2.0:L,TestGetCveContentTypes,TestVulnInfos_FilterIgnorePkgs/filter_pkgs_1,TestStorePackageStatuses,TestVulnInfo_AttackVector,TestVulnInfo_PatchStatus,TestVulnInfos_FilterByCvssOver,TestLibraryScanners_Find/miss,TestVulnInfo_PatchStatus/windows_fixed,Test_NewPortStat/asterisk,TestVulnInfo_PatchStatus/cpe,TestSortPackageStatues,Test_NewPortStat/ipv6_loopback,TestVulnInfo_PatchStatus/package_unfixed,TestVulnInfo_AttackVector/2.0:N,TestGetCveContentTypes/ubuntu,TestVulnInfo_AttackVector/2.0:A,TestToSortedSlice,TestVulnInfo_AttackVector/3.0:N,TestVulnInfos_FilterIgnorePkgs,TestMaxCvssScores,TestRemoveRaspbianPackFromResult,Test_IsRaspbianPackage/nameRegExp,TestVulnInfos_FilterByCvssOver/over_7.0,TestPackage_FormatVersionFromTo/nfy#01,TestVulnInfos_FilterByConfidenceOver/over_0,TestScanResult_Sort/already_asc,TestVulnInfos_FilterIgnoreCves/filter_ignored,TestGetCveContentTypes/redhat > /workspace/stdout.log 2> /workspace/stderr.log
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
