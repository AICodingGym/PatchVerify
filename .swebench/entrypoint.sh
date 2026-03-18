#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 25a5f278e1116ca22f86d86b4a5259ca05ef2623
git checkout 25a5f278e1116ca22f86d86b4a5259ca05ef2623

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 8bd3604dc54b681f1f0f7dd52cbc70b3024184b6 -- internal/server/audit/template/executer_test.go internal/server/audit/template/leveled_logger_test.go internal/server/audit/webhook/client_test.go
fi

# Run tests
bash /workspace/run_script.sh TestExecuter_JSON_Failure,TestExecuter_Execute,TestConstructorWebhookTemplate,TestWebhookClient,TestExecuter_Execute_toJson_valid_Json,TestLeveledLogger,TestConstructorWebhookClient > /workspace/stdout.log 2> /workspace/stderr.log
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
