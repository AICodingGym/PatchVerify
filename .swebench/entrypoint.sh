#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 3c6bd20465f0c801ebbcdadaf998e46b37b98e6b
git checkout 3c6bd20465f0c801ebbcdadaf998e46b37b98e6b

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 967855b429f749c28c112b8cb1b15bc79157f973 -- internal/server/evaluator_test.go test/api.sh
fi

# Run tests
bash /workspace/run_script.sh TestListFlags_PaginationNextPageToken,TestCacheUnaryInterceptor_UpdateFlag,TestEvaluate_ErrorGettingRules,TestEvaluate_MatchAll_RolloutDistribution,TestEvaluate_FirstRolloutRuleIsZero,TestEvaluate_MatchAny_NoVariants_NoDistributions,TestEvaluate_MatchAny_RolloutDistribution_MultiRule,TestUpdateSegment,TestCacheUnaryInterceptor_UpdateVariant,TestEvaluate_ErrorGettingDistributions,TestUpdateFlag,TestUpdateConstraint,TestEvaluate_FlagNotFound,TestCreateDistribution,TestCacheUnaryInterceptor_DeleteVariant,TestCreateFlag,TestListSegments_PaginationNextPageToken,TestGetRule,TestDeleteVariant,TestEvaluationUnaryInterceptor_BatchEvaluation,TestCreateVariant,TestCacheUnaryInterceptor_CreateVariant,TestEvaluate_MatchAll_SingleVariantDistribution,TestEvaluate_MatchAll_RolloutDistribution_MultiRule,TestEvaluate_MatchAny_RolloutDistribution,TestListRules_PaginationNextPageToken,TestBatchEvaluate,TestDeleteFlag,TestDeleteRule,TestOrderRules,TestErrorUnaryInterceptor,TestValidationUnaryInterceptor,TestCacheUnaryInterceptor_DeleteFlag,TestEvaluate_FlagDisabled,TestCreateSegment,TestEvaluationUnaryInterceptor_Evaluation,TestEvaluate_FlagNoRules,TestEvaluate_RulesOutOfOrder,TestListFlags_PaginationOffset,TestDeleteDistribution,TestGetFlag,TestEvaluate_MatchAll_NoConstraints,TestBatchEvaluate_FlagNotFoundExcluded,TestEvaluate_MatchAny_SingleVariantDistribution,TestUpdateVariant,TestListSegments_PaginationOffset,TestEvaluate_MatchAny_NoConstraints,TestEvaluationUnaryInterceptor_Noop,TestCreateConstraint,Test_matchesNumber,Test_matchesBool,TestCreateRule,TestEvaluate_MatchAll_NoVariants_NoDistributions,Test_matchesString,TestCacheUnaryInterceptor_GetFlag,TestCacheUnaryInterceptor_Evaluate,TestListRules_PaginationOffset,TestUpdateDistribution,TestUpdateRule,TestGetSegment,TestDeleteSegment,TestBatchEvaluate_FlagNotFound,TestDeleteConstraint,TestEvaluate_MultipleZeroRolloutDistributions > /workspace/stdout.log 2> /workspace/stderr.log
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
