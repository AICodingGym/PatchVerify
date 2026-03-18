#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard c0e40217f35e2d2a067bbb881c3871565eaf54b2
git checkout c0e40217f35e2d2a067bbb881c3871565eaf54b2

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout ad26925bb6628260cfe0fcf90ec0a8cba381f4a4 -- test/components/views/elements/Pill-test.tsx test/components/views/elements/__snapshots__/Pill-test.tsx.snap test/components/views/messages/TextualBody-test.tsx test/components/views/messages/__snapshots__/TextualBody-test.tsx.snap test/test-utils/test-utils.ts
fi

# Run tests
bash /workspace/run_script.sh test/components/views/messages/TextualBody-test.tsx,test/utils/location/parseGeoUri-test.ts,test/components/views/elements/Pill-test.ts,test/editor/serialize-test.ts,test/components/views/rooms/wysiwyg_composer/utils/createMessageContent-test.ts,test/linkify-matrix-test.ts,test/utils/beacon/geolocation-test.ts,test/components/views/messages/TextualBody-test.ts,test/components/views/elements/__snapshots__/Pill-test.tsx.snap,test/components/views/settings/devices/DeviceDetails-test.ts,test/components/views/messages/RoomPredecessorTile-test.ts,test/test-utils/test-utils.ts,test/components/views/settings/tabs/user/SessionManagerTab-test.ts,test/editor/caret-test.ts,test/components/views/elements/Pill-test.tsx,test/utils/MultiInviter-test.ts,test/Terms-test.ts,test/components/views/messages/__snapshots__/TextualBody-test.tsx.snap,test/components/views/rooms/BasicMessageComposer-test.ts,test/utils/exportUtils/HTMLExport-test.ts > /workspace/stdout.log 2> /workspace/stderr.log
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
