#!/bin/bash
# Executor model for agent CLI
# Handles human vs agent execution, intervention, and workflow state

# Executor types
EXECUTOR_HUMAN="human"
EXECUTOR_AGENT="agent"
EXECUTOR_HYBRID="hybrid"

# Workflow states
STATE_RUNNING="running"
STATE_WAITING_APPROVAL="waiting_approval"
STATE_WAITING_HUMAN="waiting_human"
STATE_COMPLETED="completed"
STATE_FAILED="failed"

# Source permissions
EXECUTOR_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$EXECUTOR_SCRIPT_DIR/permissions.sh" 2>/dev/null || true

# Execute a command with permission check
# Usage: execute_with_check <command> <args...>
execute_with_check() {
    local command="$1"
    shift
    
    # Check permission
    if ! check_permission "$command"; then
        return 1
    fi
    
    # Execute the actual command function
    "$command" "$@"
}

# Wait for human intervention
# Usage: wait_for_human <reason> [timeout_seconds]
wait_for_human() {
    local reason="$1"
    local timeout="${2:-0}"  # 0 = no timeout
    
    local executor
    executor=$(detect_executor)
    
    echo ""
    echo "=================================================="
    echo "[HUMAN INTERVENTION REQUIRED]"
    echo "=================================================="
    echo ""
    echo "Reason: $reason"
    echo ""
    
    if [[ "$executor" == "agent" ]]; then
        # In agent mode, we can't wait interactively
        echo "[INFO] Running in agent mode"
        echo "[INFO] Please handle this manually and re-run the command"
        echo ""
        echo "To continue after manual intervention:"
        echo "  1. Complete the required action"
        echo "  2. Re-run the command"
        echo ""
        return 1
    fi
    
    # In human mode, wait for input
    echo "Press Enter when ready to continue, or Ctrl+C to cancel"
    
    if [[ "$timeout" -gt 0 ]]; then
        echo "(Timeout: ${timeout}s)"
        read -t "$timeout" -p "> " || {
            echo ""
            echo "[TIMEOUT] No response within ${timeout}s"
            return 1
        }
    else
        read -p "> "
    fi
    
    echo "[OK] Continuing..."
    return 0
}

# Save workflow state for resumption
# Usage: save_workflow_state <context_path> <state> <data>
save_workflow_state() {
    local context_path="$1"
    local state="$2"
    local data="${3:-}"
    
    local state_file="$context_path/workflow_state.yaml"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    cat > "$state_file" << EOF
# Workflow State
# Updated: $timestamp

state: "$state"
updated_at: "$timestamp"
executor: "$(detect_executor)"

# Additional data
data: |
  $data

# History
history:
  - state: "$state"
    timestamp: "$timestamp"
EOF
    
    echo "[INFO] Workflow state saved: $state"
}

# Load workflow state
# Usage: load_workflow_state <context_path>
load_workflow_state() {
    local context_path="$1"
    local state_file="$context_path/workflow_state.yaml"
    
    if [[ ! -f "$state_file" ]]; then
        echo "$STATE_RUNNING"
        return
    fi
    
    grep "^state:" "$state_file" | sed 's/state: *//' | tr -d '"'
}

# Check if workflow can proceed
# Usage: can_proceed <context_path>
can_proceed() {
    local context_path="$1"
    
    local state
    state=$(load_workflow_state "$context_path")
    
    case "$state" in
        "$STATE_RUNNING"|"$STATE_COMPLETED")
            return 0
            ;;
        "$STATE_WAITING_APPROVAL"|"$STATE_WAITING_HUMAN")
            echo "[BLOCKED] Workflow is waiting: $state" >&2
            return 1
            ;;
        "$STATE_FAILED")
            echo "[WARN] Previous workflow failed - proceeding anyway" >&2
            return 0
            ;;
        *)
            return 0
            ;;
    esac
}

# Execute with human fallback
# Usage: execute_or_human <command> <human_instruction>
execute_or_human() {
    local command="$1"
    local human_instruction="$2"
    shift 2
    
    local executor
    executor=$(detect_executor)
    
    # Try to execute
    if "$command" "$@" 2>/dev/null; then
        return 0
    fi
    
    # If failed, provide human instruction
    echo ""
    echo "[FALLBACK] Automated execution failed"
    echo ""
    echo "Please perform manually:"
    echo "  $human_instruction"
    echo ""
    
    if [[ "$executor" == "human" ]]; then
        wait_for_human "Manual action required"
    else
        return 1
    fi
}

# Show execution info
show_execution_info() {
    echo "=================================================="
    echo "Execution Info"
    echo "=================================================="
    echo ""
    echo "Executor:    $(detect_executor)"
    echo "Interactive: $([[ -t 0 ]] && echo "yes" || echo "no")"
    echo "CI Mode:     $([[ -n "${CI:-}" ]] && echo "yes" || echo "no")"
    echo ""
    
    if [[ -n "${AGENT_MODE:-}" ]]; then
        echo "Agent Mode:  $AGENT_MODE"
    fi
    
    echo "=================================================="
}
