#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 2d075079f112658b02e67b409958d5872477aad6
git checkout 2d075079f112658b02e67b409958d5872477aad6

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore\|problem_statement\.md\|hints_text\.md\|CLAUDE\.md\|AGENTS\.md\|\.claudeignore\|\.copilotignore\|\.cursorignore\|\.cursorrules\|\.devcontainer\|\.vscode" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 54e73c2f5466ef5daec3fb30922b9ac654e4ed25 -- models/scanresults_test.go models/vulninfos_test.go
fi

# Run tests
bash /workspace/run_script.sh TestVulnInfo_AttackVector/3.0:N,TestFindByBinName,TestMaxCvss2Scores,TestVulnInfo_AttackVector/3.1:N,TestVulnInfos_FilterByCvssOver/over_high,TestSourceLinks,TestLibraryScanners_Find/miss,TestDistroAdvisories_AppendIfMissing/append,TestVulnInfos_FilterIgnoreCves,TestSummaries,Test_parseListenPorts/normal,TestVulnInfos_FilterUnfixed,TestLibraryScanners_Find/multi_file,TestVulnInfo_AttackVector/2.0:L,TestCvss3Scores,TestPackage_FormatVersionFromTo/fixed,TestMaxCvss3Scores,TestExcept,TestVulnInfos_FilterIgnorePkgs/filter_pkgs_2,TestCountGroupBySeverity,TestCvss2Scores,TestFormatMaxCvssScore,TestVulnInfos_FilterIgnorePkgs,Test_IsRaspbianPackage/verRegExp,TestVulnInfos_FilterByCvssOver/over_7.0,TestDistroAdvisories_AppendIfMissing/duplicate_no_append,TestPackage_FormatVersionFromTo/nfy3,Test_IsRaspbianPackage/debianPackage,Test_IsRaspbianPackage/nameList,TestAddBinaryName,Test_parseListenPorts/ipv6_loopback,TestIsDisplayUpdatableNum,TestTitles,TestPackage_FormatVersionFromTo/nfy2,Test_parseListenPorts/asterisk,TestVulnInfo_AttackVector/2.0:A,TestVulnInfos_FilterUnfixed/filter_ok,Test_parseListenPorts,TestAppendIfMissing,TestMergeNewVersion,TestMerge,TestVulnInfo_AttackVector,Test_parseListenPorts/empty,TestVulnInfos_FilterByCvssOver,TestVulnInfos_FilterIgnorePkgs/filter_pkgs_3,TestPackage_FormatVersionFromTo/nfy,TestStorePackageStatuses,TestVulnInfo_AttackVector/2.0:N,TestVulnInfos_FilterIgnorePkgs/filter_pkgs_1,TestPackage_FormatVersionFromTo,Test_IsRaspbianPackage,TestVulnInfos_FilterIgnoreCves/filter_ignored,TestLibraryScanners_Find,TestLibraryScanners_Find/single_file,TestSortByConfident,Test_IsRaspbianPackage/nameRegExp,TestPackage_FormatVersionFromTo/nfy#01,TestToSortedSlice,TestSortPackageStatues,TestMaxCvssScores,TestDistroAdvisories_AppendIfMissing > /workspace/stdout.log 2> /workspace/stderr.log
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
