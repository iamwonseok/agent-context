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

# ============================================
# State Visibility Layer (RFC-004 v2.0)
# ============================================

# Mode constants
MODE_PLANNING="planning"
MODE_IMPLEMENTATION="implementation"
MODE_VERIFICATION="verification"
MODE_RESEARCH="research"

# Cursor mode constants
CURSOR_MODE_PLAN="plan"
CURSOR_MODE_ASK="ask"
CURSOR_MODE_AGENT="agent"
CURSOR_MODE_DEBUG="debug"

# Show state assertion for a skill
# Usage: show_state_assertion <skill_name> <mode> <cursor_mode> <purpose>
show_state_assertion() {
    local skill_name="$1"
    local mode="$2"
    local cursor_mode="$3"
    local purpose="${4:-}"

    echo ""
    echo "=================================================="
    echo "AGENT MODE: ${skill_name}"
    echo "=================================================="
    echo ""
    echo "  Mode:        ${mode}"
    echo "  Cursor Mode: ${cursor_mode}"
    if [[ -n "$purpose" ]]; then
        echo "  Purpose:     ${purpose}"
    fi
    echo ""
}

# Show state assertion with boundaries
# Usage: show_state_assertion_full <skill_name> <mode> <cursor_mode> <purpose> <will_do> <will_not>
show_state_assertion_full() {
    local skill_name="$1"
    local mode="$2"
    local cursor_mode="$3"
    local purpose="${4:-}"
    local will_do="${5:-}"
    local will_not="${6:-}"

    show_state_assertion "$skill_name" "$mode" "$cursor_mode" "$purpose"

    if [[ -n "$will_do" ]] || [[ -n "$will_not" ]]; then
        echo "  Boundaries:"
        if [[ -n "$will_do" ]]; then
            echo "    Will:     ${will_do}"
        fi
        if [[ -n "$will_not" ]]; then
            echo "    Will NOT: ${will_not}"
        fi
        echo ""
    fi
}

# Get mode for a skill category
# Usage: get_mode_for_category <category>
get_mode_for_category() {
    local category="$1"

    case "$category" in
        analyze)
            echo "$MODE_RESEARCH"
            ;;
        plan|planning)
            echo "$MODE_PLANNING"
            ;;
        execute)
            echo "$MODE_IMPLEMENTATION"
            ;;
        validate)
            echo "$MODE_VERIFICATION"
            ;;
        integrate)
            echo "$MODE_IMPLEMENTATION"
            ;;
        *)
            echo "$MODE_IMPLEMENTATION"
            ;;
    esac
}

# Get cursor mode for a skill category
# Usage: get_cursor_mode_for_category <category>
get_cursor_mode_for_category() {
    local category="$1"

    case "$category" in
        analyze)
            echo "$CURSOR_MODE_ASK"
            ;;
        plan|planning)
            echo "$CURSOR_MODE_PLAN"
            ;;
        execute)
            echo "$CURSOR_MODE_AGENT"
            ;;
        validate)
            echo "$CURSOR_MODE_DEBUG"
            ;;
        integrate)
            echo "$CURSOR_MODE_AGENT"
            ;;
        *)
            echo "$CURSOR_MODE_AGENT"
            ;;
    esac
}

# Save current mode to context
# Usage: save_current_mode <context_path> <mode>
save_current_mode() {
    local context_path="$1"
    local mode="$2"

    echo "$mode" > "$context_path/mode.txt"
}

# Load current mode from context
# Usage: load_current_mode <context_path>
load_current_mode() {
    local context_path="$1"
    local mode_file="$context_path/mode.txt"

    if [[ -f "$mode_file" ]]; then
        cat "$mode_file"
    else
        echo "$MODE_PLANNING"  # Default to planning
    fi
}
