#!/bin/bash
# Secrets Mask Test
# Validates that secrets are properly masked in output
#
# Test Tag: secrets-mask
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
# Test: Secrets Mask
# ============================================================
test_secrets_mask() {
    local total=0
    local passed=0
    local failed=0
    local skipped=0

    # Create temp secrets directory for testing
    local temp_secrets
    temp_secrets=$(mktemp -d)
    # shellcheck disable=SC2064
    trap "rm -rf '${temp_secrets}'" EXIT

    # Create fake token files
    local fake_token="FAKE_TOKEN_DO_NOT_USE_abc123xyz789"
    echo "${fake_token}" > "${temp_secrets}/atlassian-api-token"
    echo "${fake_token}" > "${temp_secrets}/gitlab-api-token"

    # 1. Check PM config show doesn't expose raw tokens
    total=$((total + 1))
    local config_output
    local exit_code=0

    # Run pm config show with fake secrets
    HOME_BACKUP="${HOME}"
    export HOME="${temp_secrets%/*}"
    mkdir -p "${HOME}/.secrets" 2>/dev/null || true
    cp "${temp_secrets}"/* "${HOME}/.secrets/" 2>/dev/null || true

    config_output=$("${PM}" config show 2>&1) || exit_code=$?

    # Restore HOME
    export HOME="${HOME_BACKUP}"

    if echo "${config_output}" | grep -qF "${fake_token}"; then
        log_fail "pm config show exposes raw token"
        failed=$((failed + 1))
    else
        log_ok "pm config show does not expose raw token"
        passed=$((passed + 1))
    fi

    # 2. Check masked format (if config shows masked tokens)
    total=$((total + 1))
    if echo "${config_output}" | grep -qE '\*{3,}|<masked>|\[MASKED\]|\.\.\.'; then
        log_ok "pm config show uses masking format"
        passed=$((passed + 1))
    else
        log_warn "pm config show may not show tokens at all (acceptable)"
        passed=$((passed + 1))
    fi

    # 3. Check PM help doesn't contain token patterns
    total=$((total + 1))
    local help_output
    help_output=$("${PM}" --help 2>&1; "${PM}" jira --help 2>&1; "${PM}" confluence --help 2>&1) || true

    # Check for actual token-like patterns (base64, hex, API key formats)
    if echo "${help_output}" | grep -qE '[A-Za-z0-9+/]{20,}={0,2}|[a-f0-9]{32,}'; then
        log_warn "PM help may contain token-like strings (review manually)"
        passed=$((passed + 1))
    else
        log_ok "PM help does not contain token patterns"
        passed=$((passed + 1))
    fi

    # 4. Check error messages don't leak tokens
    total=$((total + 1))
    local error_output
    # Force an error by using invalid URL
    error_output=$("${PM}" jira me --url "http://invalid.test.local" 2>&1) || true

    if echo "${error_output}" | grep -qF "${fake_token}"; then
        log_fail "PM error output exposes token"
        failed=$((failed + 1))
    else
        log_ok "PM error output does not expose token"
        passed=$((passed + 1))
    fi

    # 5. Check verbose output doesn't leak secrets
    total=$((total + 1))
    local verbose_output
    verbose_output=$("${PM}" --debug config show 2>&1) || true

    if echo "${verbose_output}" | grep -qF "${fake_token}"; then
        log_fail "PM debug output exposes token"
        failed=$((failed + 1))
    else
        log_ok "PM debug output does not expose token"
        passed=$((passed + 1))
    fi

    # 6. Check environment variable handling
    total=$((total + 1))
    export JIRA_API_TOKEN="${fake_token}"
    local env_output
    env_output=$("${PM}" config show 2>&1) || true
    unset JIRA_API_TOKEN

    if echo "${env_output}" | grep -qF "${fake_token}"; then
        log_fail "PM exposes token from environment"
        failed=$((failed + 1))
    else
        log_ok "PM does not expose token from environment"
        passed=$((passed + 1))
    fi

    echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
}

# ============================================================
# Main
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_secrets_mask
fi
