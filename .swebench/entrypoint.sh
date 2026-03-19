#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 847c6438e7604bf45a6a4efda0925f41b4f14d7f
git checkout 847c6438e7604bf45a6a4efda0925f41b4f14d7f

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore\|problem_statement\.md\|hints_text\.md" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout abd80417728b16c6502067914d27989ee575f0ee -- scan/redhatbase_test.go
fi

# Run tests
bash /workspace/run_script.sh Test_redhatBase_parseRpmQfLine,TestParseChangelog/vlc,Test_redhatBase_parseRpmQfLine/is_not_owned_by_any_package,TestIsAwsInstanceID,Test_matchListenPorts/open_empty,Test_detectScanDest/asterisk,TestParseInstalledPackagesLine,Test_base_parseGrepProcMap,TestViaHTTP,Test_updatePortStatus/nil_affected_procs,Test_matchListenPorts/no_match_port,TestParsePkgInfo,TestScanUpdatablePackage,Test_updatePortStatus,Test_updatePortStatus/update_multi_packages,TestParseAptCachePolicy,TestIsRunningKernelSUSE,Test_matchListenPorts,Test_base_parseLsOf,TestParseApkVersion,Test_updatePortStatus/update_match_asterisk,TestIsRunningKernelRedHatLikeLinux,TestSplitAptCachePolicy,TestParseChangelog/realvnc-vnc-server,TestGetUpdatablePackNames,Test_matchListenPorts/port_empty,TestParseCheckRestart,TestParseIfconfig,Test_debian_parseGetPkgName/success,Test_base_parseLsProcExe/systemd,TestParseYumCheckUpdateLine,Test_detectScanDest/single-addr,Test_detectScanDest/dup-addr-port,Test_base_parseGrepProcMap/systemd,TestParseChangelog,TestParseLxdPs,TestGetCveIDsFromChangelog,Test_debian_parseGetPkgName,TestParseDockerPs,TestParseApkInfo,Test_base_parseLsOf/lsof-duplicate-port,TestParsePkgVersion,TestParseInstalledPackagesLinesRedhat,Test_redhatBase_parseRpmQfLine/permission_denied_will_be_ignored,Test_base_parseLsOf/lsof,TestParseNeedsRestarting,TestParseSystemctlStatus,Test_detectScanDest,Test_updatePortStatus/update_match_multi_address,TestGetChangelogCache,Test_redhatBase_parseRpmQfLine/No_such_file_or_directory_will_be_ignored,Test_matchListenPorts/single_match,TestParseIp,TestScanUpdatablePackages,Test_detectScanDest/multi-addr,Test_updatePortStatus/nil_listen_ports,Test_matchListenPorts/no_match_address,TestParseYumCheckUpdateLinesAmazon,Test_redhatBase_parseDnfModuleList,Test_base_parseLsProcExe,Test_redhatBase_parseDnfModuleList/Success,Test_detectScanDest/empty,TestDecorateCmd,Test_redhatBase_parseRpmQfLine/valid_line,TestParseOSRelease,Test_redhatBase_parseRpmQfLine/err,TestSplitIntoBlocks,Test_matchListenPorts/asterisk_match,TestParseYumCheckUpdateLines,Test_updatePortStatus/update_match_single_address,TestParseBlock > /workspace/stdout.log 2> /workspace/stderr.log
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
