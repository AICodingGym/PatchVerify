#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 0b192c8d132e07e024340a9780c1641a5de5b326
git checkout 0b192c8d132e07e024340a9780c1641a5de5b326

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup only when a real code patch was provided (not just .swebench/.github)
HAS_CODE_PATCH=$(grep "^diff --git" /workspace/patch.diff 2>/dev/null | grep -v "\.swebench\|\.github\|submit\.sh\|\.gitignore\|problem_statement\.md\|hints_text\.md\|CLAUDE\.md\|AGENTS\.md\|\.claudeignore\|\.copilotignore\|\.cursorignore\|\.cursorrules\|\.devcontainer\|\.vscode" | wc -l)
if [ "$HAS_CODE_PATCH" -gt 0 ]; then
  git checkout d873ea4fa67d3132eccba39213c1ca2f52064dcc -- lib/client/api_test.go tool/tsh/proxy_test.go
fi

# Run tests
bash /workspace/run_script.sh TestSaveGetTrustedCerts,TestNewInsecureWebClientHTTPProxy,TestLocalKeyAgent_AddDatabaseKey,TestListKeys,TestNewClient_UseKeyPrincipals,TestKeyCRUD,TestKnownHosts,TestEndPlaybackWhilePaused,TestNewClientWithPoolHTTPProxy,TestClientAPI,TestHostCertVerification,TestDefaultHostPromptFunc,TestPruneOldHostKeys,TestMatchesWildcard,TestEmptyPlay,TestNewClientWithPoolNoProxy,TestParseSearchKeywords_SpaceDelimiter,TestMemLocalKeyStore,TestApplyProxySettings,TestConfigDirNotDeleted,TestAddKey_withoutSSHCert,TestParseSearchKeywords,TestWebProxyHostPort,TestProxySSHConfig,TestHostKeyVerification,TestStop,TestPlayPause,TestNewInsecureWebClientNoProxy,TestVirtualPathNames,TestEndPlaybackWhilePlaying,TestDeleteAll,TestLoadKey,TestCheckKey,TestCanPruneOldHostsEntry,TestParseKnownHost,TestPlainHttpFallback,TestIsOldHostsEntry,TestParseProxyHostString,TestAddKey,TestTeleportClient_Login_local > /workspace/stdout.log 2> /workspace/stderr.log
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
