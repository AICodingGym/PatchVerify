#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 1bf94531fdb3599ccfbc5aca574152b8802bf5eb
git checkout 1bf94531fdb3599ccfbc5aca574152b8802bf5eb

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 3982ba725883e71d4e3e618c61d5140eeb8d850a -- db/backup_test.go db/db_test.go persistence/album_repository_test.go persistence/artist_repository_test.go persistence/collation_test.go persistence/genre_repository_test.go persistence/mediafile_repository_test.go persistence/persistence_suite_test.go persistence/player_repository_test.go persistence/playlist_repository_test.go persistence/playqueue_repository_test.go persistence/property_repository_test.go persistence/radio_repository_test.go persistence/sql_bookmarks_test.go persistence/user_repository_test.go
fi

# Run tests
bash /workspace/run_script.sh TestPersistence,TestDB > /workspace/stdout.log 2> /workspace/stderr.log
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
