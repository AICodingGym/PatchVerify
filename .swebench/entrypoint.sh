#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 8a8ab8cb18161244ee6f078b43a89b3588d99a4d
git checkout 8a8ab8cb18161244ee6f078b43a89b3588d99a4d

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup (checkout gold test files)
git checkout 4b680b996061044e93ef5977a081661665d3360a -- models/scanresults_test.go scan/freebsd_test.go

# Run tests
bash /workspace/run_script.sh TestParseIp,TestSplitAptCachePolicy,TestIsRunningKernelRedHatLikeLinux,TestDecorateCmd,TestParseDockerPs,TestParsePkgVersion,TestParseChangelog/realvnc-vnc-server,TestGetCveIDsFromChangelog,TestParseApkInfo,TestParseLxdPs,TestIsDisplayUpdatableNum,TestScanUpdatablePackages,TestIsRunningKernelSUSE,Test_base_parseLsProcExe,TestGetChangelogCache,Test_base_parseLsOf,TestParseAptCachePolicy,TestParseBlock,TestParseInstalledPackagesLinesRedhat,Test_base_parseLsOf/lsof,TestParseSystemctlStatus,TestParseChangelog,TestParseYumCheckUpdateLinesAmazon,TestParseCheckRestart,TestParseApkVersion,TestParseIfconfig,TestParseNeedsRestarting,TestViaHTTP,TestParsePkgInfo,Test_debian_parseGetPkgName/success,TestParseOSRelease,Test_base_parseGrepProcMap,TestParseScanedPackagesLineRedhat,TestGetUpdatablePackNames,Test_base_parseGrepProcMap/systemd,TestParseChangelog/vlc,Test_base_parseLsProcExe/systemd,TestIsAwsInstanceID,TestParseYumCheckUpdateLines,TestScanUpdatablePackage,Test_debian_parseGetPkgName,TestSplitIntoBlocks,TestParseYumCheckUpdateLine > /workspace/stdout.log 2> /workspace/stderr.log

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
