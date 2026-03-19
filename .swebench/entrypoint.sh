#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 025143d85654c604656571c363d0c7b9a6579f62
git checkout 025143d85654c604656571c363d0c7b9a6579f62

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore\|problem_statement\.md\|hints_text\.md\|CLAUDE\.md\|AGENTS\.md\|\.claudeignore\|\.copilotignore\|\.cursorignore\|\.cursorrules\|\.devcontainer\|\.vscode" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout fd2959260ef56463ad8afa4c973f47a50306edd4 -- lib/config/configuration_test.go
fi

# Run tests
bash /workspace/run_script.sh TestProxyKube/new_and_old_formats,TestProxyKube/legacy_format,_no_local_cluster,TestProxyKube/not_configured,TestProxyKube/legacy_format,_with_local_cluster,TestProxyKube,TestProxyKube/new_format_and_old_explicitly_disabled,TestProxyKube/new_format > /workspace/stdout.log 2> /workspace/stderr.log
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
