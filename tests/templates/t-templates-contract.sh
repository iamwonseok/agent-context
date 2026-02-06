#!/bin/bash
# Templates Contract Test
# Verifies template files exist and follow token conventions
#
# Test Tag: templates-contract
# Layer: 0 (Static/Contract)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEMPLATES_DIR="${PROJECT_ROOT}/templates"

# ============================================================
# Test Output Helpers
# ============================================================
log_ok() { echo "[V] $1"; }
log_fail() { echo "[X] $1"; }
log_warn() { echo "[!] $1"; }

# ============================================================
# Test: Templates Contract
# ============================================================
test_templates_contract() {
    local total=0
    local passed=0
    local failed=0
    local skipped=0

    # Required template files
    local required_templates=(
        "project.yaml.tmpl"
        "cursorrules.index_map.tmpl"
    )

    # 1. Check required template files exist
    for tmpl in "${required_templates[@]}"; do
        total=$((total + 1))
        if [[ -f "${TEMPLATES_DIR}/${tmpl}" ]]; then
            log_ok "Template exists: ${tmpl}"
            passed=$((passed + 1))
        else
            log_fail "Template missing: ${tmpl}"
            failed=$((failed + 1))
        fi
    done

    # 2. Check project.yaml.tmpl has valid mustache-style tokens
    total=$((total + 1))
    local project_tmpl="${TEMPLATES_DIR}/project.yaml.tmpl"
    if [[ -f "${project_tmpl}" ]]; then
        # Check for mustache tokens {{VAR}}
        if grep -qE '\{\{[A-Z_]+\}\}' "${project_tmpl}"; then
            log_ok "project.yaml.tmpl has mustache tokens"
            passed=$((passed + 1))
        else
            log_fail "project.yaml.tmpl missing mustache tokens"
            failed=$((failed + 1))
        fi
    else
        log_fail "project.yaml.tmpl not found for token check"
        failed=$((failed + 1))
    fi

    # 3. Check for expected tokens in project.yaml.tmpl
    local expected_tokens=(
        "JIRA_URL"
        "JIRA_PROJECT"
        "JIRA_EMAIL"
    )

    for token in "${expected_tokens[@]}"; do
        total=$((total + 1))
        if grep -q "{{${token}}}" "${project_tmpl}" 2>/dev/null; then
            log_ok "Token found: {{${token}}}"
            passed=$((passed + 1))
        else
            log_fail "Token missing: {{${token}}}"
            failed=$((failed + 1))
        fi
    done

    # 4. Check conditional tokens (mustache sections)
    total=$((total + 1))
    if grep -qE '\{\{#[A-Z_]+\}\}' "${project_tmpl}" 2>/dev/null; then
        log_ok "project.yaml.tmpl has conditional sections"
        passed=$((passed + 1))
    else
        log_warn "project.yaml.tmpl has no conditional sections (optional)"
        passed=$((passed + 1))  # Optional feature
    fi

    # 5. Check templates directory structure
    total=$((total + 1))
    if [[ -d "${TEMPLATES_DIR}" ]]; then
        log_ok "templates/ directory exists"
        passed=$((passed + 1))
    else
        log_fail "templates/ directory missing"
        failed=$((failed + 1))
    fi

    # 6. Check no secrets in templates
    total=$((total + 1))
    local has_secrets=false
    local secret_patterns=("password" "api_key" "secret" "token=")
    for pattern in "${secret_patterns[@]}"; do
        if grep -riqE "${pattern}[[:space:]]*=" "${TEMPLATES_DIR}"/*.tmpl 2>/dev/null; then
            has_secrets=true
            break
        fi
    done

    if [[ "${has_secrets}" == "false" ]]; then
        log_ok "No hardcoded secrets in templates"
        passed=$((passed + 1))
    else
        log_fail "Possible secrets found in templates"
        failed=$((failed + 1))
    fi

    echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
}

# ============================================================
# Main
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_templates_contract
fi
