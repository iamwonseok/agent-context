#!/bin/bash
# Lightweight checks for agent workflow
# Design: Warnings over blocking, user autonomy preserved
# See .agent/why.md for rationale

# Check if lint passes
check_lint() {
    local project_root="$1"
    
    # Look for common linters
    if [[ -f "$project_root/package.json" ]]; then
        if grep -q '"lint"' "$project_root/package.json"; then
            npm run lint 2>/dev/null && return 0
            return 1
        fi
    fi
    
    if [[ -f "$project_root/Makefile" ]]; then
        if grep -q '^lint:' "$project_root/Makefile"; then
            make lint 2>/dev/null && return 0
            return 1
        fi
    fi
    
    # No linter found - pass with info
    echo "  [INFO] No linter configured"
    return 0
}

# Check if tests pass
check_tests() {
    local project_root="$1"
    
    # Look for test runners
    if [[ -f "$project_root/package.json" ]]; then
        if grep -q '"test"' "$project_root/package.json"; then
            npm test 2>/dev/null && return 0
            return 1
        fi
    fi
    
    if [[ -f "$project_root/Makefile" ]]; then
        if grep -q '^test:' "$project_root/Makefile"; then
            make test 2>/dev/null && return 0
            return 1
        fi
    fi
    
    # Python pytest
    if command -v pytest &>/dev/null && [[ -d "$project_root/tests" ]]; then
        pytest "$project_root/tests" 2>/dev/null && return 0
        return 1
    fi
    
    echo "  [INFO] No test runner configured"
    return 0
}

# Check intent alignment (lightweight)
# Returns 0 if aligned, 1 if deviation found (as warning only)
check_intent_alignment() {
    local project_root="$1"
    local context_path="$2"
    
    # Find plan files
    local plan_files=()
    for f in "$project_root"/plan/*.md; do
        [[ -f "$f" ]] && plan_files+=("$f")
    done
    
    if [[ ${#plan_files[@]} -eq 0 ]]; then
        echo "  [INFO] No plan files found in plan/"
        return 0
    fi
    
    # Get changed files
    local changed_files
    changed_files=$(git diff --name-only HEAD 2>/dev/null)
    
    if [[ -z "$changed_files" ]]; then
        changed_files=$(git diff --name-only origin/main...HEAD 2>/dev/null)
    fi
    
    if [[ -z "$changed_files" ]]; then
        echo "  [INFO] No changes to check"
        return 0
    fi
    
    # Simple heuristic: are changed files mentioned in any plan?
    local unmentioned=()
    while IFS= read -r file; do
        local mentioned=false
        for plan in "${plan_files[@]}"; do
            if grep -q "$file" "$plan" 2>/dev/null; then
                mentioned=true
                break
            fi
        done
        if [[ "$mentioned" == "false" ]]; then
            unmentioned+=("$file")
        fi
    done <<< "$changed_files"
    
    if [[ ${#unmentioned[@]} -gt 0 ]]; then
        echo "  [WARN] Some files not mentioned in plan:"
        for f in "${unmentioned[@]:0:5}"; do
            echo "    - $f"
        done
        if [[ ${#unmentioned[@]} -gt 5 ]]; then
            echo "    ... and $((${#unmentioned[@]} - 5)) more"
        fi
        return 1
    fi
    
    return 0
}

# Check if verification.md exists
check_verification_exists() {
    local context_path="$1"
    
    if [[ -f "$context_path/verification.md" ]]; then
        return 0
    fi
    return 1
}

# Check if retrospective.md exists
check_retrospective_exists() {
    local context_path="$1"
    
    if [[ -f "$context_path/retrospective.md" ]]; then
        return 0
    fi
    return 1
}

# Run all checks with warnings (not blocking)
# Returns summary of check results
run_all_checks() {
    local project_root="$1"
    local context_path="$2"
    
    local lint_ok=false
    local test_ok=false
    local intent_ok=false
    
    echo ""
    echo "=================================================="
    echo "Running Quality Checks"
    echo "=================================================="
    echo ""
    
    # Lint
    echo "[Lint]"
    if check_lint "$project_root"; then
        echo "  [PASS] Lint check passed"
        lint_ok=true
    else
        echo "  [WARN] Lint check failed"
    fi
    echo ""
    
    # Tests
    echo "[Tests]"
    if check_tests "$project_root"; then
        echo "  [PASS] Tests passed"
        test_ok=true
    else
        echo "  [WARN] Tests failed"
    fi
    echo ""
    
    # Intent alignment
    echo "[Intent Alignment]"
    if check_intent_alignment "$project_root" "$context_path"; then
        echo "  [PASS] Changes align with plan"
        intent_ok=true
    else
        echo "  [WARN] Some changes may not be in plan"
        echo "  [RECOMMEND] Review plan or document deviation"
    fi
    echo ""
    
    # Summary
    echo "=================================================="
    echo "Summary"
    echo "=================================================="
    local pass_count=0
    [[ "$lint_ok" == "true" ]] && ((pass_count++))
    [[ "$test_ok" == "true" ]] && ((pass_count++))
    [[ "$intent_ok" == "true" ]] && ((pass_count++))
    
    echo "Checks: $pass_count/3 passed"
    
    if [[ $pass_count -lt 3 ]]; then
        echo ""
        echo "[RECOMMEND] Fix warnings before committing"
        echo "[INFO] Use --force to commit anyway (not recommended)"
        return 1
    fi
    
    echo ""
    echo "[PASS] All checks passed - OK to commit"
    return 0
}

# Pre-submit checks (verification + retrospective)
run_submit_checks() {
    local context_path="$1"
    local force="${2:-false}"
    
    local verification_ok=false
    local retro_ok=false
    
    echo ""
    echo "=================================================="
    echo "Pre-Submit Checks"
    echo "=================================================="
    echo ""
    
    # Verification
    echo "[Verification]"
    if check_verification_exists "$context_path"; then
        echo "  [PASS] verification.md found"
        verification_ok=true
    else
        echo "  [WARN] verification.md not found"
        echo "  [RECOMMEND] Run 'agent dev verify' to generate"
    fi
    echo ""
    
    # Retrospective
    echo "[Retrospective]"
    if check_retrospective_exists "$context_path"; then
        echo "  [PASS] retrospective.md found"
        retro_ok=true
    else
        echo "  [WARN] retrospective.md not found"
        echo "  [RECOMMEND] Run 'agent dev retro' to create"
    fi
    echo ""
    
    # Summary
    echo "=================================================="
    
    if [[ "$verification_ok" == "true" ]] && [[ "$retro_ok" == "true" ]]; then
        echo "[PASS] Ready to submit"
        return 0
    fi
    
    if [[ "$force" == "true" ]]; then
        echo "[WARN] Submitting with missing artifacts (forced)"
        return 0
    fi
    
    echo "[WARN] Missing recommended artifacts"
    echo ""
    echo "Continue anyway? [y/N] "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    return 1
}

# Update summary.yaml with check results
update_summary_with_checks() {
    local context_path="$1"
    local lint_ok="$2"
    local test_ok="$3"
    local intent_ok="$4"
    
    local summary_file="$context_path/summary.yaml"
    
    if [[ ! -f "$summary_file" ]]; then
        generate_summary "$context_path"
    fi
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Append check results (simple approach without yq dependency)
    cat >> "$summary_file" << EOF

# Check Results (Updated: $timestamp)
last_check:
  timestamp: "$timestamp"
  lint: "$lint_ok"
  tests: "$test_ok"
  intent_alignment: "$intent_ok"
EOF
}
