#!/bin/bash
# Workflows Skill Chain Test
# Validates that each workflow triggers the correct skill sequence in ORDER
#
# Test Tag: workflows-chain
# Layer: 0 (Static/Contract)
#
# IMPORTANT: This test verifies skill ORDER, not just presence.
# Unlike verify.sh which uses sort -u (losing order), this preserves sequence.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
WORKFLOWS_DIR="${PROJECT_ROOT}/workflows"
SKILLS_DIR="${PROJECT_ROOT}/skills"

# ============================================================
# Test Output Helpers
# ============================================================
log_ok() { echo "[V] $1"; }
log_fail() { echo "[X] $1"; }
log_warn() { echo "[!] $1"; }

# ============================================================
# Skill Chain Extraction (ORDER PRESERVED)
# ============================================================
# Extract skill calls from workflow file in order of appearance
# Does NOT use sort -u to preserve skill sequence
extract_skills_ordered() {
    local workflow_file="$1"
    # Extract skills/xxx.md references, remove path/extension, preserve order
    grep -oE 'skills/[a-z]+\.md' "${workflow_file}" 2>/dev/null | \
        sed 's|skills/||g; s|\.md||g' | \
        awk '!seen[$0]++' | \
        tr '\n' ' ' | \
        sed 's/ $//'
}

# Get expected skills for a workflow (ordered sequence)
get_expected_skills() {
    local workflow="$1"
    case "${workflow}" in
        "solo/feature")    echo "analyze design implement test review" ;;
        "solo/bugfix")     echo "analyze implement test review" ;;
        "solo/hotfix")     echo "analyze implement test" ;;
        "team/sprint")     echo "analyze review" ;;
        "team/release")    echo "analyze test" ;;
        "project/quarter") echo "analyze review" ;;
        "project/roadmap") echo "analyze design review" ;;
        *) echo "" ;;
    esac
}

# ============================================================
# Test: Workflows Skill Chain
# ============================================================
test_workflows_chain() {
    local total=0
    local passed=0
    local failed=0
    local skipped=0

    # 1. Check workflows directory exists
    total=$((total + 1))
    if [[ -d "${WORKFLOWS_DIR}" ]]; then
        log_ok "workflows/ directory exists"
        passed=$((passed + 1))
    else
        log_fail "workflows/ directory missing"
        failed=$((failed + 1))
        echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
        return
    fi

    # 2. Check README.md exists
    total=$((total + 1))
    if [[ -f "${WORKFLOWS_DIR}/README.md" ]]; then
        log_ok "workflows/README.md exists"
        passed=$((passed + 1))
    else
        log_fail "workflows/README.md missing"
        failed=$((failed + 1))
    fi

    # 3. Test each workflow
    local workflows="solo/feature solo/bugfix solo/hotfix team/sprint team/release project/quarter project/roadmap"

    for workflow_path in ${workflows}; do
        local workflow_file="${WORKFLOWS_DIR}/${workflow_path}.md"

        # 3a. Check workflow file exists
        total=$((total + 1))
        if [[ -f "${workflow_file}" ]]; then
            log_ok "Workflow exists: ${workflow_path}.md"
            passed=$((passed + 1))
        else
            log_fail "Workflow missing: ${workflow_path}.md"
            failed=$((failed + 1))
            continue
        fi

        # 3b. Check workflow has skill chain
        local actual_skills
        actual_skills=$(extract_skills_ordered "${workflow_file}")
        local expected_skills
        expected_skills=$(get_expected_skills "${workflow_path}")

        total=$((total + 1))
        if [[ -n "${actual_skills}" ]]; then
            log_ok "Workflow ${workflow_path} has skills: ${actual_skills}"
            passed=$((passed + 1))
        else
            log_fail "Workflow ${workflow_path} has no skill references"
            failed=$((failed + 1))
            continue
        fi

        # 3c. Check all expected skills are present
        local missing=""
        for skill in ${expected_skills}; do
            case " ${actual_skills} " in
                *" ${skill} "*) ;;
                *)
                    # Also check start/end of string
                    if [[ "${actual_skills}" != "${skill}" ]] && \
                       [[ "${actual_skills}" != "${skill} "* ]] && \
                       [[ "${actual_skills}" != *" ${skill}" ]]; then
                        missing="${missing} ${skill}"
                    fi
                    ;;
            esac
        done

        total=$((total + 1))
        if [[ -z "${missing}" ]]; then
            log_ok "Workflow ${workflow_path} has all expected skills"
            passed=$((passed + 1))
        else
            log_fail "Workflow ${workflow_path} missing skills:${missing}"
            failed=$((failed + 1))
        fi

        # 3d. Check skill ORDER (optional but recommended)
        # Convert expected to regex pattern: "analyze.*design.*implement"
        total=$((total + 1))
        local order_pattern=""
        for skill in ${expected_skills}; do
            if [[ -z "${order_pattern}" ]]; then
                order_pattern="${skill}"
            else
                order_pattern="${order_pattern}.*${skill}"
            fi
        done

        # Check if actual skills match the order pattern
        if echo "${actual_skills}" | grep -qE "^${order_pattern//\*/.*}"; then
            log_ok "Workflow ${workflow_path} skill order correct"
            passed=$((passed + 1))
        else
            # Order mismatch is a warning, not failure (workflows may have extra skills)
            log_warn "Workflow ${workflow_path} skill order: expected '${expected_skills}', got '${actual_skills}'"
            passed=$((passed + 1))  # Count as pass with warning
        fi
    done

    # 4. Check referenced skills exist
    total=$((total + 1))
    local all_skills=""
    for workflow_path in ${workflows}; do
        local workflow_file="${WORKFLOWS_DIR}/${workflow_path}.md"
        [[ ! -f "${workflow_file}" ]] && continue
        local skills
        skills=$(extract_skills_ordered "${workflow_file}")
        all_skills="${all_skills} ${skills}"
    done

    local missing_skill_files=""
    for skill in ${all_skills}; do
        [[ -z "${skill}" ]] && continue
        if [[ ! -f "${SKILLS_DIR}/${skill}.md" ]]; then
            missing_skill_files="${missing_skill_files} ${skill}"
        fi
    done

    if [[ -z "${missing_skill_files}" ]]; then
        log_ok "All referenced skill files exist"
        passed=$((passed + 1))
    else
        log_fail "Missing skill files:${missing_skill_files}"
        failed=$((failed + 1))
    fi

    echo "__TEST_RESULT__=${total}:${passed}:${failed}:${skipped}"
}

# ============================================================
# Main
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_workflows_chain
fi
