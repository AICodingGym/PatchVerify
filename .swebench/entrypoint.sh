#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 90801eb38bd0bcca067c02ccc7434b6b9309c03c
git checkout 90801eb38bd0bcca067c02ccc7434b6b9309c03c

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout b7fea97bb68c6628a644580076f840109132f074 -- test/unit-tests/components/views/settings/encryption/__snapshots__/ChangeRecoveryKey-test.tsx.snap test/unit-tests/components/views/settings/encryption/__snapshots__/ResetIdentityPanel-test.tsx.snap test/unit-tests/components/views/settings/tabs/user/__snapshots__/EncryptionUserSettingsTab-test.tsx.snap
fi

# Run tests
bash /workspace/run_script.sh test/unit-tests/MatrixClientPeg-test.ts,test/unit-tests/utils/i18n-helpers-test.ts,test/unit-tests/components/structures/FilePanel-test.ts,test/unit-tests/components/views/auth/AuthHeaderLogo-test.ts,test/unit-tests/components/views/settings/encryption/ResetIdentityPanel-test.ts,test/unit-tests/components/views/dialogs/ShareDialog-test.ts,test/unit-tests/stores/room-list/utils/roomMute-test.ts,test/unit-tests/components/views/settings/tabs/user/__snapshots__/EncryptionUserSettingsTab-test.tsx.snap,test/unit-tests/components/views/settings/encryption/__snapshots__/ResetIdentityPanel-test.tsx.snap,test/unit-tests/components/structures/RoomView-test.ts,test/unit-tests/components/views/messages/MImageBody-test.ts,test/unit-tests/components/views/settings/encryption/ChangeRecoveryKey-test.ts,test/unit-tests/Image-test.ts,test/unit-tests/utils/dm/findDMForUser-test.ts,test/unit-tests/components/views/dialogs/RoomSettingsDialog-test.ts,test/unit-tests/components/views/settings/encryption/__snapshots__/ChangeRecoveryKey-test.tsx.snap,test/unit-tests/components/views/rooms/memberlist/MemberTileView-test.ts,test/unit-tests/SlashCommands-test.ts,test/unit-tests/components/views/settings/ThemeChoicePanel-test.ts,test/unit-tests/components/structures/TabbedView-test.ts,test/unit-tests/components/structures/ThreadView-test.ts,test/unit-tests/components/views/settings/tabs/user/EncryptionUserSettingsTab-test.ts,test/unit-tests/utils/local-room-test.ts,test/unit-tests/settings/SettingsStore-test.ts,test/unit-tests/components/views/rooms/RoomHeader/RoomHeader-test.ts,test/unit-tests/UserActivity-test.ts,test/unit-tests/components/views/rooms/RoomHeader/CallGuestLinkButton-test.ts > /workspace/stdout.log 2> /workspace/stderr.log
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
