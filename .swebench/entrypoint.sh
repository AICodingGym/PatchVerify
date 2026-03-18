#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard e658995760ac1209cb12df97027a2e282b4536ae
git checkout e658995760ac1209cb12df97027a2e282b4536ae

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 379058e10f3dbc0fdcaf80394bd09b18927e7d33 -- test/integration/targets/ansible-doc/broken-docs/collections/ansible_collections/testns/testcol/plugins/lookup/noop.py test/lib/ansible_test/_util/controller/sanity/pylint/plugins/unwanted.py test/support/integration/plugins/module_utils/network/common/utils.py test/support/network-integration/collections/ansible_collections/ansible/netcommon/plugins/module_utils/network/common/utils.py test/units/executor/module_common/test_recursive_finder.py test/units/module_utils/common/test_collections.py test/units/module_utils/conftest.py test/units/modules/conftest.py
fi

# Run tests
bash /workspace/run_script.sh test/lib/ansible_test/_util/controller/sanity/pylint/plugins/unwanted.py,test/units/modules/conftest.py,test/units/module_utils/conftest.py,test/integration/targets/ansible-doc/broken-docs/collections/ansible_collections/testns/testcol/plugins/lookup/noop.py,test/units/executor/module_common/test_recursive_finder.py,test/support/network-integration/collections/ansible_collections/ansible/netcommon/plugins/module_utils/network/common/utils.py,test/support/integration/plugins/module_utils/network/common/utils.py,test/units/module_utils/common/test_collections.py > /workspace/stdout.log 2> /workspace/stderr.log

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
