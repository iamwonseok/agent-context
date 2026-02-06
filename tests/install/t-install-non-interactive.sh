#!/bin/bash
# Install Non-Interactive Test
# Tests non-interactive install mode
#
# Test Tag: install-non-interactive
# Layer: 1 (Offline Functional)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
INSTALL_SCRIPT="${PROJECT_ROOT}/builtin/install.sh"

# ============================================================
# Test Output Helpers
# ============================================================
log_ok() { echo "[V] $1"; }
log_fail() { echo "[X] $1"; }
log_progress() { echo "[*] $1"; }

# ============================================================
# Test: Install Non-Interactive
# ============================================================
test_install_non_interactive() {
    local total=0
    local passed=0
    local failed=0
    local skipped=0

    # Create temporary directory
    local temp_dir
    temp_dir=$(mktemp -d)
    # shellcheck disable=SC2064
    trap "rm -rf '${temp_dir}'" EXIT

    log_progress "Creating temp project in ${temp_dir}..."

    # 1. Check install script exists
    total=$((total + 1))
    if [[ -f "${INSTALL_SCRIPT}" ]]; then
        log_ok "Install script exists"
        passed=$((passed + 1))
    else
        log_fail "Install script not found: ${INSTALL_SCRIPT}"
        failed=$((failed + 1))
        echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
        return
    fi

    # 2. Initialize git repo (required for install)
    total=$((total + 1))
    if git -C "${temp_dir}" init -q 2>/dev/null; then
        log_ok "Git repo initialized"
        passed=$((passed + 1))
    else
        log_fail "Git init failed"
        failed=$((failed + 1))
        echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
        return
    fi

    # 3. Run non-interactive install
    total=$((total + 1))
    if bash "${INSTALL_SCRIPT}" --non-interactive --force "${temp_dir}" >/dev/null 2>&1; then
        log_ok "Non-interactive install completed"
        passed=$((passed + 1))
    else
        log_fail "Non-interactive install failed"
        failed=$((failed + 1))
        echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
        return
    fi

    # 4. Verify .cursorrules created
    total=$((total + 1))
    if [[ -f "${temp_dir}/.cursorrules" ]]; then
        log_ok ".cursorrules created"
        passed=$((passed + 1))
    else
        log_fail ".cursorrules missing"
        failed=$((failed + 1))
    fi

    # 5. Verify .project.yaml created
    total=$((total + 1))
    if [[ -f "${temp_dir}/.project.yaml" ]]; then
        log_ok ".project.yaml created"
        passed=$((passed + 1))
    else
        log_fail ".project.yaml missing"
        failed=$((failed + 1))
    fi

    # 6. Verify .agent/ directory created
    total=$((total + 1))
    if [[ -d "${temp_dir}/.agent" ]]; then
        log_ok ".agent/ created"
        passed=$((passed + 1))
    else
        log_fail ".agent/ missing"
        failed=$((failed + 1))
    fi

    echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
}

# ============================================================
# Main
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_install_non_interactive
fi
