#!/bin/bash
# Agent CLI Test Suite

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
AGENT_BIN="${TOOLS_DIR}/agent/bin/agent"
AGENT_LIB="${TOOLS_DIR}/agent/lib"

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
    if bash -n "$AGENT_BIN" 2>/dev/null; then
        test_pass "agent (main CLI) syntax"
    else
        test_fail "agent (main CLI) syntax"
    fi

    # Library files
    local libs=(
        branch.sh
        checks.sh
        context.sh
        executor.sh
        git-strategy.sh
        handoff.sh
        init.sh
        manager.sh
        markdown.sh
        parser.sh
        permissions.sh
        roles.sh
        upload.sh
    )

    for lib in "${libs[@]}"; do
        local lib_path="${AGENT_LIB}/${lib}"
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

    # agent --help
    if "$AGENT_BIN" --help 2>&1 | grep -q "USAGE:"; then
        test_pass "agent --help"
    else
        test_fail "agent --help"
    fi

    # agent -h
    if "$AGENT_BIN" -h 2>&1 | grep -q "USAGE:"; then
        test_pass "agent -h"
    else
        test_fail "agent -h"
    fi

    # agent help
    if "$AGENT_BIN" help 2>&1 | grep -q "USAGE:"; then
        test_pass "agent help"
    else
        test_fail "agent help"
    fi

    # agent (no args)
    if "$AGENT_BIN" 2>&1 | grep -q "USAGE:"; then
        test_pass "agent (no args shows help)"
    else
        test_fail "agent (no args shows help)"
    fi

    # agent --version
    if "$AGENT_BIN" --version 2>&1 | grep -q "agent version"; then
        test_pass "agent --version"
    else
        test_fail "agent --version"
    fi

    # agent version
    if "$AGENT_BIN" version 2>&1 | grep -q "agent version"; then
        test_pass "agent version"
    else
        test_fail "agent version"
    fi
}

# ============================================================
# 3. Developer Command Tests
# ============================================================
test_dev_commands() {
    section "Developer Command Tests"

    # agent dev help
    if "$AGENT_BIN" dev help 2>&1 | grep -qE "(USAGE:|start|status)"; then
        test_pass "agent dev help"
    else
        test_fail "agent dev help"
    fi

    # agent dev status (should work in git repo)
    local output
    output=$("$AGENT_BIN" dev status 2>&1) || true
    if echo "$output" | grep -qE "(Current Branch:|Status|not in a git)"; then
        test_pass "agent dev status"
    else
        test_fail "agent dev status"
    fi

    # agent dev list
    output=$("$AGENT_BIN" dev list 2>&1) || true
    if echo "$output" | grep -qE "(Active|branches|worktrees|No active)"; then
        test_pass "agent dev list"
    else
        test_fail "agent dev list"
    fi

    # agent status (shortcut)
    output=$("$AGENT_BIN" status 2>&1) || true
    if echo "$output" | grep -qE "(Workflow Status|Project Root|not in a git)"; then
        test_pass "agent status"
    else
        test_fail "agent status"
    fi
}

# ============================================================
# 4. Manager Command Tests
# ============================================================
test_mgr_commands() {
    section "Manager Command Tests"

    # agent mgr help
    if "$AGENT_BIN" mgr help 2>&1 | grep -qE "(USAGE:|pending|review)"; then
        test_pass "agent mgr help"
    else
        test_fail "agent mgr help"
    fi

    # agent mgr pending (may fail without config, but should not crash)
    local output
    output=$("$AGENT_BIN" mgr pending 2>&1) || true
    if echo "$output" | grep -qE "(Pending|MR|not configured|ERROR)"; then
        test_pass "agent mgr pending"
    else
        test_fail "agent mgr pending"
    fi
}

# ============================================================
# 5. Config Tests
# ============================================================
test_config() {
    section "Config Tests"

    # agent config show
    local output
    output=$("$AGENT_BIN" config show 2>&1) || true
    if echo "$output" | grep -qE "(Configuration|Project Root|not in a git)"; then
        test_pass "agent config show"
    else
        test_fail "agent config show"
    fi
}

# ============================================================
# 6. Error Handling Tests
# ============================================================
test_error_handling() {
    section "Error Handling Tests"

    # Unknown command
    if "$AGENT_BIN" unknown_command 2>&1 | grep -q "ERROR"; then
        test_pass "agent unknown_command (error)"
    else
        test_fail "agent unknown_command (error)"
    fi

    # Unknown dev subcommand
    if "$AGENT_BIN" dev unknown 2>&1 | grep -q "ERROR"; then
        test_pass "agent dev unknown (error)"
    else
        test_fail "agent dev unknown (error)"
    fi

    # Unknown mgr subcommand
    if "$AGENT_BIN" mgr unknown 2>&1 | grep -q "ERROR"; then
        test_pass "agent mgr unknown (error)"
    else
        test_fail "agent mgr unknown (error)"
    fi

    # Unknown config subcommand
    if "$AGENT_BIN" config unknown 2>&1 | grep -q "ERROR"; then
        test_pass "agent config unknown (error)"
    else
        test_fail "agent config unknown (error)"
    fi
}

# ============================================================
# 7. Shortcut Commands Tests
# ============================================================
test_shortcuts() {
    section "Shortcut Commands Tests"

    # agent list (should forward to dev list)
    local output
    output=$("$AGENT_BIN" list 2>&1) || true
    if echo "$output" | grep -qE "(Active|branches|worktrees|No active)"; then
        test_pass "agent list (shortcut to dev list)"
    else
        test_fail "agent list (shortcut to dev list)"
    fi

    # agent pending (should forward to mgr pending)
    output=$("$AGENT_BIN" pending 2>&1) || true
    if echo "$output" | grep -qE "(Pending|MR|not configured|ERROR)"; then
        test_pass "agent pending (shortcut to mgr pending)"
    else
        test_fail "agent pending (shortcut to mgr pending)"
    fi
}

# ============================================================
# Main
# ============================================================
main() {
    echo "=========================================="
    echo "Agent CLI Test Suite"
    echo "=========================================="
    echo "Agent Binary: ${AGENT_BIN}"

    # Check if Agent binary exists
    if [[ ! -f "$AGENT_BIN" ]]; then
        echo "[ERROR] Agent binary not found: $AGENT_BIN"
        exit 1
    fi

    if [[ ! -x "$AGENT_BIN" ]]; then
        echo "[WARN] Agent binary not executable, adding +x"
        chmod +x "$AGENT_BIN"
    fi

    # Run tests
    test_syntax
    test_help
    test_dev_commands
    test_mgr_commands
    test_config
    test_error_handling
    test_shortcuts

    echo ""
    echo "=========================================="
    echo "Agent Test Results"
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
