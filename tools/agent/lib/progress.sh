#!/bin/bash
# Progress tracking library for debugging and audit trail
# Usage: source this file and use progress_* functions
#
# Format: [TIMESTAMP] TYPE: message
# Types: START, SKILL, RETRY, ERROR, DONE, INFO

# Get context directory for current task
_progress_get_context_dir() {
    local task_id="${1:-}"
    
    if [[ -n "$task_id" ]]; then
        echo ".context/$task_id"
    elif [[ -n "$AGENT_TASK_ID" ]]; then
        echo ".context/$AGENT_TASK_ID"
    else
        echo ".context/default"
    fi
}

# Get progress file path
_progress_get_file() {
    local context_dir
    context_dir="$(_progress_get_context_dir "$1")"
    echo "$context_dir/progress.txt"
}

# Format timestamp
_progress_timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

# Write to progress file
_progress_write() {
    local type="$1"
    local message="$2"
    local task_id="${3:-}"
    local progress_file
    
    progress_file="$(_progress_get_file "$task_id")"
    
    # Create directory if needed
    mkdir -p "$(dirname "$progress_file")"
    
    # Append to progress file
    echo "[$(_progress_timestamp)] $type: $message" >> "$progress_file"
    
    # Also print to stdout if not in quiet mode
    if [[ "${AGENT_QUIET:-0}" != "1" ]]; then
        echo "[$(_progress_timestamp)] $type: $message"
    fi
}

# Initialize progress for a new task
# Usage: progress_init TASK-123 "UART driver implementation"
progress_init() {
    local task_id="$1"
    local description="${2:-}"
    local context_dir
    
    if [[ -z "$task_id" ]]; then
        echo "[ERROR] progress_init requires task_id" >&2
        return 1
    fi
    
    context_dir="$(_progress_get_context_dir "$task_id")"
    mkdir -p "$context_dir"
    
    # Export for subsequent calls
    export AGENT_TASK_ID="$task_id"
    
    _progress_write "START" "$task_id ${description:+\"$description\"}" "$task_id"
    
    # Also create/update state.yaml
    cat > "$context_dir/state.yaml" << EOF
task_id: $task_id
description: "$description"
branch: ""
current_stage: analyze
stages:
  analyze: pending
  planning: pending
  execute: pending
  validate: pending
  integrate: pending
started_at: $(_progress_timestamp)
last_error: null
retry_count: 0
EOF
}

# Log skill execution
# Usage: progress_skill analyze/parse-requirement OK
# Usage: progress_skill execute/write-code FAIL "lint error"
progress_skill() {
    local skill="$1"
    local status="$2"
    local detail="${3:-}"
    
    if [[ "$status" == "OK" ]]; then
        _progress_write "SKILL" "$skill - OK"
    else
        _progress_write "SKILL" "$skill - $status${detail:+ ($detail)}"
    fi
}

# Log retry attempt
# Usage: progress_retry execute/write-code 2
progress_retry() {
    local skill="$1"
    local attempt="${2:-}"
    
    _progress_write "RETRY" "$skill${attempt:+ (attempt $attempt)}"
}

# Log error
# Usage: progress_error "Failed to create branch"
progress_error() {
    local message="$1"
    
    _progress_write "ERROR" "$message"
    
    # Update state.yaml if exists
    local state_file
    state_file="$(_progress_get_context_dir)/state.yaml"
    if [[ -f "$state_file" ]]; then
        # Update last_error (simple sed replacement)
        sed -i.bak "s/^last_error:.*/last_error: \"$message\"/" "$state_file"
        rm -f "$state_file.bak"
    fi
}

# Log completion
# Usage: progress_done "MR !456 created"
progress_done() {
    local message="${1:-completed}"
    
    _progress_write "DONE" "$message"
    
    # Update state.yaml if exists
    local state_file
    state_file="$(_progress_get_context_dir)/state.yaml"
    if [[ -f "$state_file" ]]; then
        echo "completed_at: $(_progress_timestamp)" >> "$state_file"
    fi
}

# Log info message
# Usage: progress_info "Switching to feature branch"
progress_info() {
    local message="$1"
    
    _progress_write "INFO" "$message"
}

# Update current stage
# Usage: progress_stage execute
progress_stage() {
    local stage="$1"
    local state_file
    
    state_file="$(_progress_get_context_dir)/state.yaml"
    if [[ -f "$state_file" ]]; then
        sed -i.bak "s/^current_stage:.*/current_stage: $stage/" "$state_file"
        rm -f "$state_file.bak"
    fi
    
    _progress_write "INFO" "Stage: $stage"
}

# Show current progress
# Usage: progress_show
# Usage: progress_show TASK-123
progress_show() {
    local task_id="${1:-}"
    local progress_file
    
    progress_file="$(_progress_get_file "$task_id")"
    
    if [[ ! -f "$progress_file" ]]; then
        echo "[INFO] No progress file found"
        return 0
    fi
    
    echo "=== Progress for ${task_id:-current task} ==="
    cat "$progress_file"
    echo "=== End of progress ==="
}

# Get last N entries
# Usage: progress_tail 5
progress_tail() {
    local n="${1:-10}"
    local progress_file
    
    progress_file="$(_progress_get_file)"
    
    if [[ -f "$progress_file" ]]; then
        tail -n "$n" "$progress_file"
    fi
}

# Check if task has errors
# Usage: if progress_has_error; then ...
progress_has_error() {
    local progress_file
    progress_file="$(_progress_get_file)"
    
    [[ -f "$progress_file" ]] && grep -q "ERROR:" "$progress_file"
}

# Get current task state
# Usage: state=$(progress_get_state current_stage)
progress_get_state() {
    local key="$1"
    local state_file
    
    state_file="$(_progress_get_context_dir)/state.yaml"
    
    if [[ -f "$state_file" ]]; then
        grep "^${key}:" "$state_file" | sed "s/^${key}:[[:space:]]*//"
    fi
}
