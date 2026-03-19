#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 409b35839628e0a63c76dbcb8d41b87e8a06782d
git checkout 409b35839628e0a63c76dbcb8d41b87e8a06782d

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore\|problem_statement\.md\|hints_text\.md\|CLAUDE\.md\|AGENTS\.md\|\.claudeignore\|\.copilotignore\|\.cursorignore\|\.cursorrules\|\.devcontainer\|\.vscode" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout fb32e5f9d9fc152a00144d56dd0af01760a2d4dc -- test/tests/contacts/ContactMergeUtilsTest.ts test/tests/contacts/VCardExporterTest.ts
fi

# Run tests
bash /workspace/run_script.sh test/tests/settings/mailaddress/MailAddressTableModelTest.js,test/tests/api/worker/search/GroupInfoIndexerTest.js,test/tests/mail/export/ExporterTest.js,test/tests/api/common/error/TutanotaErrorTest.js,test/tests/settings/TemplateEditorModelTest.js,test/tests/misc/credentials/CredentialsProviderTest.js,test/tests/gui/ColorTest.js,test/tests/translations/TranslationKeysTest.js,test/tests/api/worker/rest/EphemeralCacheStorageTest.js,test/tests/api/worker/rest/EntityRestCacheTest.js,test/tests/misc/DeviceConfigTest.js,test/tests/contacts/ContactUtilsTest.js,test/tests/calendar/EventDragHandlerTest.js,test/tests/calendar/eventeditor/CalendarEventAlarmModelTest.js,test/tests/api/worker/rest/CborDateEncoderTest.js,test/tests/calendar/eventeditor/CalendarEventWhoModelTest.js,test/tests/api/worker/crypto/CryptoFacadeTest.js,test/tests/misc/ClientDetectorTest.js,test/tests/api/worker/rest/CustomCacheHandlerTest.js,test/tests/api/worker/search/IndexerCoreTest.js,test/tests/contacts/VCardImporterTest.js,test/tests/api/worker/search/TokenizerTest.js,test/tests/api/worker/facades/BlobAccessTokenFacadeTest.js,test/tests/contacts/VCardExporterTest.js,test/tests/mail/MailUtilsSignatureTest.js,test/tests/misc/OutOfOfficeNotificationTest.js,test/tests/api/worker/facades/MailAddressFacadeTest.js,test/tests/misc/UsageTestModelTest.js,test/tests/api/common/utils/EntityUtilsTest.js,test/tests/api/worker/EventBusClientTest.js,test/tests/api/worker/search/IndexerTest.js,test/tests/api/worker/rest/CacheStorageProxyTest.js,test/tests/settings/whitelabel/CustomColorEditorTest.js,test/tests/misc/credentials/NativeCredentialsEncryptionTest.js,test/tests/misc/PasswordUtilsTest.js,test/tests/serviceworker/SwTest.js,test/tests/calendar/CalendarViewModelTest.js,test/tests/calendar/eventeditor/CalendarEventWhenModelTest.js,test/tests/api/worker/facades/MailFacadeTest.js,test/tests/api/worker/search/ContactIndexerTest.js,test/tests/api/worker/crypto/CompatibilityTest.js,test/tests/api/worker/rest/EntityRestClientTest.js,test/tests/api/worker/crypto/OwnerEncSessionKeysUpdateQueueTest.js,test/tests/gui/animation/AnimationsTest.js,test/tests/calendar/CalendarUtilsTest.js,test/tests/api/common/utils/LoggerTest.js,test/tests/contacts/VCardExporterTest.ts,test/tests/subscription/CreditCardViewModelTest.js,test/tests/api/worker/facades/CalendarFacadeTest.js,test/tests/misc/news/items/ReferralLinkNewsTest.js,test/tests/api/worker/search/SearchIndexEncodingTest.js,test/tests/misc/RecipientsModelTest.js,test/tests/api/worker/search/EventQueueTest.js,test/tests/gui/ThemeControllerTest.js,test/tests/mail/MailModelTest.js,test/tests/calendar/CalendarParserTest.js,test/tests/api/worker/search/SuggestionFacadeTest.js,test/tests/api/worker/facades/LoginFacadeTest.js,test/tests/api/worker/search/MailIndexerTest.js,test/tests/api/worker/facades/BlobFacadeTest.js,test/tests/login/LoginViewModelTest.js,test/tests/api/worker/utils/SleepDetectorTest.js,test/tests/misc/parsing/MailAddressParserTest.js,test/tests/misc/HtmlSanitizerTest.js,test/tests/api/common/utils/BirthdayUtilsTest.js,test/tests/api/common/utils/PlainTextSearchTest.js,test/tests/mail/KnowledgeBaseSearchFilterTest.js,test/tests/mail/TemplateSearchFilterTest.js,test/tests/api/worker/search/SearchFacadeTest.js,test/tests/api/worker/facades/ConfigurationDbTest.js,test/tests/calendar/CalendarImporterTest.js,test/tests/mail/SendMailModelTest.js,test/tests/calendar/AlarmSchedulerTest.js,test/tests/api/main/EntropyCollectorTest.js,test/tests/api/worker/rest/ServiceExecutorTest.js,test/tests/support/FaqModelTest.js,test/tests/api/worker/UrlifierTest.js,test/tests/misc/FormatterTest.js,test/tests/mail/model/FolderSystemTest.js,test/tests/mail/InboxRuleHandlerTest.js,test/tests/contacts/ContactMergeUtilsTest.ts,test/tests/misc/LanguageViewModelTest.js,test/tests/misc/webauthn/WebauthnClientTest.js,test/tests/subscription/SubscriptionUtilsTest.js,test/tests/settings/login/secondfactor/SecondFactorEditModelTest.js,test/tests/misc/FormatValidatorTest.js,test/tests/api/worker/search/IndexUtilsTest.js,test/tests/gui/base/WizardDialogNTest.js,test/tests/api/common/error/RestErrorTest.js,test/tests/settings/UserDataExportTest.js,test/tests/misc/SchedulerTest.js,test/tests/calendar/CalendarGuiUtilsTest.js,test/tests/contacts/ContactMergeUtilsTest.js,test/tests/api/worker/SuspensionHandlerTest.js,test/tests/calendar/CalendarModelTest.js,test/tests/misc/ListModelTest.js,test/tests/gui/GuiUtilsTest.js,test/tests/api/common/utils/FileUtilsTest.js,test/tests/misc/ParserTest.js,test/tests/api/common/utils/CommonFormatterTest.js,test/tests/api/worker/facades/UserFacadeTest.js,test/tests/mail/export/BundlerTest.js,test/tests/file/FileControllerTest.js,test/tests/misc/credentials/CredentialsKeyProviderTest.js,test/tests/subscription/PriceUtilsTest.js,test/tests/api/worker/rest/RestClientTest.js,test/tests/misc/NewsModelTest.js,test/tests/api/worker/CompressionTest.js,test/tests/calendar/eventeditor/CalendarEventModelTest.js > /workspace/stdout.log 2> /workspace/stderr.log

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
