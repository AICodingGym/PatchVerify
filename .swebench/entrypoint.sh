#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard bb69574e02bd62e5ccd3cebb25e1c992641afb2a
git checkout bb69574e02bd62e5ccd3cebb25e1c992641afb2a

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 1330415d33a27594c948a36d9d7701f496229e9f -- lib/utils/parse/parse_test.go
fi

# Run tests
bash /workspace/run_script.sh TestMatch/bad_regexp,TestInterpolate/mapped_traits,TestVariable/internal_with_spaces_removed,TestMatch/unknown_function,TestInterpolate/error_in_mapping_traits,TestMatchers/regexp_matcher_positive,TestMatch,TestVariable/no_curly_bracket_suffix,TestMatchers/regexp_matcher_negative,TestMatch/wildcard,TestMatch/unsupported_namespace,TestMatch/no_curly_bracket_prefix,TestMatch/unsupported_variable_syntax,TestMatch/raw_regexp,TestMatch/regexp.not_match_call,TestVariable/variable_with_local_function,TestMatch/string_literal,TestMatch/unknown_namespace,TestVariable/external_with_no_brackets,TestVariable/too_many_levels_of_nesting_in_the_variable,TestVariable,TestInterpolate/missed_traits,TestVariable/valid_with_brackets,TestInterpolate/literal_expression,TestVariable/regexp_function_call_not_allowed,TestVariable/invalid_dot_syntax,TestVariable/string_literal,TestInterpolate/mapped_traits_with_email.local,TestVariable/internal_with_no_brackets,TestVariable/invalid_variable_syntax,TestMatch/regexp.match_call,TestVariable/variable_with_prefix_and_suffix,TestMatchers/prefix/suffix_matcher_positive,TestInterpolate,TestInterpolate/traits_with_prefix_and_suffix,TestMatch/no_curly_bracket_suffix,TestMatchers/not_matcher,TestVariable/invalid_syntax,TestMatchers/prefix/suffix_matcher_negative,TestVariable/no_curly_bracket_prefix,TestMatchers,TestVariable/empty_variable > /workspace/stdout.log 2> /workspace/stderr.log
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
