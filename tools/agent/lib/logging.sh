#!/bin/bash
# Logging library for agent-context
# All CLI commands are logged to .context/logs/agent.log
# All workflow/skill executions are logged to .context/logs/workflow.log
#
# Usage: source this file at the start of any command
#
# Log format:
#   [TIMESTAMP] [PID:xxxxx] [branch:xxx] TYPE: message
#
# Note: Do NOT use 'set -e' in this library as it's sourced by other scripts

# =============================================================================
# Configuration
# =============================================================================

# Note: Check AGENT_LOGGING directly in each function to support runtime changes
# Default: logging enabled (AGENT_LOGGING=1)

_logging_enabled() {
    [[ "${AGENT_LOGGING:-1}" == "1" ]]
}

_logging_verbose() {
    [[ "${AGENT_LOG_VERBOSE:-0}" == "1" ]]
}

# =============================================================================
# Path Detection
# =============================================================================

# Find project root (directory with .git or .project.yaml)
_log_find_project_root() {
    local dir="${1:-$PWD}"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.git" ]] || [[ -f "$dir/.project.yaml" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    echo ""
}

# Detect worktree name from current path
# - In worktree: returns worktree name (e.g., TASK-123)
# - In main: returns empty string
_log_get_worktree_name() {
    local dir="${1:-$PWD}"
    
    # Pattern: /.worktrees/TASK-XXX/
    if [[ "$dir" == *"/.worktrees/"* ]]; then
        echo "$dir" | sed 's|.*/.worktrees/\([^/]*\).*|\1|'
    else
        echo ""
    fi
}

# Get log directory path
# - main: .context/logs/
# - worktree: main/.context/{worktree-name}/logs/ (via symlink)
_log_get_dir() {
    local project_root
    project_root=$(_log_find_project_root)
    
    if [[ -z "$project_root" ]]; then
        project_root="$PWD"
    fi
    
    local worktree_name
    worktree_name=$(_log_get_worktree_name)
    
    local context_dir="$project_root/.context"
    
    # If .context is a symlink, resolve to real path
    if [[ -L "$context_dir" ]]; then
        context_dir=$(readlink "$context_dir")
        # Handle relative symlink
        if [[ ! "$context_dir" = /* ]]; then
            context_dir="$project_root/$context_dir"
        fi
    fi
    
    local log_dir
    if [[ -n "$worktree_name" ]]; then
        log_dir="$context_dir/$worktree_name/logs"
    else
        log_dir="$context_dir/logs"
    fi
    
    mkdir -p "$log_dir"
    echo "$log_dir"
}

# Get CLI log file path
_log_get_agent_file() {
    echo "$(_log_get_dir)/agent.log"
}

# Get workflow log file path  
_log_get_workflow_file() {
    echo "$(_log_get_dir)/workflow.log"
}

# =============================================================================
# Metadata
# =============================================================================

# Get current git branch
_log_get_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "no-branch"
}

# Format timestamp
_log_timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

# Get formatted prefix with PID and branch
_log_prefix() {
    local branch
    branch=$(_log_get_branch)
    echo "[PID:$$] [branch:$branch]"
}

# =============================================================================
# CLI Command Logging (agent.log)
# =============================================================================

# Log command start
# Usage: log_cmd_start "agnt-c dev start TASK-123"
log_cmd_start() {
    if ! _logging_enabled; then return 0; fi
    
    local cmd="$1"
    local log_file
    log_file=$(_log_get_agent_file)
    
    echo "[$(_log_timestamp)] $(_log_prefix) CMD: $cmd" >> "$log_file"
    
    if _logging_verbose; then echo "[LOG] CMD: $cmd"; fi
}

# Log command end with exit code
# Usage: log_cmd_end 0 "success"
log_cmd_end() {
    if ! _logging_enabled; then return 0; fi
    
    local exit_code="$1"
    local message="${2:-}"
    local log_file
    log_file=$(_log_get_agent_file)
    
    local status="success"
    if [[ "$exit_code" != "0" ]]; then status="failed"; fi
    
    echo "[$(_log_timestamp)] $(_log_prefix) EXIT: $exit_code ($status)${message:+ - $message}" >> "$log_file"
    
    if _logging_verbose; then echo "[LOG] EXIT: $exit_code"; fi
}

# Log info message
# Usage: log_info "Creating branch feature/TASK-123"
log_info() {
    if ! _logging_enabled; then return 0; fi
    
    local message="$1"
    local log_file
    log_file=$(_log_get_agent_file)
    
    echo "[$(_log_timestamp)] $(_log_prefix) INFO: $message" >> "$log_file"
}

# Log warning
# Usage: log_warn "Branch already exists"
log_warn() {
    if ! _logging_enabled; then return 0; fi
    
    local message="$1"
    local log_file
    log_file=$(_log_get_agent_file)
    
    echo "[$(_log_timestamp)] $(_log_prefix) WARN: $message" >> "$log_file"
}

# Log error
# Usage: log_error "Failed to create branch"
log_error() {
    if ! _logging_enabled; then return 0; fi
    
    local message="$1"
    local log_file
    log_file=$(_log_get_agent_file)
    
    echo "[$(_log_timestamp)] $(_log_prefix) ERR: $message" >> "$log_file"
}

# =============================================================================
# Workflow/Skill Logging (workflow.log)
# =============================================================================

# Session ID for grouping workflow executions
WORKFLOW_SESSION_ID=""

# Generate session ID
_workflow_session_id() {
    if [[ -z "$WORKFLOW_SESSION_ID" ]]; then
        WORKFLOW_SESSION_ID=$(date +%s%N | sha256sum | head -c 8)
    fi
    echo "$WORKFLOW_SESSION_ID"
}

# Get workflow log prefix
_workflow_prefix() {
    local task_id="${AGENT_TASK_ID:-unknown}"
    local session
    session=$(_workflow_session_id)
    echo "[TASK:$task_id] [session:$session]"
}

# Log workflow start
# Usage: log_workflow_start "developer/feature"
log_workflow_start() {
    if ! _logging_enabled; then return 0; fi
    
    local workflow="$1"
    local log_file
    log_file=$(_log_get_workflow_file)
    
    echo "[$(_log_timestamp)] $(_workflow_prefix) WORKFLOW_START: $workflow" >> "$log_file"
}

# Log workflow end
# Usage: log_workflow_end "developer/feature" "completed"
log_workflow_end() {
    if ! _logging_enabled; then return 0; fi
    
    local workflow="$1"
    local status="${2:-completed}"
    local log_file
    log_file=$(_log_get_workflow_file)
    
    echo "[$(_log_timestamp)] $(_workflow_prefix) WORKFLOW_END: $workflow ($status)" >> "$log_file"
}

# Log skill start
# Usage: log_skill_start "analyze/parse-requirement"
log_skill_start() {
    if ! _logging_enabled; then return 0; fi
    
    local skill="$1"
    local log_file
    log_file=$(_log_get_workflow_file)
    
    echo "[$(_log_timestamp)] $(_workflow_prefix) SKILL_START: $skill" >> "$log_file"
    
    # Store start time for duration calculation (replace / and - with _)
    local var_name="SKILL_START_${skill//\//_}"
    var_name="${var_name//-/_}"
    export "$var_name=$(date +%s)"
}

# Log skill end
# Usage: log_skill_end "analyze/parse-requirement" "OK"
# Usage: log_skill_end "execute/write-code" "FAIL" "lint error"
log_skill_end() {
    if ! _logging_enabled; then return 0; fi
    
    local skill="$1"
    local status="${2:-OK}"
    local detail="${3:-}"
    local log_file
    log_file=$(_log_get_workflow_file)
    
    # Calculate duration (replace / and - with _)
    local start_var="SKILL_START_${skill//\//_}"
    start_var="${start_var//-/_}"
    local start_time="${!start_var:-0}"
    local duration=""
    if [[ "$start_time" != "0" ]]; then
        local end_time
        end_time=$(date +%s)
        duration=" ($((end_time - start_time))s)"
    fi
    
    echo "[$(_log_timestamp)] $(_workflow_prefix) SKILL_END: $skill - $status$duration${detail:+ - $detail}" >> "$log_file"
}

# Log skill error
# Usage: log_skill_error "execute/write-code" "lint failed"
log_skill_error() {
    if ! _logging_enabled; then return 0; fi
    
    local skill="$1"
    local message="$2"
    local log_file
    log_file=$(_log_get_workflow_file)
    
    echo "[$(_log_timestamp)] $(_workflow_prefix) SKILL_ERROR: $skill - $message" >> "$log_file"
}

# Log skill retry
# Usage: log_skill_retry "execute/write-code" 2
log_skill_retry() {
    if ! _logging_enabled; then return 0; fi
    
    local skill="$1"
    local attempt="${2:-}"
    local log_file
    log_file=$(_log_get_workflow_file)
    
    echo "[$(_log_timestamp)] $(_workflow_prefix) SKILL_RETRY: $skill${attempt:+ (attempt $attempt)}" >> "$log_file"
}

# Log skill skip
# Usage: log_skill_skip "validate/review-code" "not required"
log_skill_skip() {
    if ! _logging_enabled; then return 0; fi
    
    local skill="$1"
    local reason="${2:-}"
    local log_file
    log_file=$(_log_get_workflow_file)
    
    echo "[$(_log_timestamp)] $(_workflow_prefix) SKILL_SKIP: $skill${reason:+ - $reason}" >> "$log_file"
}

# =============================================================================
# Log Query Functions
# =============================================================================

# Show recent logs
# Usage: log_show [lines] [--errors] [--worktree NAME]
log_show() {
    local lines=50
    local errors_only=0
    local worktree=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --errors) errors_only=1; shift ;;
            --worktree) worktree="$2"; shift 2 ;;
            [0-9]*) lines="$1"; shift ;;
            *) shift ;;
        esac
    done
    
    local project_root
    project_root=$(_log_find_project_root)
    
    local log_file
    if [[ -n "$worktree" ]]; then
        log_file="$project_root/.context/$worktree/logs/agent.log"
    else
        log_file=$(_log_get_agent_file)
    fi
    
    if [[ ! -f "$log_file" ]]; then
        echo "[INFO] No log file found: $log_file"
        return 0
    fi
    
    if [[ "$errors_only" == "1" ]]; then
        grep -E "(ERR:|EXIT: [^0])" "$log_file" | tail -n "$lines"
    else
        tail -n "$lines" "$log_file"
    fi
}

# Show all worktree logs (run from main)
# Usage: log_show_all
log_show_all() {
    local project_root
    project_root=$(_log_find_project_root)
    
    echo "=== Main logs ==="
    [[ -f "$project_root/.context/logs/agent.log" ]] && \
        tail -n 20 "$project_root/.context/logs/agent.log"
    
    for dir in "$project_root/.context"/*/; do
        [[ ! -d "$dir" ]] && continue
        [[ "$dir" == *"/logs/" ]] && continue
        
        local name
        name=$(basename "$dir")
        echo ""
        echo "=== $name logs ==="
        [[ -f "$dir/logs/agent.log" ]] && tail -n 20 "$dir/logs/agent.log"
    done
}

# Get log file path
# Usage: log_path [--workflow]
log_path() {
    if [[ "$1" == "--workflow" ]]; then
        _log_get_workflow_file
    else
        _log_get_agent_file
    fi
}

# =============================================================================
# Wrapper for Commands (Auto-logging)
# =============================================================================

# Execute command with automatic logging
# Usage: logged_exec "description" command arg1 arg2 ...
logged_exec() {
    local description="$1"
    shift
    
    log_cmd_start "$description: $*"
    
    local exit_code=0
    "$@" || exit_code=$?
    
    log_cmd_end "$exit_code"
    
    return $exit_code
}

# =============================================================================
# Initialization
# =============================================================================

# Initialize logging for a command
# Call this at the start of CLI commands
# Usage: log_init "agnt-c dev start TASK-123"
log_init() {
    local cmd="$1"
    
    # Create log directory
    local log_dir
    log_dir=$(_log_get_dir)
    
    # Log command start
    log_cmd_start "$cmd"
    
    # Set trap to log exit
    trap 'log_cmd_end $?' EXIT
}

echo "[logging.sh] Loaded (AGENT_LOGGING=${AGENT_LOGGING:-1})" >&2
