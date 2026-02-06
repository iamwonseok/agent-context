#!/bin/bash
# CLI Version Test
# Validates CLI version output format
#
# Test Tag: cli-version
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
# Test: CLI Version
# ============================================================
test_cli_version() {
    local total=0
    local passed=0
    local failed=0
    local skipped=0

    # 1. Check --version returns exit 0
    total=$((total + 1))
    local version_output
    local exit_code=0
    version_output=$("${CLI}" --version 2>&1) || exit_code=$?

    if [[ ${exit_code} -eq 0 ]]; then
        log_ok "--version returns exit 0"
        passed=$((passed + 1))
    else
        log_fail "--version returns exit ${exit_code}"
        failed=$((failed + 1))
    fi

    # 2. Check version output matches semver pattern
    total=$((total + 1))
    if echo "${version_output}" | grep -qE '[0-9]+\.[0-9]+\.[0-9]+'; then
        log_ok "Version output contains semver: ${version_output}"
        passed=$((passed + 1))
    else
        log_fail "Version output missing semver pattern: ${version_output}"
        failed=$((failed + 1))
    fi

    # 3. Check -V shorthand works (note: -v is --verbose, -V is --version)
    total=$((total + 1))
    local v_output
    v_output=$("${CLI}" -V 2>&1) || exit_code=$?

    if echo "${v_output}" | grep -qE '[0-9]+\.[0-9]+\.[0-9]+'; then
        log_ok "-V shorthand works"
        passed=$((passed + 1))
    else
        log_fail "-V shorthand failed or missing semver"
        failed=$((failed + 1))
    fi

    # 4. Check version consistency (--version == -V)
    total=$((total + 1))
    if [[ "${version_output}" == "${v_output}" ]]; then
        log_ok "--version and -V output match"
        passed=$((passed + 1))
    else
        log_fail "--version and -V output differ"
        failed=$((failed + 1))
    fi

    echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
}

# ============================================================
# Main
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_cli_version
fi
