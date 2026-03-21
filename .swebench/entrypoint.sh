#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 2cd2d1a9a21e29c51f63c5dab938b9efc09bb862
git checkout 2cd2d1a9a21e29c51f63c5dab938b9efc09bb862

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup (checkout gold test files)
git checkout 436341a4a522dc83eb8bddd1164b764c8dd6bc45 -- config/os_test.go scanner/windows_test.go

# Run tests
bash /workspace/run_script.sh TestEOL_IsStandardSupportEnded/Fedora_38_supported,TestEOL_IsStandardSupportEnded/Fedora_37_eol_since_2023-12-6,TestEOL_IsStandardSupportEnded,Test_windows_detectKBsFromKernelVersion/10.0.19045.2130,Test_windows_detectKBsFromKernelVersion/10.0.20348.9999,Test_windows_detectKBsFromKernelVersion/10.0.19045.2129,Test_windows_detectKBsFromKernelVersion,Test_windows_detectKBsFromKernelVersion/10.0.20348.1547,TestEOL_IsStandardSupportEnded/Fedora_40_supported,Test_windows_detectKBsFromKernelVersion/10.0.22621.1105 > /workspace/stdout.log 2> /workspace/stderr.log

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
    failed = [t for t in data.get('tests', []) if t.get('status') in ('FAILED', 'ERROR')]
    if failed:
        print(f'{len(failed)} test(s) FAILED')
        sys.exit(1)
    print('All tests passed')
except Exception as e:
    print(f'Could not check results: {e}')
    sys.exit(1)
"
