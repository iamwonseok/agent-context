#!/usr/bin/env bash
# Layer 2 Test: Jira Authentication against Mock Server
# Requires: Mock server running on MOCK_API_HOST:MOCK_API_PORT
set -euo pipefail

# Source test helpers if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${AGENT_CONTEXT_DIR:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"

# Test counters
TOTAL=0
PASSED=0
FAILED=0

# Mock server configuration
MOCK_HOST="${MOCK_API_HOST:-localhost}"
MOCK_PORT="${MOCK_API_PORT:-8899}"
MOCK_BASE_URL="http://${MOCK_HOST}:${MOCK_PORT}"

# Test utilities
pass() {
    ((TOTAL++))
    ((PASSED++))
    echo "[V] $1"
}

fail() {
    ((TOTAL++))
    ((FAILED++))
    echo "[X] $1"
}

skip() {
    echo "[-] $1"
}

# Check mock server is running
check_mock_server() {
    local response
    if response=$(curl -s -o /dev/null -w "%{http_code}" "${MOCK_BASE_URL}/health" 2>/dev/null); then
        if [[ "$response" == "200" ]]; then
            return 0
        fi
    fi
    return 1
}

# ============================================================
# Test Cases
# ============================================================

test_mock_server_health() {
    echo "[i] Testing mock server health check..."

    local response
    response=$(curl -s "${MOCK_BASE_URL}/health" 2>/dev/null || true)

    if echo "$response" | grep -q '"status".*"ok"'; then
        pass "Mock server health check passed"
    else
        fail "Mock server health check failed"
    fi
}

test_jira_auth_without_token() {
    echo "[i] Testing Jira auth without token (expect 401)..."

    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" "${MOCK_BASE_URL}/rest/api/2/myself" 2>/dev/null || true)

    if [[ "$status" == "401" ]]; then
        pass "Jira auth without token returns 401"
    else
        fail "Jira auth without token expected 401, got $status"
    fi
}

test_jira_auth_with_token() {
    echo "[i] Testing Jira auth with Bearer token..."

    local response status
    status=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer mock-token-12345" \
        "${MOCK_BASE_URL}/rest/api/2/myself" 2>/dev/null || true)

    if [[ "$status" == "200" ]]; then
        pass "Jira auth with Bearer token returns 200"
    else
        fail "Jira auth with Bearer token expected 200, got $status"
    fi

    # Verify response content
    response=$(curl -s \
        -H "Authorization: Bearer mock-token-12345" \
        "${MOCK_BASE_URL}/rest/api/2/myself" 2>/dev/null || true)

    if echo "$response" | grep -q '"accountId"'; then
        pass "Jira myself endpoint returns accountId"
    else
        fail "Jira myself endpoint missing accountId"
    fi

    if echo "$response" | grep -q '"displayName"'; then
        pass "Jira myself endpoint returns displayName"
    else
        fail "Jira myself endpoint missing displayName"
    fi
}

test_jira_server_info() {
    echo "[i] Testing Jira server info endpoint..."

    local response
    response=$(curl -s \
        -H "Authorization: Bearer mock-token-12345" \
        "${MOCK_BASE_URL}/rest/api/2/serverInfo" 2>/dev/null || true)

    if echo "$response" | grep -q '"baseUrl"'; then
        pass "Jira serverInfo returns baseUrl"
    else
        fail "Jira serverInfo missing baseUrl"
    fi

    if echo "$response" | grep -q '"version"'; then
        pass "Jira serverInfo returns version"
    else
        fail "Jira serverInfo missing version"
    fi
}

test_jira_projects_list() {
    echo "[i] Testing Jira projects list..."

    local response
    response=$(curl -s \
        -H "Authorization: Bearer mock-token-12345" \
        "${MOCK_BASE_URL}/rest/api/2/project" 2>/dev/null || true)

    if echo "$response" | grep -q '"key"'; then
        pass "Jira projects list returns project keys"
    else
        fail "Jira projects list missing project keys"
    fi
}

# ============================================================
# Main
# ============================================================

main() {
    echo "============================================"
    echo "  Layer 2: Jira Authentication Mock Tests"
    echo "============================================"
    echo ""
    echo "Mock Server: ${MOCK_BASE_URL}"
    echo ""

    # Check if mock server is running
    if ! check_mock_server; then
        echo "[!] Mock server not running at ${MOCK_BASE_URL}"
        echo "[!] Start with: python tests/mock/server/mock_server.py"
        echo ""
        echo "__TEST_RESULT__=0:0:0:0"
        exit 0
    fi

    test_mock_server_health
    test_jira_auth_without_token
    test_jira_auth_with_token
    test_jira_server_info
    test_jira_projects_list

    echo ""
    echo "============================================"
    if [[ ${FAILED} -eq 0 ]]; then
        echo "[V] All tests passed"
    else
        echo "[X] Some tests failed"
    fi
    echo "Summary: total=${TOTAL} passed=${PASSED} failed=${FAILED}"
    echo "__TEST_RESULT__=${TOTAL}:${PASSED}:${FAILED}:0"

    [[ ${FAILED} -eq 0 ]] || exit 1
}

main "$@"
