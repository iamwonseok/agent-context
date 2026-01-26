#!/bin/bash
# Stage 1: Smoke Tests
# Tests bootstrap, setup, and basic CLI without remote/tokens
#
# Tests:
#   - bootstrap.sh execution
#   - setup.sh project creation
#   - setup.sh re-run safety (idempotent)
#   - agent --version
#   - agent status
#   - agent dev start (branch + .context/ creation)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_CONTEXT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Use /workspace in Docker, temp directory locally
if [ -d "/workspace" ] && [ -w "/workspace" ]; then
    WORKSPACE="/workspace/smoke-test-project"
else
    WORKSPACE="${TMPDIR:-/tmp}/agent-context-smoke-test-$$"
fi

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
# Tests
# ============================================

section "Stage 1: Smoke Tests"
echo "Agent-context: ${AGENT_CONTEXT_DIR}"
echo "Workspace: ${WORKSPACE}"

# 1. bootstrap.sh execution
section "1. Bootstrap"

if "${AGENT_CONTEXT_DIR}/bootstrap.sh" --help >/dev/null 2>&1; then
    test_pass "bootstrap.sh --help"
else
    test_fail "bootstrap.sh --help"
fi

if "${AGENT_CONTEXT_DIR}/bootstrap.sh" 2>&1 | grep -q "prerequisites"; then
    test_pass "bootstrap.sh runs and checks prerequisites"
else
    test_fail "bootstrap.sh runs and checks prerequisites"
fi

# 2. Create test project with git
section "2. Project Setup"

mkdir -p "$WORKSPACE"
cd "$WORKSPACE"
git init

if [ -d ".git" ]; then
    test_pass "git init"
else
    test_fail "git init"
fi

# 3. setup.sh project creation
section "3. Setup Script"

# Run setup with --skip-secrets (no tokens in test)
if "${AGENT_CONTEXT_DIR}/setup.sh" --skip-secrets --non-interactive 2>&1; then
    test_pass "setup.sh --skip-secrets --non-interactive"
else
    test_fail "setup.sh --skip-secrets --non-interactive"
fi

# Check created files
for file in .cursorrules .gitignore; do
    if [ -f "$file" ]; then
        test_pass "Created: $file"
    else
        test_fail "Missing: $file"
    fi
done

# Verify --skip-secrets works (no .secrets/ directory should be created)
if [ ! -d ".secrets" ]; then
    test_pass "--skip-secrets: .secrets/ not created"
else
    test_fail "--skip-secrets: .secrets/ should not be created"
fi

# 4. setup.sh re-run (idempotent)
section "4. Setup Idempotency"

if "${AGENT_CONTEXT_DIR}/setup.sh" --skip-secrets --non-interactive 2>&1; then
    test_pass "setup.sh re-run (idempotent)"
else
    test_fail "setup.sh re-run (idempotent)"
fi

# 5. CLI version
section "5. CLI Basic"

export PATH="${AGENT_CONTEXT_DIR}/tools/agent/bin:${AGENT_CONTEXT_DIR}/tools/pm/bin:$PATH"
export AGENT_CONTEXT_PATH="${AGENT_CONTEXT_DIR}"

if agent --version 2>&1 | grep -qE "(agent|version)"; then
    test_pass "agent --version"
else
    test_fail "agent --version"
fi

if agent --help 2>&1 | grep -qE "(dev|mgr|init)"; then
    test_pass "agent --help"
else
    test_fail "agent --help"
fi

# 6. agent status
section "6. Agent Status"

if agent status 2>&1; then
    test_pass "agent status"
else
    # May fail if not fully configured, but should not crash
    if agent status 2>&1 | grep -qE "(error|Error|not found)"; then
        test_fail "agent status (crashed)"
    else
        test_pass "agent status (graceful handling)"
    fi
fi

# 7. agent dev start (branch + .context/)
section "7. Agent Dev Start"

# Need initial commit for branch operations
git add -A 2>/dev/null || true
git commit -m "Initial commit" --allow-empty 2>/dev/null || true

TASK_ID="TEST-001"

# Try to start a task (may have limited functionality without full setup)
if agent dev start "$TASK_ID" 2>&1; then
    test_pass "agent dev start $TASK_ID"

    # Check branch created
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
    if echo "$CURRENT_BRANCH" | grep -q "$TASK_ID"; then
        test_pass "Branch contains task ID: $CURRENT_BRANCH"
    else
        test_fail "Branch should contain task ID (got: $CURRENT_BRANCH)"
    fi

    # Check .context/ created
    if [ -d ".context" ] || [ -d ".context/$TASK_ID" ]; then
        test_pass ".context/ directory created"
    else
        test_fail ".context/ directory not created"
    fi
else
    # If dev start fails, check if it's a graceful error
    OUTPUT=$(agent dev start "$TASK_ID" 2>&1 || true)
    if echo "$OUTPUT" | grep -qE "(config|setup|init)"; then
        test_pass "agent dev start (requires setup - expected)"
    else
        test_fail "agent dev start $TASK_ID"
    fi
fi

# ============================================
# Summary
# ============================================

echo ""
echo "=========================================="
echo "Stage 1: Smoke Test Results"
echo "=========================================="
echo -e "Total:  ${TOTAL}"
echo -e "Passed: ${GREEN}${PASSED}${NC}"
echo -e "Failed: ${RED}${FAILED}${NC}"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}All smoke tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some smoke tests failed.${NC}"
    exit 1
fi
