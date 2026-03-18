#!/bin/bash
set -x

# ENV exports from Dockerfiles
export DEBIAN_FRONTEND=noninteractive
export DISPLAY=:99
export QT_QPA_PLATFORM=offscreen
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard fce306d5f184f185b660f35ec2808b6745d57520
git checkout fce306d5f184f185b660f35ec2808b6745d57520

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 3e21c8214a998cb1058defd15aabb24617a76402 -- tests/unit/keyinput/test_keyutils.py
fi

# Run tests
bash /workspace/run_script.sh tests/unit/keyinput/test_bindingtrie.py,tests/unit/keyinput/test_keyutils.py > /workspace/stdout.log 2> /workspace/stderr.log
RUN_SCRIPT_EXIT=$?

# Parse results
python /workspace/parser.py /workspace/stdout.log /workspace/stderr.log /workspace/output.json || true

# Print outputs for GHA log
echo '=== STDOUT ==='
cat /workspace/stdout.log 2>/dev/null || true
echo '=== STDERR ==='
cat /workspace/stderr.log 2>/dev/null || true
echo '=== PARSED OUTPUT ==='
cat /workspace/output.json 2>/dev/null || true

# Exit with the test runner's exit code (non-zero = build failure or test failures)
exit $RUN_SCRIPT_EXIT
