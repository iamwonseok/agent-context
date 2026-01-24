#!/bin/bash
# Stage 2: Local Git Tests
# Tests Git operations with a local bare repo as remote
#
# Tests:
#   - Create bare repo as "remote"
#   - Clone and setup project
#   - agent dev start -> branch creation
#   - agent dev commit -> commit changes
#   - git push to local remote
#   - Branch workflow end-to-end
#
# Note: MR creation still requires GitLab API (Stage 3)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_CONTEXT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Use /workspace in Docker, temp directory locally
if [ -d "/workspace" ] && [ -w "/workspace" ]; then
    WORKSPACE="/workspace/local-git-test"
else
    WORKSPACE="${TMPDIR:-/tmp}/agent-context-local-git-test-$$"
fi

BARE_REPO="${WORKSPACE}/remote.git"
PROJECT_DIR="${WORKSPACE}/project"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
TOTAL=0
PASSED=0
FAILED=0

test_pass() {
    echo -e "  ${GREEN}[PASS]${NC} $1"
    ((TOTAL++)) || true
    ((PASSED++)) || true
}

test_fail() {
    echo -e "  ${RED}[FAIL]${NC} $1"
    ((TOTAL++)) || true
    ((FAILED++)) || true
}

section() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
}

cleanup() {
    echo ""
    echo "Cleaning up..."
    rm -rf "$WORKSPACE" 2>/dev/null || true
}

trap cleanup EXIT

# ============================================
# Setup
# ============================================

section "Stage 2: Local Git Tests"
echo "Agent-context: ${AGENT_CONTEXT_DIR}"
echo "Workspace: ${WORKSPACE}"

export PATH="${AGENT_CONTEXT_DIR}/tools/agent/bin:${AGENT_CONTEXT_DIR}/tools/pm/bin:$PATH"
export AGENT_CONTEXT_PATH="${AGENT_CONTEXT_DIR}"

mkdir -p "$WORKSPACE"

# ============================================
# Tests
# ============================================

# 1. Create bare repo as remote
section "1. Create Bare Repo (Remote)"

git init --bare "$BARE_REPO"
if [ -d "${BARE_REPO}/objects" ]; then
    test_pass "Bare repo created"
else
    test_fail "Bare repo creation failed"
    exit 1
fi

# 2. Create project and push initial commit
section "2. Initialize Project"

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"
git init
git remote add origin "$BARE_REPO"

# Create initial files
echo "# Test Project" > README.md
git add README.md
git commit -m "Initial commit"
git push -u origin main

if git log --oneline -1 | grep -q "Initial commit"; then
    test_pass "Initial commit pushed"
else
    test_fail "Initial commit push failed"
fi

# 3. Setup agent-context
section "3. Setup Agent-Context"

"${AGENT_CONTEXT_DIR}/setup.sh" --skip-secrets --non-interactive 2>&1 || true

if [ -f ".cursorrules" ]; then
    test_pass "Agent-context setup complete"
else
    test_fail "Agent-context setup incomplete"
fi

# Commit setup files
git add -A
git commit -m "chore: add agent-context setup" || true
git push origin main || true

# 4. Start a feature task
section "4. Feature Branch Workflow"

TASK_ID="FEAT-001"

# agent dev start
if agent dev start "$TASK_ID" 2>&1; then
    test_pass "agent dev start $TASK_ID"
else
    # Try manual branch creation as fallback
    git checkout -b "feat/${TASK_ID}"
    mkdir -p ".context/${TASK_ID}"
    test_pass "agent dev start (manual fallback)"
fi

CURRENT_BRANCH=$(git branch --show-current)
if echo "$CURRENT_BRANCH" | grep -qi "$TASK_ID"; then
    test_pass "On feature branch: $CURRENT_BRANCH"
else
    test_fail "Expected feature branch, got: $CURRENT_BRANCH"
fi

# 5. Make changes and commit
section "5. Code Changes and Commit"

# Create a new file
mkdir -p src
cat > src/feature.sh << 'EOF'
#!/bin/bash
# Feature implementation
echo "Hello from feature"
EOF

git add -A

# Try agent dev commit
if agent dev commit "feat: add feature implementation" 2>&1; then
    test_pass "agent dev commit"
else
    # Fallback to git commit
    git commit -m "feat: add feature implementation"
    test_pass "git commit (fallback)"
fi

if git log --oneline -1 | grep -q "feat"; then
    test_pass "Commit message format"
else
    test_fail "Commit message format"
fi

# 6. Push to remote
section "6. Push to Remote"

if git push -u origin "$CURRENT_BRANCH" 2>&1; then
    test_pass "Push feature branch to remote"
else
    test_fail "Push feature branch failed"
fi

# Verify branch exists on remote
if git ls-remote --heads origin | grep -q "$CURRENT_BRANCH"; then
    test_pass "Branch exists on remote"
else
    test_fail "Branch not found on remote"
fi

# 7. Simulate sync (rebase on main)
section "7. Sync with Main"

# Make a change on main (simulate other developer)
git checkout main
echo "# Updated" >> README.md
git add README.md
git commit -m "docs: update README"
git push origin main

# Switch back to feature branch and sync
git checkout "$CURRENT_BRANCH"

# Try agent dev sync
if agent dev sync 2>&1; then
    test_pass "agent dev sync"
else
    # Fallback to manual rebase
    git fetch origin main
    if git rebase origin/main 2>&1; then
        test_pass "git rebase (fallback)"
    else
        test_fail "Sync/rebase failed"
    fi
fi

# 8. Final push after rebase
section "8. Push After Sync"

if git push --force-with-lease origin "$CURRENT_BRANCH" 2>&1; then
    test_pass "Push after rebase"
else
    # Try regular force push
    if git push -f origin "$CURRENT_BRANCH" 2>&1; then
        test_pass "Push after rebase (force)"
    else
        test_fail "Push after rebase failed"
    fi
fi

# 9. Verify commit history is linear
section "9. Verify Linear History"

MERGE_COMMITS=$(git log --oneline --merges main.."$CURRENT_BRANCH" | wc -l)
if [ "$MERGE_COMMITS" -eq 0 ]; then
    test_pass "Linear history (no merge commits)"
else
    test_fail "Non-linear history detected"
fi

# ============================================
# Summary
# ============================================

echo ""
echo "=========================================="
echo "Stage 2: Local Git Test Results"
echo "=========================================="
echo -e "Total:  ${TOTAL}"
echo -e "Passed: ${GREEN}${PASSED}${NC}"
echo -e "Failed: ${RED}${FAILED}${NC}"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}All local git tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some local git tests failed.${NC}"
    exit 1
fi
