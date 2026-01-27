#!/bin/bash
# File Naming Conventions Validation
# Enforces naming standards per policies/README.md

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

# Test 1: Skills naming (skills/{category}/{skill-name}/SKILL.md)
test_skills_naming() {
    section "Skills Naming: skills/{category}/{skill-name}/SKILL.md"
    
    local invalid_count=0
    
    # Check for .md files that are not SKILL.md or README.md
    for md_file in "${PROJECT_ROOT}"/skills/*/*.md; do
        if [ -f "$md_file" ]; then
            local basename=$(basename "$md_file")
            if [ "$basename" != "SKILL.md" ] && [ "$basename" != "README.md" ]; then
                test_fail "Invalid skill file: $md_file (must be SKILL.md)"
                ((invalid_count++)) || true
            fi
        fi
    done
    
    # Check all SKILL.md files are in correct structure
    for skill_file in "${PROJECT_ROOT}"/skills/*/*/SKILL.md; do
        if [ -f "$skill_file" ]; then
            local rel_path="${skill_file#$PROJECT_ROOT/}"
            # Extract category and skill-name
            if [[ "$rel_path" =~ ^skills/([a-z]+)/([a-z-]+)/SKILL\.md$ ]]; then
                test_pass "Valid structure: $rel_path"
            else
                test_fail "Invalid structure: $rel_path"
                ((invalid_count++)) || true
            fi
        fi
    done
    
    if [ "$invalid_count" -eq 0 ]; then
        test_pass "All skill files follow naming convention"
    fi
}

# Test 2: Workflows naming (workflows/{role}/{workflow-name}.md)
test_workflows_naming() {
    section "Workflows Naming: workflows/{role}/{workflow-name}.md"
    
    local invalid_count=0
    
    # Check workflows are in developer/ or manager/ subdirectories
    for workflow_file in "${PROJECT_ROOT}"/workflows/*/*.md; do
        if [ -f "$workflow_file" ]; then
            local rel_path="${workflow_file#$PROJECT_ROOT/}"
            local basename=$(basename "$workflow_file")
            
            if [ "$basename" = "README.md" ]; then
                continue
            fi
            
            # Check pattern: workflows/{developer|manager}/{name}.md
            if [[ "$rel_path" =~ ^workflows/(developer|manager)/[a-z-]+\.md$ ]]; then
                test_pass "Valid structure: $rel_path"
            else
                test_fail "Invalid structure: $rel_path (must be developer/ or manager/)"
                ((invalid_count++)) || true
            fi
        fi
    done
    
    # Check for workflows directly in workflows/ (old format)
    for workflow_file in "${PROJECT_ROOT}"/workflows/*.md; do
        if [ -f "$workflow_file" ]; then
            local basename=$(basename "$workflow_file")
            if [ "$basename" != "README.md" ]; then
                test_fail "Old format: workflows/$basename (should be in developer/ or manager/)"
                ((invalid_count++)) || true
            fi
        fi
    done
    
    if [ "$invalid_count" -eq 0 ]; then
        test_pass "All workflow files follow naming convention"
    fi
}

# Test 3: RFCs naming (docs/rfcs/NNN-title.md)
test_rfcs_naming() {
    section "RFCs Naming: docs/rfcs/NNN-title.md"
    
    local invalid_count=0
    
    for rfc_file in "${PROJECT_ROOT}"/docs/rfcs/*.md; do
        if [ -f "$rfc_file" ]; then
            local basename=$(basename "$rfc_file")
            
            # Skip special files
            if [ "$basename" = "README.md" ] || [ "$basename" = "future-work.md" ]; then
                continue
            fi
            
            # Check pattern: NNN-title.md (3 digits followed by dash and title)
            if [[ "$basename" =~ ^[0-9]{3}-[a-z0-9-]+\.md$ ]]; then
                test_pass "Valid RFC name: $basename"
            else
                test_fail "Invalid RFC name: $basename (must be NNN-title.md)"
                ((invalid_count++)) || true
            fi
        fi
    done
    
    # Check archived RFCs
    for rfc_file in "${PROJECT_ROOT}"/docs/rfcs/archive/*.md; do
        if [ -f "$rfc_file" ]; then
            local basename=$(basename "$rfc_file")
            
            if [ "$basename" = "README.md" ]; then
                continue
            fi
            
            if [[ "$basename" =~ ^[0-9]{3}-[a-z0-9-]+\.md$ ]]; then
                test_pass "Valid archived RFC: $basename"
            else
                test_warn "Archived RFC with non-standard name: $basename"
            fi
        fi
    done
    
    if [ "$invalid_count" -eq 0 ]; then
        test_pass "All RFC files follow naming convention"
    fi
}

# Test 4: Template naming
test_template_naming() {
    section "Template Naming"
    
    # Check _template directories
    if [ -d "${PROJECT_ROOT}/skills/_template" ]; then
        if [ -f "${PROJECT_ROOT}/skills/_template/SKILL.md" ]; then
            test_pass "Skill template exists: skills/_template/SKILL.md"
        else
            test_fail "Skill template missing: skills/_template/SKILL.md"
        fi
    fi
    
    if [ -d "${PROJECT_ROOT}/docs/rfcs/_template" ]; then
        if [ -f "${PROJECT_ROOT}/docs/rfcs/_template/RFC-TEMPLATE.md" ]; then
            test_pass "RFC template exists: docs/rfcs/_template/RFC-TEMPLATE.md"
        else
            test_warn "RFC template missing or misnamed"
        fi
    fi
}

# Test 5: Test fixtures (for this script)
test_fixtures_naming() {
    section "Test Fixtures (for testing this script)"
    
    local fixtures_dir="${SCRIPT_DIR}/fixtures/naming"
    
    if [ ! -d "$fixtures_dir" ]; then
        test_warn "No test fixtures directory"
        return
    fi
    
    # Test PASS cases
    if [ -d "$fixtures_dir/pass" ]; then
        test_pass "Test fixtures exist for naming validation"
        
        # Count valid structures
        local valid_count=0
        for item in "$fixtures_dir"/pass/*; do
            if [ -e "$item" ]; then
                ((valid_count++)) || true
            fi
        done
        
        if [ "$valid_count" -gt 0 ]; then
            test_pass "Found $valid_count valid naming examples"
        fi
    fi
    
    # Test FAIL cases
    if [ -d "$fixtures_dir/fail" ]; then
        local invalid_count=0
        for item in "$fixtures_dir"/fail/*; do
            if [ -e "$item" ]; then
                ((invalid_count++)) || true
            fi
        done
        
        if [ "$invalid_count" -gt 0 ]; then
            test_pass "Found $invalid_count invalid naming examples"
        fi
    fi
}

# Main
main() {
    echo "=========================================="
    echo "File Naming Conventions Validation"
    echo "=========================================="
    echo "Project: ${PROJECT_ROOT}"
    echo ""
    echo "Standards (from policies/README.md):"
    echo "  - Skills: skills/{category}/{skill-name}/SKILL.md"
    echo "  - Workflows: workflows/{role}/{workflow-name}.md"
    echo "  - RFCs: docs/rfcs/NNN-descriptive-title.md"
    
    test_skills_naming
    test_workflows_naming
    test_rfcs_naming
    test_template_naming
    test_fixtures_naming
    
    echo ""
    echo "=========================================="
    echo "Results"
    echo "=========================================="
    echo -e "Total:  ${TOTAL}"
    echo -e "Passed: ${GREEN}${PASSED}${NC}"
    echo -e "Failed: ${RED}${FAILED}${NC}"
    echo ""
    
    if [ "$FAILED" -eq 0 ]; then
        echo -e "${GREEN}[PASS] All naming conventions followed!${NC}"
        exit 0
    else
        echo -e "${RED}[FAIL] Some files violate naming conventions.${NC}"
        exit 1
    fi
}

main "$@"
