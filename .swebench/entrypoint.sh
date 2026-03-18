#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 6d34eb88d95c02013d781a29dfffaaf2901cd81f
git checkout 6d34eb88d95c02013d781a29dfffaaf2901cd81f

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout bec27fb4c0a40c5f8bbcf26a475704227d65ee73 -- test/integration/targets/ansible-doc/fakecollrole.output test/integration/targets/ansible-doc/fakemodule.output test/integration/targets/ansible-doc/fakerole.output test/integration/targets/ansible-doc/noop.output test/integration/targets/ansible-doc/noop_vars_plugin.output test/integration/targets/ansible-doc/notjsonfile.output test/integration/targets/ansible-doc/randommodule-text-verbose.output test/integration/targets/ansible-doc/randommodule-text.output test/integration/targets/ansible-doc/randommodule.output test/integration/targets/ansible-doc/runme.sh test/integration/targets/ansible-doc/test.yml test/integration/targets/ansible-doc/test_docs_returns.output test/integration/targets/ansible-doc/test_docs_suboptions.output test/integration/targets/ansible-doc/test_docs_yaml_anchors.output test/integration/targets/ansible-doc/yolo-text.output test/integration/targets/ansible-doc/yolo.output test/integration/targets/collections/runme.sh test/units/cli/test_doc.py
fi

# Run tests
bash /workspace/run_script.sh test/units/cli/test_doc.py > /workspace/stdout.log 2> /workspace/stderr.log

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
