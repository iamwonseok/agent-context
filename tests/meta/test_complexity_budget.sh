#!/bin/bash
# Complexity Budget Validation
# Enforces line limits per ARCHITECTURE.md and policies/README.md

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

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

test_warn() {
    echo -e "  ${YELLOW}[!!]${NC} $1"
}

section() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Complexity Budget Limits (from ARCHITECTURE.md)
SKILL_MAX=200
WORKFLOW_MAX=100
CLI_CMD_MAX=100
HELPER_LIB_MAX=300

check_file_complexity() {
    local file="$1"
    local max_lines="$2"
    local label="$3"
    
    if [ ! -f "$file" ]; then
        return
    fi
    
    local lines=$(wc -l < "$file" | tr -d ' ')
    local filename=$(basename "$file")
    
    if [ "$lines" -le "$max_lines" ]; then
        test_pass "$label: $filename ($lines/$max_lines lines)"
    else
        test_fail "$label: $filename ($lines/$max_lines lines) - EXCEEDS LIMIT"
    fi
}

# Test 1: Skills (max 200 lines)
test_skills_complexity() {
    section "Skills Complexity (max ${SKILL_MAX} lines)"
    
    local skill_count=0
    
    for skill_file in "${PROJECT_ROOT}"/skills/*/*/SKILL.md; do
        if [ -f "$skill_file" ]; then
            check_file_complexity "$skill_file" "$SKILL_MAX" "Skill"
            ((skill_count++)) || true
        fi
    done
    
    if [ "$skill_count" -eq 0 ]; then
        test_warn "No skill files found"
    fi
}

# Test 2: Workflows (max 100 lines)
test_workflows_complexity() {
    section "Workflows Complexity (max ${WORKFLOW_MAX} lines)"
    
    local workflow_count=0
    
    for workflow_file in "${PROJECT_ROOT}"/workflows/*/*.md; do
        if [ -f "$workflow_file" ] && [ "$(basename "$workflow_file")" != "README.md" ]; then
            check_file_complexity "$workflow_file" "$WORKFLOW_MAX" "Workflow"
            ((workflow_count++)) || true
        fi
    done
    
    if [ "$workflow_count" -eq 0 ]; then
        test_warn "No workflow files found"
    fi
}

# Test 3: CLI Commands (max 100 lines)
test_cli_complexity() {
    section "CLI Commands Complexity (max ${CLI_CMD_MAX} lines)"
    
    local cli_count=0
    
    # Check agent CLI functions
    for cli_file in "${PROJECT_ROOT}"/tools/agent/lib/*.sh; do
        if [ -f "$cli_file" ]; then
            check_file_complexity "$cli_file" "$CLI_CMD_MAX" "CLI Lib"
            ((cli_count++)) || true
        fi
    done
    
    # Check pm CLI functions
    for cli_file in "${PROJECT_ROOT}"/tools/pm/lib/*.sh; do
        if [ -f "$cli_file" ]; then
            check_file_complexity "$cli_file" "$CLI_CMD_MAX" "PM Lib"
            ((cli_count++)) || true
        fi
    done
    
    if [ "$cli_count" -eq 0 ]; then
        test_warn "No CLI library files found"
    fi
}

# Test 4: Helper Libraries (max 300 lines)
test_helper_complexity() {
    section "Helper Libraries Complexity (max ${HELPER_LIB_MAX} lines)"
    
    local helper_count=0
    
    # Check lint helpers
    for helper_file in "${PROJECT_ROOT}"/tools/lint/scripts/*.sh; do
        if [ -f "$helper_file" ]; then
            check_file_complexity "$helper_file" "$HELPER_LIB_MAX" "Helper"
            ((helper_count++)) || true
        fi
    done
    
    if [ "$helper_count" -eq 0 ]; then
        test_warn "No helper library files found"
    fi
}

# Test 5: Test Fixtures (if exist)
test_fixtures_complexity() {
    section "Test Fixtures (for testing this script)"
    
    local fixtures_dir="${SCRIPT_DIR}/fixtures/complexity"
    
    if [ ! -d "$fixtures_dir" ]; then
        test_warn "No test fixtures directory"
        return
    fi
    
    # Test PASS cases
    if [ -d "$fixtures_dir/pass" ]; then
        for pass_file in "$fixtures_dir"/pass/*.md; do
            if [ -f "$pass_file" ]; then
                local filename=$(basename "$pass_file")
                case "$filename" in
                    skill-*.md)
                        check_file_complexity "$pass_file" "$SKILL_MAX" "Fixture[PASS]"
                        ;;
                    workflow-*.md)
                        check_file_complexity "$pass_file" "$WORKFLOW_MAX" "Fixture[PASS]"
                        ;;
                esac
            fi
        done
    fi
    
    # Test FAIL cases (should exceed limits)
    if [ -d "$fixtures_dir/fail" ]; then
        for fail_file in "$fixtures_dir"/fail/*.md; do
            if [ -f "$fail_file" ]; then
                local filename=$(basename "$fail_file")
                local lines=$(wc -l < "$fail_file" | tr -d ' ')
                
                case "$filename" in
                    skill-*.md)
                        if [ "$lines" -gt "$SKILL_MAX" ]; then
                            test_pass "Fixture[FAIL]: $filename ($lines lines) - correctly exceeds limit"
                        else
                            test_fail "Fixture[FAIL]: $filename ($lines lines) - should exceed $SKILL_MAX"
                        fi
                        ;;
                    workflow-*.md)
                        if [ "$lines" -gt "$WORKFLOW_MAX" ]; then
                            test_pass "Fixture[FAIL]: $filename ($lines lines) - correctly exceeds limit"
                        else
                            test_fail "Fixture[FAIL]: $filename ($lines lines) - should exceed $WORKFLOW_MAX"
                        fi
                        ;;
                esac
            fi
        done
    fi
}

# Main
main() {
    echo "=========================================="
    echo "Complexity Budget Validation"
    echo "=========================================="
    echo "Project: ${PROJECT_ROOT}"
    echo ""
    echo "Limits (from ARCHITECTURE.md):"
    echo "  - Skills: ${SKILL_MAX} lines"
    echo "  - Workflows: ${WORKFLOW_MAX} lines"
    echo "  - CLI Commands: ${CLI_CMD_MAX} lines"
    echo "  - Helper Libraries: ${HELPER_LIB_MAX} lines"
    
    test_skills_complexity
    test_workflows_complexity
    test_cli_complexity
    test_helper_complexity
    test_fixtures_complexity
    
    echo ""
    echo "=========================================="
    echo "Results"
    echo "=========================================="
    echo -e "Total:  ${TOTAL}"
    echo -e "Passed: ${GREEN}${PASSED}${NC}"
    echo -e "Failed: ${RED}${FAILED}${NC}"
    echo ""
    
    if [ "$FAILED" -eq 0 ]; then
        echo -e "${GREEN}[PASS] All complexity budget checks passed!${NC}"
        exit 0
    else
        echo -e "${RED}[FAIL] Some files exceed complexity budget.${NC}"
        exit 1
    fi
}

main "$@"
