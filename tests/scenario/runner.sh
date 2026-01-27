#!/bin/bash
# Scenario Test Runner
# Executes scenario documents and validates results
#
# Usage:
#   ./runner.sh                      # Run all scenarios
#   ./runner.sh --scenario=001       # Run specific scenario
#   ./runner.sh --list               # List available scenarios
#   ./runner.sh --dry-run            # Show commands without executing
#   ./runner.sh --quick              # Run only core scenarios (001,011,012,013)
#   ./runner.sh --junit=report.xml   # Output JUnit XML

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_CONTEXT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source libraries
source "${SCRIPT_DIR}/lib/parser.sh"
source "${SCRIPT_DIR}/lib/executor.sh"
source "${SCRIPT_DIR}/lib/validator.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Options
DRY_RUN=false
QUICK_MODE=false
SCENARIO_FILTER=""
JUNIT_OUTPUT=""
VERBOSE=false

# Counters
TOTAL_SCENARIOS=0
PASSED_SCENARIOS=0
FAILED_SCENARIOS=0
SKIPPED_SCENARIOS=0

# Core scenarios for quick mode
CORE_SCENARIOS=("001" "011" "012" "013")

# Parse arguments
parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --scenario=*)
                SCENARIO_FILTER="${1#--scenario=}"
                ;;
            --list)
                list_available_scenarios
                exit 0
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --quick)
                QUICK_MODE=true
                ;;
            --junit=*)
                JUNIT_OUTPUT="${1#--junit=}"
                ;;
            --verbose|-v)
                VERBOSE=true
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

show_help() {
    cat << 'EOF'
Scenario Test Runner

Usage:
    ./runner.sh [options]

Options:
    --scenario=NNN    Run specific scenario (e.g., --scenario=001)
    --list            List available scenarios
    --dry-run         Show commands without executing
    --quick           Run only core scenarios (001,011,012,013)
    --junit=FILE      Output JUnit XML report
    --verbose, -v     Show detailed output
    --help, -h        Show this help

Examples:
    ./runner.sh                      # Run all scenarios
    ./runner.sh --scenario=001       # Run scenario 001 only
    ./runner.sh --quick --dry-run    # Preview core scenarios
    ./runner.sh --junit=results.xml  # Generate JUnit report

Environment Variables:
    GITLAB_API_TOKEN    Required for GitLab scenarios
    GITHUB_TOKEN        Required for GitHub scenarios
    JIRA_API_TOKEN      Required for JIRA scenarios
    JIRA_EMAIL          Required for JIRA Cloud

EOF
}

list_available_scenarios() {
    echo ""
    echo -e "${BLUE}=== Available Scenarios ===${NC}"
    echo ""
    
    local scenarios
    scenarios=$(list_scenarios "$SCRIPT_DIR")
    
    for file in $scenarios; do
        local num
        num=$(get_scenario_number "$file")
        local name
        name=$(basename "$file" .md)
        
        # Get title
        local title
        title=$(head -1 "$file" | sed 's/^#[[:space:]]*//')
        
        # Mark core scenarios
        local marker=""
        if [[ " ${CORE_SCENARIOS[*]} " =~ " ${num} " ]]; then
            marker=" [core]"
        fi
        
        echo -e "  ${GREEN}${num}${NC}: ${title}${marker}"
    done
    
    echo ""
    echo "Total: $(echo "$scenarios" | wc -l | tr -d ' ') scenarios"
}

# Check prerequisites for a scenario
check_scenario_prerequisites() {
    local scenario_file="$1"
    local missing=()
    
    # Check for required tokens based on scenario content
    if grep -qE 'gitlab|GitLab' "$scenario_file"; then
        if [ -z "$GITLAB_API_TOKEN" ] && [ -z "$GITLAB_TOKEN" ]; then
            missing+=("GITLAB_API_TOKEN")
        fi
    fi
    
    if grep -qE 'github|GitHub' "$scenario_file"; then
        if [ -z "$GITHUB_TOKEN" ] && [ -z "$GH_TOKEN" ]; then
            missing+=("GITHUB_TOKEN")
        fi
    fi
    
    if grep -qE 'jira|JIRA' "$scenario_file"; then
        if [ -z "$JIRA_API_TOKEN" ] && [ -z "$JIRA_TOKEN" ]; then
            missing+=("JIRA_API_TOKEN")
        fi
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "${missing[*]}"
        return 1
    fi
    
    return 0
}

# Run a single scenario
run_scenario() {
    local scenario_file="$1"
    local scenario_num
    scenario_num=$(get_scenario_number "$scenario_file")
    local scenario_name
    scenario_name=$(basename "$scenario_file" .md)
    
    echo ""
    echo -e "${BLUE}=========================================="
    echo "Scenario ${scenario_num}: ${scenario_name}"
    echo -e "==========================================${NC}"
    
    # Parse metadata
    local metadata
    metadata=$(parse_scenario_metadata "$scenario_file")
    local title
    title=$(echo "$metadata" | grep "^TITLE:" | cut -d: -f2-)
    
    echo "Title: ${title}"
    
    # Check prerequisites
    local missing_prereqs
    if ! missing_prereqs=$(check_scenario_prerequisites "$scenario_file"); then
        echo -e "${YELLOW}[SKIP]${NC} Missing prerequisites: ${missing_prereqs}"
        ((SKIPPED_SCENARIOS++))
        return 0
    fi
    
    # Parse and execute commands
    local passed=0
    local failed=0
    local skipped=0
    local step=0
    
    # Create temp work directory
    local work_dir="/tmp/scenario-test-${scenario_num}-$$"
    setup_test_env "$work_dir"
    cd "$work_dir" || return 1
    
    # Parse commands
    local commands
    commands=$(parse_scenario_commands "$scenario_file")
    
    # Process each step
    local current_cmd=""
    while IFS= read -r line; do
        case "$line" in
            STEP:*)
                step="${line#STEP:}"
                ;;
            CMD:*)
                current_cmd="${line#CMD:}"
                ;;
            ---)
                if [ -n "$current_cmd" ]; then
                    echo ""
                    echo -e "  ${BLUE}Step ${step}:${NC}"
                    
                    # Show command (truncated if long)
                    local display_cmd
                    display_cmd=$(echo "$current_cmd" | head -1)
                    if [ ${#display_cmd} -gt 60 ]; then
                        display_cmd="${display_cmd:0:57}..."
                    fi
                    echo "    Command: ${display_cmd}"
                    
                    # Execute
                    if execute_with_dry_run "$current_cmd" "$DRY_RUN"; then
                        if [ "$EXEC_OUTPUT" = "[SKIP:gitlab]" ] || \
                           [ "$EXEC_OUTPUT" = "[SKIP:github]" ] || \
                           [ "$EXEC_OUTPUT" = "[SKIP:jira]" ]; then
                            echo -e "    ${YELLOW}[SKIP]${NC} Service not available"
                            ((skipped++))
                        elif [ "$EXEC_OUTPUT" = "[DRY-RUN]" ]; then
                            echo -e "    ${YELLOW}[DRY-RUN]${NC}"
                            ((skipped++))
                        else
                            echo -e "    ${GREEN}[PASS]${NC} (${EXEC_DURATION}s)"
                            [ "$VERBOSE" = true ] && echo "    Output: ${EXEC_OUTPUT:0:100}"
                            ((passed++))
                        fi
                    else
                        echo -e "    ${RED}[FAIL]${NC} Exit code: ${EXEC_EXIT_CODE}"
                        [ "$VERBOSE" = true ] && echo "    Output: ${EXEC_OUTPUT:0:200}"
                        ((failed++))
                    fi
                    
                    current_cmd=""
                fi
                ;;
        esac
    done <<< "$commands"
    
    # Cleanup
    cd "$AGENT_CONTEXT_DIR" || true
    cleanup_test_env "$work_dir"
    
    # Report
    local total=$((passed + failed + skipped))
    echo ""
    echo "  Summary: ${passed} passed, ${failed} failed, ${skipped} skipped (${total} total)"
    
    if [ "$failed" -eq 0 ]; then
        echo -e "  ${GREEN}SCENARIO PASSED${NC}"
        ((PASSED_SCENARIOS++))
        return 0
    else
        echo -e "  ${RED}SCENARIO FAILED${NC}"
        ((FAILED_SCENARIOS++))
        return 1
    fi
}

# Generate JUnit XML report
generate_junit_xml() {
    local output_file="$1"
    
    cat > "$output_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="scenario-tests" tests="${TOTAL_SCENARIOS}" failures="${FAILED_SCENARIOS}" skipped="${SKIPPED_SCENARIOS}" time="0">
EOF
    
    # Add individual test results (simplified)
    local scenarios
    scenarios=$(list_scenarios "$SCRIPT_DIR")
    
    for file in $scenarios; do
        local name
        name=$(basename "$file" .md)
        echo "  <testcase classname=\"scenarios\" name=\"${name}\" time=\"0\"/>" >> "$output_file"
    done
    
    echo "</testsuite>" >> "$output_file"
    
    echo "JUnit report written to: ${output_file}"
}

# Main
main() {
    parse_args "$@"
    
    echo ""
    echo -e "${BLUE}=========================================="
    echo "Scenario Test Runner"
    echo -e "==========================================${NC}"
    echo "Agent-context: ${AGENT_CONTEXT_DIR}"
    echo "Dry-run: ${DRY_RUN}"
    echo "Quick mode: ${QUICK_MODE}"
    
    # Setup environment
    export PATH="${AGENT_CONTEXT_DIR}/tools/agent/bin:${AGENT_CONTEXT_DIR}/tools/pm/bin:$PATH"
    export AGENT_CONTEXT_PATH="${AGENT_CONTEXT_DIR}"
    
    # Get scenarios to run
    local scenarios
    scenarios=$(list_scenarios "$SCRIPT_DIR")
    
    # Filter scenarios
    if [ -n "$SCENARIO_FILTER" ]; then
        scenarios=$(echo "$scenarios" | grep "${SCENARIO_FILTER}" || true)
    fi
    
    if [ "$QUICK_MODE" = true ]; then
        local filtered=""
        for num in "${CORE_SCENARIOS[@]}"; do
            local match
            match=$(echo "$scenarios" | grep "/${num}-" || true)
            [ -n "$match" ] && filtered="${filtered}${match}"$'\n'
        done
        scenarios=$(echo "$filtered" | grep -v '^$')
    fi
    
    # Count scenarios
    TOTAL_SCENARIOS=$(echo "$scenarios" | grep -c -v '^$' || echo 0)
    
    if [ "$TOTAL_SCENARIOS" -eq 0 ]; then
        echo ""
        echo -e "${YELLOW}No scenarios found matching criteria${NC}"
        exit 0
    fi
    
    echo "Scenarios to run: ${TOTAL_SCENARIOS}"
    
    # Run scenarios
    local scenario_result=0
    for file in $scenarios; do
        [ -z "$file" ] && continue
        run_scenario "$file" || scenario_result=1
    done
    
    # Summary
    echo ""
    echo -e "${BLUE}=========================================="
    echo "Final Summary"
    echo -e "==========================================${NC}"
    echo "Total Scenarios: ${TOTAL_SCENARIOS}"
    echo -e "Passed: ${GREEN}${PASSED_SCENARIOS}${NC}"
    echo -e "Failed: ${RED}${FAILED_SCENARIOS}${NC}"
    echo -e "Skipped: ${YELLOW}${SKIPPED_SCENARIOS}${NC}"
    echo ""
    
    # Generate JUnit if requested
    if [ -n "$JUNIT_OUTPUT" ]; then
        generate_junit_xml "$JUNIT_OUTPUT"
    fi
    
    # Exit status
    if [ "$FAILED_SCENARIOS" -eq 0 ]; then
        echo -e "${GREEN}All scenarios passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some scenarios failed.${NC}"
        exit 1
    fi
}

main "$@"
