#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 5af1a227339e46c7abf3f2815e4c636a0c01098e
git checkout 5af1a227339e46c7abf3f2815e4c636a0c01098e

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore\|problem_statement\.md\|hints_text\.md" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout e1fab805afcfc92a2a615371d0ec1e667503c254 -- gost/debian_test.go gost/ubuntu_test.go models/packages_test.go scanner/debian_test.go
fi

# Run tests
bash /workspace/run_script.sh TestDebian_Supported,TestNewCveContentType,TestRemoveRaspbianPackFromResult,TestMerge,Test_debian_parseInstalledPackages,TestFormatMaxCvssScore,TestDebian_ConvertToModel,TestIsDisplayUpdatableNum,TestDebian_detect,TestSortByConfident,TestLibraryScanners_Find,TestToSortedSlice,TestMaxCvssScores,TestStorePackageStatuses,Test_NewPortStat,TestVulnInfos_FilterIgnoreCves,TestSortPackageStatues,TestVulnInfo_PatchStatus,TestVulnInfos_FilterByConfidenceOver,TestCvss2Scores,TestFindByBinName,Test_IsRaspbianPackage,TestUbuntu_Supported,TestDebian_CompareSeverity,Test_detect,TestVulnInfos_FilterIgnorePkgs,TestUbuntuConvertToModel,TestPackage_FormatVersionFromTo,TestTitles,TestSourceLinks,TestAppendIfMissing,TestIsKernelSourcePackage,TestSummaries,TestMaxCvss2Scores,TestVulnInfos_FilterByCvssOver,TestScanResult_Sort,TestCvss3Scores,TestExcept,TestDistroAdvisories_AppendIfMissing,TestVulnInfos_FilterUnfixed,TestAddBinaryName,TestGetCveContentTypes,TestCveContents_Sort,TestVulnInfo_AttackVector,TestParseCwe,TestRenameKernelSourcePackageName,TestMaxCvss3Scores,TestMergeNewVersion,TestCountGroupBySeverity > /workspace/stdout.log 2> /workspace/stderr.log

# Parse results
python /workspace/parser.py /workspace/stdout.log /workspace/stderr.log /workspace/output.json || true

# Print outputs for GHA log
echo '=== STDOUT ==='
cat /workspace/stdout.log 2>/dev/null || true
echo '=== STDERR ==='
cat /workspace/stderr.log 2>/dev/null || true
echo '=== PARSED OUTPUT ==='
cat /workspace/output.json 2>/dev/null || true

# Exit non-zero if any test failed
python -c "
import json, sys
try:
    with open('/workspace/output.json') as f:
        data = json.load(f)
    failed = [t for t in data.get('tests', []) if t.get('status') == 'FAILED']
    if failed:
        print(f'{len(failed)} test(s) FAILED')
        sys.exit(1)
    print('All tests passed')
except Exception as e:
    print(f'Could not check results: {e}')
    sys.exit(1)
"
