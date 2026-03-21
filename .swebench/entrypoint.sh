#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard dccdd8a091bc57785341d911b7d8c7867d522e9a
git checkout dccdd8a091bc57785341d911b7d8c7867d522e9a

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup (checkout gold test files)
git checkout 407407d306e9431d6aa0ab566baa6e44e5ba2904 -- contrib/trivy/parser/v2/parser_test.go

# Run tests
bash /workspace/run_script.sh TestParse > /workspace/stdout.log 2> /workspace/stderr.log

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
