#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 396812cebff3ebfd075bbed04acefc65e787a537
git checkout 396812cebff3ebfd075bbed04acefc65e787a537

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore\|problem_statement\.md\|hints_text\.md\|CLAUDE\.md\|AGENTS\.md\|\.claudeignore\|\.copilotignore\|\.cursorignore\|\.cursorrules\|\.devcontainer\|\.vscode" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout ba6c4a135412c4296dd5551bd94042f0dc024504 -- lib/service/service_test.go lib/service/state_test.go
fi

# Run tests
bash /workspace/run_script.sh TestMonitor/ok_event_remains_in_recovering_state_because_not_enough_time_passed,TestProcessStateGetState/multiple_components,_one_is_recovering,TestProcessStateGetState/multiple_components,_one_is_degraded,TestMonitor/ok_event_in_new_component_causes_overall_OK_state,TestMonitor/ok_event_after_enough_time_causes_OK_state,TestMonitor,TestProcessStateGetState/one_component_in_stateOK,TestMonitor/ok_event_in_one_component_keeps_overall_status_degraded_due_to_other_component,TestMonitor/degraded_event_in_a_new_component_causes_degraded_state,TestMonitor/degraded_event_causes_degraded_state,TestProcessStateGetState/multiple_components,_one_is_starting,TestProcessStateGetState/no_components,TestMonitor/ok_event_in_new_component_causes_overall_recovering_state,TestProcessStateGetState/multiple_components_in_stateOK,TestProcessStateGetState,TestMonitor/ok_event_causes_recovering_state > /workspace/stdout.log 2> /workspace/stderr.log
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
