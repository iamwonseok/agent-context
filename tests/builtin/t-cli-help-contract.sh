#!/bin/bash
# CLI Help Contract Test
# Validates that all CLI subcommands return exit 0 for --help
#
# Test Tag: cli-help-contract
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
log_warn() { echo "[!] $1"; }

# ============================================================
# Test: CLI Help Contract
# ============================================================
test_cli_help_contract() {
    local total=0
    local passed=0
    local failed=0
    local skipped=0

    # All CLI subcommands to test
    local subcommands=(
        ""           # main help
        "init"
        "install"
        "update"
        "upgrade"
        "clean"
        "doctor"
        "audit"
        "tests"
        "log"
        "report"
    )

    # 1. Check CLI executable exists
    total=$((total + 1))
    if [[ -x "${CLI}" ]]; then
        log_ok "CLI executable exists: ${CLI}"
        passed=$((passed + 1))
    else
        log_fail "CLI not executable: ${CLI}"
        failed=$((failed + 1))
        echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
        return
    fi

    # 2. Test --help for each subcommand
    for cmd in "${subcommands[@]}"; do
        total=$((total + 1))
        local help_output
        local exit_code=0

        if [[ -z "${cmd}" ]]; then
            help_output=$("${CLI}" --help 2>&1) || exit_code=$?
            cmd="(main)"
        else
            help_output=$("${CLI}" "${cmd}" --help 2>&1) || exit_code=$?
        fi

        if [[ ${exit_code} -eq 0 ]]; then
            log_ok "${cmd} --help returns exit 0"
            passed=$((passed + 1))

            # 2b. Check for usage keyword (loose check)
            total=$((total + 1))
            if echo "${help_output}" | grep -qiE '(usage|commands|options)'; then
                log_ok "${cmd} --help has usage/commands/options keyword"
                passed=$((passed + 1))
            else
                log_warn "${cmd} --help missing usage keyword (optional)"
                passed=$((passed + 1))  # Warning, not failure
            fi
        else
            log_fail "${cmd} --help returns exit ${exit_code}"
            failed=$((failed + 1))
        fi
    done

    echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
}

# ============================================================
# Main
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_cli_help_contract
fi
