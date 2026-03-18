#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 4253550c999d27fac802f616dbe50dd884e93f51
git checkout 4253550c999d27fac802f616dbe50dd884e93f51

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 457a3a9627fb9a0800d0aecf1d4713fb634a9011 -- scanner/windows_test.go
fi

# Run tests
bash /workspace/run_script.sh Test_windows_detectKBsFromKernelVersion,Test_windows_detectKBsFromKernelVersion/10.0.20348.1547,Test_windows_detectKBsFromKernelVersion/10.0.22621.1105,Test_windows_detectKBsFromKernelVersion/10.0.19045.2129,Test_windows_detectKBsFromKernelVersion/10.0.20348.9999,Test_windows_detectKBsFromKernelVersion/10.0.19045.2130 > /workspace/stdout.log 2> /workspace/stderr.log

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
