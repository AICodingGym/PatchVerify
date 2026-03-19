#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard e4f1e03f6234bbe88564bdfc2d23f120db3c67a6
git checkout e4f1e03f6234bbe88564bdfc2d23f120db3c67a6

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore\|problem_statement\.md\|hints_text\.md\|CLAUDE\.md\|AGENTS\.md\|\.claudeignore\|\.copilotignore\|\.cursorignore\|\.cursorrules\|\.devcontainer\|\.vscode" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 3c1489e588dacea455ccf4c352a3b1006902e2d4 -- models/scanresults_test.go models/vulninfos_test.go report/syslog_test.go
fi

# Run tests
bash /workspace/run_script.sh TestLibraryScanners_Find/miss,Test_parseListenPorts/asterisk,Test_IsRaspbianPackage/nameRegExp,Test_parseListenPorts/ipv6_loopback,TestVulnInfo_AttackVector/2.0:A,TestFilterIgnoreCveIDsContainer,TestFilterIgnorePkgsContainer,TestExcept,TestPackage_FormatVersionFromTo/nfy,TestLibraryScanners_Find,TestVulnInfo_AttackVector/2.0:N,TestPackage_FormatVersionFromTo/nfy3,TestSummaries,TestFilterUnfixed,TestMaxCvss3Scores,Test_IsRaspbianPackage,TestPackage_FormatVersionFromTo,TestVulnInfo_AttackVector,TestSortPackageStatues,TestPackage_FormatVersionFromTo/nfy2,TestCvss2Scores,TestCountGroupBySeverity,TestFilterIgnoreCveIDs,TestFindByBinName,TestTitles,Test_IsRaspbianPackage/debianPackage,TestFilterByCvssOver,TestSortByConfident,Test_parseListenPorts,TestMaxCvssScores,TestVulnInfo_AttackVector/3.1:N,TestAppendIfMissing,TestMaxCvss2Scores,TestFilterIgnorePkgs,TestDistroAdvisories_AppendIfMissing/duplicate_no_append,TestAddBinaryName,Test_IsRaspbianPackage/verRegExp,TestMergeNewVersion,TestLibraryScanners_Find/single_file,Test_IsRaspbianPackage/nameList,TestIsDisplayUpdatableNum,TestFormatMaxCvssScore,TestVulnInfo_AttackVector/3.0:N,TestCvss3Scores,Test_parseListenPorts/empty,TestDistroAdvisories_AppendIfMissing/append,TestPackage_FormatVersionFromTo/fixed,TestSourceLinks,Test_parseListenPorts/normal,TestDistroAdvisories_AppendIfMissing,TestLibraryScanners_Find/multi_file,TestPackage_FormatVersionFromTo/nfy#01,TestMerge,TestToSortedSlice,TestStorePackageStatuses,TestVulnInfo_AttackVector/2.0:L > /workspace/stdout.log 2> /workspace/stderr.log
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
