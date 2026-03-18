#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 28f7aac9a5970d27ff3757875b464a5a58a1eb1a
git checkout 28f7aac9a5970d27ff3757875b464a5a58a1eb1a

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 494d9de6f0a94ffb491e74744d2735bce02dc0ab -- test/components/structures/RoomView-test.tsx test/stores/RoomViewStore-test.ts
fi

# Run tests
bash /workspace/run_script.sh test/components/views/settings/devices/filter-test.ts,test/components/structures/LoggedInView-test.ts,test/languageHandler-test.ts,test/components/views/settings/devices/SecurityRecommendations-test.ts,test/utils/EventUtils-test.ts,test/events/RelationsHelper-test.ts,test/utils/exportUtils/exportCSS-test.ts,test/components/views/settings/EventIndexPanel-test.ts,test/stores/RoomViewStore-test.ts,test/components/structures/RoomView-test.tsx,test/SlashCommands-test.ts,test/components/views/messages/MStickerBody-test.ts,test/components/views/messages/DateSeparator-test.ts,test/components/views/beacon/LeftPanelLiveShareWarning-test.ts,test/utils/room/canInviteTo-test.ts,test/settings/handlers/RoomDeviceSettingsHandler-test.ts,test/components/views/rooms/RoomPreviewBar-test.ts,test/components/views/settings/CrossSigningPanel-test.ts,test/components/views/beacon/OwnBeaconStatus-test.ts,test/components/views/elements/Pill-test.ts,test/components/views/audio_messages/RecordingPlayback-test.ts,test/components/views/messages/EncryptionEvent-test.ts,test/components/views/elements/ExternalLink-test.ts > /workspace/stdout.log 2> /workspace/stderr.log
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
