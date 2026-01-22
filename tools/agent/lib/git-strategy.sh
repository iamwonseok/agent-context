#!/bin/bash
# Git Strategy for agent CLI
# Supports: Interactive Mode (branch) and Detached Mode (worktree)

# Default base branch
DEFAULT_BASE_BRANCH="main"

# Worktree root directory
WORKTREE_ROOT=".worktrees"

# Detect current mode
# Returns: "interactive" or "detached"
detect_git_mode() {
    local git_dir
    git_dir=$(git rev-parse --git-dir 2>/dev/null) || return 1
    
    if [[ "$git_dir" == *".git/worktrees/"* ]]; then
        echo "detached"
    else
        echo "interactive"
    fi
}

# Check if branch exists
branch_exists() {
    local branch="$1"
    git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null
}

# Check if remote branch exists
remote_branch_exists() {
    local branch="$1"
    local remote="${2:-origin}"
    git show-ref --verify --quiet "refs/remotes/$remote/$branch" 2>/dev/null
}

# Get current branch name
get_current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Get branch prefix for task type
# TASK-123 -> feat/
# BUG-456 -> fix/
# HOTFIX-789 -> hotfix/
get_branch_prefix() {
    local task_id="$1"
    
    case "$task_id" in
        BUG-*|bug-*)
            echo "fix/"
            ;;
        HOTFIX-*|hotfix-*)
            echo "hotfix/"
            ;;
        REFACTOR-*|refactor-*)
            echo "refactor/"
            ;;
        *)
            echo "feat/"
            ;;
    esac
}

# Generate branch name from task ID
# TASK-123 -> feat/TASK-123
generate_branch_name() {
    local task_id="$1"
    local prefix
    prefix=$(get_branch_prefix "$task_id")
    echo "${prefix}${task_id}"
}

# Generate worktree directory name
# TASK-123 with try="jwt" -> TASK-123-jwt
generate_worktree_name() {
    local task_id="$1"
    local try_name="$2"
    
    if [[ -n "$try_name" ]]; then
        echo "${task_id}-${try_name}"
    else
        echo "$task_id"
    fi
}

# List active branches for tasks
list_task_branches() {
    echo "Active Task Branches:"
    echo ""
    
    local branches
    branches=$(git branch --list 'feat/*' --list 'fix/*' --list 'hotfix/*' --list 'refactor/*' 2>/dev/null)
    
    if [[ -z "$branches" ]]; then
        echo "  (none)"
        return
    fi
    
    local current_branch
    current_branch=$(get_current_branch)
    
    while IFS= read -r branch; do
        branch="${branch#  }"  # Remove leading spaces
        branch="${branch#\* }" # Remove asterisk for current
        
        local marker=""
        if [[ "$branch" == "$current_branch" ]]; then
            marker=" <- current"
        fi
        
        # Extract task ID
        local task_id
        task_id=$(extract_task_from_branch "$branch") || task_id="(no task)"
        
        echo "  $branch ($task_id)$marker"
    done <<< "$branches"
}

# List active worktrees
list_worktrees() {
    local project_root="$1"
    local worktree_root="$project_root/$WORKTREE_ROOT"
    
    echo "Active Worktrees:"
    echo ""
    
    if [[ ! -d "$worktree_root" ]]; then
        echo "  (none)"
        return
    fi
    
    local found=false
    for dir in "$worktree_root"/*/; do
        if [[ -d "$dir" ]]; then
            local name
            name=$(basename "$dir")
            local branch
            branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null) || branch="(unknown)"
            echo "  $name (branch: $branch)"
            found=true
        fi
    done
    
    if [[ "$found" == "false" ]]; then
        echo "  (none)"
    fi
}

# Sync with base branch (fetch + rebase)
sync_with_base() {
    local base_branch="${1:-$DEFAULT_BASE_BRANCH}"
    local action="${2:-rebase}"  # rebase, continue, abort
    
    case "$action" in
        continue)
            echo "Continuing rebase..."
            git rebase --continue
            ;;
        abort)
            echo "Aborting rebase..."
            git rebase --abort
            ;;
        *)
            echo "Syncing with $base_branch..."
            
            # Fetch latest
            echo "  Fetching origin/$base_branch..."
            git fetch origin "$base_branch" || {
                echo "[ERROR] Failed to fetch origin/$base_branch" >&2
                return 1
            }
            
            # Check if rebase is needed
            local current_branch
            current_branch=$(get_current_branch)
            
            local behind
            behind=$(git rev-list --count "HEAD..origin/$base_branch" 2>/dev/null) || behind=0
            
            if [[ "$behind" -eq 0 ]]; then
                echo "  Already up to date."
                return 0
            fi
            
            echo "  $behind commits behind origin/$base_branch"
            echo "  Rebasing..."
            
            if ! git rebase "origin/$base_branch"; then
                echo ""
                echo "[CONFLICT] Rebase conflicts detected!"
                echo ""
                echo "To resolve:"
                echo "  1. Fix conflicts in the files listed above"
                echo "  2. Run: git add <resolved-files>"
                echo "  3. Run: agent dev sync --continue"
                echo ""
                echo "To abort and restore previous state:"
                echo "  Run: agent dev sync --abort"
                return 1
            fi
            
            echo "  Sync complete."
            ;;
    esac
}
