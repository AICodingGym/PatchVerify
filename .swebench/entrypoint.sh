#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 32864671f44b7bbd9edc8e2bc1d6255906c31f5b
git checkout 32864671f44b7bbd9edc8e2bc1d6255906c31f5b

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 56a620b8fc9ef7a0819b47709aa541cdfdbba00b -- internal/config/config_test.go internal/server/audit/audit_test.go internal/server/audit/webhook/client_test.go internal/server/audit/webhook/webhook_test.go internal/server/middleware/grpc/support_test.go
fi

# Run tests
bash /workspace/run_script.sh TestSegment,TestCacheUnaryInterceptor_Evaluation_Boolean,TestAuditUnaryInterceptor_CreateRule,TestAuditUnaryInterceptor_DeleteRule,TestCacheUnaryInterceptor_CreateVariant,TestAuditUnaryInterceptor_UpdateSegment,TestVariant,TestAuditUnaryInterceptor_UpdateFlag,TestAuditUnaryInterceptor_DeleteConstraint,TestAuditUnaryInterceptor_UpdateRollout,TestCacheUnaryInterceptor_Evaluation_Variant,TestAuditUnaryInterceptor_DeleteSegment,TestAuditUnaryInterceptor_DeleteFlag,TestAuditUnaryInterceptor_DeleteVariant,TestEvaluationUnaryInterceptor_Evaluation,TestAuditUnaryInterceptor_CreateSegment,TestConstraint,TestCacheUnaryInterceptor_UpdateFlag,TestAuditUnaryInterceptor_CreateFlag,TestFlag,TestValidationUnaryInterceptor,TestEvaluationUnaryInterceptor_BatchEvaluation,TestAuditUnaryInterceptor_CreateConstraint,TestErrorUnaryInterceptor,TestAuditUnaryInterceptor_UpdateConstraint,TestGRPCMethodToAction,TestSink,TestCacheUnaryInterceptor_UpdateVariant,TestAuditUnaryInterceptor_DeleteRollout,TestNamespace,TestAuditUnaryInterceptor_UpdateRule,TestAuthMetadataAuditUnaryInterceptor,TestCacheUnaryInterceptor_DeleteVariant,TestSinkSpanExporter,TestLoad,TestAuditUnaryInterceptor_UpdateVariant,TestCacheUnaryInterceptor_Evaluate,TestDistribution,TestAuditUnaryInterceptor_CreateRollout,TestHTTPClient_Failure,TestAuditUnaryInterceptor_DeleteDistribution,TestAuditUnaryInterceptor_UpdateNamespace,TestHTTPClient_Success,TestCacheUnaryInterceptor_DeleteFlag,TestAuditUnaryInterceptor_CreateToken,TestChecker,TestAuditUnaryInterceptor_CreateNamespace,TestHTTPClient_Success_WithSignedPayload,TestAuditUnaryInterceptor_CreateVariant,TestAuditUnaryInterceptor_CreateDistribution,TestAuditUnaryInterceptor_DeleteNamespace,TestRule,TestEvaluationUnaryInterceptor_Noop,TestAuditUnaryInterceptor_UpdateDistribution,TestCacheUnaryInterceptor_GetFlag > /workspace/stdout.log 2> /workspace/stderr.log
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
