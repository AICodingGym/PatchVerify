#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 5069ba6fa22fbbf208352ff341ea7a85d6eca29f
git checkout 5069ba6fa22fbbf208352ff341ea7a85d6eca29f

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout e50808c03e4b9d25a6a78af9c61a3b1616ea356b -- internal/config/config_test.go internal/server/audit/audit_test.go internal/server/auth/server_test.go internal/server/middleware/grpc/middleware_test.go internal/server/middleware/grpc/support_test.go
fi

# Run tests
bash /workspace/run_script.sh TestAuditUnaryInterceptor_CreateFlag,TestCacheUnaryInterceptor_UpdateVariant,TestValidationUnaryInterceptor,TestTracingExporter,TestAuditUnaryInterceptor_DeleteConstraint,TestJSONSchema,TestAuditUnaryInterceptor_UpdateConstraint,TestAuditUnaryInterceptor_UpdateRule,TestAuditUnaryInterceptor_UpdateNamespace,TestAuditUnaryInterceptor_CreateNamespace,TestAuditUnaryInterceptor_DeleteVariant,TestAuditUnaryInterceptor_UpdateSegment,TestCacheUnaryInterceptor_GetFlag,TestAuditUnaryInterceptor_CreateVariant,TestAuditUnaryInterceptor_CreateConstraint,TestErrorUnaryInterceptor,TestSinkSpanExporter,TestServeHTTP,Test_mustBindEnv,TestEvaluationUnaryInterceptor_BatchEvaluation,TestScheme,TestAuditUnaryInterceptor_DeleteFlag,TestAuditUnaryInterceptor_DeleteNamespace,TestLoad,TestCacheUnaryInterceptor_DeleteFlag,TestAuditUnaryInterceptor_DeleteDistribution,TestAuditUnaryInterceptor_CreateSegment,TestEvaluationUnaryInterceptor_Noop,TestAuditUnaryInterceptor_DeleteRule,TestCacheUnaryInterceptor_DeleteVariant,TestAuditUnaryInterceptor_DeleteSegment,TestEvaluationUnaryInterceptor_Evaluation,TestAuditUnaryInterceptor_CreateRule,TestAuditUnaryInterceptor_UpdateDistribution,TestLogEncoding,TestAuditUnaryInterceptor_CreateDistribution,TestCacheBackend,TestCacheUnaryInterceptor_UpdateFlag,TestCacheUnaryInterceptor_Evaluate,TestAuditUnaryInterceptor_UpdateVariant,TestDatabaseProtocol,TestCacheUnaryInterceptor_CreateVariant,TestAuditUnaryInterceptor_UpdateFlag > /workspace/stdout.log 2> /workspace/stderr.log
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
