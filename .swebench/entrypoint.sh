#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard d5a740ddca57ed344d1d023383d4aff563657424
git checkout d5a740ddca57ed344d1d023383d4aff563657424

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 3889ddeb4b780ab4bac9ca2e75f8c1991bcabe83 -- test/integration/targets/iptables/aliases test/integration/targets/iptables/tasks/chain_management.yml test/integration/targets/iptables/tasks/main.yml test/integration/targets/iptables/vars/alpine.yml test/integration/targets/iptables/vars/centos.yml test/integration/targets/iptables/vars/default.yml test/integration/targets/iptables/vars/fedora.yml test/integration/targets/iptables/vars/redhat.yml test/integration/targets/iptables/vars/suse.yml test/units/modules/test_iptables.py
fi

# Run tests
bash /workspace/run_script.sh test/units/modules/test_iptables.py > /workspace/stdout.log 2> /workspace/stderr.log

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
