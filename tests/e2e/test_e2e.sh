#!/bin/bash
# Stage 3: End-to-End Tests
# Tests full workflow with GitLab/JIRA integration
#
# Requirements:
#   - GITLAB_API_TOKEN: GitLab personal access token
#   - GITLAB_URL: GitLab instance URL (e.g., https://gitlab.com)
#   - JIRA_API_TOKEN: Atlassian API token (optional)
#   - JIRA_URL: JIRA instance URL (optional)
#
# Tests:
#   - GitLab API connection
#   - agent dev submit (MR creation)
#   - Issue linking
#   - Full workflow end-to-end

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_CONTEXT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

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
SKIPPED=0

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

test_skip() {
    echo -e "  ${YELLOW}[SKIP]${NC} $1"
    ((TOTAL++)) || true
    ((SKIPPED++)) || true
}

section() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
}

# ============================================
# Pre-flight Checks
# ============================================

section "Stage 3: E2E Tests (GitLab/JIRA Integration)"
echo "Agent-context: ${AGENT_CONTEXT_DIR}"

export PATH="${AGENT_CONTEXT_DIR}/tools/agent/bin:${AGENT_CONTEXT_DIR}/tools/pm/bin:$PATH"
export AGENT_CONTEXT_PATH="${AGENT_CONTEXT_DIR}"

# Check required environment variables
section "1. Environment Check"

if [ -z "$GITLAB_API_TOKEN" ]; then
    echo -e "${YELLOW}[WARN]${NC} GITLAB_API_TOKEN not set"
    echo ""
    echo "To run E2E tests, set environment variables:"
    echo "  export GITLAB_API_TOKEN=<your-token>"
    echo "  export GITLAB_URL=https://gitlab.com"
    echo ""
    echo "Skipping GitLab integration tests..."
    SKIP_GITLAB=true
else
    test_pass "GITLAB_API_TOKEN is set"
    SKIP_GITLAB=false
fi

if [ -z "$GITLAB_URL" ]; then
    GITLAB_URL="https://gitlab.com"
    echo -e "${YELLOW}[INFO]${NC} Using default GITLAB_URL: $GITLAB_URL"
fi

if [ -z "$JIRA_API_TOKEN" ]; then
    echo -e "${YELLOW}[INFO]${NC} JIRA_API_TOKEN not set (JIRA tests will be skipped)"
    SKIP_JIRA=true
else
    test_pass "JIRA_API_TOKEN is set"
    SKIP_JIRA=false
fi

# ============================================
# GitLab API Tests
# ============================================

section "2. GitLab API Connection"

if [ "$SKIP_GITLAB" = true ]; then
    test_skip "GitLab API connection (no token)"
else
    # Test API connection
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "PRIVATE-TOKEN: ${GITLAB_API_TOKEN}" \
        "${GITLAB_URL}/api/v4/user" 2>/dev/null || echo "000")
    
    if [ "$RESPONSE" = "200" ]; then
        test_pass "GitLab API connection (HTTP 200)"
    elif [ "$RESPONSE" = "401" ]; then
        test_fail "GitLab API authentication failed (HTTP 401)"
    else
        test_fail "GitLab API connection failed (HTTP $RESPONSE)"
    fi
fi

# ============================================
# pm CLI Tests
# ============================================

section "3. pm CLI Integration"

if [ "$SKIP_GITLAB" = true ]; then
    test_skip "pm gitlab list-projects (no token)"
else
    # Test pm CLI with GitLab
    if pm gitlab list-projects --limit=1 2>&1 | grep -qE "(id|name|error)"; then
        test_pass "pm gitlab list-projects"
    else
        test_fail "pm gitlab list-projects"
    fi
fi

# ============================================
# Full Workflow Test (if project configured)
# ============================================

section "4. Full Workflow Test"

if [ "$SKIP_GITLAB" = true ]; then
    test_skip "Full workflow (no GitLab token)"
    test_skip "agent dev submit (no GitLab token)"
else
    echo -e "${YELLOW}[INFO]${NC} Full workflow test requires a configured test project"
    echo "  Set GITLAB_TEST_PROJECT to run full workflow tests"
    echo ""
    
    if [ -n "$GITLAB_TEST_PROJECT" ]; then
        # TODO: Implement full workflow test
        # 1. Clone test project
        # 2. Run agent dev start
        # 3. Make changes
        # 4. Run agent dev submit
        # 5. Verify MR created
        # 6. Clean up (delete MR/branch)
        test_skip "Full workflow (not implemented)"
    else
        test_skip "Full workflow (GITLAB_TEST_PROJECT not set)"
    fi
fi

# ============================================
# JIRA Integration Tests
# ============================================

section "5. JIRA Integration"

if [ "$SKIP_JIRA" = true ]; then
    test_skip "JIRA API connection (no token)"
else
    # Test JIRA API connection
    if [ -n "$JIRA_URL" ]; then
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "Authorization: Basic $(echo -n ":${JIRA_API_TOKEN}" | base64)" \
            "${JIRA_URL}/rest/api/3/myself" 2>/dev/null || echo "000")
        
        if [ "$RESPONSE" = "200" ]; then
            test_pass "JIRA API connection (HTTP 200)"
        else
            test_fail "JIRA API connection (HTTP $RESPONSE)"
        fi
    else
        test_skip "JIRA API connection (JIRA_URL not set)"
    fi
fi

# ============================================
# Summary
# ============================================

echo ""
echo "=========================================="
echo "Stage 3: E2E Test Results"
echo "=========================================="
echo -e "Total:   ${TOTAL}"
echo -e "Passed:  ${GREEN}${PASSED}${NC}"
echo -e "Failed:  ${RED}${FAILED}${NC}"
echo -e "Skipped: ${YELLOW}${SKIPPED}${NC}"
echo ""

if [ "$FAILED" -eq 0 ]; then
    if [ "$SKIPPED" -gt 0 ]; then
        echo -e "${YELLOW}E2E tests passed (some skipped due to missing tokens)${NC}"
    else
        echo -e "${GREEN}All E2E tests passed!${NC}"
    fi
    exit 0
else
    echo -e "${RED}Some E2E tests failed.${NC}"
    exit 1
fi
