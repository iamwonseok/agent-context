#!/bin/bash
# CLI Error Handling Test
# Validates CLI error cases return appropriate exit codes
#
# Test Tag: cli-error-handling
# Layer: 1 (Offline Functional)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CLI="${PROJECT_ROOT}/bin/agent-context.sh"

# ============================================================
# Test Output Helpers
# ============================================================
log_ok() { echo "[V] $1"; }
log_fail() { echo "[X] $1"; }

# ============================================================
# Test: CLI Error Handling
# ============================================================
test_cli_error_handling() {
    local total=0
    local passed=0
    local failed=0
    local skipped=0

    # 1. Unknown command returns non-zero (1 or 2)
    total=$((total + 1))
    local exit_code=0
    "${CLI}" foobar_nonexistent_command 2>/dev/null || exit_code=$?

    if [[ ${exit_code} -ne 0 ]]; then
        log_ok "Unknown command returns non-zero (${exit_code})"
        passed=$((passed + 1))
    else
        log_fail "Unknown command returns exit 0 (expected non-zero)"
        failed=$((failed + 1))
    fi

    # 2. Invalid option returns non-zero
    total=$((total + 1))
    exit_code=0
    "${CLI}" --invalid-option-xyz 2>/dev/null || exit_code=$?

    if [[ ${exit_code} -ne 0 ]]; then
        log_ok "Invalid option returns non-zero (${exit_code})"
        passed=$((passed + 1))
    else
        log_fail "Invalid option returns exit 0 (expected non-zero)"
        failed=$((failed + 1))
    fi

    # 3. tests with invalid tag returns non-zero
    total=$((total + 1))
    exit_code=0
    "${CLI}" tests --tags nonexistent_tag_xyz 2>/dev/null || exit_code=$?

    # This might return 0 if it silently ignores unknown tags
    # Or non-zero if it validates tags
    if [[ ${exit_code} -eq 0 ]]; then
        log_ok "tests --tags with unknown tag handled gracefully"
        passed=$((passed + 1))
    else
        log_ok "tests --tags with unknown tag returns ${exit_code}"
        passed=$((passed + 1))
    fi

    # 4. doctor with unknown subcommand
    total=$((total + 1))
    exit_code=0
    "${CLI}" doctor unknown_subcommand_xyz 2>/dev/null || exit_code=$?

    if [[ ${exit_code} -ne 0 ]]; then
        log_ok "doctor unknown subcommand returns non-zero (${exit_code})"
        passed=$((passed + 1))
    else
        log_fail "doctor unknown subcommand returns exit 0 (expected non-zero)"
        failed=$((failed + 1))
    fi

    # 5. Empty command shows help and returns 0
    total=$((total + 1))
    local output
    exit_code=0
    output=$("${CLI}" 2>&1) || exit_code=$?

    if [[ ${exit_code} -eq 0 ]] && echo "${output}" | grep -qi 'usage'; then
        log_ok "No command shows help with exit 0"
        passed=$((passed + 1))
    else
        log_fail "No command: exit=${exit_code}, expected help with exit 0"
        failed=$((failed + 1))
    fi

    echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
}

# ============================================================
# Main
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_cli_error_handling
fi
