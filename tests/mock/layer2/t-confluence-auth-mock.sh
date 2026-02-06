#!/usr/bin/env bash
# Layer 2 Test: Confluence Authentication against Mock Server
# Requires: Mock server running on MOCK_API_HOST:MOCK_API_PORT
set -euo pipefail

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

test_confluence_auth_without_token() {
    echo "[i] Testing Confluence auth without token (expect 401)..."

    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" \
        "${MOCK_BASE_URL}/wiki/rest/api/user/current" 2>/dev/null || true)

    if [[ "$status" == "401" ]]; then
        pass "Confluence auth without token returns 401"
    else
        fail "Confluence auth without token expected 401, got $status"
    fi
}

test_confluence_auth_with_token() {
    echo "[i] Testing Confluence auth with Bearer token..."

    local response status
    status=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer mock-token-12345" \
        "${MOCK_BASE_URL}/wiki/rest/api/user/current" 2>/dev/null || true)

    if [[ "$status" == "200" ]]; then
        pass "Confluence auth with Bearer token returns 200"
    else
        fail "Confluence auth with Bearer token expected 200, got $status"
    fi

    # Verify response content
    response=$(curl -s \
        -H "Authorization: Bearer mock-token-12345" \
        "${MOCK_BASE_URL}/wiki/rest/api/user/current" 2>/dev/null || true)

    if echo "$response" | grep -q '"accountId"'; then
        pass "Confluence current user returns accountId"
    else
        fail "Confluence current user missing accountId"
    fi

    if echo "$response" | grep -q '"displayName"'; then
        pass "Confluence current user returns displayName"
    else
        fail "Confluence current user missing displayName"
    fi
}

test_confluence_spaces_list() {
    echo "[i] Testing Confluence spaces list..."

    local response
    response=$(curl -s \
        -H "Authorization: Bearer mock-token-12345" \
        "${MOCK_BASE_URL}/wiki/rest/api/space" 2>/dev/null || true)

    if echo "$response" | grep -q '"results"'; then
        pass "Confluence spaces list returns results array"
    else
        fail "Confluence spaces list missing results"
    fi

    if echo "$response" | grep -q '"key"'; then
        pass "Confluence spaces contain space keys"
    else
        fail "Confluence spaces missing space keys"
    fi
}

test_confluence_content_list() {
    echo "[i] Testing Confluence content list..."

    local response
    response=$(curl -s \
        -H "Authorization: Bearer mock-token-12345" \
        "${MOCK_BASE_URL}/wiki/rest/api/content" 2>/dev/null || true)

    if echo "$response" | grep -q '"results"'; then
        pass "Confluence content list returns results"
    else
        fail "Confluence content list missing results"
    fi
}

test_confluence_content_get() {
    echo "[i] Testing Confluence content get by ID..."

    local response status
    status=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer mock-token-12345" \
        "${MOCK_BASE_URL}/wiki/rest/api/content/12345" 2>/dev/null || true)

    if [[ "$status" == "200" ]]; then
        pass "Confluence content get returns 200"
    else
        fail "Confluence content get expected 200, got $status"
    fi

    response=$(curl -s \
        -H "Authorization: Bearer mock-token-12345" \
        "${MOCK_BASE_URL}/wiki/rest/api/content/12345" 2>/dev/null || true)

    if echo "$response" | grep -q '"title"'; then
        pass "Confluence content returns title"
    else
        fail "Confluence content missing title"
    fi
}

# ============================================================
# Main
# ============================================================

main() {
    echo "============================================"
    echo "  Layer 2: Confluence Authentication Mock"
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

    test_confluence_auth_without_token
    test_confluence_auth_with_token
    test_confluence_spaces_list
    test_confluence_content_list
    test_confluence_content_get

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
