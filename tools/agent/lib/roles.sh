#!/bin/bash
# Role management for agent CLI
# Supports: developer (dev), manager (mgr)

# Current role (auto-detected or explicit)
CURRENT_ROLE=""

# Detect role based on context
# - Check git config user
# - Check environment variable
# - Default to developer
detect_role() {
    # Explicit environment variable
    if [[ -n "$AGENT_ROLE" ]]; then
        case "$AGENT_ROLE" in
            dev|developer)
                CURRENT_ROLE="developer"
                ;;
            mgr|manager)
                CURRENT_ROLE="manager"
                ;;
            *)
                echo "[WARN] Unknown AGENT_ROLE: $AGENT_ROLE, defaulting to developer" >&2
                CURRENT_ROLE="developer"
                ;;
        esac
        return
    fi

    # Default to developer
    CURRENT_ROLE="developer"
}

# Check if current role is developer
is_developer() {
    detect_role
    [[ "$CURRENT_ROLE" == "developer" ]]
}

# Check if current role is manager
is_manager() {
    detect_role
    [[ "$CURRENT_ROLE" == "manager" ]]
}

# Get role display name
get_role_display() {
    detect_role
    case "$CURRENT_ROLE" in
        developer) echo "Developer" ;;
        manager) echo "Manager" ;;
        *) echo "Unknown" ;;
    esac
}

# Validate command is allowed for current role
# Some commands are role-specific
validate_role_command() {
    local command="$1"
    local required_role="$2"

    detect_role

    # Developer-only commands
    local dev_only="start code check commit"
    # Manager-only commands
    local mgr_only="approve merge assign"

    case "$required_role" in
        developer)
            if ! is_developer; then
                echo "[WARN] '$command' is typically a developer command" >&2
            fi
            ;;
        manager)
            if ! is_manager; then
                echo "[WARN] '$command' is typically a manager command" >&2
            fi
            ;;
    esac
}

# Show agent configuration
show_agent_config() {
    local project_root
    project_root=$(find_project_root 2>/dev/null) || project_root="(not found)"

    echo "=================================================="
    echo "Agent Configuration"
    echo "=================================================="
    echo ""
    echo "Project Root: $project_root"
    echo ""
    echo "[Role]"
    detect_role
    echo "  Current Role: $(get_role_display)"
    echo "  AGENT_ROLE env: ${AGENT_ROLE:-(not set)}"
    echo ""
    echo "[Git Strategy]"
    echo "  Default Mode: Interactive (branch)"
    echo "  Worktree Root: .worktrees/"
    echo ""
    echo "[Context]"
    echo "  Interactive: .context/{task-id}/"
    echo "  Detached: .worktrees/{task-id}/.context/"
    echo ""
    echo "[Integration]"
    echo "  pm CLI: $(command -v pm 2>/dev/null || echo '.agent/tools/pm/bin/pm')"
    echo "=================================================="
}

# Initialize project for agent workflow
agent_init() {
    echo "Initializing project for agent workflow..."

    local project_root
    project_root=$(find_project_root 2>/dev/null) || {
        echo "[ERROR] Not in a git repository" >&2
        return 1
    }

    # Create .context directory
    if [[ ! -d "$project_root/.context" ]]; then
        mkdir -p "$project_root/.context"
        echo "(v) Created .context/"
    fi

    # Add to .gitignore if not already
    local gitignore="$project_root/.gitignore"
    if [[ -f "$gitignore" ]]; then
        if ! grep -q "^\.context/" "$gitignore" 2>/dev/null; then
            echo "" >> "$gitignore"
            echo "# Agent workflow context" >> "$gitignore"
            echo ".context/" >> "$gitignore"
            echo "(v) Added .context/ to .gitignore"
        fi

        if ! grep -q "^\.worktrees/" "$gitignore" 2>/dev/null; then
            echo ".worktrees/" >> "$gitignore"
            echo "(v) Added .worktrees/ to .gitignore"
        fi
    fi

    echo ""
    echo "Project initialized for agent workflow."
    echo "Run 'agent dev start <task-id>' to begin working."
}
