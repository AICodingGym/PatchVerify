#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 6bc4523cf7c2c48bdf76b7a22e12e078f2c53f7f
git checkout 6bc4523cf7c2c48bdf76b7a22e12e078f2c53f7f

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 6205c70462e0ce2e1e77afb3a70b55d0fdfe1b31 -- test/voice-broadcast/models/VoiceBroadcastPlayback-test.ts test/voice-broadcast/utils/determineVoiceBroadcastLiveness-test.ts
fi

# Run tests
bash /workspace/run_script.sh test/useTopic-test.ts,test/components/views/typography/Caption-test.ts,test/voice-broadcast/utils/determineVoiceBroadcastLiveness-test.ts,test/utils/location/parseGeoUri-test.ts,test/components/views/settings/devices/DeviceDetails-test.ts,test/voice-broadcast/models/VoiceBroadcastPlayback-test.ts,test/stores/room-list/algorithms/Algorithm-test.ts,test/utils/beacon/bounds-test.ts,test/components/views/context_menus/EmbeddedPage-test.ts,test/components/structures/auth/ForgotPassword-test.ts,test/toasts/IncomingCallToast-test.ts,test/components/views/dialogs/ChangelogDialog-test.ts,test/theme-test.ts,test/components/views/settings/tabs/user/SessionManagerTab-test.ts > /workspace/stdout.log 2> /workspace/stderr.log
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
