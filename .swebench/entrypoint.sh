#!/bin/bash
set -x

# ENV exports from Dockerfiles
export DEBIAN_FRONTEND=noninteractive
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard f9a450551de47ac2b9d1d7e66a103cbf8f05c37f
git checkout f9a450551de47ac2b9d1d7e66a103cbf8f05c37f

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout d2f80991180337e2be23d6883064a67dcbaeb662 -- test/integration/targets/ansible-galaxy-collection-cli/aliases test/integration/targets/ansible-galaxy-collection-cli/files/expected.txt test/integration/targets/ansible-galaxy-collection-cli/files/expected_full_manifest.txt test/integration/targets/ansible-galaxy-collection-cli/files/full_manifest_galaxy.yml test/integration/targets/ansible-galaxy-collection-cli/files/galaxy.yml test/integration/targets/ansible-galaxy-collection-cli/files/make_collection_dir.py test/integration/targets/ansible-galaxy-collection-cli/tasks/main.yml test/integration/targets/ansible-galaxy-collection-cli/tasks/manifest.yml test/units/galaxy/test_collection.py
fi

# Run tests
bash /workspace/run_script.sh test/units/galaxy/test_collection.py,test/integration/targets/ansible-galaxy-collection-cli/files/make_collection_dir.py > /workspace/stdout.log 2> /workspace/stderr.log

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
