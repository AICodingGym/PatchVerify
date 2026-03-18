#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 56d261e7c28e47faf537061e6ad3b306459a3e93
git checkout 56d261e7c28e47faf537061e6ad3b306459a3e93

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout f1bc91a1b999656dbdb2495ccb57bf2105b84920 -- server/evaluator_test.go server/rule_test.go storage/db_test.go storage/evaluator_test.go storage/rule_test.go
fi

# Run tests
bash /workspace/run_script.sh TestFlagsPagination,TestUpdateFlag_NotFound,TestUpdateRule,TestListSegments,TestCreateVariant_FlagNotFound,TestUpdateVariant_NotFound,TestUpdateVariant_DuplicateName,TestUpdateRuleAndDistribution,TestNew,TestEvaluate_RolloutDistribution,Test_matchesString,TestListRulesPagination,TestCreateRule,TestUpdateConstraint_NotFound,TestCreateConstraint,TestCreateDistribution,TestCreateVariant_DuplicateName,TestCreateSegment,TestEvaluate_NoConstraints,TestUpdateSegment_NotFound,TestCreateConstraint_ErrInvalid,TestCreateDistribution_NoRule,TestDeleteConstraint_NotFound,TestParse,TestGetRule,TestUpdateConstraint_ErrInvalid,TestCreateConstraint_SegmentNotFound,TestDeleteConstraint,Test_evaluate,TestGetSegment,TestCreateVariant_DuplicateName_DifferentFlag,TestUpdateSegment,TestCreateRule_FlagNotFound,TestErrorUnaryInterceptor,Test_matchesNumber,TestCreateRuleAndDistribution,TestEvaluate_FlagDisabled,TestDeleteSegment_NotFound,TestDeleteDistribution,Test_validate,TestDeleteSegment,TestCreateSegment_DuplicateKey,TestDeleteRule,TestWithCache,TestCreateRule_SegmentNotFound,TestDeleteRule_NotFound,TestGetSegmentNotFound,TestUpdateConstraint,TestEvaluate_NoVariants_NoDistributions,TestEvaluate_SingleVariantDistribution,TestDeleteVariant_NotFound,TestListSegmentsPagination,TestListRules,TestEvaluate_FlagNotFound,Test_matchesBool,TestDeleteFlag_NotFound,TestEvaluate,TestUpdateRule_NotFound,TestCreateFlag_DuplicateKey,TestOrderRules,TestEvaluate_FlagNoRules,TestUpdateDistribution > /workspace/stdout.log 2> /workspace/stderr.log

# Parse results
python /workspace/parser.py /workspace/stdout.log /workspace/stderr.log /workspace/output.json || true

# Print outputs for GHA log
echo '=== STDOUT ==='
cat /workspace/stdout.log 2>/dev/null || true
echo '=== STDERR ==='
cat /workspace/stderr.log 2>/dev/null || true
echo '=== PARSED OUTPUT ==='
cat /workspace/output.json 2>/dev/null || true

# Exit non-zero if any test failed
python -c "
import json, sys
try:
    with open('/workspace/output.json') as f:
        data = json.load(f)
    failed = [t for t in data.get('tests', []) if t.get('status') == 'FAILED']
    if failed:
        print(f'{len(failed)} test(s) FAILED')
        sys.exit(1)
    print('All tests passed')
except Exception as e:
    print(f'Could not check results: {e}')
    sys.exit(1)
"
