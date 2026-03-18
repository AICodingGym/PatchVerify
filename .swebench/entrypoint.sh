#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard d8518f64d954113c9363335eb25201befa2de6f2
git checkout d8518f64d954113c9363335eb25201befa2de6f2

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout b67138b316b1e9c11df8a4a8391fe5cc8e75ff9f -- openlibrary/catalog/marc/tests/test_data/bin_expect/880_Nihon_no_chasho.json openlibrary/catalog/marc/tests/test_data/bin_expect/880_alternate_script.json openlibrary/catalog/marc/tests/test_data/bin_expect/880_arabic_french_many_linkages.json openlibrary/catalog/marc/tests/test_data/bin_expect/880_publisher_unlinked.json openlibrary/catalog/marc/tests/test_data/bin_expect/880_table_of_contents.json openlibrary/catalog/marc/tests/test_data/bin_expect/bpl_0486266893.json openlibrary/catalog/marc/tests/test_data/bin_expect/ithaca_two_856u.json openlibrary/catalog/marc/tests/test_data/bin_input/880_Nihon_no_chasho.mrc openlibrary/catalog/marc/tests/test_data/bin_input/880_alternate_script.mrc openlibrary/catalog/marc/tests/test_data/bin_input/880_arabic_french_many_linkages.mrc openlibrary/catalog/marc/tests/test_data/bin_input/880_publisher_unlinked.mrc openlibrary/catalog/marc/tests/test_data/bin_input/880_table_of_contents.mrc openlibrary/catalog/marc/tests/test_data/xml_expect/nybc200247.json openlibrary/catalog/marc/tests/test_data/xml_expect/soilsurveyrepor00statgoog.json openlibrary/catalog/marc/tests/test_data/xml_input/nybc200247_marc.xml openlibrary/catalog/marc/tests/test_marc_binary.py openlibrary/catalog/marc/tests/test_parse.py
fi

# Run tests
bash /workspace/run_script.sh openlibrary/catalog/marc/tests/test_marc_binary.py,openlibrary/catalog/marc/tests/test_parse.py > /workspace/stdout.log 2> /workspace/stderr.log

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
