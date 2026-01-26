#!/bin/bash
# Skills → Tools Integration Tests
# Validates that skills reference valid tools and tools are available

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SKILLS_DIR="${PROJECT_ROOT}/skills"
TOOLS_DIR="${PROJECT_ROOT}/tools"

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
    echo -e "  ${GREEN}(v)${NC} $1"
    ((TOTAL++)) || true
    ((PASSED++)) || true
}

test_fail() {
    echo -e "  ${RED}(x)${NC} $1"
    ((TOTAL++)) || true
    ((FAILED++)) || true
}

test_warn() {
    echo -e "  ${YELLOW}(!)${NC} $1"
}

section() {
    echo ""
    echo -e "${BLUE}--- $1 ---${NC}"
}

# Test 1: Validate skill documentation mentions appropriate tools
test_skill_tool_references() {
    section "Skill Tool References"

    # validate/check-style should mention linters
    if grep -q -E "(lint|flake8|shellcheck|clang-format)" "${SKILLS_DIR}/validate/check-style/SKILL.md" 2>/dev/null; then
        test_pass "validate/check-style mentions linter tools"
    else
        test_fail "validate/check-style missing linter references"
    fi

    # validate/run-tests should mention test frameworks
    if grep -q -E "(pytest|jest|make test)" "${SKILLS_DIR}/validate/run-tests/SKILL.md" 2>/dev/null; then
        test_pass "validate/run-tests mentions test frameworks"
    else
        test_fail "validate/run-tests missing test framework references"
    fi

    # integrate/commit-changes should mention git
    if grep -q -E "(git commit|git add)" "${SKILLS_DIR}/integrate/commit-changes/SKILL.md" 2>/dev/null; then
        test_pass "integrate/commit-changes mentions git"
    else
        test_fail "integrate/commit-changes missing git references"
    fi

    # integrate/create-merge-request should mention pm or git
    if grep -q -E "(pm|git push|gh pr|glab mr)" "${SKILLS_DIR}/integrate/create-merge-request/SKILL.md" 2>/dev/null; then
        test_pass "integrate/create-merge-request mentions PM/git tools"
    else
        test_fail "integrate/create-merge-request missing tool references"
    fi
}

# Test 2: Verify critical system tools are available
test_system_tools_available() {
    section "System Tools Availability"

    for tool in git grep make; do
        if command -v $tool >/dev/null 2>&1; then
            test_pass "System tool available: $tool"
        else
            test_fail "System tool missing: $tool"
        fi
    done
}

# Test 3: Verify agent CLI tools exist
test_agent_tools_exist() {
    section "Agent Tools Existence"

    if [ -f "${TOOLS_DIR}/agent/bin/agent" ]; then
        test_pass "agent CLI exists"
    else
        test_fail "agent CLI missing"
    fi

    if [ -f "${TOOLS_DIR}/pm/bin/pm" ]; then
        test_pass "pm CLI exists"
    else
        test_fail "pm CLI missing"
    fi

    if [ -d "${TOOLS_DIR}/lint" ]; then
        test_pass "lint tools directory exists"
    else
        test_fail "lint tools directory missing"
    fi
}

# Test 4: Verify tool executability
test_tool_executability() {
    section "Tool Executability"

    if [ -x "${TOOLS_DIR}/agent/bin/agent" ]; then
        test_pass "agent CLI is executable"
    else
        test_warn "agent CLI not executable (may need bootstrap)"
    fi

    if [ -x "${TOOLS_DIR}/pm/bin/pm" ]; then
        test_pass "pm CLI is executable"
    else
        test_warn "pm CLI not executable (may need bootstrap)"
    fi
}

# Test 5: Verify skill scripts exist and are executable
test_skill_scripts() {
    section "Skill Scripts"

    # Check if any skill has scripts directory
    for skill_script in "${SKILLS_DIR}"/*/scripts/*.sh; do
        if [ -f "$skill_script" ]; then
            local script_name=$(basename "$skill_script")
            if [ -x "$skill_script" ]; then
                test_pass "Script executable: $script_name"
            else
                test_fail "Script not executable: $script_name"
            fi
        fi
    done
}

# Test 6: Verify tools have basic help/usage
test_tool_help() {
    section "Tool Documentation"

    # Test agent CLI has help
    if [ -f "${TOOLS_DIR}/agent/bin/agent" ]; then
        if grep -q -E "(usage|--help|-h)" "${TOOLS_DIR}/agent/bin/agent" 2>/dev/null; then
            test_pass "agent CLI has help/usage"
        else
            test_warn "agent CLI missing help documentation"
        fi
    fi

    # Test pm CLI has help
    if [ -f "${TOOLS_DIR}/pm/bin/pm" ]; then
        if grep -q -E "(usage|--help|-h)" "${TOOLS_DIR}/pm/bin/pm" 2>/dev/null; then
            test_pass "pm CLI has help/usage"
        else
            test_warn "pm CLI missing help documentation"
        fi
    fi
}

# Main
main() {
    echo "=========================================="
    echo "Skills → Tools Integration Tests"
    echo "=========================================="
    echo "Project: ${PROJECT_ROOT}"

    test_skill_tool_references
    test_system_tools_available
    test_agent_tools_exist
    test_tool_executability
    test_skill_scripts
    test_tool_help

    echo ""
    echo "=========================================="
    echo "Results"
    echo "=========================================="
    echo -e "Total:  ${TOTAL}"
    echo -e "Passed: ${GREEN}${PASSED}${NC}"
    echo -e "Failed: ${RED}${FAILED}${NC}"
    echo ""

    if [ "$FAILED" -eq 0 ]; then
        echo -e "${GREEN}All integration tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some integration tests failed.${NC}"
        exit 1
    fi
}

main "$@"
