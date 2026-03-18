#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 1e32ae3ec085dc3ab8611b88b56baf6354fa0762
git checkout 1e32ae3ec085dc3ab8611b88b56baf6354fa0762

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 08ac40d050a64e1d2646ece4959af0c42bf6b7b5 -- openlibrary/catalog/add_book/tests/test_add_book.py openlibrary/catalog/marc/tests/test_data/bin_expect/ithaca_college_75002321.json openlibrary/catalog/marc/tests/test_data/bin_expect/lesnoirsetlesrou0000garl_meta.json openlibrary/catalog/marc/tests/test_data/bin_expect/memoirsofjosephf00fouc_meta.json openlibrary/catalog/marc/tests/test_data/bin_expect/warofrebellionco1473unit_meta.json openlibrary/catalog/marc/tests/test_data/xml_expect/00schlgoog.json openlibrary/catalog/marc/tests/test_data/xml_expect/warofrebellionco1473unit.json
fi

# Run tests
bash /workspace/run_script.sh openlibrary/catalog/marc/tests/test_parse.py,openlibrary/catalog/add_book/tests/test_add_book.py > /workspace/stdout.log 2> /workspace/stderr.log

# Parse results
python /workspace/parser.py /workspace/stdout.log /workspace/stderr.log /workspace/output.json || true

# Print outputs for GHA log
echo '=== STDOUT ==='
cat /workspace/stdout.log 2>/dev/null || true
echo '=== STDERR ==='
cat /workspace/stderr.log 2>/dev/null || true
echo '=== PARSED OUTPUT ==='
cat /workspace/output.json 2>/dev/null || true

# Exit non-zero if any test failed
python -c "
import json, sys
try:
    with open('/workspace/output.json') as f:
        data = json.load(f)
    failed = [t for t in data.get('tests', []) if t.get('status') == 'FAILED']
    if failed:
        print(f'{len(failed)} test(s) FAILED')
        sys.exit(1)
    print('All tests passed')
except Exception as e:
    print(f'Could not check results: {e}')
    sys.exit(1)
"
