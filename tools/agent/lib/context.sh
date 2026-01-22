#!/bin/bash
# Context management for agent CLI
# Manages .context/{task-id}/ directories for work tracking

# Context directory name
CONTEXT_DIR=".context"

# Initialize context for a task
# Usage: init_context <project_root> <task_id> <mode>
init_context() {
    local project_root="$1"
    local task_id="$2"
    local mode="${3:-interactive}"  # interactive or detached
    
    local context_path
    
    if [[ "$mode" == "detached" ]]; then
        # In detached mode, context is inside the worktree
        context_path="$project_root/$CONTEXT_DIR"
    else
        # In interactive mode, context is task-specific
        context_path="$project_root/$CONTEXT_DIR/$task_id"
    fi
    
    # Create directory structure
    mkdir -p "$context_path/attempts"
    
    # Create try.yaml
    create_try_yaml "$context_path" "$task_id" "$mode"
    
    echo "  Context initialized: $context_path"
}

# Create try.yaml file
create_try_yaml() {
    local context_path="$1"
    local task_id="$2"
    local mode="$3"
    
    local try_file="$context_path/try.yaml"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || branch="unknown"
    
    cat > "$try_file" << EOF
# Agent Workflow Context
# Task: $task_id
# Created: $timestamp

task_id: "$task_id"
mode: "$mode"
branch: "$branch"
started_at: "$timestamp"
status: "in_progress"

# Goal description (filled by agent or user)
goal: |
  TODO: Describe the goal of this task

# Expected outcome
expected: |
  TODO: Describe expected outcome

# Actual outcome (filled on completion)
actual: ""

# Key learnings (filled on completion)
learnings: []

# Attempt counter
attempt_count: 0
EOF
}

# Create a new attempt record
# Usage: create_attempt <context_path> <description>
create_attempt() {
    local context_path="$1"
    local description="${2:-Attempt}"
    
    local try_file="$context_path/try.yaml"
    
    if [[ ! -f "$try_file" ]]; then
        echo "[ERROR] Context not initialized: $context_path" >&2
        return 1
    fi
    
    # Get current attempt count and increment
    local count
    count=$(grep "^attempt_count:" "$try_file" | awk '{print $2}')
    count=$((count + 1))
    
    # Update count in try.yaml
    if command -v yq &>/dev/null; then
        yq -i ".attempt_count = $count" "$try_file"
    else
        # Simple sed replacement
        sed -i.bak "s/^attempt_count:.*/attempt_count: $count/" "$try_file"
        rm -f "${try_file}.bak"
    fi
    
    # Create attempt file
    local attempt_file
    attempt_file=$(printf "%s/attempts/attempt-%03d.yaml" "$context_path" "$count")
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    cat > "$attempt_file" << EOF
# Attempt $count
# Created: $timestamp

attempt_number: $count
timestamp: "$timestamp"
description: "$description"

# What was tried
approach: |
  TODO: Describe approach

# Result
result: ""
status: "in_progress"

# Files changed
files_changed: []

# Commit SHA (if committed)
commit_sha: ""

# Notes
notes: []
EOF
    
    echo "$attempt_file"
}

# Update attempt with result
# Usage: update_attempt <attempt_file> <status> <result>
update_attempt() {
    local attempt_file="$1"
    local status="$2"
    local result="$3"
    
    if [[ ! -f "$attempt_file" ]]; then
        echo "[ERROR] Attempt file not found: $attempt_file" >&2
        return 1
    fi
    
    if command -v yq &>/dev/null; then
        yq -i ".status = \"$status\" | .result = \"$result\"" "$attempt_file"
    else
        # Simple replacement (limited)
        sed -i.bak "s/^status:.*/status: \"$status\"/" "$attempt_file"
        rm -f "${attempt_file}.bak"
    fi
}

# Generate summary from attempts
# Usage: generate_summary <context_path>
generate_summary() {
    local context_path="$1"
    local summary_file="$context_path/summary.yaml"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Count attempts
    local attempt_count
    attempt_count=$(ls -1 "$context_path/attempts/"attempt-*.yaml 2>/dev/null | wc -l | tr -d ' ')
    
    # Get task info from try.yaml
    local task_id=""
    local goal=""
    if [[ -f "$context_path/try.yaml" ]]; then
        task_id=$(grep "^task_id:" "$context_path/try.yaml" | sed 's/task_id: *//' | tr -d '"')
    fi
    
    cat > "$summary_file" << EOF
# Context Summary
# Generated: $timestamp

task_id: "$task_id"
generated_at: "$timestamp"
total_attempts: $attempt_count

# Summary of work done
summary: |
  Task $task_id
  Total attempts: $attempt_count
  
  TODO: Add detailed summary

# Key decisions made
decisions: []

# Open questions
open_questions: []

# For MR description
mr_description: |
  ## Context
  
  Task: $task_id
  
  ## Changes
  
  TODO: Describe changes
  
  ## Testing
  
  TODO: Describe testing done
EOF
    
    echo "  Summary generated: $summary_file"
}

# Archive context (called after submit)
archive_context() {
    local project_root="$1"
    local task_id="$2"
    
    local context_path="$project_root/$CONTEXT_DIR/$task_id"
    
    if [[ ! -d "$context_path" ]]; then
        echo "  No context to archive for $task_id"
        return 0
    fi
    
    # Generate final summary
    generate_summary "$context_path"
    
    # For MVP, just note that context would be archived/deleted
    echo "  Context archived for $task_id"
    echo "  [INFO] In production, context would be uploaded to Issue/MR"
}

# List active contexts
list_active_contexts() {
    local project_root="$1"
    local context_root="$project_root/$CONTEXT_DIR"
    
    if [[ ! -d "$context_root" ]]; then
        echo "  (no active contexts)"
        return
    fi
    
    local found=false
    for dir in "$context_root"/*/; do
        if [[ -d "$dir" ]] && [[ -f "$dir/try.yaml" ]]; then
            local task_id
            task_id=$(basename "$dir")
            local status
            status=$(grep "^status:" "$dir/try.yaml" 2>/dev/null | awk '{print $2}' | tr -d '"')
            echo "  $task_id (status: ${status:-unknown})"
            found=true
        fi
    done
    
    if [[ "$found" == "false" ]]; then
        echo "  (no active contexts)"
    fi
}

# Get context path for current work
get_current_context() {
    local project_root
    project_root=$(find_project_root 2>/dev/null) || return 1
    
    local mode
    mode=$(detect_git_mode)
    
    if [[ "$mode" == "detached" ]]; then
        echo "$(pwd)/$CONTEXT_DIR"
    else
        local branch
        branch=$(get_current_branch)
        local task_id
        task_id=$(extract_task_from_branch "$branch") || return 1
        echo "$project_root/$CONTEXT_DIR/$task_id"
    fi
}
