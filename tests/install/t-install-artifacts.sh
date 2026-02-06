#!/bin/bash
# Install Artifacts Test
# Verifies that install creates all expected artifacts
#
# Test Tag: install-artifacts
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
log_warn() { echo "[!] $1"; }

# ============================================================
# Test: Install Artifacts
# ============================================================
test_install_artifacts() {
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

    # Setup: Initialize git and run install
    git -C "${temp_dir}" init -q 2>/dev/null || true
    if ! bash "${INSTALL_SCRIPT}" --non-interactive --force --profile full "${temp_dir}" >/dev/null 2>&1; then
        log_fail "Install failed - cannot verify artifacts"
        echo "__TEST_RESULT__=1:0:1:0"
        return
    fi

    # 1. .cursorrules exists and is non-empty
    total=$((total + 1))
    if [[ -s "${temp_dir}/.cursorrules" ]]; then
        log_ok ".cursorrules exists and is non-empty"
        passed=$((passed + 1))
    else
        log_fail ".cursorrules missing or empty"
        failed=$((failed + 1))
    fi

    # 2. .project.yaml exists and is non-empty
    total=$((total + 1))
    if [[ -s "${temp_dir}/.project.yaml" ]]; then
        log_ok ".project.yaml exists and is non-empty"
        passed=$((passed + 1))
    else
        log_fail ".project.yaml missing or empty"
        failed=$((failed + 1))
    fi

    # 3. .agent/skills/ exists
    total=$((total + 1))
    if [[ -d "${temp_dir}/.agent/skills" ]]; then
        log_ok ".agent/skills/ created"
        passed=$((passed + 1))
    else
        log_fail ".agent/skills/ missing"
        failed=$((failed + 1))
    fi

    # 4. .agent/workflows/ exists
    total=$((total + 1))
    if [[ -d "${temp_dir}/.agent/workflows" ]]; then
        log_ok ".agent/workflows/ created"
        passed=$((passed + 1))
    else
        log_fail ".agent/workflows/ missing"
        failed=$((failed + 1))
    fi

    # 5. Check skill files exist
    local skills=(analyze design implement test review)
    for skill in "${skills[@]}"; do
        total=$((total + 1))
        if [[ -f "${temp_dir}/.agent/skills/${skill}.md" ]]; then
            log_ok ".agent/skills/${skill}.md exists"
            passed=$((passed + 1))
        else
            log_fail ".agent/skills/${skill}.md missing"
            failed=$((failed + 1))
        fi
    done

    # 6. Check workflow files exist
    local workflows=(solo/feature solo/bugfix solo/hotfix)
    for wf in "${workflows[@]}"; do
        total=$((total + 1))
        if [[ -f "${temp_dir}/.agent/workflows/${wf}.md" ]]; then
            log_ok ".agent/workflows/${wf}.md exists"
            passed=$((passed + 1))
        else
            log_fail ".agent/workflows/${wf}.md missing"
            failed=$((failed + 1))
        fi
    done

    # 7. .project.yaml contains expected structure
    total=$((total + 1))
    if grep -q 'roles:' "${temp_dir}/.project.yaml" 2>/dev/null; then
        log_ok ".project.yaml has 'roles:' section"
        passed=$((passed + 1))
    else
        log_fail ".project.yaml missing 'roles:' section"
        failed=$((failed + 1))
    fi

    # 8. .cursorrules references key directories
    total=$((total + 1))
    if grep -qE 'skills|workflows|ARCHITECTURE' "${temp_dir}/.cursorrules" 2>/dev/null; then
        log_ok ".cursorrules references expected paths"
        passed=$((passed + 1))
    else
        log_warn ".cursorrules may be missing expected references"
        passed=$((passed + 1))  # Warning only
    fi

    echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
}

# ============================================================
# Main
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_install_artifacts
fi
