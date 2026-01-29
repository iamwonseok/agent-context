#!/bin/bash
# Workflow-Skill Integration Test
# Verifies that each workflow triggers the correct skill sequence
#
# Usage: bash test_workflow_skills.sh [--verbose]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
WORKFLOWS_DIR="${PROJECT_ROOT}/workflows"
SKILLS_DIR="${PROJECT_ROOT}/skills"

# Source logging library
source "${PROJECT_ROOT}/tools/agent/lib/logging.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if space-separated string contains element
string_contains() {
    local element="$1"
    local string="$2"
    for item in $string; do
        [[ "$item" == "$element" ]] && return 0
    done
    return 1
}

VERBOSE=0
[[ "$1" == "--verbose" ]] && VERBOSE=1

# Get expected skills for a workflow
get_expected_skills() {
    local workflow="$1"
    case "$workflow" in
        "solo/feature")  echo "analyze design implement test review" ;;
        "solo/bugfix")   echo "analyze implement test review" ;;
        "solo/hotfix")   echo "analyze implement test" ;;
        "team/sprint")   echo "analyze review" ;;
        "team/release")  echo "analyze test" ;;
        "project/quarter") echo "analyze review" ;;
        "project/roadmap") echo "analyze design review" ;;
        *) echo "" ;;
    esac
}

# Extract skill calls from workflow file
extract_skills() {
    local workflow_file="$1"
    grep -oE 'skills/[a-z]+\.md' "$workflow_file" 2>/dev/null | \
        sed 's|skills/||g; s|\.md||g' | \
        sort -u | \
        tr '\n' ' ' | \
        sed 's/ $//'
}

# Test a single workflow
test_workflow() {
    local workflow_path="$1"
    local workflow_file="${WORKFLOWS_DIR}/${workflow_path}.md"

    if [[ ! -f "$workflow_file" ]]; then
        echo -e "  ${RED}[NG]${NC} File not found: ${workflow_path}.md"
        return 1
    fi

    local actual_skills
    actual_skills=$(extract_skills "$workflow_file")

    local expected_skills
    expected_skills=$(get_expected_skills "$workflow_path")

    if [[ $VERBOSE -eq 1 ]]; then
        echo "  Workflow: ${workflow_path}"
        echo "  Expected: ${expected_skills}"
        echo "  Actual:   ${actual_skills}"
    fi

    # Check if all expected skills are present
    local missing=""
    for skill in $expected_skills; do
        if ! string_contains "$skill" "$actual_skills"; then
            missing="$missing $skill"
        fi
    done

    if [[ -z "$missing" ]]; then
        echo -e "  ${GREEN}[OK]${NC} ${workflow_path}: ${actual_skills}"
        return 0
    else
        echo -e "  ${RED}[NG]${NC} ${workflow_path}: missing${missing}"
        return 1
    fi
}

# Generate sequence log for a workflow run
log_workflow_sequence() {
    local workflow_path="$1"
    local task_id="${2:-TEST-$(date +%s)}"

    local workflow_file="${WORKFLOWS_DIR}/${workflow_path}.md"
    local skills
    skills=$(extract_skills "$workflow_file")

    # Start sequence log
    seq_log_start "$task_id" "Test run for ${workflow_path}"
    seq_log_workflow_begin "$workflow_path"

    # Log each skill call
    for skill in $skills; do
        seq_log_skill_begin "$skill"
        sleep 0.05
        seq_log_skill_end "$skill" "OK"
    done

    seq_log_workflow_end "$workflow_path" "OK" "$(echo $skills | wc -w | tr -d ' ') skills"
    local log_file
    log_file=$(seq_log_end "OK")

    echo "$log_file"
}

# Main
main() {
    echo "=========================================="
    echo "Workflow-Skill Integration Test"
    echo "=========================================="
    echo "Workflows: ${WORKFLOWS_DIR}"
    echo ""

    local total=0
    local passed=0
    local failed=0

    echo -e "${BLUE}--- Skill Sequence Check ---${NC}"

    # Test all workflows
    local workflows="solo/feature solo/bugfix solo/hotfix team/sprint team/release project/quarter project/roadmap"

    for workflow_path in $workflows; do
        ((total++)) || true
        if test_workflow "$workflow_path"; then
            ((passed++)) || true
        else
            ((failed++)) || true
        fi
    done

    echo ""
    echo -e "${BLUE}--- Sequence Log Test ---${NC}"

    # Generate a sample sequence log
    echo "  Generating sequence log for solo/feature..."
    local log_file
    log_file=$(AGENT_LOG_VERBOSE=0 log_workflow_sequence "solo/feature" "TEST-001")

    if [[ -n "$log_file" ]] && [[ -f "$log_file" ]]; then
        echo -e "  ${GREEN}[OK]${NC} Log created: $log_file"
        ((passed++)) || true

        if [[ $VERBOSE -eq 1 ]]; then
            echo ""
            echo "  --- Log Content ---"
            cat "$log_file" | sed 's/^/  /'
            echo "  -------------------"
        fi
    else
        echo -e "  ${RED}[NG]${NC} Log creation failed"
        ((failed++)) || true
    fi
    ((total++)) || true

    echo ""
    echo "=========================================="
    echo "Results"
    echo "=========================================="
    echo -e "Total:  ${total}"
    echo -e "Passed: ${GREEN}${passed}${NC}"
    echo -e "Failed: ${RED}${failed}${NC}"
    echo ""

    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        exit 1
    fi
}

main "$@"
