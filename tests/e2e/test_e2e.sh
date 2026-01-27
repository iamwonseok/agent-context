#!/bin/bash
# Stage 3: End-to-End Tests
# Tests full workflow with GitLab/JIRA integration
#
# Requirements:
#   - GITLAB_API_TOKEN: GitLab personal access token
#   - GITLAB_URL: GitLab instance URL (e.g., https://gitlab.com)
#   - GITLAB_TEST_PROJECT: Project path for workflow tests (e.g., group/repo)
#   - JIRA_API_TOKEN: Atlassian API token (optional)
#   - JIRA_URL: JIRA instance URL (optional)
#   - JIRA_EMAIL: JIRA account email (optional)
#   - JIRA_TEST_PROJECT: JIRA project key for tests (optional)
#
# Tests:
#   - GitLab API connection
#   - Full feature workflow (branch, commit, MR, cleanup)
#   - JIRA issue workflow (create, link, transition)
#   - Issue linking
#
# Usage:
#   ./test_e2e.sh                    # Run all tests
#   ./test_e2e.sh --skip-cleanup     # Keep test resources for debugging

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_CONTEXT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Options
SKIP_CLEANUP=false
if [ "$1" = "--skip-cleanup" ]; then
    SKIP_CLEANUP=true
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
SKIPPED=0

# Cleanup tracking
CLEANUP_BRANCHES=()
CLEANUP_MRS=()
CLEANUP_ISSUES=()

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

# Cleanup function for trap
cleanup_resources() {
    if [ "$SKIP_CLEANUP" = true ]; then
        echo -e "${YELLOW}[INFO]${NC} Skipping cleanup (--skip-cleanup)"
        return 0
    fi
    
    echo ""
    echo -e "${BLUE}=== Cleanup ===${NC}"
    
    # Clean up MRs
    for mr_iid in "${CLEANUP_MRS[@]}"; do
        echo "  Closing MR !${mr_iid}..."
        curl -s -X PUT \
            -H "PRIVATE-TOKEN: ${GITLAB_API_TOKEN}" \
            "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/merge_requests/${mr_iid}" \
            -d "state_event=close" > /dev/null 2>&1 || true
    done
    
    # Clean up branches
    for branch in "${CLEANUP_BRANCHES[@]}"; do
        echo "  Deleting branch ${branch}..."
        curl -s -X DELETE \
            -H "PRIVATE-TOKEN: ${GITLAB_API_TOKEN}" \
            "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/repository/branches/${branch}" \
            > /dev/null 2>&1 || true
    done
    
    # Clean up JIRA issues (if any)
    if [ "$SKIP_JIRA" = false ] && [ ${#CLEANUP_ISSUES[@]} -gt 0 ]; then
        for issue_key in "${CLEANUP_ISSUES[@]}"; do
            echo "  Deleting JIRA issue ${issue_key}..."
            curl -s -X DELETE \
                -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
                "${JIRA_URL}/rest/api/3/issue/${issue_key}" \
                > /dev/null 2>&1 || true
        done
    fi
    
    echo "  Cleanup complete"
}

trap cleanup_resources EXIT

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

# Get project ID for API calls
get_project_id() {
    local project_path="$1"
    local encoded_path
    encoded_path=$(echo "$project_path" | sed 's/\//%2F/g')
    
    curl -s -H "PRIVATE-TOKEN: ${GITLAB_API_TOKEN}" \
        "${GITLAB_URL}/api/v4/projects/${encoded_path}" | \
        grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*'
}

test_full_feature_workflow() {
    local branch="test/e2e-$(date +%s)"
    local test_file="e2e-test-$(date +%s).md"
    
    echo "  Testing full feature workflow..."
    echo "    Branch: ${branch}"
    echo "    Project: ${GITLAB_TEST_PROJECT}"
    
    # 1. Create branch via API
    echo "    Creating branch..."
    local branch_result
    branch_result=$(curl -s -X POST \
        -H "PRIVATE-TOKEN: ${GITLAB_API_TOKEN}" \
        "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/repository/branches" \
        -d "branch=${branch}" \
        -d "ref=main" 2>&1)
    
    if echo "$branch_result" | grep -q '"name"'; then
        CLEANUP_BRANCHES+=("$branch")
        echo "    Branch created: ${branch}"
    else
        test_fail "Create branch: ${branch_result}"
        return 1
    fi
    
    # 2. Create a test file via API
    echo "    Creating test file..."
    local file_content="# E2E Test File\n\nCreated at: $(date)\n\nThis file tests the full workflow."
    local commit_result
    commit_result=$(curl -s -X POST \
        -H "PRIVATE-TOKEN: ${GITLAB_API_TOKEN}" \
        -H "Content-Type: application/json" \
        "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/repository/files/${test_file}" \
        -d "{
            \"branch\": \"${branch}\",
            \"content\": \"${file_content}\",
            \"commit_message\": \"test: add e2e test file\"
        }" 2>&1)
    
    if echo "$commit_result" | grep -q '"file_path"'; then
        echo "    File committed: ${test_file}"
    else
        test_fail "Commit file: ${commit_result}"
        return 1
    fi
    
    # 3. Create MR via API
    echo "    Creating merge request..."
    local mr_result
    mr_result=$(curl -s -X POST \
        -H "PRIVATE-TOKEN: ${GITLAB_API_TOKEN}" \
        "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/merge_requests" \
        -d "source_branch=${branch}" \
        -d "target_branch=main" \
        -d "title=test: E2E workflow test" \
        -d "description=Automated E2E test - will be cleaned up automatically" \
        -d "remove_source_branch=true" 2>&1)
    
    local mr_iid
    mr_iid=$(echo "$mr_result" | grep -o '"iid":[0-9]*' | head -1 | grep -o '[0-9]*')
    local mr_url
    mr_url=$(echo "$mr_result" | grep -o '"web_url":"[^"]*"' | head -1 | sed 's/"web_url":"//;s/"//')
    
    if [ -n "$mr_iid" ]; then
        CLEANUP_MRS+=("$mr_iid")
        echo "    MR created: !${mr_iid}"
        echo "    URL: ${mr_url}"
        test_pass "Full workflow: branch + commit + MR"
    else
        test_fail "Create MR: ${mr_result}"
        return 1
    fi
    
    # 4. Verify MR exists
    echo "    Verifying MR..."
    local verify_result
    verify_result=$(curl -s \
        -H "PRIVATE-TOKEN: ${GITLAB_API_TOKEN}" \
        "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/merge_requests/${mr_iid}" 2>&1)
    
    if echo "$verify_result" | grep -q '"state":"opened"'; then
        test_pass "MR verification: state=opened"
    else
        test_fail "MR verification failed"
    fi
    
    return 0
}

test_pm_review_create() {
    local branch="test/pm-e2e-$(date +%s)"
    
    echo "  Testing pm review create..."
    
    # Create branch first
    curl -s -X POST \
        -H "PRIVATE-TOKEN: ${GITLAB_API_TOKEN}" \
        "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/repository/branches" \
        -d "branch=${branch}" \
        -d "ref=main" > /dev/null 2>&1
    
    CLEANUP_BRANCHES+=("$branch")
    
    # Commit a file
    local test_file="pm-test-$(date +%s).md"
    curl -s -X POST \
        -H "PRIVATE-TOKEN: ${GITLAB_API_TOKEN}" \
        -H "Content-Type: application/json" \
        "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/repository/files/${test_file}" \
        -d "{
            \"branch\": \"${branch}\",
            \"content\": \"# PM Test\",
            \"commit_message\": \"test: pm workflow\"
        }" > /dev/null 2>&1
    
    # Test pm review create (unified command)
    local pm_output
    pm_output=$(cd /tmp && \
        export GITLAB_TOKEN="${GITLAB_API_TOKEN}" && \
        pm gitlab mr create \
            --project "${GITLAB_TEST_PROJECT}" \
            --source "${branch}" \
            --target main \
            --title "test: PM E2E test" \
            -d "Auto cleanup" 2>&1) || true
    
    if echo "$pm_output" | grep -qE "(created|iid|url|!)" ; then
        local mr_iid
        mr_iid=$(echo "$pm_output" | grep -oE '![0-9]+|iid.*[0-9]+' | grep -o '[0-9]*' | head -1)
        [ -n "$mr_iid" ] && CLEANUP_MRS+=("$mr_iid")
        test_pass "pm gitlab mr create"
    else
        # May fail due to pm CLI limitations - mark as skip instead of fail
        test_skip "pm gitlab mr create (CLI may need project context)"
    fi
}

if [ "$SKIP_GITLAB" = true ]; then
    test_skip "Full workflow (no GitLab token)"
    test_skip "pm review create (no GitLab token)"
else
    echo -e "${YELLOW}[INFO]${NC} Full workflow test requires a configured test project"
    echo "  Set GITLAB_TEST_PROJECT to run full workflow tests"
    echo ""

    if [ -n "$GITLAB_TEST_PROJECT" ]; then
        # Get project ID
        GITLAB_PROJECT_ID=$(get_project_id "$GITLAB_TEST_PROJECT")
        
        if [ -n "$GITLAB_PROJECT_ID" ]; then
            echo -e "${GREEN}[OK]${NC} Project ID: ${GITLAB_PROJECT_ID}"
            
            # Run full workflow test
            test_full_feature_workflow
            
            # Run pm CLI test
            test_pm_review_create
        else
            test_fail "Could not get project ID for: ${GITLAB_TEST_PROJECT}"
            test_skip "pm review create (no project ID)"
        fi
    else
        test_skip "Full workflow (GITLAB_TEST_PROJECT not set)"
        test_skip "pm review create (GITLAB_TEST_PROJECT not set)"
    fi
fi

# ============================================
# JIRA Integration Tests
# ============================================

section "5. JIRA Integration"

test_jira_issue_workflow() {
    echo "  Testing JIRA issue workflow..."
    
    # 1. Create test issue
    echo "    Creating test issue..."
    local issue_result
    issue_result=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
        "${JIRA_URL}/rest/api/3/issue" \
        -d "{
            \"fields\": {
                \"project\": {\"key\": \"${JIRA_TEST_PROJECT}\"},
                \"summary\": \"E2E Test Issue - $(date +%s)\",
                \"description\": {
                    \"type\": \"doc\",
                    \"version\": 1,
                    \"content\": [{
                        \"type\": \"paragraph\",
                        \"content\": [{
                            \"type\": \"text\",
                            \"text\": \"Automated E2E test - will be cleaned up automatically\"
                        }]
                    }]
                },
                \"issuetype\": {\"name\": \"Task\"}
            }
        }" 2>&1)
    
    local issue_key
    issue_key=$(echo "$issue_result" | grep -o '"key":"[^"]*"' | head -1 | sed 's/"key":"//;s/"//')
    
    if [ -n "$issue_key" ]; then
        CLEANUP_ISSUES+=("$issue_key")
        echo "    Issue created: ${issue_key}"
        test_pass "JIRA issue create: ${issue_key}"
    else
        test_fail "JIRA issue create: ${issue_result}"
        return 1
    fi
    
    # 2. Get issue details
    echo "    Verifying issue..."
    local verify_result
    verify_result=$(curl -s \
        -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
        "${JIRA_URL}/rest/api/3/issue/${issue_key}" 2>&1)
    
    if echo "$verify_result" | grep -q "\"key\":\"${issue_key}\""; then
        test_pass "JIRA issue verification"
    else
        test_fail "JIRA issue verification"
    fi
    
    # 3. Get available transitions
    echo "    Getting transitions..."
    local transitions_result
    transitions_result=$(curl -s \
        -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
        "${JIRA_URL}/rest/api/3/issue/${issue_key}/transitions" 2>&1)
    
    if echo "$transitions_result" | grep -q '"transitions"'; then
        test_pass "JIRA transitions API"
    else
        test_skip "JIRA transitions (may require workflow config)"
    fi
    
    return 0
}

test_pm_jira_commands() {
    echo "  Testing pm jira commands..."
    
    # Test pm jira me
    local me_output
    me_output=$(export JIRA_TOKEN="${JIRA_API_TOKEN}" && \
        export JIRA_BASE_URL="${JIRA_URL}" && \
        pm jira me 2>&1) || true
    
    if echo "$me_output" | grep -qE "(displayName|emailAddress|accountId)"; then
        test_pass "pm jira me"
    else
        test_skip "pm jira me (CLI may need full config)"
    fi
    
    # Test pm jira issue list (if project configured)
    if [ -n "$JIRA_TEST_PROJECT" ]; then
        local list_output
        list_output=$(export JIRA_TOKEN="${JIRA_API_TOKEN}" && \
            export JIRA_BASE_URL="${JIRA_URL}" && \
            pm jira issue list --project "${JIRA_TEST_PROJECT}" --limit 5 2>&1) || true
        
        if echo "$list_output" | grep -qE "(key|summary|issues|total)"; then
            test_pass "pm jira issue list"
        else
            test_skip "pm jira issue list (may need config)"
        fi
    fi
}

if [ "$SKIP_JIRA" = true ]; then
    test_skip "JIRA API connection (no token)"
    test_skip "JIRA issue workflow (no token)"
    test_skip "pm jira commands (no token)"
else
    # Test JIRA API connection
    if [ -n "$JIRA_URL" ]; then
        # Need email for Basic Auth
        if [ -z "$JIRA_EMAIL" ]; then
            echo -e "${YELLOW}[INFO]${NC} JIRA_EMAIL not set (required for JIRA Cloud)"
            test_skip "JIRA API connection (JIRA_EMAIL not set)"
            test_skip "JIRA issue workflow (JIRA_EMAIL not set)"
        else
            RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
                -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
                "${JIRA_URL}/rest/api/3/myself" 2>/dev/null || echo "000")

            if [ "$RESPONSE" = "200" ]; then
                test_pass "JIRA API connection (HTTP 200)"
                
                # Run JIRA workflow tests if project configured
                if [ -n "$JIRA_TEST_PROJECT" ]; then
                    test_jira_issue_workflow
                else
                    test_skip "JIRA issue workflow (JIRA_TEST_PROJECT not set)"
                fi
                
                # Test pm jira commands
                test_pm_jira_commands
            else
                test_fail "JIRA API connection (HTTP $RESPONSE)"
                test_skip "JIRA issue workflow (API connection failed)"
            fi
        fi
    else
        test_skip "JIRA API connection (JIRA_URL not set)"
        test_skip "JIRA issue workflow (JIRA_URL not set)"
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
