#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 53415bfdfeb9f25e6755dde2bc41e9dbca4fa791
git checkout 53415bfdfeb9f25e6755dde2bc41e9dbca4fa791

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 53b42e321777a598aaf2bb3eab22d710569f83a8 -- test/components/views/dialogs/spotlight/RoomResultContextMenus-test.tsx test/components/views/rooms/RoomHeader-test.tsx test/components/views/rooms/RoomTile-test.tsx
fi

# Run tests
bash /workspace/run_script.sh test/components/views/settings/tabs/room/SecurityRoomSettingsTab-test.ts,test/components/views/dialogs/spotlight/RoomResultContextMenus-test.tsx,test/utils/ShieldUtils-test.ts,test/components/structures/LoggedInView-test.ts,test/stores/room-list/MessagePreviewStore-test.ts,test/components/views/rooms/RoomHeader-test.ts,test/components/views/settings/tabs/room/VoipRoomSettingsTab-test.ts,test/components/structures/ThreadView-test.ts,test/components/views/dialogs/spotlight/RoomResultContextMenus-test.ts,test/components/views/rooms/RoomHeader-test.tsx,test/components/views/rooms/wysiwyg_composer/SendWysiwygComposer-test.ts,test/components/views/rooms/RoomTile-test.ts,test/components/structures/auth/Registration-test.ts,test/components/views/elements/crypto/VerificationQRCode-test.ts,test/components/views/rooms/RoomTile-test.tsx,test/utils/DateUtils-test.ts,test/components/views/messages/MessageActionBar-test.ts,test/utils/tooltipify-test.ts,test/utils/exportUtils/HTMLExport-test.ts > /workspace/stdout.log 2> /workspace/stderr.log
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
