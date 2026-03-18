#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 1a6a284bc124d579c44053a6b0435cd20ead715c
git checkout 1a6a284bc124d579c44053a6b0435cd20ead715c

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout f78257235ec3429ef42af6687738cd327ec77ce8 -- log/log_test.go
fi

# Run tests
bash /workspace/run_script.sh TestLevelThreshold,TestInvalidRegex,TestLevelThreshold/errorLogLevel,TestEntryDataValues/map_value,TestEntryMessage,TestLevels/undefinedAcceptedLevels,TestEntryDataValues/match_on_key,TestLevels,TestEntryDataValues,TestEntryDataValues/string_value,TestLevels/definedAcceptedLevels,TestLog,TestLevelThreshold/unknownLogLevel > /workspace/stdout.log 2> /workspace/stderr.log
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
