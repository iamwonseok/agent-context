#!/bin/bash
# Branch operations for Interactive Mode
# Creates, switches, and manages task branches

# Start work on a task (Interactive Mode - Branch)
# Creates: feat/TASK-123 branch and .context/TASK-123/ directory
dev_start() {
    parse_start_options "$@" || return 1

    local project_root
    project_root=$(find_project_root) || return 1

    echo "Starting task: $TASK_ID"
    echo ""

    if [[ "$DETACHED" == "true" ]]; then
        # Detached mode - use worktree
        start_detached "$project_root"
    else
        # Interactive mode - use branch
        start_interactive "$project_root"
    fi
}

# Start in Interactive Mode (branch)
start_interactive() {
    local project_root="$1"
    local branch_name
    branch_name=$(generate_branch_name "$TASK_ID")

    echo "[Mode] Interactive (branch)"
    echo "[Branch] $branch_name"
    echo ""

    # Check if branch already exists
    if branch_exists "$branch_name"; then
        echo "[INFO] Branch $branch_name already exists"
        echo "Switching to existing branch..."
        git checkout "$branch_name" || return 1
    else
        # Ensure we're on the base branch first
        echo "Creating branch from $FROM_BRANCH..."

        # Fetch latest if remote exists
        if remote_branch_exists "$FROM_BRANCH"; then
            git fetch origin "$FROM_BRANCH" 2>/dev/null || true
        fi

        # Create and checkout new branch
        git checkout -b "$branch_name" "origin/$FROM_BRANCH" 2>/dev/null || \
        git checkout -b "$branch_name" "$FROM_BRANCH" || {
            echo "[ERROR] Failed to create branch" >&2
            return 1
        }
    fi

    # Initialize context
    init_context "$project_root" "$TASK_ID" "interactive"

    echo ""
    echo "=================================================="
    echo "[OK] Task $TASK_ID started"
    echo "=================================================="
    echo "Branch: $branch_name"
    echo "Context: .context/$TASK_ID/"
    echo ""
    echo "Next steps:"
    echo "  - Make your changes"
    echo "  - agent dev check    # Verify changes"
    echo "  - agent dev commit   # Commit changes"
    echo "  - agent dev submit   # Create MR"
    echo "=================================================="
}

# Start in Detached Mode (worktree)
start_detached() {
    local project_root="$1"
    local worktree_name
    worktree_name=$(generate_worktree_name "$TASK_ID" "$TRY_NAME")
    local worktree_path="$project_root/$WORKTREE_ROOT/$worktree_name"
    local branch_name
    branch_name=$(generate_branch_name "$TASK_ID")

    # Add try suffix to branch if specified
    if [[ -n "$TRY_NAME" ]]; then
        branch_name="${branch_name}-${TRY_NAME}"
    fi

    echo "[Mode] Detached (worktree)"
    echo "[Worktree] $worktree_path"
    echo "[Branch] $branch_name"
    echo ""

    # Create worktree root if needed
    mkdir -p "$project_root/$WORKTREE_ROOT"

    # Check if worktree already exists
    if [[ -d "$worktree_path" ]]; then
        echo "[INFO] Worktree already exists: $worktree_path"
        echo "Use 'agent dev switch $worktree_name' to switch to it."
        return 0
    fi

    # Fetch latest base branch
    if remote_branch_exists "$FROM_BRANCH"; then
        git fetch origin "$FROM_BRANCH" 2>/dev/null || true
    fi

    # Create worktree with new branch
    echo "Creating worktree..."
    git worktree add -b "$branch_name" "$worktree_path" "origin/$FROM_BRANCH" 2>/dev/null || \
    git worktree add -b "$branch_name" "$worktree_path" "$FROM_BRANCH" || {
        echo "[ERROR] Failed to create worktree" >&2
        return 1
    }

    # Initialize context (inside worktree)
    init_context "$worktree_path" "$TASK_ID" "detached"

    echo ""
    echo "=================================================="
    echo "[OK] Task $TASK_ID started (detached)"
    echo "=================================================="
    echo "Worktree: $worktree_path"
    echo "Branch: $branch_name"
    echo "Context: $worktree_path/.context/"
    echo ""
    echo "To work in this worktree:"
    echo "  cd $worktree_path"
    echo "  # or"
    echo "  agent dev switch $worktree_name"
    echo "=================================================="
}

# List active tasks
dev_list() {
    local project_root
    project_root=$(find_project_root) || return 1

    echo "=================================================="
    echo "Active Tasks"
    echo "=================================================="
    echo ""

    list_task_branches
    echo ""
    list_worktrees "$project_root"
    echo ""
    echo "=================================================="
}

# Switch to another branch or worktree
dev_switch() {
    local target="$1"

    if [[ -z "$target" ]]; then
        echo "[ERROR] Target branch or worktree required" >&2
        echo "Usage: agent dev switch <branch|worktree>" >&2
        return 1
    fi

    local project_root
    project_root=$(find_project_root) || return 1

    local from_branch
    from_branch=$(get_current_branch 2>/dev/null) || from_branch=""

    # Check if it's a worktree
    local worktree_path="$project_root/$WORKTREE_ROOT/$target"
    if [[ -d "$worktree_path" ]]; then
        handoff_save_interactive "$project_root" "$from_branch"
        echo "Switching to worktree: $target"
        cd "$worktree_path" || return 1
        echo "Now in: $(pwd)"
        local new_root
        new_root=$(find_project_root 2>/dev/null) || new_root="$(pwd)"
        local to_branch
        to_branch=$(get_current_branch 2>/dev/null) || to_branch=""
        handoff_show_and_cleanup "$new_root" "$to_branch"
        return 0
    fi

    # Otherwise, treat as branch
    handoff_save_interactive "$project_root" "$from_branch"
    echo "Switching to branch: $target"
    git checkout "$target" || return 1
    local to_branch
    to_branch=$(get_current_branch 2>/dev/null) || to_branch=""
    handoff_show_and_cleanup "$project_root" "$to_branch"
}

# Show current status
dev_status() {
    cmd_status
}

# Run quality checks (lint, test, intent alignment)
# Options:
#   --install-hook    Install pre-commit hook
#   --uninstall-hook  Remove agent-installed pre-commit hook
#   --status          Show hook status
# Warnings only - does not block commit
dev_check() {
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --install-hook)
                hook_install
                return $?
                ;;
            --uninstall-hook)
                hook_uninstall
                return $?
                ;;
            --status)
                hook_status
                return $?
                ;;
            --help|-h)
                show_check_help
                return 0
                ;;
        esac
        shift
    done

    # Default: run quality checks
    local project_root
    project_root=$(find_project_root) || return 1

    local context_path
    context_path=$(get_current_context 2>/dev/null) || context_path=""

    # Run all checks
    run_all_checks "$project_root" "$context_path"
    local result=$?

    # Update summary if context exists
    if [[ -n "$context_path" ]] && [[ -d "$context_path" ]]; then
        # Results are warnings only, continue either way
        echo ""
        echo "[INFO] Check results saved to context"
    fi

    return $result
}

# Show check help
show_check_help() {
    cat << 'EOF'
agent dev check - Run quality checks and manage pre-commit hooks

USAGE:
    agent dev check [options]

OPTIONS:
    --install-hook    Install pre-commit hook (runs lint + test)
    --uninstall-hook  Remove agent-installed pre-commit hook
    --status          Show pre-commit hook status
    -h, --help        Show this help

Without options, runs quality checks:
    - Lint (if configured)
    - Tests (if configured)
    - Intent alignment (plan vs changes)

EXAMPLES:
    # Run quality checks
    agent dev check

    # Install pre-commit hook
    agent dev check --install-hook

    # Check hook status
    agent dev check --status

    # Remove hook
    agent dev check --uninstall-hook

NOTES:
    - Pre-commit hook runs: make lint && make test
    - To skip hook during commit: git commit --no-verify
    - Only removes hooks installed by agent (preserves custom hooks)
EOF
}

# RFC-004 Phase 2: Process answered questions
dev_debrief() {
    local project_root
    project_root=$(find_project_root) || return 1

    local context_path
    context_path=$(get_current_context 2>/dev/null) || {
        echo "[ERROR] No active context found"
        echo "[INFO] Run 'agent dev start <task-id>' first"
        return 1
    }

    local task_id
    task_id=$(extract_task_from_branch "$(get_current_branch)") || task_id="unknown"

    echo "=================================================="
    echo "Processing Questions (Debrief)"
    echo "=================================================="
    echo ""
    echo "Task: $task_id"
    echo "Context: $context_path"
    echo ""

    # Check if questions.md exists
    if [[ ! -f "$context_path/questions.md" ]]; then
        echo "[ERROR] questions.md not found in context"
        echo "[INFO] Questions should be generated during 'agent dev analyze' phase"
        return 1
    fi

    # Process questions
    echo "Processing answered questions from questions.md..."
    process_questions "$context_path"

    echo ""
    echo "[OK] Debrief complete"
    echo ""
    echo "[NEXT] Update design documents based on answers"
    echo "       - Check llm_context.md for recorded decisions"
    echo "       - Update design-solution.md if needed"
    echo "       - Continue with 'agent dev code'"
}

# Generate verification report
dev_verify() {
    local project_root
    project_root=$(find_project_root) || return 1

    local context_path
    context_path=$(get_current_context 2>/dev/null) || {
        echo "[WARN] No active context found"
        echo "[INFO] Generating verification in current directory"
        context_path="."
    }

    local task_id
    task_id=$(extract_task_from_branch "$(get_current_branch)") || task_id="unknown"

    local verification_file="$context_path/verification.md"
    local template_file="$TEMPLATES_DIR/verification.md"

    echo "=================================================="
    echo "Generating Verification Report"
    echo "=================================================="
    echo ""

    if [[ -f "$verification_file" ]]; then
        echo "[INFO] verification.md already exists: $verification_file"
        echo ""
        read -p "Overwrite? [y/N] " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Keeping existing file."
            return 0
        fi
    fi

    # Ensure context directory exists
    mkdir -p "$context_path"

    # Generate from template
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    if [[ -f "$template_file" ]]; then
        sed -e "s/{{TASK_ID}}/$task_id/g" \
            -e "s/{{TIMESTAMP}}/$timestamp/g" \
            "$template_file" > "$verification_file"
    else
        # Inline template if file not found
        cat > "$verification_file" << EOF
# Verification Report: $task_id

Generated: $timestamp

## Requirements Status

| ID | Requirement | Status | Evidence |
|----|-------------|--------|----------|
| R1 | TODO | [ ] | TODO |

## Quality Gates

| Gate | Status | Details |
|------|--------|---------|
| Lint | [ ] | Run 'agent dev check' |
| Tests | [ ] | Run 'agent dev check' |

## Verification Result

- [ ] PASS: All critical requirements met
- [ ] NEEDS WORK: Gaps identified
EOF
    fi

    echo "[OK] Verification report created: $verification_file"
    echo ""

    # RFC-004 Phase 2: Generate quick-summary.md
    echo "Generating quick summary..."
    if command -v generate_quick_summary &>/dev/null; then
        generate_quick_summary "$context_path" 2>/dev/null && \
            echo "[OK] Quick summary generated: $context_path/quick-summary.md" || \
            echo "[WARN] Quick summary generation failed (non-critical)"
    fi
    echo ""

    echo "[NEXT] Edit the file to check off completed requirements"
    echo "       Then run 'agent dev retro' to create retrospective"

    # Open in editor if available
    if [[ -n "${EDITOR:-}" ]]; then
        echo ""
        read -p "Open in editor? [Y/n] " open_response
        if [[ ! "$open_response" =~ ^[Nn]$ ]]; then
            $EDITOR "$verification_file"
        fi
    fi
}

# Create/edit retrospective document
dev_retro() {
    local project_root
    project_root=$(find_project_root) || return 1

    local context_path
    context_path=$(get_current_context 2>/dev/null) || {
        echo "[WARN] No active context found"
        echo "[INFO] Generating retrospective in current directory"
        context_path="."
    }

    local task_id
    task_id=$(extract_task_from_branch "$(get_current_branch)") || task_id="unknown"

    local retro_file="$context_path/retrospective.md"
    local template_file="$TEMPLATES_DIR/retrospective.md"

    echo "=================================================="
    echo "Creating Retrospective"
    echo "=================================================="
    echo ""

    if [[ -f "$retro_file" ]]; then
        echo "[INFO] retrospective.md already exists: $retro_file"
        echo ""
        read -p "Open for editing? [Y/n] " response
        if [[ ! "$response" =~ ^[Nn]$ ]] && [[ -n "${EDITOR:-}" ]]; then
            $EDITOR "$retro_file"
        fi
        return 0
    fi

    # Ensure context directory exists
    mkdir -p "$context_path"

    # Get commit history for this branch
    local commits
    commits=$(git log --oneline origin/main..HEAD 2>/dev/null) || \
    commits=$(git log --oneline -10 2>/dev/null) || \
    commits="(no commits found)"

    # Generate from template
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    if [[ -f "$template_file" ]]; then
        sed -e "s/{{TASK_ID}}/$task_id/g" \
            -e "s/{{TIMESTAMP}}/$timestamp/g" \
            "$template_file" > "$retro_file"

        # Replace commits placeholder
        # Use a temp file to handle multiline
        local temp_file
        temp_file=$(mktemp)
        awk -v commits="$commits" '{
            gsub(/\{\{COMMITS\}\}/, commits)
            print
        }' "$retro_file" > "$temp_file"
        mv "$temp_file" "$retro_file"
    else
        # Inline template if file not found
        cat > "$retro_file" << EOF
# Retrospective: $task_id

Generated: $timestamp

## Intent

TODO: Describe the original goal

## What Changed

$commits

## Surprises

- TODO: Any surprises?

## Learnings

- TODO: What worked well?
- TODO: What could be improved?

## Next Steps

- [ ] TODO: Follow-up tasks
EOF
    fi

    echo "[OK] Retrospective created: $retro_file"
    echo ""
    echo "[NEXT] Fill in the sections before running 'agent dev submit'"

    # Open in editor if available
    if [[ -n "${EDITOR:-}" ]]; then
        echo ""
        read -p "Open in editor? [Y/n] " open_response
        if [[ ! "$open_response" =~ ^[Nn]$ ]]; then
            $EDITOR "$retro_file"
        fi
    fi
}

# Sync with base branch
dev_sync() {
    local action=""
    local base_branch="$DEFAULT_BASE_BRANCH"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --continue)
                action="continue"
                ;;
            --abort)
                action="abort"
                ;;
            --base=*)
                base_branch="${1#*=}"
                ;;
            *)
                base_branch="$1"
                ;;
        esac
        shift
    done

    sync_with_base "$base_branch" "$action"
}

# Submit work (create MR)
# Options:
#   --only=<step>[,<step>,...]  Run only specified steps
#   --skip=<step>[,<step>,...]  Skip specified steps
#   Steps: sync, push, pr, jira
#   --sync     Shortcut for including sync step (deprecated, use --only)
#   --draft    Create MR/PR as draft
#   --force    Skip pre-submit checks
dev_submit() {
    local draft=false
    local force=false
    local only_steps=""
    local skip_steps=""
    # Default: run all steps (sync is opt-in for backward compatibility)
    local run_sync=false
    local run_push=true
    local run_pr=true
    local run_jira=true

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --only=*)
                only_steps="${1#*=}"
                ;;
            --skip=*)
                skip_steps="${1#*=}"
                ;;
            --sync)
                # Backward compatibility: --sync enables sync step
                run_sync=true
                ;;
            --draft)
                draft=true
                ;;
            --force)
                force=true
                ;;
            --help|-h)
                show_submit_help
                return 0
                ;;
        esac
        shift
    done

    # Process --only option
    if [[ -n "$only_steps" ]]; then
        run_sync=false
        run_push=false
        run_pr=false
        run_jira=false
        IFS=',' read -ra steps <<< "$only_steps"
        for step in "${steps[@]}"; do
            case "$step" in
                sync)  run_sync=true ;;
                push)  run_push=true ;;
                pr)    run_pr=true ;;
                jira)  run_jira=true ;;
                *)
                    echo "[ERROR] Unknown step: $step" >&2
                    echo "Valid steps: sync, push, pr, jira" >&2
                    return 1
                    ;;
            esac
        done
    fi

    # Process --skip option
    if [[ -n "$skip_steps" ]]; then
        IFS=',' read -ra steps <<< "$skip_steps"
        for step in "${steps[@]}"; do
            case "$step" in
                sync)  run_sync=false ;;
                push)  run_push=false ;;
                pr)    run_pr=false ;;
                jira)  run_jira=false ;;
                *)
                    echo "[ERROR] Unknown step: $step" >&2
                    echo "Valid steps: sync, push, pr, jira" >&2
                    return 1
                    ;;
            esac
        done
    fi

    # Validate step dependencies
    if [[ "$run_pr" == "true" ]] && [[ "$run_push" == "false" ]]; then
        # Check if remote branch exists
        local current_branch
        current_branch=$(get_current_branch)
        if ! remote_branch_exists "$current_branch"; then
            echo "[ERROR] Cannot create PR: remote branch does not exist" >&2
            echo "[INFO] Run 'agent dev submit --only=push' first" >&2
            echo "       or use '--only=push,pr' to push and create PR together" >&2
            return 1
        fi
    fi

    local project_root
    project_root=$(find_project_root) || return 1

    local current_branch
    current_branch=$(get_current_branch)

    local task_id
    task_id=$(extract_task_from_branch "$current_branch") || {
        echo "[WARN] Could not extract task ID from branch: $current_branch"
        task_id="N/A"
    }

    # Calculate total steps
    local total_steps=0
    local step_names=()
    [[ "$run_sync" == "true" ]] && { ((total_steps++)); step_names+=("sync"); }
    [[ "$run_push" == "true" ]] && { ((total_steps++)); step_names+=("push"); }
    [[ "$run_pr" == "true" ]] && { ((total_steps++)); step_names+=("pr"); }
    [[ "$run_jira" == "true" ]] && { ((total_steps++)); step_names+=("jira"); }

    echo "=================================================="
    echo "Submitting: $current_branch"
    echo "=================================================="
    echo "Steps: ${step_names[*]:-none}"
    echo ""

    # Pre-submit checks (verification + retrospective)
    local context_path
    context_path=$(get_current_context 2>/dev/null) || context_path=""

    if [[ -n "$context_path" ]] && [[ -d "$context_path" ]]; then
        echo "[Pre-check] Running pre-submit checks..."
        if ! run_submit_checks "$context_path" "$force"; then
            echo ""
            echo "[BLOCKED] Fix issues or use --force to skip"
            return 1
        fi
        echo ""
    fi

    local current_step=0
    local completed_steps=()
    local failed_step=""

    # Step: Sync
    if [[ "$run_sync" == "true" ]]; then
        ((current_step++))
        echo "[Step $current_step/$total_steps] Syncing with base branch..."
        if sync_with_base; then
            completed_steps+=("sync")
        else
            failed_step="sync"
            echo ""
            _submit_status "${completed_steps[*]}" "$failed_step"
            return 1
        fi
        echo ""
    fi

    # Step: Push
    if [[ "$run_push" == "true" ]]; then
        ((current_step++))
        echo "[Step $current_step/$total_steps] Pushing branch..."
        if git push -u origin "$current_branch"; then
            completed_steps+=("push")
        else
            failed_step="push"
            echo "[ERROR] Failed to push branch" >&2
            _submit_status "${completed_steps[*]}" "$failed_step"
            return 1
        fi
        echo ""
    fi

    # Step: Create MR/PR
    if [[ "$run_pr" == "true" ]]; then
        ((current_step++))
        echo "[Step $current_step/$total_steps] Creating Merge Request..."
        local pm_cmd="$SCRIPT_DIR/../../pm/bin/pm"
        if [[ ! -x "$pm_cmd" ]]; then
            pm_cmd=$(command -v pm 2>/dev/null) || {
                echo "[WARN] pm CLI not found, skipping MR creation"
                echo "Create MR manually on GitLab/GitHub"
                pm_cmd=""
            }
        fi

        if [[ -n "$pm_cmd" ]]; then
            local commit_msg
            commit_msg=$(git log -1 --format=%s)
            local mr_title="$task_id: $commit_msg"

            # Get context summary for MR description
            local mode
            mode=$(detect_git_mode)
            if [[ "$mode" == "detached" ]]; then
                context_path="$(pwd)/.context"
            else
                context_path="$project_root/.context/$task_id"
            fi

            if [[ -f "$context_path/summary.yaml" ]]; then
                echo "  Including context summary in MR description..."
            fi

            # Detect platform and create MR/PR
            local platform=""
            local config_output
            config_output=$("$pm_cmd" config show 2>/dev/null)
            if echo "$config_output" | grep -A2 "\[GitHub\]" | grep -q "Repo:.*[a-zA-Z0-9]"; then
                platform="github"
            elif echo "$config_output" | grep -A3 "\[GitLab\]" | grep -q "Project:.*[a-zA-Z0-9]"; then
                platform="gitlab"
            fi

            if [[ "$platform" == "github" ]]; then
                echo "  Creating GitHub Pull Request..."
                local pr_result
                if [[ "$draft" == "true" ]]; then
                    pr_result=$("$pm_cmd" github pr create --head "$current_branch" --title "$mr_title" --draft 2>&1)
                else
                    pr_result=$("$pm_cmd" github pr create --head "$current_branch" --title "$mr_title" 2>&1)
                fi
                if echo "$pr_result" | grep -q "Created:"; then
                    echo "$pr_result"
                    completed_steps+=("pr")
                else
                    echo "$pr_result"
                    echo "  [WARN] PR creation failed, create manually"
                fi
            elif [[ "$platform" == "gitlab" ]]; then
                echo "  Creating GitLab Merge Request..."
                local mr_result
                if [[ "$draft" == "true" ]]; then
                    mr_result=$("$pm_cmd" gitlab mr create --source "$current_branch" --title "$mr_title" --draft 2>&1)
                else
                    mr_result=$("$pm_cmd" gitlab mr create --source "$current_branch" --title "$mr_title" 2>&1)
                fi
                if echo "$mr_result" | grep -q "Created:"; then
                    echo "$mr_result"
                    completed_steps+=("pr")
                else
                    echo "$mr_result"
                    echo "  [WARN] MR creation failed, create manually"
                fi
            else
                echo "[WARN] No GitHub/GitLab configured, skipping MR/PR creation"
                echo "      Configure with: pm config init"
            fi
        fi
        echo ""
    fi

    # Step: Jira transition
    if [[ "$run_jira" == "true" ]]; then
        ((current_step++))
        echo "[Step $current_step/$total_steps] Updating Jira status..."
        if [[ "$task_id" == "N/A" ]] || [[ -z "$task_id" ]]; then
            echo "  [SKIP] No task ID found, skipping Jira update"
        else
            local pm_cmd="$SCRIPT_DIR/../../pm/bin/pm"
            if [[ ! -x "$pm_cmd" ]]; then
                pm_cmd=$(command -v pm 2>/dev/null) || pm_cmd=""
            fi
            if [[ -n "$pm_cmd" ]]; then
                # Try to transition to "In Review" status
                local jira_result
                jira_result=$("$pm_cmd" jira issue transition "$task_id" "In Review" 2>&1) && {
                    echo "  [OK] Jira status updated to 'In Review'"
                    completed_steps+=("jira")
                } || {
                    echo "  [WARN] Jira transition failed: $jira_result"
                    echo "  [INFO] Update Jira status manually"
                }
            else
                echo "  [SKIP] pm CLI not found"
            fi
        fi
        echo ""
    fi

    # Archive context (always run if we did any submit steps)
    if [[ ${#completed_steps[@]} -gt 0 ]]; then
        echo "[Cleanup] Archiving context..."
        archive_context "$project_root" "$task_id" 2>/dev/null || true
        echo ""
    fi

    # Final status
    echo "=================================================="
    echo "[OK] Submit complete"
    echo "=================================================="
    _submit_status "${completed_steps[*]}" ""
    echo "Next: Wait for MR review and approval"
    echo "=================================================="
}

# Helper: Show submit status
_submit_status() {
    local completed="$1"
    local failed="$2"

    if [[ -n "$completed" ]]; then
        echo "Completed: $completed"
    fi
    if [[ -n "$failed" ]]; then
        echo "Failed: $failed"
    fi
}

# Show submit help
show_submit_help() {
    cat << 'EOF'
agent dev submit - Submit work (sync, push, create MR, update Jira)

USAGE:
    agent dev submit [options]

OPTIONS:
    --only=<steps>    Run only specified steps (comma-separated)
    --skip=<steps>    Skip specified steps (comma-separated)
    --sync            Include sync step (shortcut for --only with sync)
    --draft           Create MR/PR as draft
    --force           Skip pre-submit checks
    -h, --help        Show this help

STEPS:
    sync    Sync with base branch (git fetch + rebase)
    push    Push branch to remote
    pr      Create MR/PR
    jira    Update Jira status to "In Review"

EXAMPLES:
    # Default: push + pr + jira (sync is opt-in)
    agent dev submit

    # Sync first, then push + pr + jira
    agent dev submit --sync

    # Only sync (rebase on main)
    agent dev submit --only=sync

    # Only push branch
    agent dev submit --only=push

    # Push and create PR together
    agent dev submit --only=push,pr

    # Skip Jira update
    agent dev submit --skip=jira

    # Create draft PR
    agent dev submit --draft

NOTES:
    - 'pr' step requires remote branch to exist
    - If --only=pr without push, remote branch must exist
    - Default behavior unchanged for backward compatibility
EOF
}

# Cleanup task
dev_cleanup() {
    local task_id="$1"

    if [[ -z "$task_id" ]]; then
        echo "[ERROR] Task ID required" >&2
        echo "Usage: agent dev cleanup <task-id>" >&2
        return 1
    fi

    task_id=$(parse_task_id "$task_id")

    local project_root
    project_root=$(find_project_root) || return 1

    echo "Cleaning up task: $task_id"
    echo ""

    local branch_name
    branch_name=$(generate_branch_name "$task_id")

    # Check for worktrees first
    local worktree_pattern="$project_root/$WORKTREE_ROOT/${task_id}*"
    local found_worktrees=false

    for wt in $worktree_pattern; do
        if [[ -d "$wt" ]]; then
            found_worktrees=true
            local wt_name
            wt_name=$(basename "$wt")
            echo "Removing worktree: $wt_name"
            git worktree remove "$wt" --force 2>/dev/null || {
                echo "[WARN] Could not remove worktree, trying manual cleanup..."
                rm -rf "$wt"
                git worktree prune
            }
        fi
    done

    # Remove branch if it exists and we're not on it
    local current_branch
    current_branch=$(get_current_branch)

    if branch_exists "$branch_name" && [[ "$current_branch" != "$branch_name" ]]; then
        echo "Removing branch: $branch_name"
        git branch -D "$branch_name" 2>/dev/null || {
            echo "[WARN] Could not remove branch: $branch_name"
        }
    elif [[ "$current_branch" == "$branch_name" ]]; then
        echo "[WARN] Cannot remove current branch: $branch_name"
        echo "Switch to another branch first."
    fi

    # Remove context
    local context_path="$project_root/.context/$task_id"
    if [[ -d "$context_path" ]]; then
        echo "Removing context: .context/$task_id"
        rm -rf "$context_path"
    fi

    echo ""
    echo "[OK] Cleanup complete for $task_id"
}

# Manager commands are in manager.sh
# Loaded via agent CLI main script
