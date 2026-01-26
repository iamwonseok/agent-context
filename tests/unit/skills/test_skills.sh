#!/bin/bash
# Skills Framework Test Suite

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$(cd "${SCRIPT_DIR}/../../../skills" && pwd)"

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

section() {
    echo ""
    echo -e "${BLUE}--- $1 ---${NC}"
}

# Skills to test (new categorized structure)
# Format: category/skill-name
SKILL_PATHS="
analyze/parse-requirement
analyze/inspect-codebase
analyze/inspect-logs
analyze/evaluate-priority
analyze/assess-status
planning/design-solution
planning/breakdown-work
planning/estimate-effort
planning/schedule-timeline
planning/allocate-resources
execute/write-code
execute/refactor-code
execute/fix-defect
execute/update-documentation
execute/manage-issues
validate/run-tests
validate/check-style
validate/review-code
validate/verify-requirements
validate/analyze-impact
validate/check-intent
integrate/commit-changes
integrate/create-merge-request
integrate/merge-changes
integrate/notify-stakeholders
integrate/publish-report
"

# 1. SKILL.md Structure
test_skill_structure() {
    section "SKILL.md Structure"

    for skill_path in $SKILL_PATHS; do
        skill_dir="${SKILLS_DIR}/${skill_path}"
        skill_file="${skill_dir}/SKILL.md"

        if [ ! -d "$skill_dir" ]; then
            continue
        fi

        echo ""
        echo "  [${skill_path}]"

        if [ -f "$skill_file" ]; then
            test_pass "SKILL.md exists"
        else
            test_fail "SKILL.md missing"
            continue
        fi

        # YAML frontmatter
        local first_line=$(head -1 "$skill_file")
        if [ "$first_line" = "---" ]; then
            test_pass "YAML frontmatter"
        else
            test_fail "YAML frontmatter missing"
        fi

        # Required fields
        for field in "name:" "description:" "version:" "inputs:" "outputs:"; do
            if grep -q "${field}" "$skill_file" 2>/dev/null; then
                test_pass "Has: ${field}"
            else
                test_fail "Missing: ${field}"
            fi
        done

        # Required sections
        for sec in "## When to Use" "## Prerequisites" "## Workflow" "## Outputs"; do
            if grep -q "^${sec}" "$skill_file" 2>/dev/null; then
                test_pass "Has: ${sec}"
            else
                test_fail "Missing: ${sec}"
            fi
        done
    done
}

# 2. Template
test_template() {
    section "Template"

    local template_file="${SKILLS_DIR}/_template/SKILL.md"

    if [ -f "$template_file" ]; then
        test_pass "_template/SKILL.md exists"
    else
        test_fail "_template/SKILL.md missing"
        return
    fi

    local first_line=$(head -1 "$template_file")
    if [ "$first_line" = "---" ]; then
        test_pass "Template has YAML"
    else
        test_fail "Template missing YAML"
    fi
}

# 3. README
test_readme() {
    section "README"

    local readme="${SKILLS_DIR}/README.md"

    if [ -f "$readme" ]; then
        test_pass "README.md exists"
    else
        test_fail "README.md missing"
        return
    fi

    # Check for category mentions
    for category in analyze plan execute validate integrate; do
        if grep -q "$category" "$readme" 2>/dev/null; then
            test_pass "Mentions: ${category}"
        else
            test_fail "Missing: ${category}"
        fi
    done
}

# 4. References
test_references() {
    section "References"

    for ref_dir in "${SKILLS_DIR}"/*/references; do
        if [ ! -d "$ref_dir" ]; then
            continue
        fi

        local skill_name=$(basename "$(dirname "$ref_dir")")
        echo ""
        echo "  [${skill_name}/references]"

        for ref_file in "$ref_dir"/*.md; do
            if [ -f "$ref_file" ]; then
                local ref_name=$(basename "$ref_file")
                test_pass "Exists: ${ref_name}"
            fi
        done
    done
}

# 5. Scripts
test_scripts() {
    section "Scripts"

    for script_file in "${SKILLS_DIR}"/*/scripts/*.sh; do
        if [ ! -f "$script_file" ]; then
            continue
        fi

        local script_name=$(echo "$script_file" | sed "s|${SKILLS_DIR}/||")
        echo ""
        echo "  [${script_name}]"

        if [ -x "$script_file" ]; then
            test_pass "Executable"
        else
            test_fail "Not executable"
        fi

        local first_line=$(head -1 "$script_file")
        if [ "$first_line" = "#!/bin/bash" ]; then
            test_pass "Has shebang"
        else
            test_fail "Missing shebang"
        fi

        if bash -n "$script_file" 2>/dev/null; then
            test_pass "Valid syntax"
        else
            test_fail "Syntax error"
        fi
    done
}

# 6. Workflows
test_workflows() {
    section "Workflows"

    local workflows_dir="${SKILLS_DIR}/../workflows"

    if [ ! -d "$workflows_dir" ]; then
        test_fail "workflows/ directory missing"
        return
    fi

    if [ -f "$workflows_dir/README.md" ]; then
        test_pass "workflows/README.md exists"
    else
        test_fail "workflows/README.md missing"
    fi

    # Test developer workflows
    for wf in feature bug-fix hotfix refactor; do
        local wf_file="$workflows_dir/developer/${wf}.md"

        if [ ! -f "$wf_file" ]; then
            test_fail "Missing: developer/${wf}.md"
            continue
        fi

        echo ""
        echo "  [developer/${wf}]"
        test_pass "File exists"

        # YAML frontmatter
        local first_line=$(head -1 "$wf_file")
        if [ "$first_line" = "---" ]; then
            test_pass "YAML frontmatter"
        else
            test_fail "YAML frontmatter missing"
        fi

        # Required YAML fields
        for field in "name:" "description:" "skills:"; do
            if grep -q "${field}" "$wf_file" 2>/dev/null; then
                test_pass "Has: ${field}"
            else
                test_fail "Missing: ${field}"
            fi
        done

        # Required sections
        for sec in "## When to Use" "## Flow" "## Quality Gates"; do
            if grep -q "^${sec}" "$wf_file" 2>/dev/null; then
                test_pass "Has: ${sec}"
            else
                test_warn "Missing: ${sec}"
            fi
        done

        # Verify referenced skills exist
        local skills_list=$(sed -n '/^skills:/,/^[a-z].*:/p' "$wf_file" | grep "^  - " | sed 's/^  - //' | sed 's/ .*//')
        for skill in $skills_list; do
            # Skip special cases like "git-workflow (worktree)"
            skill=$(echo "$skill" | sed 's/(.*//')
            if [ -d "${SKILLS_DIR}/${skill}" ]; then
                test_pass "Skill exists: ${skill}"
            else
                test_fail "Skill not found: ${skill}"
            fi
        done
    done

    # Test manager workflows
    for wf in initiative epic task-assignment monitoring approval; do
        local wf_file="$workflows_dir/manager/${wf}.md"

        if [ ! -f "$wf_file" ]; then
            test_fail "Missing: manager/${wf}.md"
            continue
        fi

        echo ""
        echo "  [manager/${wf}]"
        test_pass "File exists"

        # YAML frontmatter
        local first_line=$(head -1 "$wf_file")
        if [ "$first_line" = "---" ]; then
            test_pass "YAML frontmatter"
        else
            test_fail "YAML frontmatter missing"
        fi

        # Required YAML fields
        for field in "name:" "description:" "skills:"; do
            if grep -q "${field}" "$wf_file" 2>/dev/null; then
                test_pass "Has: ${field}"
            else
                test_fail "Missing: ${field}"
            fi
        done

        # Verify referenced skills exist
        local skills_list=$(sed -n '/^skills:/,/^[a-z].*:/p' "$wf_file" | grep "^  - " | sed 's/^  - //' | sed 's/ .*//')
        for skill in $skills_list; do
            # Skip special cases like "git-workflow (worktree)"
            skill=$(echo "$skill" | sed 's/(.*//')
            if [ -d "${SKILLS_DIR}/${skill}" ]; then
                test_pass "Skill exists: ${skill}"
            else
                test_fail "Skill not found: ${skill}"
            fi
        done
    done
}

# 7. Language Policy (no Korean, no icon-style Unicode)
# Allowed: arrows (→), box chars (├└│─), block elements (█░), math symbols (×±)
# Forbidden: checkmarks (✓✗), emoji icons (⚠️✅🔴⏸️), stars (★)
test_language_policy() {
    section "Language Policy"

    local has_korean=0
    local has_forbidden_unicode=0

    # Check for Korean characters (UTF-8 byte range)
    echo "  Checking for Korean..."
    local korean_files=$(LC_ALL=C grep -r -l $'[\xEA-\xED]' "${SKILLS_DIR}" "${SKILLS_DIR}/../workflows" 2>/dev/null | grep -E '\.(md|sh)$' || true)

    if [ -z "$korean_files" ]; then
        test_pass "No Korean characters"
    else
        test_fail "Korean found in:"
        echo "$korean_files" | while read -r f; do
            echo "    - $f"
        done
        has_korean=1
    fi

    # Check for forbidden Unicode icons only (not box chars or arrows)
    # Forbidden: checkmarks, stars, emoji-style icons
    echo "  Checking for forbidden Unicode icons..."

    # Use actual characters in grep pattern (more reliable than hex)
    # Checkmarks, X marks, stars
    local checkmark_files=$(grep -r -l '[✓✗☑☒]' "${SKILLS_DIR}" "${SKILLS_DIR}/../workflows" 2>/dev/null | grep -E '\.(md)$' || true)

    # Stars: ★ ☆
    local star_files=$(grep -r -l '[★☆]' "${SKILLS_DIR}" "${SKILLS_DIR}/../workflows" 2>/dev/null | grep -E '\.(md)$' || true)

    # Common emoji (warning, check, red circle, pause)
    local emoji_files=$(grep -r -l '[⚠✅🔴⏸]' "${SKILLS_DIR}" "${SKILLS_DIR}/../workflows" 2>/dev/null | grep -E '\.(md)$' || true)

    local all_forbidden="${checkmark_files}${star_files}${emoji_files}"

    if [ -z "$all_forbidden" ]; then
        test_pass "No forbidden Unicode icons"
    else
        test_fail "Forbidden Unicode icons found:"
        if [ -n "$checkmark_files" ]; then
            echo "    Checkmarks (use [x] instead):"
            echo "$checkmark_files" | while read -r f; do [ -n "$f" ] && echo "      - $f"; done
        fi
        if [ -n "$star_files" ]; then
            echo "    Stars (use numbers instead):"
            echo "$star_files" | while read -r f; do [ -n "$f" ] && echo "      - $f"; done
        fi
        if [ -n "$emoji_files" ]; then
            echo "    Emoji icons (use [PASS]/[FAIL]/[WARN] instead):"
            echo "$emoji_files" | while read -r f; do [ -n "$f" ] && echo "      - $f"; done
        fi
        has_forbidden_unicode=1
    fi
}

# Main
main() {
    echo "=========================================="
    echo "Skills Framework Test Suite"
    echo "=========================================="
    echo "Skills: ${SKILLS_DIR}"

    test_skill_structure
    test_template
    test_readme
    test_references
    test_scripts
    test_workflows
    test_language_policy

    echo ""
    echo "=========================================="
    echo "Results"
    echo "=========================================="
    echo -e "Total:  ${TOTAL}"
    echo -e "Passed: ${GREEN}${PASSED}${NC}"
    echo -e "Failed: ${RED}${FAILED}${NC}"
    echo ""

    if [ "$FAILED" -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        exit 1
    fi
}

main "$@"
