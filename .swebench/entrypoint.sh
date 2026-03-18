#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard e6fe7b7ea8aad2672854b96b5eb7fb863e19cf92
git checkout e6fe7b7ea8aad2672854b96b5eb7fb863e19cf92

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 880428ab94c6ea98d3d18dcaeb17e8767adcb461 -- test/test-utils/test-utils.ts test/toasts/UnverifiedSessionToast-test.tsx test/toasts/__snapshots__/UnverifiedSessionToast-test.tsx.snap
fi

# Run tests
bash /workspace/run_script.sh test/toasts/UnverifiedSessionToast-test.tsx,test/components/structures/MessagePanel-test.ts,test/components/views/rooms/wysiwyg_composer/SendWysiwygComposer-test.ts,test/hooks/useUserOnboardingTasks-test.ts,test/components/views/spaces/SpaceSettingsVisibilityTab-test.ts,test/components/views/dialogs/polls/PollListItemEnded-test.ts,test/toasts/__snapshots__/UnverifiedSessionToast-test.tsx.snap,test/components/views/elements/PowerSelector-test.ts,test/createRoom-test.ts,test/components/views/settings/tabs/user/KeyboardUserSettingsTab-test.ts,test/test-utils/test-utils.ts,test/toasts/UnverifiedSessionToast-test.ts > /workspace/stdout.log 2> /workspace/stderr.log
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
