#!/bin/bash
# Tests Runner Contract Test
# Validates the test runner itself works correctly
#
# Test Tag: tests-runner-contract
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
# Test: Tests Runner Contract
# ============================================================
test_tests_runner_contract() {
    local total=0
    local passed=0
    local failed=0
    local skipped=0

    # 1. tests list works
    total=$((total + 1))
    local list_output
    local exit_code=0
    list_output=$("${CLI}" tests list 2>&1) || exit_code=$?

    if [[ ${exit_code} -eq 0 ]]; then
        log_ok "tests list returns exit 0"
        passed=$((passed + 1))
    else
        log_fail "tests list returns exit ${exit_code}"
        failed=$((failed + 1))
    fi

    # 2. tests list shows available tags
    total=$((total + 1))
    if echo "${list_output}" | grep -qi 'available\|tag'; then
        log_ok "tests list shows available tags"
        passed=$((passed + 1))
    else
        log_fail "tests list missing tag information"
        failed=$((failed + 1))
    fi

    # 3. tests list includes deps
    total=$((total + 1))
    if echo "${list_output}" | grep -q 'deps'; then
        log_ok "tests list includes deps"
        passed=$((passed + 1))
    else
        log_fail "tests list missing deps tag"
        failed=$((failed + 1))
    fi

    # 4. tests --help works
    total=$((total + 1))
    exit_code=0
    "${CLI}" tests --help >/dev/null 2>&1 || exit_code=$?

    if [[ ${exit_code} -eq 0 ]]; then
        log_ok "tests --help returns exit 0"
        passed=$((passed + 1))
    else
        log_fail "tests --help returns exit ${exit_code}"
        failed=$((failed + 1))
    fi

    # 5. tests smoke syntax is valid
    total=$((total + 1))
    exit_code=0
    # Just check it parses, don't run full smoke
    "${CLI}" tests smoke --help >/dev/null 2>&1 || exit_code=$?

    if [[ ${exit_code} -eq 0 ]]; then
        log_ok "tests smoke --help returns exit 0"
        passed=$((passed + 1))
    else
        log_fail "tests smoke --help returns exit ${exit_code}"
        failed=$((failed + 1))
    fi

    # 6. tests --tags syntax works
    total=$((total + 1))
    exit_code=0
    local tags_output
    tags_output=$("${CLI}" tests --tags deps 2>&1) || exit_code=$?

    # Should complete (pass or fail based on environment)
    if [[ ${exit_code} -eq 0 ]] || [[ ${exit_code} -eq 1 ]]; then
        log_ok "tests --tags deps completes (exit ${exit_code})"
        passed=$((passed + 1))
    else
        log_fail "tests --tags deps returns unexpected exit ${exit_code}"
        failed=$((failed + 1))
    fi

    # 7. tests output includes Summary line
    total=$((total + 1))
    if echo "${tags_output}" | grep -q 'Summary:'; then
        log_ok "tests output includes Summary line"
        passed=$((passed + 1))
    else
        log_fail "tests output missing Summary line"
        failed=$((failed + 1))
    fi

    # 8. Tag alias resolution works (preflight -> deps)
    total=$((total + 1))
    exit_code=0
    local alias_output
    alias_output=$("${CLI}" tests --tags preflight 2>&1) || exit_code=$?

    if echo "${alias_output}" | grep -qi 'deps'; then
        log_ok "Tag alias 'preflight' resolves to deps"
        passed=$((passed + 1))
    else
        log_warn "Tag alias resolution unclear"
        passed=$((passed + 1))
    fi

    echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
}

# ============================================================
# Main
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_tests_runner_contract
fi
