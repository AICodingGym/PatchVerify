#!/bin/bash
set -x

# ENV exports from Dockerfiles
export PYTEST_ADDOPTS="--tb=short -v --continue-on-collection-errors --reruns=3"
export UV_HTTP_TIMEOUT=60

cd /app

git reset --hard 6f2f17a7f6749418d0bb329169b9181dba446845
git checkout 6f2f17a7f6749418d0bb329169b9181dba446845

# Apply user patch
git apply -v /workspace/patch.diff || echo 'WARNING: patch apply failed'

# Apply test setup (checkout gold test files)
git checkout 02d1efb8560a1aa1c72cfb1c08edd8b84a9511b4 -- lib/reversetunnel/localsite_test.go

# Run tests
bash /workspace/run_script.sh TestAgentStoreRace,TestCachingResolver,TestAgentStorePopLen,TestEmitConnTeleportSmallReads,TestAgentFailedToClaimLease,TestAgentCertChecker,TestAgentStart,Test_remoteSite_getLocalWatchedCerts,TestStaticResolver,TestLocalSiteOverlap,TestRemoteClusterTunnelManagerSync,TestServerKeyAuth,TestCreateRemoteAccessPoint,TestConnectedProxyGetter,TestAgentStateTransitions,TestEmitConnTeleport,TestAgentPoolConnectionCount,TestEmitConnNotTeleportSmallReads,TestEmitConnNotTeleport,TestResolveViaWebClient > /workspace/stdout.log 2> /workspace/stderr.log
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
