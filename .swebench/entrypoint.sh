#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard be52cd325af38f53fa6b6f869bc10b88160e06e2
git checkout be52cd325af38f53fa6b6f869bc10b88160e06e2

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout e6681abe6a7113cfd2da507f05581b7bdf398540 -- lib/events/auditwriter_test.go lib/events/emitter_test.go lib/events/stream_test.go
fi

# Run tests
bash /workspace/run_script.sh TestStreamerCompleteEmpty,TestAsyncEmitter/Receive,TestProtoStreamer/small_load_test_with_some_uneven_numbers,TestProtoStreamer/one_event_using_the_whole_part,TestWriterEmitter,TestAsyncEmitter/Slow,TestProtoStreamer/no_events,TestExport,TestAuditWriter,TestAsyncEmitter/Close,TestProtoStreamer/5MB_similar_to_S3_min_size_in_bytes,TestProtoStreamer,TestAuditWriter/ResumeMiddle,TestAsyncEmitter,TestAuditWriter/Backoff,TestAuditWriter/Session,TestAuditLog,TestAuditWriter/ResumeStart,TestProtoStreamer/get_a_part_per_message > /workspace/stdout.log 2> /workspace/stderr.log
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
