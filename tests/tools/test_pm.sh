#!/bin/bash
# PM CLI Test Suite
# Tests JIRA/Confluence integration (GitLab/GitHub removed - use glab/gh instead)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PM_BIN="${PROJECT_ROOT}/tools/pm/bin/pm"
PM_LIB="${PROJECT_ROOT}/tools/pm/lib"

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
    echo -e "  ${GREEN}[OK]${NC} $1"
    ((TOTAL++)) || true
    ((PASSED++)) || true
}

test_fail() {
    echo -e "  ${RED}[NG]${NC} $1"
    ((TOTAL++)) || true
    ((FAILED++)) || true
}

test_skip() {
    echo -e "  ${YELLOW}[--]${NC} $1"
    ((TOTAL++)) || true
    ((SKIPPED++)) || true
}

section() {
    echo ""
    echo -e "${BLUE}--- $1 ---${NC}"
}

# ============================================================
# 1. Syntax Tests
# ============================================================
test_syntax() {
    section "Syntax Tests"

    # Main CLI
    if bash -n "$PM_BIN" 2>/dev/null; then
        test_pass "pm (main CLI) syntax"
    else
        test_fail "pm (main CLI) syntax"
    fi

    # Library files (updated list)
    for lib in config.sh jira.sh confluence.sh export.sh; do
        local lib_path="${PM_LIB}/${lib}"
        if [[ -f "$lib_path" ]]; then
            if bash -n "$lib_path" 2>/dev/null; then
                test_pass "${lib} syntax"
            else
                test_fail "${lib} syntax"
            fi
        else
            test_fail "${lib} missing"
        fi
    done
}

# ============================================================
# 2. Help Tests
# ============================================================
test_help() {
    section "Help Tests"

    # pm --help
    if "$PM_BIN" --help 2>&1 | grep -q "USAGE:"; then
        test_pass "pm --help"
    else
        test_fail "pm --help"
    fi

    # pm -h
    if "$PM_BIN" -h 2>&1 | grep -q "USAGE:"; then
        test_pass "pm -h"
    else
        test_fail "pm -h"
    fi

    # pm (no args)
    if "$PM_BIN" 2>&1 | grep -q "USAGE:"; then
        test_pass "pm (no args shows help)"
    else
        test_fail "pm (no args shows help)"
    fi

    # pm --version
    if "$PM_BIN" --version 2>&1 | grep -q "pm version"; then
        test_pass "pm --version"
    else
        test_fail "pm --version"
    fi

    # Check version is 2.0.0
    if "$PM_BIN" --version 2>&1 | grep -q "2.0.0"; then
        test_pass "pm version is 2.0.0"
    else
        test_fail "pm version is 2.0.0"
    fi
}

# ============================================================
# 3. Config Tests
# ============================================================
test_config() {
    section "Config Tests"

    # pm config show
    local output
    output=$("$PM_BIN" config show 2>&1) || true

    if echo "$output" | grep -qE "(Project Configuration|not configured|Cannot find)"; then
        test_pass "pm config show"
    else
        test_fail "pm config show"
    fi

    # pm config init (in temp dir)
    local temp_dir
    temp_dir=$(mktemp -d)
    cd "$temp_dir"
    git init -q 2>/dev/null || true

    if "$PM_BIN" config init 2>&1 | grep -q "Created"; then
        test_pass "pm config init"
    else
        test_fail "pm config init"
    fi

    if [[ -f ".project.yaml" ]]; then
        test_pass "pm config init creates .project.yaml"
    else
        test_fail "pm config init creates .project.yaml"
    fi

    # Cleanup
    cd - >/dev/null
    rm -rf "$temp_dir"
}

# ============================================================
# 4. Error Handling Tests
# ============================================================
test_error_handling() {
    section "Error Handling Tests"

    # Unknown command
    if "$PM_BIN" unknown_command 2>&1 | grep -q "ERROR"; then
        test_pass "pm unknown_command (error)"
    else
        test_fail "pm unknown_command (error)"
    fi

    # pm jira (no subcommand)
    if "$PM_BIN" jira 2>&1 | grep -q "Usage:"; then
        test_pass "pm jira (usage)"
    else
        test_fail "pm jira (usage)"
    fi

    # pm confluence (no subcommand)
    if "$PM_BIN" confluence 2>&1 | grep -q "Usage:"; then
        test_pass "pm confluence (usage)"
    else
        test_fail "pm confluence (usage)"
    fi

    # pm jira unknown
    if "$PM_BIN" jira unknown 2>&1 | grep -q "ERROR"; then
        test_pass "pm jira unknown (error)"
    else
        test_fail "pm jira unknown (error)"
    fi

    # pm confluence unknown
    if "$PM_BIN" confluence unknown 2>&1 | grep -q "ERROR"; then
        test_pass "pm confluence unknown (error)"
    else
        test_fail "pm confluence unknown (error)"
    fi

    # pm jira issue (no subcommand)
    if "$PM_BIN" jira issue 2>&1 | grep -q "Usage:"; then
        test_pass "pm jira issue (usage)"
    else
        test_fail "pm jira issue (usage)"
    fi

    # pm confluence page (no subcommand)
    if "$PM_BIN" confluence page 2>&1 | grep -q "Usage:"; then
        test_pass "pm confluence page (usage)"
    else
        test_fail "pm confluence page (usage)"
    fi
}

# ============================================================
# 5. JIRA API Tests (require tokens)
# ============================================================
test_jira_api() {
    section "JIRA API Tests (require tokens)"

    # Check for JIRA token
    if [[ -n "$JIRA_TOKEN" ]] || [[ -f ".secrets/atlassian-api-token" ]]; then
        local output

        # jira me
        output=$("$PM_BIN" jira me 2>&1) || true
        if echo "$output" | grep -qE "(Name:|Email:|not configured)"; then
            test_pass "pm jira me"
        else
            test_fail "pm jira me"
        fi

        # jira issue list
        output=$("$PM_BIN" jira issue list 2>&1) || true
        if echo "$output" | grep -qE "(KEY|Total:|No issues|not configured)"; then
            test_pass "pm jira issue list"
        else
            test_fail "pm jira issue list"
        fi
    else
        test_skip "pm jira me (no token)"
        test_skip "pm jira issue list (no token)"
    fi
}

# ============================================================
# 6. Confluence API Tests (require tokens)
# ============================================================
test_confluence_api() {
    section "Confluence API Tests (require tokens)"

    # Check for Confluence token (same as JIRA)
    if [[ -n "$JIRA_TOKEN" ]] || [[ -n "$CONFLUENCE_TOKEN" ]] || [[ -f ".secrets/atlassian-api-token" ]]; then
        local output

        # confluence me
        output=$("$PM_BIN" confluence me 2>&1) || true
        if echo "$output" | grep -qE "(Name:|Email:|not configured)"; then
            test_pass "pm confluence me"
        else
            test_fail "pm confluence me"
        fi

        # confluence space list
        output=$("$PM_BIN" confluence space list 2>&1) || true
        if echo "$output" | grep -qE "(KEY|Name|No spaces|not configured)"; then
            test_pass "pm confluence space list"
        else
            test_fail "pm confluence space list"
        fi
    else
        test_skip "pm confluence me (no token)"
        test_skip "pm confluence space list (no token)"
    fi
}

# ============================================================
# Main
# ============================================================
main() {
    echo "=========================================="
    echo "PM CLI Test Suite"
    echo "=========================================="
    echo "PM Binary: ${PM_BIN}"

    # Check if PM binary exists
    if [[ ! -f "$PM_BIN" ]]; then
        echo "[ERROR] PM binary not found: $PM_BIN"
        exit 1
    fi

    if [[ ! -x "$PM_BIN" ]]; then
        echo "[!!] PM binary not executable, adding +x"
        chmod +x "$PM_BIN"
    fi

    # Run tests
    test_syntax
    test_help
    test_config
    test_error_handling
    test_jira_api
    test_confluence_api

    echo ""
    echo "=========================================="
    echo "PM Test Results"
    echo "=========================================="
    echo -e "Total:   ${TOTAL}"
    echo -e "Passed:  ${GREEN}${PASSED}${NC}"
    echo -e "Failed:  ${RED}${FAILED}${NC}"
    echo -e "Skipped: ${YELLOW}${SKIPPED}${NC}"
    echo ""

    if [[ "$FAILED" -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        exit 1
    fi
}

main "$@"
