#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 899e567d89a15411311ed44fb34ec218ccb06389
git checkout 899e567d89a15411311ed44fb34ec218ccb06389

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout e42da21a07a5ae35835ec54f74004ebd58713874 -- server/evaluator_test.go
fi

# Run tests
bash /workspace/run_script.sh TestGetFlagNotFound,TestCreateRule_SegmentNotFound,TestDeleteConstraint_NotFound,TestGetEvaluationDistributions,TestEvaluate_MultipleZeroRolloutDistributions,TestValidate_DeleteDistributionRequest,TestEvaluate_MatchAny_NoVariants_NoDistributions,TestListRulesPagination,TestUpdateFlag,TestDeleteConstraint,TestValidate_UpdateConstraintRequest,TestCreateConstraint_SegmentNotFound,TestValidate_EvaluationRequest,TestValidate_CreateVariantRequest,TestValidate_CreateSegmentRequest,TestDeleteSegment_NotFound,TestValidate_GetRuleRequest,TestValidate_CreateDistributionRequest,TestEvaluate_MatchAny_NoConstraints,TestDeleteRule_NotFound,TestValidate_UpdateVariantRequest,TestParse,TestValidate_UpdateFlagRequest,TestUpdateConstraint_NotFound,TestCreateFlag,TestValidate_UpdateDistributionRequest,TestBatchEvaluate,TestOpen,TestGetEvaluationRules_NoResults,TestValidate_OrderRulesRequest,TestDeleteVariant_NotFound,TestCreateVariant_FlagNotFound,TestDeleteVariant,TestGetSegmentNotFound,TestCreateVariant_DuplicateName,TestValidate_CreateConstraintRequest,TestUpdateSegment,TestCreateRuleAndDistribution,TestMigratorRun,TestValidate_GetFlagRequest,TestEvaluate_RulesOutOfOrder,TestEvaluate_FlagNoRules,TestValidate_DeleteFlagRequest,TestUpdateVariant_DuplicateName,TestEvaluate_FlagDisabled,TestValidate_UpdateSegmentRequest,TestEvaluate_MatchAny_SingleVariantDistribution,TestDeleteRule,TestCreateRule,TestEvaluate_MatchAll_NoVariants_NoDistributions,TestValidate_UpdateRuleRequest,TestCreateVariant,TestUpdateRuleAndDistribution,TestListSegments,TestDeleteDistribution,TestEvaluate_MatchAll_RolloutDistribution_MultiRule,Test_matchesNumber,TestGetRule,TestCreateConstraint,TestListSegmentsPagination,TestOrderRules,TestValidate_GetSegmentRequest,TestUpdateDistribution,TestUpdateRule_NotFound,TestListFlags,TestCreateSegment,TestValidate_ListRuleRequest,TestValidationUnaryInterceptor,TestGetEvaluationDistributions_MaintainOrder,TestCreateSegment_DuplicateKey,TestEvaluate_FlagNotFound,TestUpdateConstraint,TestEvaluate_MatchAll_RolloutDistribution,Test_matchesString,TestDeleteFlag,TestErrorUnaryInterceptor,TestCreateRule_FlagNotFound,TestUpdateVariant_NotFound,TestValidate_DeleteConstraintRequest,TestCreateFlag_DuplicateKey,TestListRules,TestValidate_DeleteVariantRequest,TestUpdateFlag_NotFound,TestEvaluate_MatchAny_RolloutDistribution,Test_matchesBool,TestValidate_CreateFlagRequest,TestValidate_DeleteSegmentRequest,TestDeleteFlag_NotFound,TestGetRule_NotFound,TestValidate_CreateRuleRequest,TestUpdateVariant,TestEvaluate_MatchAll_NoConstraints,TestGetFlag,TestEvaluate_MatchAll_SingleVariantDistribution,TestUpdateSegment_NotFound,TestFlagsPagination,TestCreateVariant_DuplicateName_DifferentFlag,TestEvaluate_FirstRolloutRuleIsZero,TestGetEvaluationRules,TestCreateDistribution,TestEvaluate_MatchAny_RolloutDistribution_MultiRule,TestUpdateRule,TestGetEvaluationDistributions_NoResults,TestGetSegment,TestCreateDistribution_NoRule,TestValidate_DeleteRuleRequest,TestGetRuleNotFound,TestDeleteSegment,TestMigratorRun_NoChange > /workspace/stdout.log 2> /workspace/stderr.log
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
