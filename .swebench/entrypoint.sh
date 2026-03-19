#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 9dfb7c231f98a2d3bf48a99577d8a55cfdb2480b
git checkout 9dfb7c231f98a2d3bf48a99577d8a55cfdb2480b

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore\|problem_statement\.md\|hints_text\.md\|CLAUDE\.md\|AGENTS\.md\|\.claudeignore\|\.copilotignore\|\.cursorignore\|\.cursorrules\|\.devcontainer\|\.vscode" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 219bc8f05d7b980e038bc1524cb021bf56397a1b -- test/api/worker/EventBusClientTest.ts
fi

# Run tests
bash /workspace/run_script.sh test/tests/api/worker/facades/LoginFacadeTest.js,test/tests/misc/OutOfOfficeNotificationTest.js,test/tests/misc/FormatterTest.js,test/tests/api/worker/crypto/CompatibilityTest.js,test/tests/api/worker/rest/ServiceExecutorTest.js,test/tests/misc/webauthn/WebauthnClientTest.js,test/tests/api/worker/CompressionTest.js,test/tests/api/worker/utils/SleepDetectorTest.js,test/tests/misc/DeviceConfigTest.js,test/tests/gui/base/WizardDialogNTest.js,test/tests/contacts/ContactMergeUtilsTest.js,test/tests/gui/animation/AnimationsTest.js,test/tests/contacts/ContactUtilsTest.js,test/tests/misc/ClientDetectorTest.js,test/tests/api/worker/facades/MailFacadeTest.js,test/tests/api/worker/search/EventQueueTest.js,test/tests/api/worker/SuspensionHandlerTest.js,test/tests/misc/SchedulerTest.js,test/tests/api/worker/rest/EntityRestCacheTest.js,test/tests/api/worker/search/MailIndexerTest.js,test/tests/api/worker/search/SuggestionFacadeTest.js,test/tests/misc/HtmlSanitizerTest.js,test/tests/misc/ParserTest.js,test/tests/api/common/error/TutanotaErrorTest.js,test/tests/api/worker/search/GroupInfoIndexerTest.js,test/tests/calendar/AlarmSchedulerTest.js,test/tests/mail/MailUtilsSignatureTest.js,test/tests/api/worker/search/IndexUtilsTest.js,test/tests/api/worker/rest/RestClientTest.js,test/tests/misc/credentials/CredentialsKeyProviderTest.js,test/tests/subscription/PriceUtilsTest.js,test/tests/misc/parsing/MailAddressParserTest.js,test/tests/mail/TemplateSearchFilterTest.js,test/tests/misc/PasswordUtilsTest.js,test/tests/calendar/EventDragHandlerTest.js,test/tests/gui/ThemeControllerTest.js,test/tests/api/common/utils/PlainTextSearchTest.js,test/tests/api/worker/EventBusClientTest.js,test/tests/gui/ColorTest.js,test/tests/login/LoginViewModelTest.js,test/tests/api/common/utils/BirthdayUtilsTest.js,test/tests/api/worker/search/ContactIndexerTest.js,test/tests/gui/GuiUtilsTest.js,test/tests/api/worker/search/IndexerTest.js,test/tests/mail/export/ExporterTest.js,test/tests/api/worker/search/SearchFacadeTest.js,test/tests/api/common/utils/LoggerTest.js,test/tests/api/worker/rest/EntityRestClientTest.js,test/tests/mail/SendMailModelTest.js,test/tests/misc/FormatValidatorTest.js,test/tests/api/worker/facades/CalendarFacadeTest.js,test/tests/calendar/CalendarParserTest.js,test/tests/contacts/VCardImporterTest.js,test/tests/misc/UsageTestModelTest.js,test/tests/subscription/SubscriptionUtilsTest.js,test/tests/misc/credentials/CredentialsProviderTest.js,test/tests/mail/MailModelTest.js,test/tests/settings/TemplateEditorModelTest.js,test/tests/api/common/error/RestErrorTest.js,test/tests/api/common/utils/EntityUtilsTest.js,test/tests/api/worker/facades/ConfigurationDbTest.js,test/tests/support/FaqModelTest.js,test/tests/api/worker/search/SearchIndexEncodingTest.js,test/tests/mail/export/BundlerTest.js,test/tests/misc/LanguageViewModelTest.js,test/tests/calendar/CalendarImporterTest.js,test/tests/mail/InboxRuleHandlerTest.js,test/tests/calendar/CalendarModelTest.js,test/tests/contacts/VCardExporterTest.js,test/tests/calendar/CalendarViewModelTest.js,test/tests/calendar/CalendarGuiUtilsTest.js,test/tests/mail/KnowledgeBaseSearchFilterTest.js,test/tests/api/worker/search/IndexerCoreTest.js,test/tests/api/worker/search/TokenizerTest.js,test/tests/calendar/CalendarUtilsTest.js,test/api/worker/EventBusClientTest.ts,test/tests/api/worker/crypto/CryptoFacadeTest.js,test/tests/misc/credentials/NativeCredentialsEncryptionTest.js,test/tests/api/worker/rest/CborDateEncoderTest.js > /workspace/stdout.log 2> /workspace/stderr.log

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
