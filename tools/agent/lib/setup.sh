# setup.sh - Agent setup command library
# Install templates to project directory

# Find agent-context root directory
find_agent_context_root() {
    # Check AGENT_CONTEXT_PATH first
    if [[ -n "$AGENT_CONTEXT_PATH" ]] && [[ -d "$AGENT_CONTEXT_PATH" ]]; then
        echo "$AGENT_CONTEXT_PATH"
        return 0
    fi

    # Check if we're in agent-context repo
    local script_root
    script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    if [[ -f "$script_root/activate.sh" ]]; then
        echo "$script_root"
        return 0
    fi

    # Check .agent/ in current project
    if [[ -d ".agent" ]] && [[ -f ".agent/activate.sh" ]]; then
        echo "$(pwd)/.agent"
        return 0
    fi

    # Check global installation
    if [[ -d "$HOME/.agent" ]] && [[ -f "$HOME/.agent/activate.sh" ]]; then
        echo "$HOME/.agent"
        return 0
    fi

    echo "[ERROR] Cannot find agent-context. Set AGENT_CONTEXT_PATH or run 'source activate.sh'" >&2
    return 1
}

# Install a single template file or directory
# Outputs status to stderr, returns "created skipped" counts to stdout
install_template() {
    local src="$1"
    local dest="$2"
    local force="$3"
    local created=0
    local skipped=0

    if [[ -e "$dest" ]]; then
        if [[ "$force" == "true" ]]; then
            echo "[WARN] Overwriting $dest" >&2
            rm -rf "$dest"
            if [[ -d "$src" ]]; then
                cp -r "$src" "$dest"
            else
                cp "$src" "$dest"
            fi
            created=1
        else
            echo "[INFO] $dest already exists, skipping" >&2
            skipped=1
        fi
    else
        echo "[OK] Created $dest" >&2
        if [[ -d "$src" ]]; then
            cp -r "$src" "$dest"
        else
            cp "$src" "$dest"
        fi
        created=1
    fi

    echo "$created $skipped"
}

# Main setup command
agent_setup() {
    local force=false

    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            --force|-f)
                force=true
                ;;
            --help|-h)
                echo "Usage: agent setup [OPTIONS]"
                echo ""
                echo "Install templates to current project directory."
                echo ""
                echo "Options:"
                echo "  --force, -f    Overwrite existing files"
                echo "  --help, -h     Show this help"
                echo ""
                echo "Files installed:"
                echo "  .cursorrules   Agent behavior rules"
                echo "  configs/       Tool configurations"
                echo "  policies/      Domain policy templates"
                return 0
                ;;
        esac
    done

    echo "=================================================="
    echo "Agent Setup"
    echo "=================================================="
    echo ""

    # Find agent-context root
    local agent_root
    agent_root=$(find_agent_context_root) || return 1
    local templates_dir="$agent_root/templates"

    if [[ ! -d "$templates_dir" ]]; then
        echo "[ERROR] Templates directory not found: $templates_dir" >&2
        return 1
    fi

    echo "Templates: $templates_dir"
    echo "Target: $(pwd)"
    echo ""

    local total_created=0
    local total_skipped=0

    # Install .cursorrules
    if [[ -f "$templates_dir/.cursorrules.template" ]]; then
        local result
        result=$(install_template "$templates_dir/.cursorrules.template" ".cursorrules" "$force")
        total_created=$((total_created + $(echo "$result" | cut -d' ' -f1)))
        total_skipped=$((total_skipped + $(echo "$result" | cut -d' ' -f2)))
    fi

    # Install configs/
    if [[ -d "$templates_dir/configs" ]]; then
        local result
        result=$(install_template "$templates_dir/configs" "configs" "$force")
        total_created=$((total_created + $(echo "$result" | cut -d' ' -f1)))
        total_skipped=$((total_skipped + $(echo "$result" | cut -d' ' -f2)))
    fi

    # Install policies/
    if [[ -d "$templates_dir/policies" ]]; then
        local result
        result=$(install_template "$templates_dir/policies" "policies" "$force")
        total_created=$((total_created + $(echo "$result" | cut -d' ' -f1)))
        total_skipped=$((total_skipped + $(echo "$result" | cut -d' ' -f2)))
    fi

    echo ""
    echo "[OK] Setup complete ($total_created created, $total_skipped skipped)"
    echo ""
    echo "Next steps:"
    echo "  1. Edit .cursorrules for project-specific rules"
    echo "  2. Add domain policies to policies/"
    echo "  3. Run 'agent dev start TASK-ID' to begin work"
    echo "=================================================="
}
