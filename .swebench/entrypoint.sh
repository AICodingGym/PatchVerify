#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 4c8c40fd3d4a58defdc80e7d22aa8d26b731353e
git checkout 4c8c40fd3d4a58defdc80e7d22aa8d26b731353e

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 9a21e247786ebd294dafafca1105fcd770ff46c6 -- test/units/module_utils/basic/test_platform_distribution.py test/units/module_utils/common/test_sys_info.py test/units/modules/test_service.py
fi

# Run tests
bash /workspace/run_script.sh test/units/module_utils/common/test_sys_info.py::test_get_distribution_not_linux[SunOS-Solaris],test/units/module_utils/common/test_sys_info.py::test_get_distribution_not_linux[Darwin-Darwin],test/units/module_utils/common/test_sys_info.py::test_get_distribution_version_not_linux[SunOS-11.4],test/units/module_utils/common/test_sys_info.py::test_get_distribution_version_not_linux[Darwin-19.6.0],test/units/module_utils/common/test_sys_info.py::test_get_distribution_not_linux[FreeBSD-Freebsd],test/units/module_utils/common/test_sys_info.py::test_get_distribution_version_not_linux[FreeBSD-12.1] > /workspace/stdout.log 2> /workspace/stderr.log

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
