#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 189d41a956ebf5b90b6cf5829d60be46c1df992e
git checkout 189d41a956ebf5b90b6cf5829d60be46c1df992e

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 2b15263e49da5625922581569834eec4838a9257 -- lib/ai/chat_test.go lib/ai/model/tokencount_test.go
fi

# Run tests
bash /workspace/run_script.sh Test_batchReducer_Add/empty,TestChat_PromptTokens/tokenize_our_prompt,TestAsynchronousTokenCounter_TokenCount,TestChat_PromptTokens/empty,TestNodeEmbeddingGeneration,TestKNNRetriever_GetRelevant,Test_batchReducer_Add/many_elements,TestChat_PromptTokens/system_and_user_messages,TestAsynchronousTokenCounter_TokenCount/empty_count,TestAsynchronousTokenCounter_TokenCount/only_completion_start,TestKNNRetriever_Insert,TestChat_Complete,TestChat_Complete/command_completion,Test_batchReducer_Add/propagate_error,TestAsynchronousTokenCounter_Finished,TestAsynchronousTokenCounter_TokenCount/completion_start_and_end,Test_batchReducer_Add/one_element,TestAsynchronousTokenCounter_TokenCount/only_completion_add,TestChat_PromptTokens,TestChat_Complete/text_completion,TestChat_PromptTokens/only_system_message,Test_batchReducer_Add,TestKNNRetriever_Remove,TestSimpleRetriever_GetRelevant,TestMarshallUnmarshallEmbedding > /workspace/stdout.log 2> /workspace/stderr.log
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
