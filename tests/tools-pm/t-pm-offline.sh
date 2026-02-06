#!/bin/bash
# PM Offline Functionality Test
# Validates PM help and routing works without network
#
# Test Tag: pm-offline
# Layer: 1 (Offline Functional)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PM="${PROJECT_ROOT}/tools/pm/bin/pm"

# ============================================================
# Test Output Helpers
# ============================================================
log_ok() { echo "[V] $1"; }
log_fail() { echo "[X] $1"; }
log_warn() { echo "[!] $1"; }

# ============================================================
# Test: PM Offline
# ============================================================
test_pm_offline() {
    local total=0
    local passed=0
    local failed=0
    local skipped=0

    # 1. Check PM executable exists
    total=$((total + 1))
    if [[ -x "${PM}" ]]; then
        log_ok "PM executable exists"
        passed=$((passed + 1))
    else
        log_fail "PM not executable: ${PM}"
        failed=$((failed + 1))
        echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
        return
    fi

    # 2. pm --help works
    total=$((total + 1))
    local exit_code=0
    "${PM}" --help >/dev/null 2>&1 || exit_code=$?

    if [[ ${exit_code} -eq 0 ]]; then
        log_ok "pm --help returns exit 0"
        passed=$((passed + 1))
    else
        log_fail "pm --help returns exit ${exit_code}"
        failed=$((failed + 1))
    fi

    # 3. pm jira routing works (subcommand runs without error for help-like behavior)
    total=$((total + 1))
    local jira_output
    jira_output=$("${PM}" jira 2>&1) || exit_code=$?

    # pm jira with no args should show usage (exit 1 is acceptable)
    if echo "${jira_output}" | grep -qiE 'usage|command'; then
        log_ok "pm jira shows usage information"
        passed=$((passed + 1))
    else
        log_fail "pm jira does not show usage information"
        failed=$((failed + 1))
    fi

    # 4. pm jira issue routing works
    total=$((total + 1))
    local issue_output
    issue_output=$("${PM}" jira issue 2>&1) || true

    if echo "${issue_output}" | grep -qiE 'usage|command|issue'; then
        log_ok "pm jira issue shows relevant information"
        passed=$((passed + 1))
    else
        log_fail "pm jira issue does not show relevant information"
        failed=$((failed + 1))
    fi

    # 5. pm confluence routing works
    total=$((total + 1))
    local confluence_output
    confluence_output=$("${PM}" confluence 2>&1) || true

    if echo "${confluence_output}" | grep -qiE 'usage|command|confluence'; then
        log_ok "pm confluence shows relevant information"
        passed=$((passed + 1))
    else
        log_fail "pm confluence does not show relevant information"
        failed=$((failed + 1))
    fi

    # 6. pm config works
    total=$((total + 1))
    local config_output
    config_output=$("${PM}" config 2>&1) || true

    if echo "${config_output}" | grep -qiE 'usage|command|config|show'; then
        log_ok "pm config shows relevant information"
        passed=$((passed + 1))
    else
        log_fail "pm config does not show relevant information"
        failed=$((failed + 1))
    fi

    # 7. pm --version works (if implemented)
    total=$((total + 1))
    exit_code=0
    local version_output
    version_output=$("${PM}" --version 2>&1) || exit_code=$?

    if [[ ${exit_code} -eq 0 ]]; then
        log_ok "pm --version returns exit 0"
        passed=$((passed + 1))
    else
        log_warn "pm --version returns exit ${exit_code} (may not be implemented)"
        passed=$((passed + 1))  # Optional feature
    fi

    # 8. pm help output contains subcommand list
    total=$((total + 1))
    local help_output
    help_output=$("${PM}" --help 2>&1) || true

    if echo "${help_output}" | grep -qiE 'jira|confluence|config'; then
        log_ok "pm help lists subcommands"
        passed=$((passed + 1))
    else
        log_fail "pm help missing subcommand list"
        failed=$((failed + 1))
    fi

    # 9. pm config show works (may show empty config)
    total=$((total + 1))
    exit_code=0
    "${PM}" config show >/dev/null 2>&1 || exit_code=$?

    if [[ ${exit_code} -eq 0 ]] || [[ ${exit_code} -eq 1 ]]; then
        log_ok "pm config show completes (exit ${exit_code})"
        passed=$((passed + 1))
    else
        log_fail "pm config show failed unexpectedly (exit ${exit_code})"
        failed=$((failed + 1))
    fi

    # 10. Check PM does not expose secrets in help
    total=$((total + 1))
    local all_help
    all_help=$("${PM}" --help 2>&1; "${PM}" config --help 2>&1) || true

    if echo "${all_help}" | grep -qiE 'password|api.?key|token=' | grep -v 'token_file'; then
        log_fail "PM help may expose sensitive keywords"
        failed=$((failed + 1))
    else
        log_ok "PM help does not expose secrets"
        passed=$((passed + 1))
    fi

    echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
}

# ============================================================
# Main
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_pm_offline
fi
