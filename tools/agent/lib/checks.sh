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

# ============================================
# Pre-commit Hook Management (RFC-005)
# ============================================

# Agent hook signature (to identify agent-installed hooks)
AGENT_HOOK_SIGNATURE="# Pre-commit hook installed by 'agent dev check --install-hook'"

# Install pre-commit hook
hook_install() {
    local project_root
    project_root=$(find_project_root 2>/dev/null) || {
        echo "[ERROR] Not in a git repository" >&2
        return 1
    }

    local hook_dir="$project_root/.git/hooks"
    local hook_file="$hook_dir/pre-commit"

    # Check if .git/hooks exists
    if [[ ! -d "$hook_dir" ]]; then
        mkdir -p "$hook_dir"
    fi

    # Check if hook already exists
    if [[ -f "$hook_file" ]]; then
        if grep -q "$AGENT_HOOK_SIGNATURE" "$hook_file"; then
            echo "[INFO] Agent pre-commit hook already installed"
            return 0
        else
            echo "[WARN] Existing pre-commit hook found (not installed by agent)"
            echo "[INFO] Backing up existing hook to $hook_file.backup"
            cp "$hook_file" "$hook_file.backup"
        fi
    fi

    # Create hook
    cat > "$hook_file" << 'HOOKEOF'
#!/bin/bash
# Pre-commit hook installed by 'agent dev check --install-hook'
# To skip: git commit --no-verify

echo "[PRE-COMMIT] Running quality checks..."

# Find project root
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"

# Lint (if make lint exists)
if [ -f "$PROJECT_ROOT/Makefile" ] && grep -q "^lint:" "$PROJECT_ROOT/Makefile"; then
    echo "[PRE-COMMIT] Running lint..."
    make -C "$PROJECT_ROOT" lint || {
        echo "[FAIL] Lint failed"
        echo "[INFO] Fix errors or use 'git commit --no-verify' to skip"
        exit 1
    }
fi

# Test (if make test exists)
if [ -f "$PROJECT_ROOT/Makefile" ] && grep -q "^test:" "$PROJECT_ROOT/Makefile"; then
    echo "[PRE-COMMIT] Running tests..."
    make -C "$PROJECT_ROOT" test || {
        echo "[FAIL] Tests failed"
        echo "[INFO] Fix tests or use 'git commit --no-verify' to skip"
        exit 1
    }
fi

echo "[PRE-COMMIT] All checks passed"
exit 0
HOOKEOF

    chmod +x "$hook_file"

    echo "[OK] Pre-commit hook installed"
    echo ""
    echo "Location: $hook_file"
    echo ""
    echo "The hook will run:"
    echo "  - make lint (if available)"
    echo "  - make test (if available)"
    echo ""
    echo "To skip: git commit --no-verify"
    echo "To remove: agent dev check --uninstall-hook"
}

# Uninstall pre-commit hook
hook_uninstall() {
    local project_root
    project_root=$(find_project_root 2>/dev/null) || {
        echo "[ERROR] Not in a git repository" >&2
        return 1
    }

    local hook_file="$project_root/.git/hooks/pre-commit"

    if [[ ! -f "$hook_file" ]]; then
        echo "[INFO] No pre-commit hook found"
        return 0
    fi

    # Check if it's an agent-installed hook
    if grep -q "$AGENT_HOOK_SIGNATURE" "$hook_file"; then
        rm "$hook_file"
        echo "[OK] Agent pre-commit hook removed"
        
        # Restore backup if exists
        if [[ -f "$hook_file.backup" ]]; then
            echo "[INFO] Restoring backup hook..."
            mv "$hook_file.backup" "$hook_file"
            echo "[OK] Original hook restored"
        fi
    else
        echo "[WARN] Pre-commit hook was not installed by agent"
        echo "[INFO] Not removing to preserve user's custom hook"
        echo ""
        echo "To manually remove: rm $hook_file"
    fi
}

# Show hook status
hook_status() {
    local project_root
    project_root=$(find_project_root 2>/dev/null) || {
        echo "[ERROR] Not in a git repository" >&2
        return 1
    }

    local hook_file="$project_root/.git/hooks/pre-commit"

    echo "=================================================="
    echo "Pre-commit Hook Status"
    echo "=================================================="
    echo ""

    if [[ ! -f "$hook_file" ]]; then
        echo "Hook installed: No"
        echo ""
        echo "To install: agent dev check --install-hook"
    elif grep -q "$AGENT_HOOK_SIGNATURE" "$hook_file"; then
        echo "Hook installed: Yes (by agent)"
        echo "Hook path: $hook_file"
        echo ""
        echo "To remove: agent dev check --uninstall-hook"
    else
        echo "Hook installed: Yes (custom/unknown)"
        echo "Hook path: $hook_file"
        echo ""
        echo "[INFO] This hook was not installed by agent"
    fi

    echo "=================================================="
}

# ============================================
# Self-Correction Protocol (RFC-004 v2.0)
# ============================================

# Mode constants for self-correction
SELF_CORRECTION_MODE_PLANNING="planning"
SELF_CORRECTION_MODE_IMPLEMENTATION="implementation"
SELF_CORRECTION_MODE_VERIFICATION="verification"
SELF_CORRECTION_MODE_RESEARCH="research"

# Detect mode violation based on current mode and actions
# Usage: detect_mode_violation <current_mode> [context_path]
# Returns: 0 if no violation, 1 if violation detected
detect_mode_violation() {
    local current_mode="$1"
    local context_path="${2:-}"
    local violation_found=false
    local violation_reason=""

    case "$current_mode" in
        planning)
            # In planning mode, code changes are violations
            if git diff --cached --name-only 2>/dev/null | grep -qE '\.(c|cpp|py|sh|js|ts|go|rs|java)$'; then
                violation_found=true
                violation_reason="Code changes detected in planning mode"
            fi
            # Check for new file creation (except .md files)
            if git diff --cached --name-only --diff-filter=A 2>/dev/null | grep -qvE '\.md$' | grep -q .; then
                violation_found=true
                violation_reason="New non-documentation files created in planning mode"
            fi
            ;;

        research)
            # In research mode, any file modification is a violation
            if git diff --cached --name-only 2>/dev/null | grep -q .; then
                violation_found=true
                violation_reason="File modifications detected in research mode"
            fi
            ;;

        verification)
            # In verification mode, new features are violations
            if git diff --cached --name-only 2>/dev/null | grep -qE '\.(c|cpp|py|sh|js|ts|go|rs|java)$'; then
                # Check if it's a new file (potential new feature)
                if git diff --cached --name-only --diff-filter=A 2>/dev/null | grep -qE '\.(c|cpp|py|sh|js|ts|go|rs|java)$'; then
                    violation_found=true
                    violation_reason="New code files added in verification mode (potential new feature)"
                fi
            fi
            ;;

        implementation)
            # Implementation mode allows most changes
            # Violation: changing test files without changing code
            local code_changes test_changes
            code_changes=$(git diff --cached --name-only 2>/dev/null | grep -cE '\.(c|cpp|py|sh|js|ts|go|rs|java)$' || echo 0)
            test_changes=$(git diff --cached --name-only 2>/dev/null | grep -cE '(test_|_test\.|\.test\.)' || echo 0)
            
            if [[ "$test_changes" -gt 0 ]] && [[ "$code_changes" -eq 0 ]]; then
                # This is OK - test-only changes can happen during TDD
                :
            fi
            ;;
    esac

    if [[ "$violation_found" == "true" ]]; then
        echo ""
        echo "=================================================="
        echo "[SELF-CORRECTION] Mode Violation Detected"
        echo "=================================================="
        echo ""
        echo "  Current Mode: $current_mode"
        echo "  Violation:    $violation_reason"
        echo ""
        echo "  Recommended Actions:"
        echo "    1. Review the changes - are they intentional?"
        echo "    2. If yes, switch to appropriate mode"
        echo "    3. If no, revert unintended changes"
        echo ""
        echo "  Note: This is a WARNING only. Use --force to proceed."
        echo "=================================================="
        return 1
    fi

    return 0
}

# Suggest mode based on current action
# Usage: suggest_mode <action>
suggest_mode() {
    local action="$1"

    case "$action" in
        analyze|inspect|review|assess|evaluate)
            echo "$SELF_CORRECTION_MODE_RESEARCH"
            ;;
        design|plan|breakdown|estimate|schedule|allocate)
            echo "$SELF_CORRECTION_MODE_PLANNING"
            ;;
        write|fix|refactor|update|manage)
            echo "$SELF_CORRECTION_MODE_IMPLEMENTATION"
            ;;
        test|check|verify|run|validate)
            echo "$SELF_CORRECTION_MODE_VERIFICATION"
            ;;
        *)
            echo "$SELF_CORRECTION_MODE_IMPLEMENTATION"
            ;;
    esac
}

# Self-correction check with mode tracking
# Usage: run_self_correction <context_path>
run_self_correction() {
    local context_path="$1"
    local mode_file="$context_path/mode.txt"
    local current_mode="planning"  # Default

    # Load current mode if exists
    if [[ -f "$mode_file" ]]; then
        current_mode=$(cat "$mode_file")
    fi

    echo ""
    echo "[Self-Correction Check]"
    echo "  Current Mode: $current_mode"

    if detect_mode_violation "$current_mode" "$context_path"; then
        echo "  [PASS] No mode violations detected"
        return 0
    else
        echo "  [WARN] Mode violation detected"
        echo "  [SUGGEST] Review changes or switch mode"
        return 1
    fi
}
