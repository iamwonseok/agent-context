#!/bin/bash
# Level 3: .cursorrules Validation
# Implements feedback from multi-model review (Claude Opus, Gemini, Sonnet)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counters
TOTAL=0
PASSED=0
FAILED=0

test_pass() {
    echo -e "  ${GREEN}(v)${NC} $1"
    ((TOTAL++)) || true
    ((PASSED++)) || true
}

test_fail() {
    echo -e "  ${RED}(x)${NC} $1"
    ((TOTAL++)) || true
    ((FAILED++)) || true
}

test_warn() {
    echo -e "  ${YELLOW}(!)${NC} $1"
}

echo "=========================================="
echo "Level 3: .cursorrules Validation"
echo "=========================================="
echo ""

# Test 1: Required sections exist
echo "[TEST] Required sections in .cursorrules"

sections=(
    "Agent Behavior"
    "Language Policy"
    "Batch Operations"
    "Common Task Patterns"
    "Skills & Workflows"
)

for sec in "${sections[@]}"; do
    if grep -q "## $sec\|### $sec" "${PROJECT_ROOT}/.cursorrules"; then
        test_pass "Section exists: $sec"
    else
        test_fail "Missing section: $sec"
    fi
done

echo ""

# Test 2: Workflow file references are valid (exclude glob patterns in tables)
echo "[TEST] Workflow file references validity"

# Extract explicit workflow file references (not glob patterns, not in tables)
# Look for patterns like: workflows/developer/feature.md
refs=$(grep -o 'workflows/[a-z]*/[a-z-]*\.md' "${PROJECT_ROOT}/.cursorrules" | sort -u || true)

if [ -n "$refs" ]; then
    while read -r ref; do
        if [ -f "${PROJECT_ROOT}/$ref" ]; then
            test_pass "Valid reference: $ref"
        else
            test_fail "Broken reference: $ref"
        fi
    done <<< "$refs"
else
    test_pass "No explicit workflow file references (uses patterns)"
fi

echo ""

# Test 3: Skill directory references are valid
echo "[TEST] Skill directory references"

# Extract skill paths like skills/category/name (not including file extensions)
skill_refs=$(grep -o 'skills/[a-z]*/[a-z-]*' "${PROJECT_ROOT}/.cursorrules" | \
    grep -v '\.' | grep -v 'README' | grep -v '_template' | \
    grep -v '\*' | sort -u || true)

if [ -n "$skill_refs" ]; then
    while read -r skill; do
        if [ -d "${PROJECT_ROOT}/$skill" ]; then
            test_pass "Skill exists: $skill"
        else
            test_fail "Skill not found: $skill"
        fi
    done <<< "$skill_refs"
else
    test_pass "No explicit skill directory references"
fi

echo ""

# Test 4: Language policy consistency
echo "[TEST] Language policy consistency"

if grep -q "Enforcement Matrix" "${PROJECT_ROOT}/.cursorrules"; then
    test_pass "Language policy has Enforcement Matrix"
else
    test_warn "No Enforcement Matrix found"
fi

# Check skills/workflows policy
if grep -q "Skills.*Required.*Forbidden\|Workflows.*Required.*Forbidden" "${PROJECT_ROOT}/.cursorrules"; then
    test_pass "Skills/Workflows language policy defined"
else
    test_warn "Skills/Workflows language policy unclear"
fi

echo ""

# Test 5: Workflow path format (developer/manager/ structure)
echo "[TEST] Workflow path format"

# Workflow references should use developer/ or manager/ subdirectories
old_format=$(grep -o 'workflows/[a-z-]*\.md' "${PROJECT_ROOT}/.cursorrules" | \
    grep -v 'developer\|manager\|README' || true)

if [ -z "$old_format" ]; then
    test_pass "Workflow paths use developer/manager/ structure"
else
    test_warn "Some workflow paths may use old format"
fi

echo ""

# Test 6: Complexity budget documentation
echo "[TEST] Complexity budget documentation"

if grep -q "Complexity Budget" "${PROJECT_ROOT}/.cursorrules"; then
    test_pass "Complexity Budget section exists"
    
    if grep -q "200 lines" "${PROJECT_ROOT}/.cursorrules" && \
       grep -q "100 lines" "${PROJECT_ROOT}/.cursorrules"; then
        test_pass "Complexity limits documented (200/100 lines)"
    else
        test_warn "Complexity limits not clear"
    fi
else
    test_warn "No Complexity Budget section"
fi

echo ""
echo "=========================================="
echo "Level 3 Results"
echo "=========================================="
echo -e "Total:  ${TOTAL}"
echo -e "Passed: ${GREEN}${PASSED}${NC}"
echo -e "Failed: ${RED}${FAILED}${NC}"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}[LEVEL 3] .cursorrules validation passed!${NC}"
    exit 0
else
    echo -e "${RED}[LEVEL 3] .cursorrules validation failed.${NC}"
    exit 1
fi
