#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard f3421c143953d2a2e3f4373f8ec366e0904f9bdd
git checkout f3421c143953d2a2e3f4373f8ec366e0904f9bdd

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 2ce8a0331e8a8f63f2c1b555db8277ffe5aa2e63 -- internal/server/middleware/grpc/middleware_test.go
fi

# Run tests
bash /workspace/run_script.sh TestCacheUnaryInterceptor_UpdateVariant,TestAuditUnaryInterceptor_OrderRollout,TestAuditUnaryInterceptor_CreateSegment,TestAuthMetadataAuditUnaryInterceptor,TestAuditUnaryInterceptor_CreateDistribution,TestFliptAcceptServerVersionUnaryInterceptor,TestAuditUnaryInterceptor_UpdateFlag,TestCacheUnaryInterceptor_UpdateFlag,TestAuditUnaryInterceptor_DeleteDistribution,TestAuditUnaryInterceptor_UpdateVariant,TestAuditUnaryInterceptor_OrderRule,TestAuditUnaryInterceptor_DeleteVariant,TestCacheUnaryInterceptor_CreateVariant,TestCacheUnaryInterceptor_Evaluation_Variant,TestAuditUnaryInterceptor_UpdateSegment,TestAuditUnaryInterceptor_CreateToken,TestAuditUnaryInterceptor_CreateRule,TestCacheUnaryInterceptor_DeleteVariant,TestEvaluationUnaryInterceptor_Noop,TestAuditUnaryInterceptor_CreateRollout,TestAuditUnaryInterceptor_DeleteRollout,TestAuditUnaryInterceptor_CreateConstraint,TestAuditUnaryInterceptor_DeleteNamespace,TestAuditUnaryInterceptor_CreateFlag,TestAuditUnaryInterceptor_CreateVariant,TestAuditUnaryInterceptor_UpdateRule,TestCacheUnaryInterceptor_DeleteFlag,TestAuditUnaryInterceptor_DeleteSegment,TestAuditUnaryInterceptor_DeleteConstraint,TestCacheUnaryInterceptor_Evaluate,TestErrorUnaryInterceptor,TestAuditUnaryInterceptor_UpdateConstraint,TestCacheUnaryInterceptor_GetFlag,TestValidationUnaryInterceptor,TestAuditUnaryInterceptor_DeleteFlag,TestAuditUnaryInterceptor_UpdateRollout,TestEvaluationUnaryInterceptor_BatchEvaluation,TestCacheUnaryInterceptor_Evaluation_Boolean,TestAuditUnaryInterceptor_CreateNamespace,TestAuditUnaryInterceptor_DeleteRule,TestAuditUnaryInterceptor_UpdateNamespace,TestEvaluationUnaryInterceptor_Evaluation,TestAuditUnaryInterceptor_UpdateDistribution > /workspace/stdout.log 2> /workspace/stderr.log
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
