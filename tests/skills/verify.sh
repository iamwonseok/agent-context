#!/bin/bash
# Skills Structure Verification Test
# Validates that each skill file follows the expected structure

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SKILLS_DIR="${PROJECT_ROOT}/skills"

# Source logging library
source "${PROJECT_ROOT}/tools/agent/lib/logging.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
TOTAL=0
PASSED=0
FAILED=0

test_pass() {
    echo -e "  ${GREEN}[OK]${NC} $1"
    ((TOTAL++)) || true
    ((PASSED++)) || true
}

test_fail() {
    echo -e "  ${RED}[NG]${NC} $1"
    ((TOTAL++)) || true
    ((FAILED++)) || true
}

section() {
    echo ""
    echo -e "${BLUE}--- $1 ---${NC}"
}

# Expected skills (Thin Skill pattern)
EXPECTED_SKILLS="analyze design implement test review"

# Required sections in each skill file
REQUIRED_SECTIONS=(
    "Interface Definition"
    "Input"
    "Output"
    "Template"
)

# ============================================================
# 1. File Existence Tests
# ============================================================
test_file_existence() {
    section "File Existence Tests"

    for skill in $EXPECTED_SKILLS; do
        local skill_file="${SKILLS_DIR}/${skill}.md"
        if [[ -f "$skill_file" ]]; then
            test_pass "${skill}.md exists"
        else
            test_fail "${skill}.md missing"
        fi
    done

    # Check README exists
    if [[ -f "${SKILLS_DIR}/README.md" ]]; then
        test_pass "README.md exists"
    else
        test_fail "README.md missing"
    fi
}

# ============================================================
# 2. Structure Tests
# ============================================================
test_structure() {
    section "Structure Tests"

    for skill in $EXPECTED_SKILLS; do
        local skill_file="${SKILLS_DIR}/${skill}.md"
        if [[ ! -f "$skill_file" ]]; then
            continue
        fi

        local all_sections_present=true
        local missing=""

        for req_section in "${REQUIRED_SECTIONS[@]}"; do
            if ! grep -q "$req_section" "$skill_file" 2>/dev/null; then
                all_sections_present=false
                missing="${missing} '${req_section}'"
            fi
        done

        if [[ "$all_sections_present" == "true" ]]; then
            test_pass "${skill}.md has all required sections"
        else
            test_fail "${skill}.md missing:${missing}"
        fi
    done
}

# ============================================================
# 3. Title Tests
# ============================================================
test_titles() {
    section "Title Tests"

    for skill in $EXPECTED_SKILLS; do
        local skill_file="${SKILLS_DIR}/${skill}.md"
        if [[ ! -f "$skill_file" ]]; then
            continue
        fi

        # Check first line is a H1 title
        local first_line
        first_line=$(head -1 "$skill_file")

        if [[ "$first_line" =~ ^#[^#] ]]; then
            # Extract title (remove # prefix)
            local title="${first_line#\# }"
            test_pass "${skill}.md has H1 title: '${title}'"
        else
            test_fail "${skill}.md missing H1 title"
        fi
    done
}

# ============================================================
# 4. Input/Output Tests
# ============================================================
test_interface() {
    section "Interface Tests"

    for skill in $EXPECTED_SKILLS; do
        local skill_file="${SKILLS_DIR}/${skill}.md"
        if [[ ! -f "$skill_file" ]]; then
            continue
        fi

        # Check for Input section with parameters
        if grep -qE "^\*\*Input.*\*\*:?" "$skill_file" 2>/dev/null; then
            # Check for at least one input parameter
            if grep -A5 "Input" "$skill_file" | grep -qE "^-\s+\`" 2>/dev/null; then
                test_pass "${skill}.md has input parameters"
            else
                test_fail "${skill}.md missing input parameters"
            fi
        else
            test_fail "${skill}.md missing Input section"
        fi

        # Check for Output section
        if grep -q "Output" "$skill_file" 2>/dev/null; then
            test_pass "${skill}.md has Output section"
        else
            test_fail "${skill}.md missing Output section"
        fi
    done
}

# ============================================================
# 5. Checklist Tests
# ============================================================
test_checklist() {
    section "Checklist Tests"

    for skill in $EXPECTED_SKILLS; do
        local skill_file="${SKILLS_DIR}/${skill}.md"
        if [[ ! -f "$skill_file" ]]; then
            continue
        fi

        # Check for checklist items (- [ ] or * [ ])
        if grep -qE "^[-*]\s+\[\s\]" "$skill_file" 2>/dev/null; then
            local count
            count=$(grep -cE "^[-*]\s+\[\s\]" "$skill_file" 2>/dev/null || echo "0")
            test_pass "${skill}.md has checklist (${count} items)"
        else
            # Checklist is optional
            echo -e "  ${YELLOW}[--]${NC} ${skill}.md no checklist (optional)"
        fi
    done
}

# ============================================================
# 6. No Context Tests (Thin Skill pattern)
# ============================================================
test_no_context() {
    section "No Context Tests (Thin Skill pattern)"

    # Skills should NOT contain project-specific context
    local forbidden_patterns=(
        "JIRA"
        "PROJ-[0-9]"
        "TASK-[0-9]"
        "gitlab.com"
        "github.com"
    )

    for skill in $EXPECTED_SKILLS; do
        local skill_file="${SKILLS_DIR}/${skill}.md"
        if [[ ! -f "$skill_file" ]]; then
            continue
        fi

        local has_context=false
        local found=""

        for pattern in "${forbidden_patterns[@]}"; do
            if grep -qE "$pattern" "$skill_file" 2>/dev/null; then
                has_context=true
                found="${found} '${pattern}'"
            fi
        done

        if [[ "$has_context" == "false" ]]; then
            test_pass "${skill}.md is context-free (thin)"
        else
            test_fail "${skill}.md contains context:${found}"
        fi
    done
}

# ============================================================
# 7. Log Skill Execution (for agent tracking)
# ============================================================
log_skill_verification() {
    section "Skill Verification Log"

    # Create a sequence log for this verification run
    seq_log_start "skill-verify" "Skill structure verification"
    seq_log_workflow_begin "tests/skills" "Manual test run"

    for skill in $EXPECTED_SKILLS; do
        seq_log_skill_begin "$skill"
        local skill_file="${SKILLS_DIR}/${skill}.md"
        if [[ -f "$skill_file" ]]; then
            seq_log_skill_end "$skill" "OK"
        else
            seq_log_skill_end "$skill" "NG"
        fi
    done

    seq_log_workflow_end "tests/skills" "OK" "$(echo $EXPECTED_SKILLS | wc -w | tr -d ' ') skills verified"
    local log_file
    log_file=$(AGENT_LOG_VERBOSE=0 seq_log_end "OK")

    if [[ -n "$log_file" ]] && [[ -f "$log_file" ]]; then
        echo -e "  ${GREEN}[OK]${NC} Log created: $log_file"
    else
        echo -e "  ${YELLOW}[--]${NC} Log not created"
    fi
}

# ============================================================
# Main
# ============================================================
main() {
    echo "=========================================="
    echo "Skills Structure Verification"
    echo "=========================================="
    echo "Skills Dir: ${SKILLS_DIR}"
    echo "Expected:   ${EXPECTED_SKILLS}"
    echo ""

    # Run tests
    test_file_existence
    test_structure
    test_titles
    test_interface
    test_checklist
    test_no_context
    log_skill_verification

    echo ""
    echo "=========================================="
    echo "Skills Test Results"
    echo "=========================================="
    echo -e "Total:  ${TOTAL}"
    echo -e "Passed: ${GREEN}${PASSED}${NC}"
    echo -e "Failed: ${RED}${FAILED}${NC}"
    echo ""

    if [[ "$FAILED" -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        exit 1
    fi
}

main "$@"
