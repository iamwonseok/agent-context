#!/bin/bash
# Meta-Validation Suite Runner
# Comprehensive validation: Structure + Policies + Patterns

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGS_DIR="${SCRIPT_DIR}/logs"

# Ensure logs directory exists
mkdir -p "${LOGS_DIR}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "Meta-Validation Suite"
echo "=========================================="
echo "Logs: ${LOGS_DIR}"
echo ""
echo "Running 7 validation tests:"
echo "  Level 1: Skills structure"
echo "  Level 2: Workflows structure"
echo "  Level 3: .cursorrules validity"
echo "  Level 4: Complexity budget"
echo "  Level 5: Naming conventions"
echo "  Level 6: Anti-patterns"
echo "  Level 7: Efficiency patterns"
echo ""

# Counter for results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

run_test() {
    local level="$1"
    local test_name="$2"
    local test_script="$3"
    
    echo ""
    echo "[$level] $test_name"
    echo "-------------------------------------------"
    ((TOTAL_TESTS++)) || true
    
    if bash "$test_script"; then
        echo -e "${GREEN}PASSED${NC}: $test_name"
        ((PASSED_TESTS++)) || true
        return 0
    else
        echo -e "${RED}FAILED${NC}: $test_name"
        ((FAILED_TESTS++)) || true
        return 1
    fi
}

# Level 1-3: Original tests
run_test "LEVEL 1" "Skills Structure" "${SCRIPT_DIR}/test_skills_structure.sh" || true
run_test "LEVEL 2" "Workflows Structure" "${SCRIPT_DIR}/test_workflows_structure.sh" || true
run_test "LEVEL 3" ".cursorrules Validation" "${SCRIPT_DIR}/test_cursorrules.sh" || true

# Level 4-7: New policy tests
run_test "LEVEL 4" "Complexity Budget" "${SCRIPT_DIR}/test_complexity_budget.sh" || true
run_test "LEVEL 5" "Naming Conventions" "${SCRIPT_DIR}/test_naming_conventions.sh" || true
run_test "LEVEL 6" "Anti-patterns" "${SCRIPT_DIR}/test_antipatterns.sh" || true
run_test "LEVEL 7" "Efficiency Patterns" "${SCRIPT_DIR}/test_efficiency_patterns.sh" || true

echo ""
echo "=========================================="
echo "All Meta Tests Summary"
echo "=========================================="
echo "Total:  $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo ""

if [ "$FAILED_TESTS" -eq 0 ]; then
    echo -e "${GREEN}All meta tests passed!${NC}"
    echo ""
    echo "Framework is consistent and follows all policies."
    exit 0
else
    echo -e "${RED}Some meta tests failed.${NC}"
    echo ""
    echo "Review logs in: $LOGS_DIR"
    exit 1
fi
