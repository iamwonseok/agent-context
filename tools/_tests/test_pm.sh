#!/bin/bash
# PM CLI Test Suite

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PM_BIN="${TOOLS_DIR}/pm/bin/pm"
PM_LIB="${TOOLS_DIR}/pm/lib"

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

# Results array for tracking
declare -a RESULTS

test_pass() {
    echo -e "  ${GREEN}[PASS]${NC} $1"
    ((TOTAL++)) || true
    ((PASSED++)) || true
    RESULTS+=("PASS|$1")
}

test_fail() {
    echo -e "  ${RED}[FAIL]${NC} $1"
    ((TOTAL++)) || true
    ((FAILED++)) || true
    RESULTS+=("FAIL|$1")
}

test_skip() {
    echo -e "  ${YELLOW}[SKIP]${NC} $1"
    ((TOTAL++)) || true
    ((SKIPPED++)) || true
    RESULTS+=("SKIP|$1")
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

    # Library files
    for lib in config.sh jira.sh gitlab.sh github.sh workflow.sh; do
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
}

# ============================================================
# 3. Config Tests
# ============================================================
test_config() {
    section "Config Tests"

    # pm config show (may fail if no .project.yaml, but should not crash)
    local output
    output=$("$PM_BIN" config show 2>&1) || true

    if echo "$output" | grep -qE "(Project Configuration|not configured|Cannot find)"; then
        test_pass "pm config show"
    else
        test_fail "pm config show"
    fi

    # pm config init --force (in temp dir)
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

    # Unknown jira subcommand
    if "$PM_BIN" jira unknown 2>&1 | grep -q "ERROR"; then
        test_pass "pm jira unknown (error)"
    else
        test_fail "pm jira unknown (error)"
    fi

    # Unknown gitlab subcommand
    if "$PM_BIN" gitlab unknown 2>&1 | grep -q "ERROR"; then
        test_pass "pm gitlab unknown (error)"
    else
        test_fail "pm gitlab unknown (error)"
    fi

    # Unknown github subcommand
    if "$PM_BIN" github unknown 2>&1 | grep -q "ERROR"; then
        test_pass "pm github unknown (error)"
    else
        test_fail "pm github unknown (error)"
    fi
}

# ============================================================
# 5. API Tests (require tokens)
# ============================================================
test_api() {
    section "API Tests (require tokens)"

    # Check for GitHub token
    if [[ -n "$GITHUB_TOKEN" ]] || [[ -f ".secrets/github-api-token" ]]; then
        # GitHub me
        local output
        output=$("$PM_BIN" github me 2>&1) || true
        if echo "$output" | grep -qE "(Username:|not configured)"; then
            test_pass "pm github me"
        else
            test_fail "pm github me"
        fi

        # GitHub PR list
        output=$("$PM_BIN" github pr list 2>&1) || true
        if echo "$output" | grep -qE "(#|No pull requests|not configured)"; then
            test_pass "pm github pr list"
        else
            test_fail "pm github pr list"
        fi

        # GitHub issue list
        output=$("$PM_BIN" github issue list 2>&1) || true
        if echo "$output" | grep -qE "(#|No issues|not configured)"; then
            test_pass "pm github issue list"
        else
            test_fail "pm github issue list"
        fi
    else
        test_skip "pm github me (no token)"
        test_skip "pm github pr list (no token)"
        test_skip "pm github issue list (no token)"
    fi

    # Check for GitLab token
    if [[ -n "$GITLAB_TOKEN" ]] || [[ -f ".secrets/gitlab-api-token" ]]; then
        local output
        output=$("$PM_BIN" gitlab me 2>&1) || true
        if echo "$output" | grep -qE "(Username:|not configured)"; then
            test_pass "pm gitlab me"
        else
            test_fail "pm gitlab me"
        fi

        output=$("$PM_BIN" gitlab mr list 2>&1) || true
        if echo "$output" | grep -qE "(!|No merge|not configured)"; then
            test_pass "pm gitlab mr list"
        else
            test_fail "pm gitlab mr list"
        fi

        output=$("$PM_BIN" gitlab issue list 2>&1) || true
        if echo "$output" | grep -qE "(#|No issues|not configured)"; then
            test_pass "pm gitlab issue list"
        else
            test_fail "pm gitlab issue list"
        fi
    else
        test_skip "pm gitlab me (no token)"
        test_skip "pm gitlab mr list (no token)"
        test_skip "pm gitlab issue list (no token)"
    fi

    # Check for Jira token
    if [[ -n "$JIRA_TOKEN" ]] || [[ -f ".secrets/atlassian-api-token" ]]; then
        local output
        output=$("$PM_BIN" jira me 2>&1) || true
        if echo "$output" | grep -qE "(Name:|Email:|not configured)"; then
            test_pass "pm jira me"
        else
            test_fail "pm jira me"
        fi

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
        echo "[WARN] PM binary not executable, adding +x"
        chmod +x "$PM_BIN"
    fi

    # Run tests
    test_syntax
    test_help
    test_config
    test_error_handling
    test_api

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
