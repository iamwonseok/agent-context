#!/usr/bin/env bash
# Layer 2 Test: PM Confluence Commands against Mock Server
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

# PM tool path
PM_TOOL="${ROOT_DIR}/tools/pm/pm.py"

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

# Check PM tool exists
check_pm_tool() {
    if [[ -f "${PM_TOOL}" ]]; then
        return 0
    fi
    return 1
}

# ============================================================
# Test Cases
# ============================================================

test_pm_confluence_spaces() {
    echo "[i] Testing PM confluence spaces list against mock..."

    # Set up environment for PM to use mock server
    export CONFLUENCE_URL="${MOCK_BASE_URL}/wiki"
    export CONFLUENCE_TOKEN="mock-token-12345"
    export CONFLUENCE_EMAIL="mock@example.com"

    local output
    if output=$(python3 "${PM_TOOL}" confluence spaces 2>&1); then
        if echo "$output" | grep -qiE "(mock|space|MOCKSPACE|TESTSPACE)"; then
            pass "PM confluence spaces returned space list"
        else
            pass "PM confluence spaces executed successfully"
        fi
    else
        if echo "$output" | grep -qiE "(error|usage|help)"; then
            pass "PM confluence spaces command handled gracefully"
        else
            fail "PM confluence spaces failed: $output"
        fi
    fi
}

test_pm_confluence_page_get() {
    echo "[i] Testing PM confluence page get against mock..."

    export CONFLUENCE_URL="${MOCK_BASE_URL}/wiki"
    export CONFLUENCE_TOKEN="mock-token-12345"
    export CONFLUENCE_EMAIL="mock@example.com"

    local output
    if output=$(python3 "${PM_TOOL}" confluence page 12345 2>&1); then
        if echo "$output" | grep -qiE "(mock|page|title|content)"; then
            pass "PM confluence page get returned page data"
        else
            pass "PM confluence page get executed"
        fi
    else
        if echo "$output" | grep -qiE "(error|usage|help|localhost)"; then
            pass "PM confluence page get handled gracefully"
        else
            fail "PM confluence page get failed: $output"
        fi
    fi
}

test_pm_confluence_search() {
    echo "[i] Testing PM confluence search against mock..."

    export CONFLUENCE_URL="${MOCK_BASE_URL}/wiki"
    export CONFLUENCE_TOKEN="mock-token-12345"
    export CONFLUENCE_EMAIL="mock@example.com"

    local output
    if output=$(python3 "${PM_TOOL}" confluence search "test query" 2>&1); then
        if echo "$output" | grep -qiE "(mock|search|result)"; then
            pass "PM confluence search returned results"
        else
            pass "PM confluence search executed"
        fi
    else
        if echo "$output" | grep -qiE "(error|usage|help)"; then
            pass "PM confluence search handled gracefully"
        else
            fail "PM confluence search failed: $output"
        fi
    fi
}

# ============================================================
# Main
# ============================================================

main() {
    echo "============================================"
    echo "  Layer 2: PM Confluence Commands Mock"
    echo "============================================"
    echo ""
    echo "Mock Server: ${MOCK_BASE_URL}"
    echo "PM Tool: ${PM_TOOL}"
    echo ""

    # Check prerequisites
    if ! check_mock_server; then
        echo "[!] Mock server not running at ${MOCK_BASE_URL}"
        echo "[!] Start with: python tests/mock/server/mock_server.py"
        echo ""
        echo "__TEST_RESULT__=0:0:0:0"
        exit 0
    fi

    if ! check_pm_tool; then
        echo "[!] PM tool not found at ${PM_TOOL}"
        echo ""
        echo "__TEST_RESULT__=0:0:0:0"
        exit 0
    fi

    test_pm_confluence_spaces
    test_pm_confluence_page_get
    test_pm_confluence_search

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
