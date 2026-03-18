#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 4f32727829c1087e9d3d9955785d8a6255457c7d
git checkout 4f32727829c1087e9d3d9955785d8a6255457c7d

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 1077729a19c0ce902e713cf6fab42c91fb7907f1 -- test/unit-tests/components/viewmodels/roomlist/RoomListViewModel-test.tsx
fi

# Run tests
bash /workspace/run_script.sh test/unit-tests/components/views/rooms/wysiwyg_composer/utils/autocomplete-test.ts,test/unit-tests/components/views/messages/MStickerBody-test.ts,test/unit-tests/vector/platform/WebPlatform-test.ts,test/unit-tests/components/views/spaces/SpaceTreeLevel-test.ts,test/unit-tests/components/views/settings/devices/DeviceDetails-test.ts,test/unit-tests/components/views/spaces/useUnreadThreadRooms-test.ts,test/unit-tests/components/views/elements/SettingsField-test.ts,test/unit-tests/theme-test.ts,test/unit-tests/utils/PinningUtils-test.ts,test/unit-tests/utils/AutoDiscoveryUtils-test.ts,test/unit-tests/components/views/messages/MVideoBody-test.ts,test/unit-tests/components/views/settings/encryption/RecoveryPanel-test.ts,test/unit-tests/components/structures/TimelinePanel-test.ts,test/unit-tests/components/viewmodels/roomlist/RoomListViewModel-test.ts,test/unit-tests/accessibility/RovingTabIndex-test.ts,test/unit-tests/components/views/polls/pollHistory/PollHistory-test.ts,test/unit-tests/components/views/settings/EventIndexPanel-test.ts,test/unit-tests/components/views/settings/tabs/room/SecurityRoomSettingsTab-test.ts,test/unit-tests/utils/local-room-test.ts,test/unit-tests/editor/diff-test.ts,test/unit-tests/components/views/dialogs/security/CreateKeyBackupDialog-test.ts,test/unit-tests/utils/leave-behaviour-test.ts,test/unit-tests/utils/permalinks/MatrixToPermalinkConstructor-test.ts,test/unit-tests/components/views/spaces/SpacePanel-test.ts,test/unit-tests/components/views/rooms/SendMessageComposer-test.ts,test/unit-tests/hooks/useNotificationSettings-test.ts,test/unit-tests/components/views/rooms/wysiwyg_composer/components/LinkModal-test.ts,test/unit-tests/components/viewmodels/roomlist/RoomListViewModel-test.tsx,test/unit-tests/components/views/settings/Notifications-test.ts,test/unit-tests/settings/SettingsStore-test.ts,test/unit-tests/components/views/rooms/UserIdentityWarning-test.ts,test/unit-tests/components/views/messages/DateSeparator-test.ts,test/unit-tests/components/views/emojipicker/EmojiPicker-test.ts,test/unit-tests/components/views/rooms/NotificationDecoration-test.ts,test/unit-tests/Rooms-test.ts,test/unit-tests/components/views/room_settings/RoomProfileSettings-test.ts,test/unit-tests/components/views/dialogs/AccessSecretStorageDialog-test.ts,test/unit-tests/SupportedBrowser-test.ts > /workspace/stdout.log 2> /workspace/stderr.log
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
