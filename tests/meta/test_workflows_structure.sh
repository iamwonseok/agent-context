#!/bin/bash
# Level 2: Workflows Structure Validation

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
echo "Level 2: Workflows Validation"
echo "=========================================="
echo ""

# Test 1: Developer workflows have validation skills
echo "[TEST] Developer workflows have validation skills"

for wf in "${PROJECT_ROOT}"/workflows/developer/*.md; do
    wf_name=$(basename "$wf")
    if grep -q "validate/run-tests\|validate/check-style" "$wf"; then
        test_pass "Validation in: $wf_name"
    else
        test_warn "No explicit validation: $wf_name"
    fi
done

echo ""

# Test 2: Feature workflow has design-test-plan skill
echo "[TEST] Feature workflow has design-test-plan skill"

if grep -q "planning/design-test-plan" "${PROJECT_ROOT}/workflows/developer/feature.md"; then
    test_pass "feature.md has design-test-plan skill"
else
    test_fail "feature.md missing design-test-plan skill"
fi

echo ""

# Test 3: All workflows have required sections
echo "[TEST] Workflow required sections"

for wf in "${PROJECT_ROOT}"/workflows/*/*.md; do
    wf_name=$(echo "$wf" | sed "s|${PROJECT_ROOT}/workflows/||")
    
    # Skip README files
    if [[ "$wf_name" == *"README"* ]]; then
        continue
    fi
    
    echo "  [$wf_name]"
    
    # Check required YAML fields
    for field in "name:" "description:" "skills:"; do
        if grep -q "$field" "$wf" 2>/dev/null; then
            test_pass "Has: $field"
        else
            test_fail "Missing: $field"
        fi
    done
done

echo ""

# Test 4: All skill references in workflows are valid
echo "[TEST] Skill references validity"

for wf in "${PROJECT_ROOT}"/workflows/*/*.md; do
    # Skip README files
    if [[ "$wf" == *"README"* ]]; then
        continue
    fi
    
    wf_name=$(echo "$wf" | sed "s|${PROJECT_ROOT}/workflows/||")
    
    # Extract skills from YAML frontmatter
    skills=$(sed -n '/^skills:/,/^[a-z].*:/p' "$wf" | grep "^  - " | sed 's/^  - //' | sed 's/ .*//')
    
    for skill in $skills; do
        # Clean up skill name (remove parenthetical notes)
        skill=$(echo "$skill" | sed 's/(.*//')
        
        if [ -d "${PROJECT_ROOT}/skills/${skill}" ]; then
            test_pass "[$wf_name] Skill exists: $skill"
        else
            test_fail "[$wf_name] Skill not found: $skill"
        fi
    done
done

echo ""
echo "=========================================="
echo "Level 2 Results"
echo "=========================================="
echo -e "Total:  ${TOTAL}"
echo -e "Passed: ${GREEN}${PASSED}${NC}"
echo -e "Failed: ${RED}${FAILED}${NC}"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}[LEVEL 2] Workflows validation passed!${NC}"
    exit 0
else
    echo -e "${RED}[LEVEL 2] Workflows validation failed.${NC}"
    exit 1
fi
