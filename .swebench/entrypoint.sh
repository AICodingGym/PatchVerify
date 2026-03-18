#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 8ebdcab7d92f90422776c4390363338dcfd98ba5
git checkout 8ebdcab7d92f90422776c4390363338dcfd98ba5

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout ee13e23b156fbad9369d6a656c827b6444343d4f -- test/components/views/right_panel/RoomHeaderButtons-test.tsx
fi

# Run tests
bash /workspace/run_script.sh test/components/views/dialogs/InteractiveAuthDialog-test.ts,test/components/views/right_panel/RoomHeaderButtons-test.tsx,test/components/views/rooms/RoomHeader-test.ts,test/components/structures/ThreadView-test.ts,test/components/views/settings/shared/SettingsSubsection-test.ts,test/components/views/right_panel/RoomHeaderButtons-test.ts,test/hooks/useProfileInfo-test.ts,test/ScalarAuthClient-test.ts,test/events/location/getShareableLocationEvent-test.ts,test/voice-broadcast/components/atoms/VoiceBroadcastHeader-test.ts > /workspace/stdout.log 2> /workspace/stderr.log
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
