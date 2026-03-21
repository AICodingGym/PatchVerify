#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 61c39637f2f3809e1b5dad05f0c57c799dce1587
git checkout 61c39637f2f3809e1b5dad05f0c57c799dce1587

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup (checkout gold test files)
git checkout e4728e388120b311c4ed469e4f942e0347a2689b -- gost/debian_test.go models/vulninfos_test.go

# Run tests
bash /workspace/run_script.sh TestDebian_detect,TestDebian_Supported,TestUbuntu_Supported,TestDebian_isKernelSourcePackage,TestParseCwe,TestUbuntuConvertToModel,Test_detect,TestCvss3Scores,TestDebian_CompareSeverity,TestUbuntu_isKernelSourcePackage,TestDebian_ConvertToModel > /workspace/stdout.log 2> /workspace/stderr.log

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
