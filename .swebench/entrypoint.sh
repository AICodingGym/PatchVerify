#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 0eaf98f050d86247bfe9bd7e41178865cb585060
git checkout 0eaf98f050d86247bfe9bd7e41178865cb585060

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout e2bd19dafa7166c96b082fb2a59eb54b4be0d778 -- internal/cache/cache_test.go internal/server/middleware/grpc/middleware_test.go internal/storage/cache/cache_test.go
fi

# Run tests
bash /workspace/run_script.sh TestAuditUnaryInterceptor_UpdateVariant,TestAuditUnaryInterceptor_CreateSegment,TestGetJSONHandleGetError,TestAuditUnaryInterceptor_CreateToken,TestAuditUnaryInterceptor_UpdateRollout,TestEvaluationCacheUnaryInterceptor_Evaluate,TestCacheControlUnaryInterceptor,TestAuditUnaryInterceptor_DeleteVariant,TestGetFlagCached,TestGetEvaluationRulesCached,TestAuditUnaryInterceptor_CreateDistribution,TestEvaluationUnaryInterceptor_Noop,TestEvaluationUnaryInterceptor_Evaluation,TestAuditUnaryInterceptor_UpdateRule,TestAuditUnaryInterceptor_CreateNamespace,TestGetEvaluationRules,TestAuditUnaryInterceptor_DeleteDistribution,TestValidationUnaryInterceptor,TestAuditUnaryInterceptor_DeleteNamespace,TestWithDoNotStore,TestAuditUnaryInterceptor_UpdateConstraint,TestIsDoNotStore,TestAuditUnaryInterceptor_CreateVariant,TestEvaluationCacheUnaryInterceptor_Evaluation_Variant,TestAuditUnaryInterceptor_DeleteRollout,TestEvaluationUnaryInterceptor_BatchEvaluation,TestAuditUnaryInterceptor_DeleteSegment,TestAuditUnaryInterceptor_DeleteConstraint,TestAuditUnaryInterceptor_DeleteFlag,TestAuditUnaryInterceptor_UpdateNamespace,TestAuditUnaryInterceptor_CreateRule,TestAuthMetadataAuditUnaryInterceptor,TestAuditUnaryInterceptor_UpdateFlag,TestAuditUnaryInterceptor_CreateConstraint,TestErrorUnaryInterceptor,TestEvaluationCacheUnaryInterceptor_Evaluation_Boolean,TestAuditUnaryInterceptor_UpdateSegment,TestAuditUnaryInterceptor_DeleteRule,TestGetJSONHandleUnmarshalError,TestSetJSONHandleMarshalError,TestAuditUnaryInterceptor_CreateFlag,TestAuditUnaryInterceptor_UpdateDistribution,TestAuditUnaryInterceptor_CreateRollout > /workspace/stdout.log 2> /workspace/stderr.log
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
