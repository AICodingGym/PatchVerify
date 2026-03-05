#!/bin/bash
set -e

echo "============================================="
echo "   SWE-bench Pro Solution Submission"
echo "   Instance: instance_internetarchive__openlibrary-c4eebe6677acc4629cb541a98d5e91311444f5d4-v13642507b4fc1f8d234172bf8129942da2c2ca26"
echo "============================================="

if git diff-index --quiet HEAD --; then
    echo "No changes detected. All changes are already committed."
else
    echo "Adding all changes..."
    git add -A
    echo "Enter commit message (or press Enter for default):"
    read -r COMMIT_MSG
    if [ -z "$COMMIT_MSG" ]; then
        COMMIT_MSG="Solution attempt for instance_internetarchive__openlibrary-c4eebe6677acc4629cb541a98d5e91311444f5d4-v13642507b4fc1f8d234172bf8129942da2c2ca26"
    fi
    echo "Committing changes..."
    git commit -m "$COMMIT_MSG"
fi

echo "Pushing to remote (branch: openlibrary-c4eebe6677acc4629cb541a98d5e91311444f5d4-v13642507b4fc1f8d234172bf8129942da2c2ca26)..."
git push origin openlibrary-c4eebe6677acc4629cb541a98d5e91311444f5d4-v13642507b4fc1f8d234172bf8129942da2c2ca26

COMMIT_HASH=$(git rev-parse HEAD)
REPO_URL=$(git remote get-url origin 2>/dev/null || echo "unknown")
echo ""
echo "Code pushed! Check test results:"
echo "  $REPO_URL/actions"
echo "  Branch: openlibrary-c4eebe6677acc4629cb541a98d5e91311444f5d4-v13642507b4fc1f8d234172bf8129942da2c2ca26"
echo "  Commit: $COMMIT_HASH"
echo ""
echo "Run ./submit.sh again after making more changes."
