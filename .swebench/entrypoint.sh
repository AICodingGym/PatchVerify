#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard d5d1ec775caf2d3c9132122c1243898e99fdb2da
git checkout d5d1ec775caf2d3c9132122c1243898e99fdb2da

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 41dfec20bfe9b62cddbbbf621bef2e9aa9685157 -- test/utils/AutoDiscoveryUtils-test.tsx
fi

# Run tests
bash /workspace/run_script.sh test/components/views/rooms/wysiwyg_composer/EditWysiwygComposer-test.ts,test/utils/AutoDiscoveryUtils-test.ts,test/components/views/beacon/BeaconMarker-test.ts,test/components/views/rooms/wysiwyg_composer/SendWysiwygComposer-test.ts,test/utils/LruCache-test.ts,test/utils/beacon/bounds-test.ts,test/components/views/dialogs/ChangelogDialog-test.ts,test/utils/AutoDiscoveryUtils-test.tsx,test/components/views/messages/MBeaconBody-test.ts,test/components/views/rooms/VoiceRecordComposerTile-test.ts,test/components/views/rooms/BasicMessageComposer-test.ts > /workspace/stdout.log 2> /workspace/stderr.log
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
