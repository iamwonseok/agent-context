#!/bin/bash
# Efficiency Pattern Validation (Limited Static Analysis)
# Checks for common efficiency anti-patterns per RFC-010

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

# Pattern 1: Repeated grep in scripts (should batch)
test_repeated_grep() {
    section "Efficiency: Repeated grep (use batch find)"
    
    local repeated_count=0
    
    # Check for scripts with many grep calls (>10)
    for script_file in "${PROJECT_ROOT}"/tools/agent/lib/*.sh; do
        if [ -f "$script_file" ]; then
            local basename=$(basename "$script_file")
            
            # Count grep calls
            local grep_count=$(grep -o "grep " "$script_file" 2>/dev/null | wc -l | tr -d ' ')
            
            if [ "$grep_count" -gt 15 ]; then
                test_warn "$basename: $grep_count grep calls (consider batching)"
                ((repeated_count++)) || true
            fi
        fi
    done
    
    if [ "$repeated_count" -eq 0 ]; then
        test_pass "No excessive grep repetition detected"
    fi
}

# Pattern 2: Sequential file operations (should parallelize)
test_sequential_operations() {
    section "Efficiency: Sequential operations (consider parallel)"
    
    # This is hard to detect statically, but we can check for loop patterns
    local sequential_count=0
    
    for script_file in "${PROJECT_ROOT}"/tools/agent/lib/*.sh; do
        if [ -f "$script_file" ]; then
            local basename=$(basename "$script_file")
            
            # Look for loops that might be inefficient
            # Pattern: for ... ; do ... read ... ; done (sequential file reads)
            if grep -q "for.*do.*read.*done" "$script_file" 2>/dev/null; then
                # This could be sequential file reading
                local loop_count=$(grep -c "for.*do" "$script_file" 2>/dev/null || echo "0")
                if [ "$loop_count" -gt 5 ]; then
                    test_warn "$basename: $loop_count loops (check if parallelizable)"
                    ((sequential_count++)) || true
                fi
            fi
        fi
    done
    
    if [ "$sequential_count" -eq 0 ]; then
        test_pass "No obvious sequential operation anti-patterns"
    fi
}

# Pattern 3: Test after each change (should test once at end)
test_excessive_testing() {
    section "Efficiency: Excessive test calls (batch tests)"
    
    # Check for test scripts that might be called too often
    local test_density=0
    
    for script_file in "${PROJECT_ROOT}"/tools/agent/lib/*.sh; do
        if [ -f "$script_file" ]; then
            local basename=$(basename "$script_file")
            local lines=$(wc -l < "$script_file" | tr -d ' ')
            
            if [ "$lines" -gt 0 ]; then
                # Count test/validate calls
                local test_calls=$(grep -c "test\|validate\|check" "$script_file" 2>/dev/null || echo "0")
                
                # Calculate density (calls per 100 lines)
                local density=0
                if [ "$lines" -gt 0 ] && [ "$test_calls" -gt 0 ]; then
                    density=$((test_calls * 100 / lines))
                fi
                
                if [ "$density" -gt 30 ]; then
                    test_warn "$basename: High test density ($density calls/100 lines)"
                    ((test_density++)) || true
                fi
            fi
        fi
    done
    
    if [ "$test_density" -eq 0 ]; then
        test_pass "No excessive test call patterns"
    fi
}

# Pattern 4: Language policy violations (batch detection)
test_language_efficiency() {
    section "Efficiency: Language policy (batch detection recommended)"
    
    # Check if .cursorrules mentions batch cleanup pattern
    if grep -q "Pattern 2.*Language" "${PROJECT_ROOT}/.cursorrules" 2>/dev/null; then
        test_pass "Language cleanup pattern documented in .cursorrules"
    else
        test_warn "Language cleanup pattern not in .cursorrules"
    fi
    
    # Check if test exists for language policy
    if [ -f "${PROJECT_ROOT}/tests/unit/skills/test_skills.sh" ]; then
        if grep -q "test_language_policy" "${PROJECT_ROOT}/tests/unit/skills/test_skills.sh" 2>/dev/null; then
            test_pass "Automated language policy test exists"
        else
            test_warn "No automated language policy test"
        fi
    fi
}

# Pattern 5: Batch operation documentation
test_batch_documentation() {
    section "Efficiency: Batch operation guidance"
    
    # Check for efficiency documentation
    if [ -f "${PROJECT_ROOT}/docs/rfcs/010-agent-efficiency-best-practices.md" ]; then
        test_pass "RFC-010 (Efficiency patterns) exists"
        
        # Check for pattern documentation
        local pattern_count=$(grep -c "Pattern [1-5]" \
            "${PROJECT_ROOT}/docs/rfcs/010-agent-efficiency-best-practices.md" 2>/dev/null || echo "0")
        
        if [ "$pattern_count" -ge 5 ]; then
            test_pass "All 5 efficiency patterns documented"
        else
            test_warn "Only $pattern_count/5 efficiency patterns documented"
        fi
    else
        test_fail "RFC-010 (Efficiency patterns) missing"
    fi
    
    # Check for .cursorrules efficiency section
    if grep -q "Batch Operations" "${PROJECT_ROOT}/.cursorrules" 2>/dev/null; then
        test_pass ".cursorrules has batch operations guidance"
    else
        test_warn ".cursorrules missing batch operations section"
    fi
}

# Test 6: Test fixtures
test_fixtures_efficiency() {
    section "Test Fixtures (for testing this script)"
    
    local fixtures_dir="${SCRIPT_DIR}/fixtures/efficiency"
    
    if [ ! -d "$fixtures_dir" ]; then
        test_warn "No test fixtures directory"
        return
    fi
    
    # Check for example scripts
    if [ -d "$fixtures_dir" ]; then
        local fixture_count=$(find "$fixtures_dir" -type f | wc -l | tr -d ' ')
        if [ "$fixture_count" -gt 0 ]; then
            test_pass "Found $fixture_count efficiency example files"
        fi
    fi
}

# Main
main() {
    echo "=========================================="
    echo "Efficiency Pattern Validation"
    echo "=========================================="
    echo "Project: ${PROJECT_ROOT}"
    echo ""
    echo "Note: This is STATIC ANALYSIS ONLY"
    echo "Runtime efficiency requires actual execution logs."
    echo ""
    echo "Checking for (from RFC-010):"
    echo "  - Repeated grep calls (use batch find)"
    echo "  - Sequential operations (consider parallel)"
    echo "  - Excessive test calls (batch at end)"
    echo "  - Language policy automation"
    echo "  - Batch operation documentation"
    
    test_repeated_grep
    test_sequential_operations
    test_excessive_testing
    test_language_efficiency
    test_batch_documentation
    test_fixtures_efficiency
    
    echo ""
    echo "=========================================="
    echo "Results"
    echo "=========================================="
    echo -e "Total:  ${TOTAL}"
    echo -e "Passed: ${GREEN}${PASSED}${NC}"
    echo -e "Failed: ${RED}${FAILED}${NC}"
    echo -e "Warned: ${YELLOW}${WARNED}${NC}"
    echo ""
    echo "NOTE: Efficiency patterns are recommendations, not hard requirements."
    echo "      Warnings indicate potential optimization opportunities."
    echo ""
    
    if [ "$FAILED" -eq 0 ]; then
        if [ "$WARNED" -eq 0 ]; then
            echo -e "${GREEN}[PASS] Efficiency patterns well documented!${NC}"
        else
            echo -e "${YELLOW}[WARN] Some optimization opportunities exist.${NC}"
        fi
        exit 0
    else
        echo -e "${RED}[FAIL] Missing critical efficiency documentation.${NC}"
        exit 1
    fi
}

main "$@"
