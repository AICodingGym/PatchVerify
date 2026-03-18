#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 8b8d24c24c1387210ad1826552126c724c49ee42
git checkout 8b8d24c24c1387210ad1826552126c724c49ee42

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 7c63d52500e145d6fff6de41dd717f61ab88d02f -- test/components/views/rooms/wysiwyg_composer/SendWysiwygComposer-test.tsx
fi

# Run tests
bash /workspace/run_script.sh test/components/views/settings/DevicesPanel-test.ts,test/components/views/settings/discovery/EmailAddresses-test.ts,test/SlidingSyncManager-test.ts,test/events/RelationsHelper-test.ts,test/components/views/rooms/wysiwyg_composer/SendWysiwygComposer-test.tsx,test/components/views/settings/devices/DeviceTypeIcon-test.ts,test/components/views/settings/devices/filter-test.ts,test/components/views/settings/shared/SettingsSubsection-test.ts,test/settings/controllers/IncompatibleController-test.ts,test/autocomplete/QueryMatcher-test.ts,test/voice-broadcast/components/molecules/VoiceBroadcastRecordingPip-test.ts,test/editor/diff-test.ts > /workspace/stdout.log 2> /workspace/stderr.log
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
