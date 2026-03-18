#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 8166306e0f8951a9554bf1437f7ef6eef54a3267
git checkout 8166306e0f8951a9554bf1437f7ef6eef54a3267

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 33299af5c9b7a7ec5a9c31d578d4ec5b18088fb7 -- test/components/views/rooms/RoomHeader-test.tsx test/components/views/rooms/__snapshots__/RoomHeader-test.tsx.snap
fi

# Run tests
bash /workspace/run_script.sh test/components/views/settings/Notifications-test.ts,test/stores/widgets/WidgetPermissionStore-test.ts,test/components/views/rooms/__snapshots__/RoomHeader-test.tsx.snap,test/components/views/polls/pollHistory/PollListItemEnded-test.ts,test/components/views/rooms/RoomHeader-test.tsx,test/hooks/useProfileInfo-test.ts,test/stores/room-list/algorithms/RecentAlgorithm-test.ts,test/components/views/elements/AppTile-test.ts,test/i18n-test/languageHandler-test.ts,test/components/views/settings/devices/deleteDevices-test.ts,test/utils/DateUtils-test.ts,test/components/views/dialogs/CreateRoomDialog-test.ts,test/editor/history-test.ts,test/components/views/rooms/wysiwyg_composer/components/WysiwygComposer-test.ts,test/voice-broadcast/components/molecules/VoiceBroadcastPlaybackBody-test.ts,test/components/views/rooms/RoomHeader-test.ts,test/components/structures/RightPanel-test.ts,test/stores/RoomViewStore-test.ts,test/voice-broadcast/stores/VoiceBroadcastRecordingsStore-test.ts,test/components/structures/auth/ForgotPassword-test.ts > /workspace/stdout.log 2> /workspace/stderr.log
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
