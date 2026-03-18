#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard ba171f1fe5814a1b9ee88f792afaf05ce5aa507b
git checkout ba171f1fe5814a1b9ee88f792afaf05ce5aa507b

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 9bf77963ee5e036d54b2a3ca202fbf6378464a5e -- test/components/views/settings/devices/DeviceDetails-test.tsx test/components/views/settings/devices/__snapshots__/CurrentDeviceSection-test.tsx.snap test/components/views/settings/devices/__snapshots__/DeviceDetails-test.tsx.snap
fi

# Run tests
bash /workspace/run_script.sh test/components/views/dialogs/ExportDialog-test.ts,test/components/views/settings/devices/CurrentDeviceSection-test.ts,test/components/views/settings/SettingsFieldset-test.ts,test/ContentMessages-test.ts,test/components/views/settings/devices/DeviceDetails-test.ts,test/components/views/settings/devices/__snapshots__/DeviceDetails-test.tsx.snap,test/components/views/settings/devices/DeviceDetails-test.tsx,test/components/views/settings/devices/__snapshots__/CurrentDeviceSection-test.tsx.snap,test/editor/serialize-test.ts,test/stores/RoomViewStore-test.ts,test/components/views/settings/DevicesPanel-test.ts,test/events/location/getShareableLocationEvent-test.ts,test/utils/beacon/bounds-test.ts,test/components/views/dialogs/SpotlightDialog-test.ts,test/components/views/elements/InteractiveTooltip-test.ts,test/utils/iterables-test.ts > /workspace/stdout.log 2> /workspace/stderr.log
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
