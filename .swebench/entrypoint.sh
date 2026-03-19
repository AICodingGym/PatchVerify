#!/bin/bash
set -x

# ENV exports from Dockerfiles
export DEBIAN_FRONTEND=noninteractive
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 42082399f3c51b8e9fb92e54312aafda1838ec4d
git checkout 42082399f3c51b8e9fb92e54312aafda1838ec4d

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore\|problem_statement\.md\|hints_text\.md\|CLAUDE\.md\|AGENTS\.md\|\.claudeignore\|\.copilotignore\|\.cursorignore\|\.cursorrules\|\.devcontainer\|\.vscode" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 369fd37de29c14c690cb3b1c09a949189734026f -- packages/components/components/country/CountrySelect.helpers.test.ts packages/components/containers/calendar/holidaysCalendarModal/tests/HolidaysCalendarModal.test.tsx packages/components/containers/calendar/settings/CalendarsSettingsSection.test.tsx packages/shared/test/calendar/holidaysCalendar/holidaysCalendar.spec.ts
fi

# Run tests
bash /workspace/run_script.sh packages/components/components/country/CountrySelect.helpers.test.ts,packages/components/containers/calendar/holidaysCalendarModal/tests/HolidaysCalendarModal.test.tsx,components/country/CountrySelect.helpers.test.ts,packages/shared/test/calendar/holidaysCalendar/holidaysCalendar.spec.ts,containers/calendar/holidaysCalendarModal/tests/HolidaysCalendarModal.test.ts,containers/calendar/settings/CalendarsSettingsSection.test.ts,packages/components/containers/calendar/settings/CalendarsSettingsSection.test.tsx > /workspace/stdout.log 2> /workspace/stderr.log

# Parse results
python /workspace/parser.py /workspace/stdout.log /workspace/stderr.log /workspace/output.json || true

# Print outputs for GHA log
echo '=== STDOUT ==='
cat /workspace/stdout.log 2>/dev/null || true
echo '=== STDERR ==='
cat /workspace/stderr.log 2>/dev/null || true
echo '=== PARSED OUTPUT ==='
cat /workspace/output.json 2>/dev/null || true

# Exit non-zero if any test failed or errored
python -c "
import json, sys
try:
    with open('/workspace/output.json') as f:
        data = json.load(f)
    tests = data.get('tests', [])
    failed = [t for t in tests if t.get('status') in ('FAILED', 'ERROR')]
    if failed:
        print(f'{len(failed)} test(s) FAILED/ERROR')
        sys.exit(1)
    if not tests:
        print('No tests found')
        sys.exit(1)
    print('All tests passed')
except Exception as e:
    print(f'Could not check results: {e}')
    sys.exit(1)
"
