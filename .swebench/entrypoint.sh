#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard d3bf2a6f26e8e549c0732c26fdcc82725d3c6633
git checkout d3bf2a6f26e8e549c0732c26fdcc82725d3c6633

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup (checkout gold test files)
git checkout 0ec945d0510cdebf92cdd8999f94610772689f14 -- scanner/redhatbase_test.go

# Run tests
bash /workspace/run_script.sh Test_redhatBase_parseInstalledPackagesLine/not_standard_rpm_style_source_package,Test_redhatBase_parseInstalledPackagesLine/release_is_empty,Test_redhatBase_parseInstalledPackagesLine/not_standard_rpm_style_source_package_2,Test_redhatBase_parseInstalledPackagesLine,Test_redhatBase_parseInstalledPackagesLine/not_standard_rpm_style_source_package_3,Test_redhatBase_parseInstalledPackagesLine/release_is_empty_2 > /workspace/stdout.log 2> /workspace/stderr.log

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
