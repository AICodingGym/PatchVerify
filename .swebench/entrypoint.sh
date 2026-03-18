#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 29c193210fc5297f0839f02eddea36aa63977516
git checkout 29c193210fc5297f0839f02eddea36aa63977516

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 6961c256035bed0b7640a6e5907652c806968478 -- test/components/views/auth/RegistrationToken-test.tsx
fi

# Run tests
bash /workspace/run_script.sh test/components/views/settings/tabs/user/SessionManagerTab-test.ts,test/components/views/spaces/QuickThemeSwitcher-test.ts,test/components/views/rooms/wysiwyg_composer/components/WysiwygComposer-test.ts,test/voice-broadcast/utils/startNewVoiceBroadcastRecording-test.ts,test/components/views/settings/devices/filter-test.ts,test/components/views/auth/RegistrationToken-test.tsx,test/components/views/settings/DevicesPanel-test.ts,test/utils/device/parseUserAgent-test.ts,test/components/views/settings/devices/SecurityRecommendations-test.ts,test/stores/room-list/filters/VisibilityProvider-test.ts,test/components/views/auth/RegistrationToken-test.ts,test/utils/FixedRollingArray-test.ts,test/components/views/rooms/wysiwyg_composer/SendWysiwygComposer-test.ts,test/components/views/elements/ExternalLink-test.ts,test/components/structures/ThreadPanel-test.ts,test/components/views/elements/Linkify-test.ts > /workspace/stdout.log 2> /workspace/stderr.log
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
