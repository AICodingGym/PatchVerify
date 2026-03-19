#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard e1152352999e04f347aaaee64b5b4e361631e7ac
git checkout e1152352999e04f347aaaee64b5b4e361631e7ac

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore\|problem_statement\.md\|hints_text\.md\|CLAUDE\.md\|AGENTS\.md\|\.claudeignore\|\.copilotignore\|\.cursorignore\|\.cursorrules\|\.devcontainer\|\.vscode" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 7eb77f5b5127c847481bcf600b4dca2b7a85cf3e -- config/portscan_test.go models/packages_test.go scanner/base_test.go
fi

# Run tests
bash /workspace/run_script.sh TestEOL_IsStandardSupportEnded/CentOS_7_supported,Test_majorDotMinor/empty,TestEOL_IsStandardSupportEnded/Ubuntu_14.04_eol,TestEOL_IsStandardSupportEnded/freebsd_11_supported,TestEOL_IsStandardSupportEnded/amazon_linux_1_eol_on_2023-6-30,TestEOL_IsStandardSupportEnded/Debian_8_supported,TestPortScanConf_getScanTechniques/nil,TestEOL_IsStandardSupportEnded/Ubuntu_18.04_ext_supported,TestEOL_IsStandardSupportEnded/Ubuntu_14.10_eol,TestEOL_IsStandardSupportEnded/Ubuntu_12.10_not_found,TestEOL_IsStandardSupportEnded/Debian_10_supported,TestEOL_IsStandardSupportEnded/RHEL8_supported,TestScanModule_IsZero/zero,TestEOL_IsStandardSupportEnded/Alpine_3.11_supported,TestEOL_IsStandardSupportEnded/CentOS_9_not_found,TestEOL_IsStandardSupportEnded/amazon_linux_1_supported,TestPortScanConf_getScanTechniques/unknown,TestEOL_IsStandardSupportEnded/CentOS_8_supported,TestEOL_IsStandardSupportEnded/freebsd_12_supported,TestEOL_IsStandardSupportEnded/RHEL6_eol,TestScanModule_IsZero,TestPortScanConf_IsZero/zero,TestDistro_MajorVersion,TestEOL_IsStandardSupportEnded/Oracle_Linux_7_supported,Test_majorDotMinor/major_dot_minor,TestEOL_IsStandardSupportEnded/Alpine_3.14_not_found,TestEOL_IsStandardSupportEnded/RHEL9_not_found,TestEOL_IsStandardSupportEnded/Ubuntu_20.10_supported,TestEOL_IsStandardSupportEnded/Ubuntu_21.04_supported,TestScanModule_validate/err,TestPortScanConf_IsZero,TestEOL_IsStandardSupportEnded/Alpine_3.12_supported,TestEOL_IsStandardSupportEnded/Ubuntu_16.04_supported,Test_majorDotMinor/major,TestToCpeURI,TestEOL_IsStandardSupportEnded/Debian_9_supported,Test_majorDotMinor/major_dot_minor_dot_release,TestEOL_IsStandardSupportEnded/freebsd_11_eol_on_2021-9-30,TestEOL_IsStandardSupportEnded/Oracle_Linux_6_eol,TestEOL_IsStandardSupportEnded/Oracle_Linux_8_supported,TestEOL_IsStandardSupportEnded/RHEL7_supported,TestEOL_IsStandardSupportEnded/freebsd_10_eol,TestEOL_IsStandardSupportEnded/alpine_3.10_supported,TestPortScanConf_IsZero/not_zero,TestPortScanConf_getScanTechniques/single,TestEOL_IsStandardSupportEnded/CentOS_6_eol,TestScanModule_validate/valid,TestEOL_IsStandardSupportEnded/Debian_11_supported,TestEOL_IsStandardSupportEnded/Ubuntu_18.04_supported,TestSyslogConfValidate,TestEOL_IsStandardSupportEnded/Alpine_3.9_eol,TestScanModule_validate,TestEOL_IsStandardSupportEnded,TestPortScanConf_getScanTechniques/multiple,TestEOL_IsStandardSupportEnded/Oracle_Linux_9_not_found,TestScanModule_IsZero/not_zero,Test_majorDotMinor,TestPortScanConf_getScanTechniques,TestEOL_IsStandardSupportEnded/amazon_linux_2_supported > /workspace/stdout.log 2> /workspace/stderr.log
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
