#!/bin/bash
# Anti-pattern Detection
# Detects common anti-patterns per ARCHITECTURE.md

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
WARNED=0

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
    ((TOTAL++)) || true
    ((WARNED++)) || true
}

section() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Anti-pattern 1: Deep Nesting (max 2 levels)
test_deep_nesting() {
    section "Anti-pattern: Deep Nesting (max 2 levels)"
    
    # Check skills directory depth
    local deep_skills=$(find "${PROJECT_ROOT}/skills" -mindepth 4 -type d 2>/dev/null || true)
    
    if [ -z "$deep_skills" ]; then
        test_pass "No deep nesting in skills/ (max 2 levels: category/skill-name)"
    else
        echo "$deep_skills" | while read -r deep_dir; do
            local rel_path="${deep_dir#$PROJECT_ROOT/}"
            test_fail "Deep nesting found: $rel_path"
        done
    fi
    
    # Check workflows directory depth
    local deep_workflows=$(find "${PROJECT_ROOT}/workflows" -mindepth 3 -type d 2>/dev/null || true)
    
    if [ -z "$deep_workflows" ]; then
        test_pass "No deep nesting in workflows/ (max 1 level: role)"
    else
        echo "$deep_workflows" | while read -r deep_dir; do
            local rel_path="${deep_dir#$PROJECT_ROOT/}"
            test_warn "Deep nesting found: $rel_path"
        done
    fi
}

# Anti-pattern 2: Custom DSL files
test_custom_dsl() {
    section "Anti-pattern: Custom DSL (use standard YAML/Markdown)"
    
    # Check for non-standard file extensions that might indicate custom DSL
    local custom_files=$(find "${PROJECT_ROOT}" \
        -type f \
        \( -name "*.dsl" -o -name "*.custom" -o -name "*.spec" -o -name "*.def" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/.git/*" \
        2>/dev/null || true)
    
    if [ -z "$custom_files" ]; then
        test_pass "No custom DSL files (*.dsl, *.custom, *.spec, *.def)"
    else
        echo "$custom_files" | while read -r dsl_file; do
            local rel_path="${dsl_file#$PROJECT_ROOT/}"
            test_warn "Potential custom DSL: $rel_path"
        done
    fi
}

# Anti-pattern 3: Hard blocking without --force option
test_hard_blocking() {
    section "Anti-pattern: Hard Blocking without --force override"
    
    local blocking_count=0
    
    # Check for exit 1 without checking for force flag
    for script_file in "${PROJECT_ROOT}"/tools/agent/lib/*.sh; do
        if [ -f "$script_file" ]; then
            local basename=$(basename "$script_file")
            
            # Look for exit 1 patterns
            local exits=$(grep -n "exit 1" "$script_file" 2>/dev/null || true)
            
            if [ -n "$exits" ]; then
                # Check if force flag is present in the file
                if grep -q "\-\-force\|--skip\|FORCE" "$script_file" 2>/dev/null; then
                    # Has override option - OK
                    : # Do nothing
                else
                    # Count lines with exit 1
                    local exit_count=$(echo "$exits" | wc -l | tr -d ' ')
                    if [ "$exit_count" -gt 3 ]; then
                        test_warn "$basename: $exit_count hard exits without --force option"
                        ((blocking_count++)) || true
                    fi
                fi
            fi
        fi
    done
    
    if [ "$blocking_count" -eq 0 ]; then
        test_pass "No excessive hard blocking patterns found"
    fi
}

# Anti-pattern 4: Complex state machines
test_state_machines() {
    section "Anti-pattern: Complex State Machines (use simple flags)"
    
    local state_count=0
    
    # Look for state machine indicators
    for script_file in "${PROJECT_ROOT}"/tools/agent/lib/*.sh; do
        if [ -f "$script_file" ]; then
            local basename=$(basename "$script_file")
            
            # Check for multiple state definitions (more than 5 states)
            local states=$(grep -i "STATE=\|_STATE\|STATUS=" "$script_file" 2>/dev/null | wc -l | tr -d ' ')
            
            if [ "$states" -gt 5 ]; then
                test_warn "$basename: $states state variables (consider simplification)"
                ((state_count++)) || true
            fi
        fi
    done
    
    if [ "$state_count" -eq 0 ]; then
        test_pass "No complex state machines detected"
    fi
}

# Anti-pattern 5: Implicit dependencies
test_implicit_dependencies() {
    section "Anti-pattern: Implicit Dependencies (be explicit)"
    
    local implicit_count=0
    
    # Check workflows for skill references
    for workflow_file in "${PROJECT_ROOT}"/workflows/*/*.md; do
        if [ -f "$workflow_file" ] && [ "$(basename "$workflow_file")" != "README.md" ]; then
            local basename=$(basename "$workflow_file")
            
            # Check if workflow has skills: section
            if ! grep -q "^skills:" "$workflow_file" 2>/dev/null; then
                test_warn "$basename: No explicit skills list in frontmatter"
                ((implicit_count++)) || true
            fi
        fi
    done
    
    if [ "$implicit_count" -eq 0 ]; then
        test_pass "All workflows explicitly declare skill dependencies"
    fi
}

# Anti-pattern 6: Forbidden Unicode (from language policy)
test_forbidden_unicode() {
    section "Anti-pattern: Forbidden Unicode Icons (use ASCII)"
    
    local unicode_count=0
    
    # Check for emoji and decorative Unicode in code
    for code_file in "${PROJECT_ROOT}"/tools/agent/lib/*.sh \
                     "${PROJECT_ROOT}"/tools/pm/lib/*.sh; do
        if [ -f "$code_file" ]; then
            local basename=$(basename "$code_file")
            
            # Check for emoji/decorative Unicode (not box chars)
            if grep -q '[✓✗★☆⚠✅🔴⏸]' "$code_file" 2>/dev/null; then
                test_fail "$basename: Contains forbidden Unicode icons"
                ((unicode_count++)) || true
            fi
        fi
    done
    
    if [ "$unicode_count" -eq 0 ]; then
        test_pass "No forbidden Unicode icons in code files"
    fi
}

# Test 7: Test fixtures
test_fixtures_antipatterns() {
    section "Test Fixtures (for testing this script)"
    
    local fixtures_dir="${SCRIPT_DIR}/fixtures/antipatterns"
    
    if [ ! -d "$fixtures_dir" ]; then
        test_warn "No test fixtures directory"
        return
    fi
    
    # Test FAIL cases (should detect anti-patterns)
    if [ -d "$fixtures_dir/fail" ]; then
        local fixture_count=0
        
        # Deep nesting example
        if [ -d "$fixtures_dir/fail/deep-nesting" ]; then
            local depth=$(find "$fixtures_dir/fail/deep-nesting" -type d | wc -l | tr -d ' ')
            if [ "$depth" -gt 3 ]; then
                test_pass "Fixture[FAIL]: deep-nesting detected (depth: $depth)"
            else
                test_fail "Fixture[FAIL]: deep-nesting should be deeper"
            fi
            ((fixture_count++)) || true
        fi
        
        # Custom DSL example
        if [ -f "$fixtures_dir/fail/custom.dsl" ]; then
            test_pass "Fixture[FAIL]: custom DSL file detected"
            ((fixture_count++)) || true
        fi
        
        if [ "$fixture_count" -gt 0 ]; then
            test_pass "Found $fixture_count anti-pattern examples"
        fi
    fi
    
    # Test PASS cases (should not detect anti-patterns)
    if [ -d "$fixtures_dir/pass" ]; then
        test_pass "Pass fixtures exist for validation"
    fi
}

# Main
main() {
    echo "=========================================="
    echo "Anti-pattern Detection"
    echo "=========================================="
    echo "Project: ${PROJECT_ROOT}"
    echo ""
    echo "Checking for (from ARCHITECTURE.md):"
    echo "  - Deep Nesting (max 2 levels)"
    echo "  - Custom DSL (use YAML/Markdown)"
    echo "  - Hard Blocking (need --force escape)"
    echo "  - Complex State Machines (use simple flags)"
    echo "  - Implicit Dependencies (be explicit)"
    echo "  - Forbidden Unicode (use ASCII)"
    
    test_deep_nesting
    test_custom_dsl
    test_hard_blocking
    test_state_machines
    test_implicit_dependencies
    test_forbidden_unicode
    test_fixtures_antipatterns
    
    echo ""
    echo "=========================================="
    echo "Results"
    echo "=========================================="
    echo -e "Total:  ${TOTAL}"
    echo -e "Passed: ${GREEN}${PASSED}${NC}"
    echo -e "Failed: ${RED}${FAILED}${NC}"
    echo -e "Warned: ${YELLOW}${WARNED}${NC}"
    echo ""
    
    if [ "$FAILED" -eq 0 ]; then
        if [ "$WARNED" -eq 0 ]; then
            echo -e "${GREEN}[PASS] No anti-patterns detected!${NC}"
        else
            echo -e "${YELLOW}[WARN] Some warnings found (not blocking).${NC}"
        fi
        exit 0
    else
        echo -e "${RED}[FAIL] Anti-patterns detected.${NC}"
        exit 1
    fi
}

main "$@"
