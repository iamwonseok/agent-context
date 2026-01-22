#!/bin/bash
# Command parser utilities for agent CLI

# Find project root (contains .agent/ or .git)
find_project_root() {
    local dir="${1:-$(pwd)}"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.agent" ]] || [[ -d "$dir/.git" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    echo "[ERROR] Cannot find project root (.agent or .git)" >&2
    return 1
}

# Parse task-id from various formats
# Supports: TASK-123, task-123, 123 (with default prefix)
parse_task_id() {
    local input="$1"
    local default_prefix="${2:-TASK}"
    
    # Already has prefix (TASK-123, BUG-456, etc.)
    if [[ "$input" =~ ^[A-Z]+-[0-9]+$ ]]; then
        echo "$input"
        return 0
    fi
    
    # Lowercase with prefix (task-123)
    if [[ "$input" =~ ^[a-z]+-[0-9]+$ ]]; then
        echo "${input^^}"  # Convert to uppercase
        return 0
    fi
    
    # Just a number
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        echo "${default_prefix}-${input}"
        return 0
    fi
    
    # Return as-is if doesn't match patterns
    echo "$input"
}

# Extract task-id from branch name
# feat/TASK-123-description -> TASK-123
extract_task_from_branch() {
    local branch="$1"
    
    # Remove prefix (feat/, fix/, hotfix/, etc.)
    local without_prefix="${branch#*/}"
    
    # Extract task-id pattern
    if [[ "$without_prefix" =~ ^([A-Z]+-[0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    
    # No task-id found
    return 1
}

# Parse options from arguments
# Usage: parse_options "$@"
# Sets global variables: DETACHED, TRY_NAME, FROM_BRANCH, TASK_ID
parse_start_options() {
    DETACHED=false
    TRY_NAME=""
    FROM_BRANCH="main"
    TASK_ID=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --detached)
                DETACHED=true
                ;;
            --try=*)
                TRY_NAME="${1#*=}"
                ;;
            --from=*)
                FROM_BRANCH="${1#*=}"
                ;;
            -*)
                echo "[ERROR] Unknown option: $1" >&2
                return 1
                ;;
            *)
                if [[ -z "$TASK_ID" ]]; then
                    TASK_ID=$(parse_task_id "$1")
                else
                    echo "[ERROR] Unexpected argument: $1" >&2
                    return 1
                fi
                ;;
        esac
        shift
    done
    
    if [[ -z "$TASK_ID" ]]; then
        echo "[ERROR] Task ID required" >&2
        return 1
    fi
}

# Show developer help
show_dev_help() {
    cat << 'EOF'
agent dev - Developer Commands

USAGE:
    agent dev <command> [options]

COMMANDS:
    start <task-id>         Start working on a task
        --detached          Use worktree mode (background work)
        --try=<name>        Name the try (for A/B testing)
        --from=<branch>     Branch to start from (default: main)
    
    list                    List active tasks
    switch <branch>         Switch to branch or worktree
    status                  Show current work status
    
    check                   Run quality checks (lint, test, intent)
                            Warnings only - does not block commit
    
    verify                  Generate verification report
                            Creates .context/{task-id}/verification.md
    
    retro                   Create/edit retrospective document
                            Creates .context/{task-id}/retrospective.md
    
    sync                    Sync with base branch (rebase)
        --continue          Continue after resolving conflicts
        --abort             Abort rebase and restore state
    
    submit                  Create MR and cleanup
        --sync              Sync before submit
        --draft             Create as draft MR
        --force             Skip pre-submit checks (not recommended)
    
    cleanup <task-id>       Clean up completed task

WORKFLOW:
    1. agent dev start TASK-123      # Start task
    2. (make changes)
    3. agent dev check               # Verify quality + intent
    4. git commit -m "..."           # Commit changes
    5. agent dev verify              # Generate verification report
    6. agent dev retro               # Write retrospective
    7. agent dev submit              # Create MR

EXAMPLES:
    agent dev start TASK-123
    agent dev check
    agent dev verify
    agent dev retro
    agent dev submit

For design philosophy, see: .agent/why.md
EOF
}

# Show manager help
show_mgr_help() {
    cat << 'EOF'
agent mgr - Manager Commands

USAGE:
    agent mgr <command> [options]

COMMANDS:
    pending                 List pending MRs for review
    review <mr-id>          Review MR details
        --comment <msg>     Add review comment
    approve <mr-id>         Approve MR
    status <id>             Check status of initiative/epic/task

EXAMPLES:
    agent mgr pending
    agent mgr review MR-456
    agent mgr approve MR-456
    agent mgr status EPIC-1
EOF
}
