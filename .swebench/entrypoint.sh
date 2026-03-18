#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard fa8f302adcde48b4a94bf45726fe4da73de5e5ab
git checkout fa8f302adcde48b4a94bf45726fe4da73de5e5ab

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 9d25c18b79bc7829a6fb08ec9e8793d5d17e2868 -- internal/server/evaluation/ofrep_bridge_test.go internal/server/ofrep/evaluation_test.go internal/server/ofrep/extensions_test.go
fi

# Run tests
bash /workspace/run_script.sh TestBoolean_SegmentMatch_Constraint_EntityId,TestEvaluator_ErrorParsingDateTime,TestVariant_FlagNotFound,TestEvaluator_DistributionNotMatched,TestEvaluator_MatchAll_RolloutDistribution,TestEvaluator_MatchAny_NoConstraints,TestBoolean_DefaultRule_NoRollouts,TestEvaluator_MatchAll_RolloutDistribution_MultiRule,TestEvaluateFlag_Failure,TestBoolean_DefaultRuleFallthrough_WithPercentageRollout,TestBoolean_PercentageRuleMatch,TestEvaluator_RulesOutOfOrder,TestEvaluator_ErrorGettingRules,TestEvaluator_FlagDisabled_DefaultVariant,TestVariant_Success,TestOFREPEvaluationBridge_Boolean,TestEvaluateFlag_Success,Test_Server_AllowsNamespaceScopedAuthentication,TestBoolean_NonBooleanFlagError,TestVariant_EvaluateFailure_OnGetEvaluationRules,TestBoolean_SegmentMatch_MultipleSegments_WithAnd,Test_matchesNumber,TestEvaluator_MatchAll_NoDistributions_DefaultVariant,TestEvaluator_DistributionNotMatched_DefaultVariant,TestEvaluator_MatchAny_NoDistributions_DefaultVariant,TestBoolean_FlagNotFoundError,TestEvaluator_ErrorGettingDistributions,TestBatch_Success,TestGetProviderConfiguration,TestBatch_UnknownFlagType,Test_matchesDateTime,TestEvaluator_MatchAny_SingleVariantDistribution,TestEvaluator_FlagNoRules_DefaultVariant,TestBatch_InternalError_GetFlag,TestEvaluator_MultipleZeroRolloutDistributions,TestEvaluator_MatchEntityId,Test_matchesBool,TestEvaluator_NonVariantFlag,TestOFREPEvaluationBridge_Variant,TestEvaluator_MatchAll_MultipleSegments,TestEvaluator_MatchAny_RolloutDistribution,TestBoolean_SegmentMatch_MultipleConstraints,TestEvaluator_MatchAny_RolloutDistribution_MultiRule,TestVariant_FlagDisabled,TestEvaluator_FlagNoRules,TestVariant_NonVariantFlag,TestBoolean_RulesOutOfOrder,TestBoolean_PercentageRuleFallthrough_SegmentMatch,Test_matchesString,TestEvaluator_FlagDisabled,TestEvaluator_MatchAll_NoConstraints,TestEvaluator_FirstRolloutRuleIsZero,TestEvaluator_MatchAll_NoVariants_NoDistributions,TestEvaluator_MatchAll_SingleVariantDistribution,TestEvaluator_MatchAny_NoVariants_NoDistributions,TestEvaluator_ErrorParsingNumber > /workspace/stdout.log 2> /workspace/stderr.log
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
