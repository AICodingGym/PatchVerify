#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 7ebf14a3432c8f0d8b31d48968a08d055bec2002
git checkout 7ebf14a3432c8f0d8b31d48968a08d055bec2002

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore\|problem_statement\.md\|hints_text\.md\|CLAUDE\.md\|AGENTS\.md\|\.claudeignore\|\.copilotignore\|\.cursorignore\|\.cursorrules\|\.devcontainer\|\.vscode" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout 1e516e989b3c0221f4af6b297d9c0e4c43e4adc3 -- test/tests/subscription/PriceUtilsTest.ts
fi

# Run tests
bash /workspace/run_script.sh test/tests/misc/SchedulerTest.js,test/tests/calendar/EventDragHandlerTest.js,test/tests/api/worker/UrlifierTest.js,test/tests/api/worker/EventBusClientTest.js,test/tests/misc/credentials/CredentialsKeyProviderTest.js,test/tests/calendar/CalendarParserTest.js,test/tests/api/worker/rest/ServiceExecutorTest.js,test/tests/api/common/utils/PlainTextSearchTest.js,test/tests/mail/export/BundlerTest.js,test/tests/api/worker/facades/BlobFacadeTest.js,test/tests/api/common/utils/CommonFormatterTest.js,test/tests/settings/TemplateEditorModelTest.js,test/tests/api/worker/rest/CborDateEncoderTest.js,test/tests/misc/FormatValidatorTest.js,test/tests/misc/FormatterTest.js,test/tests/subscription/CreditCardViewModelTest.js,test/tests/api/worker/search/IndexerTest.js,test/tests/misc/DeviceConfigTest.js,test/tests/misc/credentials/CredentialsProviderTest.js,test/tests/contacts/VCardImporterTest.js,test/tests/api/worker/facades/BlobAccessTokenFacadeTest.js,test/tests/calendar/eventeditor/CalendarEventWhoModelTest.js,test/tests/gui/ColorTest.js,test/tests/api/worker/rest/RestClientTest.js,test/tests/calendar/CalendarImporterTest.js,test/tests/calendar/AlarmSchedulerTest.js,test/tests/api/worker/search/IndexUtilsTest.js,test/tests/api/common/error/RestErrorTest.js,test/tests/calendar/CalendarGuiUtilsTest.js,test/tests/api/worker/utils/SleepDetectorTest.js,test/tests/api/worker/rest/EntityRestCacheTest.js,test/tests/settings/UserDataExportTest.js,test/tests/api/worker/facades/CalendarFacadeTest.js,test/tests/api/worker/rest/CacheStorageProxyTest.js,test/tests/mail/KnowledgeBaseSearchFilterTest.js,test/tests/api/worker/crypto/OwnerEncSessionKeysUpdateQueueTest.js,test/tests/api/worker/facades/LoginFacadeTest.js,test/tests/settings/whitelabel/CustomColorEditorTest.js,test/tests/mail/model/FolderSystemTest.js,test/tests/misc/ParserTest.js,test/tests/api/worker/search/SearchFacadeTest.js,test/tests/api/common/utils/FileUtilsTest.js,test/tests/gui/base/WizardDialogNTest.js,test/tests/api/worker/search/SearchIndexEncodingTest.js,test/tests/api/worker/facades/MailFacadeTest.js,test/tests/api/worker/search/EventQueueTest.js,test/tests/misc/RecipientsModelTest.js,test/tests/misc/UsageTestModelTest.js,test/tests/api/worker/CompressionTest.js,test/tests/api/worker/crypto/CompatibilityTest.js,test/tests/contacts/VCardExporterTest.js,test/tests/subscription/PriceUtilsTest.ts,test/tests/api/worker/rest/CustomCacheHandlerTest.js,test/tests/mail/TemplateSearchFilterTest.js,test/tests/settings/login/secondfactor/SecondFactorEditModelTest.js,test/tests/support/FaqModelTest.js,test/tests/api/common/utils/BirthdayUtilsTest.js,test/tests/mail/SendMailModelTest.js,test/tests/api/worker/SuspensionHandlerTest.js,test/tests/contacts/ContactMergeUtilsTest.js,test/tests/calendar/eventeditor/CalendarEventWhenModelTest.js,test/tests/api/worker/facades/UserFacadeTest.js,test/tests/api/main/EntropyCollectorTest.js,test/tests/misc/ListModelTest.js,test/tests/gui/GuiUtilsTest.js,test/tests/misc/parsing/MailAddressParserTest.js,test/tests/api/worker/search/SuggestionFacadeTest.js,test/tests/misc/ClientDetectorTest.js,test/tests/misc/credentials/NativeCredentialsEncryptionTest.js,test/tests/misc/HtmlSanitizerTest.js,test/tests/api/worker/search/IndexerCoreTest.js,test/tests/api/worker/crypto/CryptoFacadeTest.js,test/tests/api/worker/search/MailIndexerTest.js,test/tests/misc/LanguageViewModelTest.js,test/tests/calendar/CalendarViewModelTest.js,test/tests/settings/mailaddress/MailAddressTableModelTest.js,test/tests/api/worker/search/GroupInfoIndexerTest.js,test/tests/calendar/CalendarUtilsTest.js,test/tests/gui/ThemeControllerTest.js,test/tests/calendar/eventeditor/CalendarEventModelTest.js,test/tests/api/worker/search/TokenizerTest.js,test/tests/subscription/SubscriptionUtilsTest.js,test/tests/subscription/PriceUtilsTest.js,test/tests/file/FileControllerTest.js,test/tests/mail/export/ExporterTest.js,test/tests/api/common/error/TutanotaErrorTest.js,test/tests/serviceworker/SwTest.js,test/tests/gui/animation/AnimationsTest.js,test/tests/api/worker/facades/MailAddressFacadeTest.js,test/tests/api/worker/rest/EntityRestClientTest.js,test/tests/mail/MailUtilsSignatureTest.js,test/tests/api/worker/facades/ConfigurationDbTest.js,test/tests/api/common/utils/LoggerTest.js,test/tests/calendar/CalendarModelTest.js,test/tests/mail/InboxRuleHandlerTest.js,test/tests/calendar/eventeditor/CalendarEventAlarmModelTest.js,test/tests/contacts/ContactUtilsTest.js,test/tests/misc/PasswordUtilsTest.js,test/tests/misc/OutOfOfficeNotificationTest.js,test/tests/api/worker/rest/EphemeralCacheStorageTest.js,test/tests/login/LoginViewModelTest.js,test/tests/api/worker/search/ContactIndexerTest.js,test/tests/mail/MailModelTest.js,test/tests/misc/news/items/ReferralLinkNewsTest.js,test/tests/translations/TranslationKeysTest.js,test/tests/api/common/utils/EntityUtilsTest.js,test/tests/misc/NewsModelTest.js,test/tests/misc/webauthn/WebauthnClientTest.js > /workspace/stdout.log 2> /workspace/stderr.log
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
