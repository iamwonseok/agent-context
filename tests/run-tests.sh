#!/bin/bash
# Agent-Context Test Runner
# Runs all test stages in sequence
#
# Usage:
#   ./tests/run-tests.sh                    # Run stages 1-2 (no tokens required)
#   ./tests/run-tests.sh --stages=1,2,3     # Run specific stages
#   ./tests/run-tests.sh --all              # Run all stages (requires tokens)
#
# Stages:
#   1: Smoke tests (no remote, no tokens)
#   2: Local Git tests (bare repo as remote)
#   3: E2E tests (requires GitLab/JIRA tokens)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_CONTEXT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default stages
STAGES="1,2"

# Parse arguments
for arg in "$@"; do
    case $arg in
        --stages=*)
            STAGES="${arg#*=}"
            ;;
        --all)
            STAGES="1,2,3"
            ;;
        --help|-h)
            echo "Usage: run-tests.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --stages=1,2,3  Run specific stages (default: 1,2)"
            echo "  --all           Run all stages including E2E"
            echo "  --help, -h      Show this help message"
            echo ""
            echo "Stages:"
            echo "  1: Smoke tests (no remote, no tokens)"
            echo "  2: Local Git tests (bare repo as remote)"
            echo "  3: E2E tests (requires GitLab/JIRA tokens)"
            echo ""
            echo "Examples:"
            echo "  ./tests/run-tests.sh                 # Run stages 1-2"
            echo "  ./tests/run-tests.sh --stages=1     # Run only stage 1"
            echo "  ./tests/run-tests.sh --all          # Run all stages"
            exit 0
            ;;
    esac
done

echo "=========================================="
echo "Agent-Context Test Suite"
echo "=========================================="
echo "Agent-context: ${AGENT_CONTEXT_DIR}"
echo "Stages: ${STAGES}"
echo ""

TOTAL_STAGES=0
PASSED_STAGES=0
FAILED_STAGES=0

run_stage() {
    local stage_num="$1"
    local stage_name="$2"
    local stage_script="$3"
    
    ((TOTAL_STAGES++)) || true
    
    echo ""
    echo -e "${BLUE}------------------------------------------${NC}"
    echo -e "${BLUE}Stage ${stage_num}: ${stage_name}${NC}"
    echo -e "${BLUE}------------------------------------------${NC}"
    
    if [ ! -f "$stage_script" ]; then
        echo -e "${RED}[ERROR]${NC} Script not found: $stage_script"
        ((FAILED_STAGES++)) || true
        return 1
    fi
    
    if bash "$stage_script"; then
        echo -e "${GREEN}[STAGE ${stage_num} PASSED]${NC}"
        ((PASSED_STAGES++)) || true
        return 0
    else
        echo -e "${RED}[STAGE ${stage_num} FAILED]${NC}"
        ((FAILED_STAGES++)) || true
        return 1
    fi
}

# Run selected stages
IFS=',' read -ra STAGE_ARRAY <<< "$STAGES"
for stage in "${STAGE_ARRAY[@]}"; do
    case $stage in
        1)
            run_stage 1 "Smoke Tests" "${SCRIPT_DIR}/smoke/test_smoke.sh" || true
            ;;
        2)
            run_stage 2 "Local Git Tests" "${SCRIPT_DIR}/local-git/test_local_git.sh" || true
            ;;
        3)
            run_stage 3 "E2E Tests" "${SCRIPT_DIR}/e2e/test_e2e.sh" || true
            ;;
        *)
            echo -e "${YELLOW}[WARN]${NC} Unknown stage: $stage"
            ;;
    esac
done

# Summary
echo ""
echo "=========================================="
echo "Test Suite Summary"
echo "=========================================="
echo -e "Total Stages:  ${TOTAL_STAGES}"
echo -e "Passed:        ${GREEN}${PASSED_STAGES}${NC}"
echo -e "Failed:        ${RED}${FAILED_STAGES}${NC}"
echo ""

if [ "$FAILED_STAGES" -eq 0 ]; then
    echo -e "${GREEN}All test stages passed!${NC}"
    exit 0
else
    echo -e "${RED}Some test stages failed.${NC}"
    exit 1
fi
