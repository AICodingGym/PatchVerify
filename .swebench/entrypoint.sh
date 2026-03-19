#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 69a9dbf3a27c6a6da4eaafb89d69849c34beed1b
git checkout 69a9dbf3a27c6a6da4eaafb89d69849c34beed1b

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore\|problem_statement\.md\|hints_text\.md" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout d6ffe82aaf2af1057b69c61bf9df777f5ab5635a -- lib/services/role_test.go lib/utils/parse/parse_test.go
fi

# Run tests
bash /workspace/run_script.sh TestVariable/no_args,TestVarValidation,TestVariable/missing_args,TestVariable/regexp_function_call_not_allowed,TestInterpolate/regexp_replacement_with_numeric_match,TestInterpolate,TestVariable/incomplete_variables_are_not_allowed,TestVarValidation/validate_namespace_error,TestVariable/invalid_arg_type,TestVariable/empty_variable,TestInterpolate/missed_traits,TestVariable,TestVarValidation/no_validation,TestVariable/external_with_no_brackets,TestMatch/raw_regexp,TestMatch/regexp.match_call,TestInterpolate/literal_expression,TestMatchers,TestVariable/invalid_syntax,TestMatch/wildcard,TestVariable/internal_with_no_brackets,TestVariable/internal_with_spaces_removed,TestVariable/string_literal,TestInterpolate/regexp_replacement_with_named_match,TestVariable/variable_with_prefix_and_suffix,TestVariable/too_many_levels_of_nesting_in_the_variable_with_property,TestVarValidation/validate_namespace_ok,TestMatch/string_literal,TestVariable/valid_with_brackets,TestInterpolate/mapped_traits_with_email.local,TestMatch/bad_regexp,TestMatch/no_curly_bracket_suffix,TestVariable/variable_with_local_function,TestMatchers/regexp_matcher_positive,FuzzNewExpression,TestInterpolate/regexp_replacement_with_multiple_matches,TestMatch/not_a_boolean_variable,TestMatchers/prefix/suffix_matcher_positive,TestVariable/regexp_replace_constant_expression,TestInterpolate/traits_with_prefix_and_suffix,TestMatch/regexp.not_match_call,FuzzNewMatcher,TestMatch/unknown_namespace,TestMatchers/regexp_matcher_negative,TestVariable/invalid_variable_syntax,TestMatchers/prefix/suffix_matcher_negative,TestVarValidation/variable_not_found,TestVariable/regexp_replace_with_variable_expression,TestApplyTraits/logins_substitute_in_allow_rule_with_multiple_functions_and_regexps,TestVariable/too_many_levels_of_nesting_in_the_variable,TestVariable/non_existing_function,TestVariable/regexp_replace_with_variable_replacement,TestApplyTraits/logins_substitute_in_allow_rule_can_have_constant_expressions,TestVariable/no_curly_bracket_suffix,TestVariable/extra_args,TestMatch/no_curly_bracket_prefix,TestVariable/invalid_dot_syntax,TestMatch/not_a_boolean_expression,TestVariable/invalid_int_variable,TestMatch/regexp.match_simple_call,TestMatch/unknown_function,TestMatch,TestApplyTraits,TestMatchers/not_matcher,TestInterpolate/mapped_traits,TestInterpolate/regexp_replacement_with_no_match,TestVariable/regexp_replace,TestVariable/invalid_string_variable,TestInterpolate/error_in_mapping_traits,TestVariable/no_curly_bracket_prefix,TestVarValidation/variable_found > /workspace/stdout.log 2> /workspace/stderr.log

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
