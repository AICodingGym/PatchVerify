#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 7ee465fe8dbcf9b319c70ef7f3bfd00b3aaab6ca
git checkout 7ee465fe8dbcf9b319c70ef7f3bfd00b3aaab6ca

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout e88e93990e3ec1e7697754b423decc510d5dd5fe -- build/testing/integration/readonly/readonly_test.go internal/server/evaluation/evaluation_test.go
fi

# Run tests
bash /workspace/run_script.sh TestVariant_Success,TestBoolean_SegmentMatch_MultipleConstraints,TestBatch_UnknownFlagType,TestEvaluator_MatchAny_NoConstraints,TestBoolean_RulesOutOfOrder,TestEvaluator_DistributionNotMatched,TestEvaluator_MatchAll_RolloutDistribution_MultiRule,TestVariant_NonVariantFlag,Test_matchesString,TestBatch_InternalError_GetFlag,Test_matchesDateTime,TestBoolean_PercentageRuleMatch,TestEvaluator_MatchAny_RolloutDistribution_MultiRule,TestEvaluator_MatchAll_NoVariants_NoDistributions,TestEvaluator_MatchAny_NoVariants_NoDistributions,TestEvaluator_MatchAll_NoConstraints,TestEvaluator_MatchAny_RolloutDistribution,TestBoolean_SegmentMatch_MultipleSegments_WithAnd,TestEvaluator_RulesOutOfOrder,Test_matchesNumber,TestVariant_FlagDisabled,TestVariant_EvaluateFailure_OnGetEvaluationRules,TestBoolean_FlagNotFoundError,TestEvaluator_NonVariantFlag,TestVariant_FlagNotFound,TestBoolean_NonBooleanFlagError,TestEvaluator_ErrorParsingDateTime,TestEvaluator_ErrorParsingNumber,TestEvaluator_MatchAll_MultipleSegments,TestBoolean_DefaultRule_NoRollouts,TestBoolean_DefaultRuleFallthrough_WithPercentageRollout,TestEvaluator_FlagNoRules,TestEvaluator_MatchAll_SingleVariantDistribution,TestEvaluator_ErrorGettingRules,TestEvaluator_ErrorGettingDistributions,TestEvaluator_MatchAll_RolloutDistribution,TestEvaluator_MatchAny_SingleVariantDistribution,TestBoolean_PercentageRuleFallthrough_SegmentMatch,TestEvaluator_MultipleZeroRolloutDistributions,TestEvaluator_FlagDisabled,Test_matchesBool,TestBatch_Success,TestEvaluator_FirstRolloutRuleIsZero > /workspace/stdout.log 2> /workspace/stderr.log
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
