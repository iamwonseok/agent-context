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

# =============================================================================
# Sequential Flow Logging (New Format)
# =============================================================================
#
# Log format:
#   workflow/developer/feature.md
#   Trigger: "user request" → matched "condition"
#
#   skills/analyze.md
#   > command → [OK] 0.1s
#   skills/analyze.md → [OK] (output.md)
#
# =============================================================================

# Current workflow log file (set by seq_log_start)
SEQ_LOG_FILE=""
SEQ_LOG_START_TIME=""
SEQ_SKILL_START_TIME=""
SEQ_SKILL_OUTPUTS=()

# Create timestamped workflow log file
# Usage: _seq_log_create_file
_seq_log_create_file() {
    local log_dir=$(_log_get_dir)
    local timestamp=$(date "+%Y-%m-%d_%H-%M-%S")
    local base_name="$log_dir/workflow_${timestamp}"
    local log_file="${base_name}.log"

    # If file exists, add counter suffix
    local counter=1
    while [[ -f "$log_file" ]]; do
        log_file="${base_name}_${counter}.log"
        ((counter++))
    done

    echo "$log_file"
}

# Write log header
# Usage: seq_log_start "user request text"
seq_log_start() {
    if ! _logging_enabled; then return 0; fi

    local user_request="${1:-}"
    local branch=$(_log_get_branch)
    local worktree=$(_log_get_worktree_name)
    [[ -z "$worktree" ]] && worktree="main"

    SEQ_LOG_FILE=$(_seq_log_create_file)
    SEQ_LOG_START_TIME=$(date +%s)

    cat >> "$SEQ_LOG_FILE" << EOF
=====================================
Branch: $branch
Worktree: $worktree
Timestamp: $(date "+%Y-%m-%d %H:%M:%S")
User Request: "$user_request"
=====================================

EOF

    if _logging_verbose; then
        echo "[SEQ_LOG] Started: $SEQ_LOG_FILE" >&2
    fi
}

# Log workflow begin
# Usage: seq_log_workflow_begin "developer/feature" "trigger_type" "trigger_detail"
# trigger_type: matched, @file, CLI
seq_log_workflow_begin() {
    if ! _logging_enabled; then return 0; fi
    [[ -z "$SEQ_LOG_FILE" ]] && return 0

    local workflow="$1"
    local trigger_detail="$2"

    cat >> "$SEQ_LOG_FILE" << EOF
workflow/$workflow.md
Trigger: $trigger_detail

EOF

    if _logging_verbose; then
        echo "workflow/$workflow.md" >&2
        echo "Trigger: $trigger_detail" >&2
        echo "" >&2
    fi
}

# Log skill begin
# Usage: seq_log_skill_begin "analyze/parse-requirement"
seq_log_skill_begin() {
    if ! _logging_enabled; then return 0; fi
    [[ -z "$SEQ_LOG_FILE" ]] && return 0

    local skill="$1"
    SEQ_SKILL_START_TIME=$(date +%s.%N 2>/dev/null || date +%s)
    SEQ_SKILL_OUTPUTS=()

    echo "skills/$skill.md" >> "$SEQ_LOG_FILE"

    if _logging_verbose; then
        echo "skills/$skill.md" >&2
    fi
}

# Log command execution
# Usage: seq_log_exec "git status" "OK" "0.1" ["error message"]
seq_log_exec() {
    if ! _logging_enabled; then return 0; fi
    [[ -z "$SEQ_LOG_FILE" ]] && return 0

    local cmd="$1"
    local status="$2"
    local duration="$3"
    local error="${4:-}"

    echo "> $cmd → [$status] ${duration}s" >> "$SEQ_LOG_FILE"
    if [[ -n "$error" ]]; then
        echo "  Error: $error" >> "$SEQ_LOG_FILE"
    fi

    if _logging_verbose; then
        echo "> $cmd → [$status] ${duration}s" >&2
        [[ -n "$error" ]] && echo "  Error: $error" >&2
    fi
}

# Add output file to current skill
# Usage: seq_log_add_output "design/feature.md"
seq_log_add_output() {
    local output="$1"
    SEQ_SKILL_OUTPUTS+=("$output")
}

# Log skill end
# Usage: seq_log_skill_end "analyze/parse-requirement" "OK" ["output1.md,output2.md"]
seq_log_skill_end() {
    if ! _logging_enabled; then return 0; fi
    [[ -z "$SEQ_LOG_FILE" ]] && return 0

    local skill="$1"
    local status="$2"
    local outputs="${3:-}"

    # Use accumulated outputs if not provided
    if [[ -z "$outputs" ]] && [[ ${#SEQ_SKILL_OUTPUTS[@]} -gt 0 ]]; then
        outputs=$(IFS=', '; echo "${SEQ_SKILL_OUTPUTS[*]}")
    fi

    local result="skills/$skill.md → [$status]"
    if [[ -n "$outputs" ]]; then
        result="$result ($outputs)"
    fi

    echo "$result" >> "$SEQ_LOG_FILE"
    echo "" >> "$SEQ_LOG_FILE"

    if _logging_verbose; then
        echo "$result" >&2
        echo "" >&2
    fi

    SEQ_SKILL_OUTPUTS=()
}

# Log tool begin
# Usage: seq_log_tool_begin "agent/lib/logging.sh"
seq_log_tool_begin() {
    if ! _logging_enabled; then return 0; fi
    [[ -z "$SEQ_LOG_FILE" ]] && return 0

    local tool="$1"

    echo "tools/$tool" >> "$SEQ_LOG_FILE"

    if _logging_verbose; then
        echo "tools/$tool" >&2
    fi
}

# Log tool end
# Usage: seq_log_tool_end "agent/lib/logging.sh" "OK"
seq_log_tool_end() {
    if ! _logging_enabled; then return 0; fi
    [[ -z "$SEQ_LOG_FILE" ]] && return 0

    local tool="$1"
    local status="$2"

    echo "tools/$tool → [$status]" >> "$SEQ_LOG_FILE"
    echo "" >> "$SEQ_LOG_FILE"

    if _logging_verbose; then
        echo "tools/$tool → [$status]" >&2
        echo "" >&2
    fi
}

# Log workflow end
# Usage: seq_log_workflow_end "developer/feature" "OK" "5/5 skills passed"
seq_log_workflow_end() {
    if ! _logging_enabled; then return 0; fi
    [[ -z "$SEQ_LOG_FILE" ]] && return 0

    local workflow="$1"
    local status="$2"
    local summary="$3"

    echo "workflow/$workflow.md → [$status] ($summary)" >> "$SEQ_LOG_FILE"

    if _logging_verbose; then
        echo "workflow/$workflow.md → [$status] ($summary)" >&2
    fi
}

# Write log footer and close
# Usage: seq_log_end "OK"
seq_log_end() {
    if ! _logging_enabled; then return 0; fi
    [[ -z "$SEQ_LOG_FILE" ]] && return 0

    local result="$1"
    local end_time=$(date +%s)
    local duration=$((end_time - SEQ_LOG_START_TIME))

    cat >> "$SEQ_LOG_FILE" << EOF

=====================================
End: $(date "+%Y-%m-%d %H:%M:%S")
Duration: ${duration}s
Result: $result
=====================================
EOF

    if _logging_verbose; then
        echo "" >&2
        echo "=====================================" >&2
        echo "End: $(date "+%Y-%m-%d %H:%M:%S")" >&2
        echo "Duration: ${duration}s" >&2
        echo "Result: $result" >&2
        echo "=====================================" >&2
        echo "[SEQ_LOG] Saved: $SEQ_LOG_FILE" >&2
    fi

    # Return the log file path
    echo "$SEQ_LOG_FILE"
}

# Get current sequential log file path
# Usage: seq_log_path
seq_log_path() {
    echo "$SEQ_LOG_FILE"
}

# =============================================================================
# Command Execution Wrapper (with logging)
# =============================================================================

# Execute command with automatic sequential logging
# Usage: exec_cmd command arg1 arg2 ...
# Returns: exit code of command
exec_cmd() {
    local cmd="$*"
    local start_time=$(date +%s.%N 2>/dev/null || date +%s)

    local output
    local exit_code=0
    output=$("$@" 2>&1) || exit_code=$?

    local end_time=$(date +%s.%N 2>/dev/null || date +%s)
    # Calculate duration (handle both GNU and BSD date)
    local duration
    if command -v bc &>/dev/null; then
        duration=$(printf "%.1f" "$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")")
    else
        duration="0.0"
    fi

    local status="OK"
    local error=""
    if [[ $exit_code -ne 0 ]]; then
        status="NG"
        error="$output"
    fi

    seq_log_exec "$cmd" "$status" "$duration" "$error"

    # Also log to traditional agent.log
    log_info "exec: $cmd → [$status]"

    return $exit_code
}

echo "[logging.sh] Loaded (AGENT_LOGGING=${AGENT_LOGGING:-1})" >&2
