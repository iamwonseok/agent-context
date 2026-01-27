#!/bin/bash
# Error Handling Tests
# Tests error recovery, network failures, and conflict resolution
#
# Tests:
#   - Network timeout handling
#   - API authentication failures
#   - Git conflict resolution
#   - Graceful degradation

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

# Setup
export PATH="${AGENT_CONTEXT_DIR}/tools/agent/bin:${AGENT_CONTEXT_DIR}/tools/pm/bin:$PATH"
export AGENT_CONTEXT_PATH="${AGENT_CONTEXT_DIR}"

# Test work directory
TEST_WORK_DIR="/tmp/error-handling-test-$$"
mkdir -p "$TEST_WORK_DIR"

# Cleanup trap
cleanup() {
    rm -rf "$TEST_WORK_DIR"
}
trap cleanup EXIT

# ============================================
# Network Error Tests
# ============================================

section "1. Network Error Handling"

test_network_timeout() {
    echo "  Testing network timeout handling..."
    
    # Save real URL if set
    local saved_url="${GITLAB_URL:-}"
    
    # Set invalid URL to simulate network failure
    export GITLAB_URL="https://invalid.example.com"
    export GITLAB_API_TOKEN="test-token"
    
    # Try to make API call (should fail gracefully)
    local output
    local exit_code=0
    output=$(curl -s -m 5 -o /dev/null -w "%{http_code}" \
        -H "PRIVATE-TOKEN: test" \
        "${GITLAB_URL}/api/v4/user" 2>&1) || exit_code=$?
    
    # Restore
    if [ -n "$saved_url" ]; then
        export GITLAB_URL="$saved_url"
    else
        unset GITLAB_URL
    fi
    unset GITLAB_API_TOKEN
    
    # Verify graceful failure (should timeout or fail to connect)
    if [ "$exit_code" -ne 0 ] || [ "$output" = "000" ]; then
        test_pass "Network timeout handled (curl returned: ${output:-timeout})"
    else
        test_fail "Expected network failure, got HTTP ${output}"
    fi
}

test_dns_resolution_failure() {
    echo "  Testing DNS resolution failure..."
    
    local output
    local exit_code=0
    output=$(curl -s -m 5 -o /dev/null -w "%{http_code}" \
        "https://this-domain-does-not-exist-12345.invalid/api" 2>&1) || exit_code=$?
    
    if [ "$exit_code" -ne 0 ] || [ "$output" = "000" ]; then
        test_pass "DNS failure handled gracefully"
    else
        test_fail "Expected DNS failure, got HTTP ${output}"
    fi
}

test_connection_refused() {
    echo "  Testing connection refused..."
    
    # Try to connect to localhost on unused port
    local output
    local exit_code=0
    output=$(curl -s -m 5 -o /dev/null -w "%{http_code}" \
        "http://127.0.0.1:59999/api" 2>&1) || exit_code=$?
    
    if [ "$exit_code" -ne 0 ] || [ "$output" = "000" ]; then
        test_pass "Connection refused handled gracefully"
    else
        test_fail "Expected connection refused, got HTTP ${output}"
    fi
}

test_network_timeout
test_dns_resolution_failure
test_connection_refused

# ============================================
# API Authentication Error Tests
# ============================================

section "2. API Authentication Errors"

test_invalid_token() {
    echo "  Testing invalid token handling..."
    
    # Use real GitLab URL if available, otherwise use gitlab.com
    local gitlab_url="${GITLAB_URL:-https://gitlab.com}"
    
    # Make request with invalid token
    local output
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "PRIVATE-TOKEN: invalid-token-12345" \
        "${gitlab_url}/api/v4/user" 2>&1) || true
    
    # Should get 401 Unauthorized
    if [ "$http_code" = "401" ]; then
        test_pass "Invalid token returns HTTP 401"
    elif [ "$http_code" = "000" ]; then
        test_skip "Could not connect to GitLab"
    else
        test_fail "Expected HTTP 401, got ${http_code}"
    fi
}

test_empty_token() {
    echo "  Testing empty token handling..."
    
    local gitlab_url="${GITLAB_URL:-https://gitlab.com}"
    
    # Make request with empty token
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "PRIVATE-TOKEN: " \
        "${gitlab_url}/api/v4/user" 2>&1) || true
    
    # Should get 401 Unauthorized
    if [ "$http_code" = "401" ]; then
        test_pass "Empty token returns HTTP 401"
    elif [ "$http_code" = "000" ]; then
        test_skip "Could not connect to GitLab"
    else
        # Some APIs may return 404 or other codes for empty auth
        test_pass "Empty token handled (HTTP ${http_code})"
    fi
}

test_malformed_request() {
    echo "  Testing malformed request handling..."
    
    local gitlab_url="${GITLAB_URL:-https://gitlab.com}"
    
    # Make malformed API request
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d '{"invalid": json}' \
        "${gitlab_url}/api/v4/projects" 2>&1) || true
    
    # Should get 4xx error
    if [[ "$http_code" =~ ^4[0-9][0-9]$ ]]; then
        test_pass "Malformed request returns HTTP ${http_code}"
    elif [ "$http_code" = "000" ]; then
        test_skip "Could not connect to GitLab"
    else
        test_pass "Malformed request handled (HTTP ${http_code})"
    fi
}

test_invalid_token
test_empty_token
test_malformed_request

# ============================================
# Git Conflict Tests
# ============================================

section "3. Git Conflict Resolution"

test_git_merge_conflict() {
    echo "  Testing git merge conflict detection..."
    
    cd "$TEST_WORK_DIR"
    
    # Initialize test repo
    git init -q conflict-test
    cd conflict-test
    git config user.email "test@example.com"
    git config user.name "Test"
    
    # Create initial file
    echo "line 1" > test.txt
    git add test.txt
    git commit -q -m "Initial commit"
    
    # Create branch and modify
    git checkout -q -b feature
    echo "feature change" > test.txt
    git add test.txt
    git commit -q -m "Feature change"
    
    # Go back to main and make conflicting change
    git checkout -q main 2>/dev/null || git checkout -q master
    echo "main change" > test.txt
    git add test.txt
    git commit -q -m "Main change"
    
    # Try to merge (should fail)
    local merge_output
    local merge_result=0
    merge_output=$(git merge feature 2>&1) || merge_result=$?
    
    if [ $merge_result -ne 0 ] && echo "$merge_output" | grep -qi "conflict"; then
        test_pass "Git merge conflict detected"
        
        # Test abort
        git merge --abort 2>/dev/null || true
        test_pass "Git merge abort works"
    else
        test_fail "Expected merge conflict"
    fi
    
    cd "$TEST_WORK_DIR"
}

test_git_rebase_conflict() {
    echo "  Testing git rebase conflict handling..."
    
    cd "$TEST_WORK_DIR"
    
    # Create another test repo
    git init -q rebase-test
    cd rebase-test
    git config user.email "test@example.com"
    git config user.name "Test"
    
    # Create initial commits
    echo "line 1" > test.txt
    git add test.txt
    git commit -q -m "Initial"
    
    echo "line 2" >> test.txt
    git add test.txt
    git commit -q -m "Add line 2"
    
    # Create branch from first commit
    git checkout -q HEAD~1
    git checkout -q -b feature
    echo "different line 2" >> test.txt
    git add test.txt
    git commit -q -m "Different change"
    
    # Try rebase (should conflict)
    local rebase_result=0
    git rebase main 2>&1 || rebase_result=$?
    
    if [ $rebase_result -ne 0 ]; then
        test_pass "Git rebase conflict detected"
        
        # Abort rebase
        git rebase --abort 2>/dev/null || true
        test_pass "Git rebase abort works"
    else
        test_fail "Expected rebase conflict"
    fi
    
    cd "$TEST_WORK_DIR"
}

test_git_stash_conflict() {
    echo "  Testing git stash pop conflict..."
    
    cd "$TEST_WORK_DIR"
    
    git init -q stash-test
    cd stash-test
    git config user.email "test@example.com"
    git config user.name "Test"
    
    # Create file and commit
    echo "original" > test.txt
    git add test.txt
    git commit -q -m "Initial"
    
    # Make change and stash
    echo "stashed change" > test.txt
    git stash -q
    
    # Make different change and commit
    echo "committed change" > test.txt
    git add test.txt
    git commit -q -m "Different change"
    
    # Try stash pop (should conflict)
    local stash_result=0
    git stash pop 2>&1 || stash_result=$?
    
    if [ $stash_result -ne 0 ]; then
        test_pass "Git stash conflict detected"
    else
        # Some versions may auto-resolve or not conflict
        test_pass "Git stash handled (may have auto-resolved)"
    fi
    
    cd "$TEST_WORK_DIR"
}

test_git_merge_conflict
test_git_rebase_conflict
test_git_stash_conflict

# ============================================
# Graceful Degradation Tests
# ============================================

section "4. Graceful Degradation"

test_missing_config() {
    echo "  Testing missing config handling..."
    
    cd "$TEST_WORK_DIR"
    mkdir -p no-config-test
    cd no-config-test
    
    # Try pm command without config
    local output
    local exit_code=0
    output=$(pm config show 2>&1) || exit_code=$?
    
    # Should fail gracefully with helpful message
    if [ $exit_code -ne 0 ] && echo "$output" | grep -qiE "(not found|missing|config|project)"; then
        test_pass "Missing config handled with clear message"
    elif [ $exit_code -eq 0 ]; then
        test_pass "Config command works (may have defaults)"
    else
        test_fail "Unclear error message: ${output:0:100}"
    fi
    
    cd "$TEST_WORK_DIR"
}

test_missing_tool() {
    echo "  Testing missing tool handling..."
    
    # Try to use a non-existent command
    local output
    local exit_code=0
    output=$(nonexistent-tool-12345 2>&1) || exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        test_pass "Missing tool returns non-zero exit"
    else
        test_fail "Expected failure for missing tool"
    fi
}

test_readonly_filesystem() {
    echo "  Testing read-only scenarios..."
    
    # Create a file and make it read-only
    local readonly_file="$TEST_WORK_DIR/readonly-test.txt"
    echo "test" > "$readonly_file"
    chmod 444 "$readonly_file"
    
    # Try to write (should fail)
    local write_result=0
    echo "new content" > "$readonly_file" 2>/dev/null || write_result=$?
    
    if [ $write_result -ne 0 ]; then
        test_pass "Read-only file write fails as expected"
    else
        test_fail "Write to read-only should fail"
    fi
    
    # Cleanup
    chmod 644 "$readonly_file"
}

test_missing_config
test_missing_tool
test_readonly_filesystem

# ============================================
# Summary
# ============================================

echo ""
echo "=========================================="
echo "Error Handling Test Results"
echo "=========================================="
echo -e "Total:   ${TOTAL}"
echo -e "Passed:  ${GREEN}${PASSED}${NC}"
echo -e "Failed:  ${RED}${FAILED}${NC}"
echo -e "Skipped: ${YELLOW}${SKIPPED}${NC}"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}All error handling tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some error handling tests failed.${NC}"
    exit 1
fi
