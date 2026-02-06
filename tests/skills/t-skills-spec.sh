#!/bin/bash
# Skills Specification Test
# Validates that each skill file follows the expected structure (Thin Skill pattern)
#
# Test Tag: skills-spec
# Layer: 0 (Static/Contract)
#
# This test wraps and extends tests/skills/verify.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SKILLS_DIR="${PROJECT_ROOT}/skills"

# ============================================================
# Test Output Helpers
# ============================================================
log_ok() { echo "[V] $1"; }
log_fail() { echo "[X] $1"; }
log_warn() { echo "[!] $1"; }

# ============================================================
# Test: Skills Specification
# ============================================================
test_skills_spec() {
    local total=0
    local passed=0
    local failed=0
    local skipped=0

    # Expected skills (Thin Skill pattern)
    local expected_skills="analyze design implement test review"

    # Required sections in each skill file
    local required_sections=(
        "Interface Definition"
        "Input"
        "Output"
    )

    # 1. Check skills directory exists
    total=$((total + 1))
    if [[ -d "${SKILLS_DIR}" ]]; then
        log_ok "skills/ directory exists"
        passed=$((passed + 1))
    else
        log_fail "skills/ directory missing"
        failed=$((failed + 1))
        echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
        return
    fi

    # 2. Check README.md exists
    total=$((total + 1))
    if [[ -f "${SKILLS_DIR}/README.md" ]]; then
        log_ok "skills/README.md exists"
        passed=$((passed + 1))
    else
        log_fail "skills/README.md missing"
        failed=$((failed + 1))
    fi

    # 3. Check each expected skill file exists
    for skill in ${expected_skills}; do
        total=$((total + 1))
        local skill_file="${SKILLS_DIR}/${skill}.md"
        if [[ -f "${skill_file}" ]]; then
            log_ok "Skill exists: ${skill}.md"
            passed=$((passed + 1))
        else
            log_fail "Skill missing: ${skill}.md"
            failed=$((failed + 1))
        fi
    done

    # 4. Check required sections in each skill
    for skill in ${expected_skills}; do
        local skill_file="${SKILLS_DIR}/${skill}.md"
        [[ ! -f "${skill_file}" ]] && continue

        for section in "${required_sections[@]}"; do
            total=$((total + 1))
            if grep -q "${section}" "${skill_file}" 2>/dev/null; then
                log_ok "${skill}.md has '${section}' section"
                passed=$((passed + 1))
            else
                log_fail "${skill}.md missing '${section}' section"
                failed=$((failed + 1))
            fi
        done
    done

    # 5. Check H1 title in each skill
    for skill in ${expected_skills}; do
        local skill_file="${SKILLS_DIR}/${skill}.md"
        [[ ! -f "${skill_file}" ]] && continue

        total=$((total + 1))
        local first_line
        first_line=$(head -1 "${skill_file}")
        if [[ "${first_line}" =~ ^#[^#] ]]; then
            log_ok "${skill}.md has H1 title"
            passed=$((passed + 1))
        else
            log_fail "${skill}.md missing H1 title"
            failed=$((failed + 1))
        fi
    done

    # 6. Check Thin Skill pattern (no project-specific context)
    local forbidden_patterns=(
        "JIRA"
        "PROJ-[0-9]"
        "TASK-[0-9]"
        "gitlab.com"
        "github.com"
    )

    for skill in ${expected_skills}; do
        local skill_file="${SKILLS_DIR}/${skill}.md"
        [[ ! -f "${skill_file}" ]] && continue

        total=$((total + 1))
        local has_context=false
        local found_pattern=""

        for pattern in "${forbidden_patterns[@]}"; do
            if grep -qE "${pattern}" "${skill_file}" 2>/dev/null; then
                has_context=true
                found_pattern="${pattern}"
                break
            fi
        done

        if [[ "${has_context}" == "false" ]]; then
            log_ok "${skill}.md is context-free (thin)"
            passed=$((passed + 1))
        else
            log_fail "${skill}.md contains project context: ${found_pattern}"
            failed=$((failed + 1))
        fi
    done

    echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
}

# ============================================================
# Main
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_skills_spec
fi
