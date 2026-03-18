#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 7a33818bd7ec89c21054691afcb6db2fb2631e14
git checkout 7a33818bd7ec89c21054691afcb6db2fb2631e14

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 772df3021201d9c73835a626df8dcb6334ad9a3e -- test/components/views/settings/__snapshots__/DevicesPanel-test.tsx.snap test/components/views/settings/devices/FilteredDeviceList-test.tsx test/components/views/settings/devices/__snapshots__/SelectableDeviceTile-test.tsx.snap test/components/views/settings/tabs/user/SessionManagerTab-test.tsx
fi

# Run tests
bash /workspace/run_script.sh test/components/views/spaces/SpacePanel-test.ts,test/components/views/settings/DevicesPanel-test.ts,test/hooks/useDebouncedCallback-test.ts,test/components/views/settings/tabs/user/SessionManagerTab-test.tsx,test/components/views/settings/__snapshots__/DevicesPanel-test.tsx.snap,test/components/views/settings/tabs/user/SessionManagerTab-test.ts,test/components/views/rooms/SearchBar-test.ts,test/components/views/settings/devices/SelectableDeviceTile-test.ts,test/utils/tooltipify-test.ts,test/utils/notifications-test.ts,test/components/views/dialogs/SpotlightDialog-test.ts,test/utils/dm/createDmLocalRoom-test.ts,test/modules/ModuleRunner-test.ts,test/components/views/settings/devices/FilteredDeviceList-test.tsx,test/components/views/settings/devices/__snapshots__/SelectableDeviceTile-test.tsx.snap,test/components/views/beacon/BeaconListItem-test.ts > /workspace/stdout.log 2> /workspace/stderr.log
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
