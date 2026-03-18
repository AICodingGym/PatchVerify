#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 97f6431d60ff5e3f9168948a306036402c316fa1
git checkout 97f6431d60ff5e3f9168948a306036402c316fa1

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 53a9b6447bd7e6110ee4a63e2ec0322c250f08d1 -- test/utils/MessageDiffUtils-test.tsx test/utils/__snapshots__/MessageDiffUtils-test.tsx.snap
fi

# Run tests
bash /workspace/run_script.sh test/components/structures/MessagePanel-test.ts,test/stores/MemberListStore-test.ts,test/components/views/messages/TextualBody-test.ts,test/components/structures/auth/Login-test.ts,test/utils/__snapshots__/MessageDiffUtils-test.tsx.snap,test/KeyBindingsManager-test.ts,test/voice-broadcast/utils/pauseNonLiveBroadcastFromOtherRoom-test.ts,test/components/views/settings/AddPrivilegedUsers-test.ts,test/components/views/dialogs/DevtoolsDialog-test.ts,test/utils/maps-test.ts,test/settings/watchers/ThemeWatcher-test.ts,test/components/views/messages/MessageEvent-test.ts,test/utils/beacon/geolocation-test.ts,test/components/views/location/Map-test.ts,test/SlashCommands-test.ts,test/components/views/elements/ReplyChain-test.ts,test/components/views/dialogs/InviteDialog-test.ts,test/components/views/beacon/BeaconViewDialog-test.ts,test/events/RelationsHelper-test.ts,test/events/location/getShareableLocationEvent-test.ts,test/components/views/elements/EventListSummary-test.ts,test/components/views/settings/devices/LoginWithQRFlow-test.ts,test/components/views/spaces/SpaceTreeLevel-test.ts,test/editor/history-test.ts,test/components/views/avatars/BaseAvatar-test.ts,test/linkify-matrix-test.ts,test/utils/MessageDiffUtils-test.tsx,test/PosthogAnalytics-test.ts,test/utils/device/clientInformation-test.ts,test/components/views/rooms/RoomPreviewBar-test.ts,test/Markdown-test.ts,test/components/views/right_panel/PinnedMessagesCard-test.ts,test/components/views/settings/devices/LoginWithQR-test.ts,test/utils/MessageDiffUtils-test.ts,test/components/views/settings/discovery/EmailAddresses-test.ts,test/modules/ProxiedModuleApi-test.ts > /workspace/stdout.log 2> /workspace/stderr.log
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
