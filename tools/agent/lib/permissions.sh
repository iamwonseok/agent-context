#!/bin/bash
# Permission model for agent CLI
# Defines which commands can be run by agents vs humans

# Permission levels
PERMISSION_HUMAN_ONLY="human_only"      # Only humans can execute
PERMISSION_AGENT_ALLOWED="agent_allowed" # Agents can execute
PERMISSION_HYBRID="hybrid"               # Requires human approval

# Get default permission for a command (function-based for bash 3.x compatibility)
get_default_permission() {
    local command="$1"
    
    case "$command" in
        # Developer commands - mostly agent allowed
        dev_start|dev_list|dev_switch|dev_status)
            echo "agent_allowed"
            ;;
        dev_check|dev_verify|dev_retro|dev_sync|dev_cleanup)
            echo "agent_allowed"
            ;;
        dev_submit)
            echo "hybrid"  # Requires human approval before MR
            ;;
        
        # Manager commands - mostly human only
        mgr_pending|mgr_review|mgr_status)
            echo "agent_allowed"  # Read-only, safe
            ;;
        mgr_approve|mgr_merge|mgr_assign)
            echo "human_only"  # Critical actions
            ;;
        
        # Default
        *)
            echo "agent_allowed"
            ;;
    esac
}

# Check if running as agent (automated) or human (interactive)
# Returns: "agent" or "human"
detect_executor() {
    # Check for common CI/CD environment variables
    if [[ -n "${CI:-}" ]] || \
       [[ -n "${GITHUB_ACTIONS:-}" ]] || \
       [[ -n "${GITLAB_CI:-}" ]] || \
       [[ -n "${JENKINS_URL:-}" ]] || \
       [[ -n "${AGENT_MODE:-}" ]]; then
        echo "agent"
        return
    fi
    
    # Check if running in a non-interactive shell
    if [[ ! -t 0 ]]; then
        echo "agent"
        return
    fi
    
    echo "human"
}

# Get permission for a command
# Usage: get_permission <command>
get_permission() {
    local command="$1"
    
    # Check project-specific overrides first
    local override
    override=$(get_project_permission_override "$command")
    if [[ -n "$override" ]]; then
        echo "$override"
        return
    fi
    
    # Fall back to default
    get_default_permission "$command"
}

# Get project-specific permission override from config
get_project_permission_override() {
    local command="$1"
    local config_file
    
    # Look for .agent/config.yaml or .project.yaml
    local project_root
    project_root=$(find_project_root 2>/dev/null) || return 1
    
    for config_file in "$project_root/.agent/config.yaml" "$project_root/.project.yaml"; do
        if [[ -f "$config_file" ]]; then
            # Try to read permission override using yq or grep
            if command -v yq &>/dev/null; then
                local perm
                perm=$(yq -r ".permissions.$command // empty" "$config_file" 2>/dev/null)
                if [[ -n "$perm" ]]; then
                    echo "$perm"
                    return
                fi
            fi
        fi
    done
    
    return 1
}

# Check if command can be executed by current executor
# Usage: check_permission <command>
# Returns: 0 if allowed, 1 if denied
check_permission() {
    local command="$1"
    
    local executor
    executor=$(detect_executor)
    
    local permission
    permission=$(get_permission "$command")
    
    case "$permission" in
        "$PERMISSION_HUMAN_ONLY")
            if [[ "$executor" == "agent" ]]; then
                echo "[BLOCKED] Command '$command' requires human execution" >&2
                echo "[INFO] This command is marked as human_only" >&2
                return 1
            fi
            ;;
        "$PERMISSION_HYBRID")
            if [[ "$executor" == "agent" ]]; then
                echo "[WARN] Command '$command' typically requires human approval" >&2
                echo "[INFO] Proceeding in automated mode..." >&2
                # Continue but log warning
            fi
            ;;
        "$PERMISSION_AGENT_ALLOWED")
            # Always allowed
            ;;
    esac
    
    return 0
}

# Request human approval for an action
# Usage: request_approval <action_description>
# Returns: 0 if approved, 1 if denied
request_approval() {
    local action="$1"
    
    local executor
    executor=$(detect_executor)
    
    if [[ "$executor" == "agent" ]]; then
        echo "[APPROVAL NEEDED] $action"
        echo "[INFO] Running in agent mode - cannot request interactive approval"
        echo "[INFO] Use --force to skip approval or run manually"
        return 1
    fi
    
    echo ""
    echo "=================================================="
    echo "[APPROVAL NEEDED]"
    echo "=================================================="
    echo ""
    echo "Action: $action"
    echo ""
    read -p "Approve? [y/N] " response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "[OK] Approved"
        return 0
    else
        echo "[CANCELLED] Action not approved"
        return 1
    fi
}

# Show permission summary for all commands
show_permissions() {
    echo "=================================================="
    echo "Command Permissions"
    echo "=================================================="
    echo ""
    echo "Current executor: $(detect_executor)"
    echo ""
    
    echo "Developer Commands:"
    local dev_cmds="dev_start dev_list dev_switch dev_status dev_check dev_verify dev_retro dev_sync dev_submit dev_cleanup"
    for cmd in $dev_cmds; do
        local perm
        perm=$(get_permission "$cmd")
        printf "  %-15s : %s\n" "$cmd" "$perm"
    done
    
    echo ""
    echo "Manager Commands:"
    local mgr_cmds="mgr_pending mgr_review mgr_approve mgr_merge mgr_assign mgr_status"
    for cmd in $mgr_cmds; do
        local perm
        perm=$(get_permission "$cmd")
        printf "  %-15s : %s\n" "$cmd" "$perm"
    done
    
    echo ""
    echo "Legend:"
    echo "  agent_allowed : Can be run by agents or humans"
    echo "  human_only    : Requires human to execute"
    echo "  hybrid        : Agent can run with warning"
    echo "=================================================="
}
