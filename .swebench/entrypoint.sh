#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard b479adddce8fe46a2df5469f130cf7b6ad70fdc4
git checkout b479adddce8fe46a2df5469f130cf7b6ad70fdc4

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout c616e54a6e23fa5616a1d56d243f69576164ef9b -- test/integration/targets/collections/collection_root_user/ansible_collections/testns/othercoll/plugins/module_utils/formerly_testcoll_pkg/__init__.py test/integration/targets/collections/collection_root_user/ansible_collections/testns/othercoll/plugins/module_utils/formerly_testcoll_pkg/submod.py test/integration/targets/collections/collection_root_user/ansible_collections/testns/testcoll/meta/runtime.yml test/integration/targets/collections/collection_root_user/ansible_collections/testns/testcoll/plugins/module_utils/nested_same/__init__.py test/integration/targets/collections/collection_root_user/ansible_collections/testns/testcoll/plugins/module_utils/nested_same/nested_same/__init__.py test/integration/targets/collections/collection_root_user/ansible_collections/testns/testcoll/plugins/module_utils/subpkg/__init__.py test/integration/targets/collections/collection_root_user/ansible_collections/testns/testcoll/plugins/module_utils/subpkg_with_init/__init__.py test/integration/targets/collections/collection_root_user/ansible_collections/testns/testcoll/plugins/module_utils/subpkg_with_init/mod_in_subpkg_with_init.py test/integration/targets/collections/collection_root_user/ansible_collections/testns/testcoll/plugins/modules/uses_collection_redirected_mu.py test/integration/targets/collections/collection_root_user/ansible_collections/testns/testcoll/plugins/modules/uses_leaf_mu_module_import_from.py test/integration/targets/collections/collection_root_user/ansible_collections/testns/testcoll/plugins/modules/uses_mu_missing.py test/integration/targets/collections/collection_root_user/ansible_collections/testns/testcoll/plugins/modules/uses_mu_missing_redirect_collection.py test/integration/targets/collections/collection_root_user/ansible_collections/testns/testcoll/plugins/modules/uses_mu_missing_redirect_module.py test/integration/targets/collections/collections/ansible_collections/testns/content_adj/plugins/module_utils/__init__.py test/integration/targets/collections/collections/ansible_collections/testns/content_adj/plugins/module_utils/sub1/__init__.py test/integration/targets/collections/posix.yml test/integration/targets/module_utils/module_utils_test.yml test/units/executor/module_common/test_recursive_finder.py
fi

# Run tests
bash /workspace/run_script.sh test/integration/targets/collections/collections/ansible_collections/testns/content_adj/plugins/module_utils/sub1/__init__.py,test/units/executor/module_common/test_recursive_finder.py,test/integration/targets/collections/collections/ansible_collections/testns/content_adj/plugins/module_utils/__init__.py,test/integration/targets/collections/collection_root_user/ansible_collections/testns/othercoll/plugins/module_utils/formerly_testcoll_pkg/__init__.py,test/integration/targets/collections/collection_root_user/ansible_collections/testns/othercoll/plugins/module_utils/formerly_testcoll_pkg/submod.py,test/integration/targets/collections/collection_root_user/ansible_collections/testns/testcoll/plugins/module_utils/subpkg_with_init/__init__.py,test/integration/targets/collections/collection_root_user/ansible_collections/testns/testcoll/plugins/modules/uses_mu_missing_redirect_module.py,test/integration/targets/collections/collection_root_user/ansible_collections/testns/testcoll/plugins/modules/uses_mu_missing.py,test/integration/targets/collections/collection_root_user/ansible_collections/testns/testcoll/plugins/module_utils/nested_same/nested_same/__init__.py,test/integration/targets/collections/collection_root_user/ansible_collections/testns/testcoll/plugins/module_utils/nested_same/__init__.py,test/integration/targets/collections/collection_root_user/ansible_collections/testns/testcoll/plugins/module_utils/subpkg_with_init/mod_in_subpkg_with_init.py,test/integration/targets/collections/collection_root_user/ansible_collections/testns/testcoll/plugins/modules/uses_leaf_mu_module_import_from.py,test/integration/targets/collections/collection_root_user/ansible_collections/testns/testcoll/plugins/modules/uses_collection_redirected_mu.py,test/integration/targets/collections/collection_root_user/ansible_collections/testns/testcoll/plugins/module_utils/subpkg/__init__.py,test/integration/targets/collections/collection_root_user/ansible_collections/testns/testcoll/plugins/modules/uses_mu_missing_redirect_collection.py > /workspace/stdout.log 2> /workspace/stderr.log

# Parse results
python /workspace/parser.py /workspace/stdout.log /workspace/stderr.log /workspace/output.json || true

# Print outputs for GHA log
echo '=== STDOUT ==='
cat /workspace/stdout.log 2>/dev/null || true
echo '=== STDERR ==='
cat /workspace/stderr.log 2>/dev/null || true
echo '=== PARSED OUTPUT ==='
cat /workspace/output.json 2>/dev/null || true

# Exit non-zero if any test failed or errored
python -c "
import json, sys
try:
    with open('/workspace/output.json') as f:
        data = json.load(f)
    tests = data.get('tests', [])
    failed = [t for t in tests if t.get('status') in ('FAILED', 'ERROR')]
    if failed:
        print(f'{len(failed)} test(s) FAILED/ERROR')
        sys.exit(1)
    if not tests:
        print('No tests found')
        sys.exit(1)
    print('All tests passed')
except Exception as e:
    print(f'Could not check results: {e}')
    sys.exit(1)
"
