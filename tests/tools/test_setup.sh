#!/bin/bash
# Unit tests for setup.sh
#
# Tests:
#   - --help option
#   - --skip-secrets option
#   - secrets-examples template resolution

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_CONTEXT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
SETUP_SCRIPT="${AGENT_CONTEXT_DIR}/setup.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Counters
TOTAL=0
PASSED=0
FAILED=0

test_pass() {
    echo -e "  ${GREEN}[OK]${NC} $1"
    ((TOTAL++)) || true
    ((PASSED++)) || true
}

test_fail() {
    echo -e "  ${RED}[NG]${NC} $1"
    ((TOTAL++)) || true
    ((FAILED++)) || true
}

# Create temp workspace
WORKSPACE="${TMPDIR:-/tmp}/test-setup-$$"
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"
git init --quiet

cleanup() {
    rm -rf "$WORKSPACE" 2>/dev/null || true
}
trap cleanup EXIT

echo "=========================================="
echo "setup.sh Unit Tests"
echo "=========================================="
echo ""

# Test 1: --help includes --skip-secrets
echo "[TEST] --help includes --skip-secrets option"
if "$SETUP_SCRIPT" --help 2>&1 | grep -q "skip-secrets"; then
    test_pass "--help shows --skip-secrets option"
else
    test_fail "--help missing --skip-secrets option"
fi

# Test 2: --skip-secrets does not create .secrets/
echo ""
echo "[TEST] --skip-secrets prevents .secrets/ creation"
rm -rf .secrets 2>/dev/null || true
"$SETUP_SCRIPT" --skip-secrets --non-interactive >/dev/null 2>&1 || true

if [ ! -d ".secrets" ]; then
    test_pass "--skip-secrets: .secrets/ not created"
else
    test_fail "--skip-secrets: .secrets/ was created (should not be)"
fi

# Test 3: Without --skip-secrets, .secrets/ is created with examples
echo ""
echo "[TEST] Without --skip-secrets, .secrets/ is created"
rm -rf .secrets 2>/dev/null || true
"$SETUP_SCRIPT" --non-interactive >/dev/null 2>&1 || true

if [ -d ".secrets" ]; then
    test_pass ".secrets/ directory created"

    # Check for example files
    if ls .secrets/*.example >/dev/null 2>&1; then
        test_pass ".secrets/ contains example files"
    else
        test_fail ".secrets/ missing example files"
    fi
else
    test_fail ".secrets/ directory not created"
fi

# Test 4: Template path uses secrets-examples (not .secrets)
echo ""
echo "[TEST] Template path resolution"
if [ -d "${AGENT_CONTEXT_DIR}/templates/secrets-examples" ]; then
    test_pass "templates/secrets-examples/ exists"
else
    test_fail "templates/secrets-examples/ not found"
fi

if [ ! -d "${AGENT_CONTEXT_DIR}/templates/.secrets" ]; then
    test_pass "templates/.secrets/ does not exist (correct)"
else
    test_fail "templates/.secrets/ exists (should be secrets-examples/)"
fi

# Summary
echo ""
echo "=========================================="
echo "setup.sh Unit Test Results"
echo "=========================================="
echo -e "Total:  ${TOTAL}"
echo -e "Passed: ${GREEN}${PASSED}${NC}"
echo -e "Failed: ${RED}${FAILED}${NC}"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}All setup.sh tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some setup.sh tests failed.${NC}"
    exit 1
fi
