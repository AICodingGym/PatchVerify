#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 23bebe4e06124becf1000e88472ae71a6ca7de4c
git checkout 23bebe4e06124becf1000e88472ae71a6ca7de4c

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup (checkout gold test files)
git checkout 9c3b4561652a15846993d477003e111f0df0c585 -- log/formatters_test.go

# Run tests
bash /workspace/run_script.sh TestLevelThreshold/errorLogLevel,TestEntryMessage,TestLevelThreshold,TestLevels,TestEntryDataValues,TestLevels/undefinedAcceptedLevels,TestLevelThreshold/unknownLogLevel,TestEntryDataValues/map_value,TestLevels/definedAcceptedLevels,TestInvalidRegex,TestEntryDataValues/match_on_key,TestEntryDataValues/string_value,TestLog > /workspace/stdout.log 2> /workspace/stderr.log
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
