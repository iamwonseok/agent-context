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

    # Check .agent/ in current project (existing symlink or directory)
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

# Create .agent symlink pointing to agent-context root
# Returns: 0 if created, 1 if skipped (already exists), 2 if error
create_agent_symlink() {
    local agent_root="$1"
    local force="$2"

    # Skip if we're in the agent-context repo itself
    if [[ "$(pwd)" == "$agent_root" ]]; then
        echo "[INFO] Skipping .agent symlink (running inside agent-context repo)" >&2
        return 1
    fi

    # Check if .agent already exists
    if [[ -e ".agent" ]] || [[ -L ".agent" ]]; then
        if [[ "$force" == "true" ]]; then
            echo "[WARN] Removing existing .agent" >&2
            rm -rf ".agent"
        else
            if [[ -L ".agent" ]]; then
                local current_target
                current_target=$(readlink ".agent")
                echo "[INFO] .agent symlink already exists -> $current_target" >&2
            else
                echo "[INFO] .agent directory already exists, skipping symlink" >&2
            fi
            return 1
        fi
    fi

    # Create symlink
    ln -s "$agent_root" ".agent"
    echo "[OK] Created .agent symlink -> $agent_root" >&2
    return 0
}

# Add entry to .gitignore if not present
add_to_gitignore() {
    local entry="$1"
    local comment="$2"

    if [[ ! -f ".gitignore" ]]; then
        echo "[INFO] Creating .gitignore" >&2
        touch ".gitignore"
    fi

    if ! grep -q "^${entry}$" ".gitignore" 2>/dev/null; then
        echo "[INFO] Adding $entry to .gitignore" >&2
        {
            echo ""
            [[ -n "$comment" ]] && echo "# $comment"
            echo "$entry"
        } >> ".gitignore"
        return 0
    fi
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

# Run interactive project configuration (from setup.sh)
run_project_config() {
    local agent_root="$1"
    local project_root="$2"

    echo ""
    echo "=================================================="
    echo "Project Configuration"
    echo "=================================================="
    echo ""
    echo "Configure your project settings."
    echo "Press Enter to use default values shown in [brackets]."
    echo ""

    # Check for global secrets
    if [[ -d "$HOME/.secrets" ]]; then
        echo "[INFO] Found global secrets at ~/.secrets/"
        local files_found
        files_found=$(ls -1 "$HOME/.secrets/" 2>/dev/null | grep -v README | head -3)
        if [[ -n "$files_found" ]]; then
            echo "       Contains: $(echo "$files_found" | tr '\n' ', ' | sed 's/,$//')"
        fi
        echo ""
        read -p "Use global secrets (~/.secrets/)? [Y/n]: " USE_GLOBAL
        if [[ "$USE_GLOBAL" != "n" && "$USE_GLOBAL" != "N" ]]; then
            SECRETS_PATH="~/.secrets"
            echo "[OK] Will use global secrets"
        else
            SECRETS_PATH=""
        fi
        echo ""
    fi

    # Default values
    local DEFAULT_JIRA_URL="https://fadutec.atlassian.net"
    local DEFAULT_JIRA_PROJECT="SVI"
    local DEFAULT_GITLAB_URL="https://gitlab.fadutec.dev"
    local DEFAULT_FEATURE_PREFIX="feat/"
    local DEFAULT_BUGFIX_PREFIX="fix/"
    local DEFAULT_HOTFIX_PREFIX="hotfix/"

    # JIRA settings
    read -p "JIRA Base URL [${DEFAULT_JIRA_URL}]: " JIRA_URL
    JIRA_URL="${JIRA_URL:-${DEFAULT_JIRA_URL}}"

    read -p "JIRA Project Key [${DEFAULT_JIRA_PROJECT}]: " JIRA_PROJECT
    JIRA_PROJECT="${JIRA_PROJECT:-${DEFAULT_JIRA_PROJECT}}"

    read -p "JIRA Email: " JIRA_EMAIL
    while [[ -z "${JIRA_EMAIL}" ]]; do
        echo "[WARN] Email is required for JIRA authentication"
        read -p "JIRA Email: " JIRA_EMAIL
    done

    # GitLab settings
    echo ""
    read -p "GitLab Base URL [${DEFAULT_GITLAB_URL}]: " GITLAB_URL
    GITLAB_URL="${GITLAB_URL:-${DEFAULT_GITLAB_URL}}"

    read -p "GitLab Project (namespace/project): " GITLAB_PROJECT
    while [[ -z "${GITLAB_PROJECT}" ]]; do
        echo "[WARN] GitLab project is required (e.g., soc-ip/agentic)"
        read -p "GitLab Project (namespace/project): " GITLAB_PROJECT
    done

    # Branch prefix settings
    echo ""
    echo "Branch naming prefixes (press Enter for defaults):"
    read -p "Feature prefix [${DEFAULT_FEATURE_PREFIX}]: " FEATURE_PREFIX
    FEATURE_PREFIX="${FEATURE_PREFIX:-${DEFAULT_FEATURE_PREFIX}}"

    read -p "Bugfix prefix [${DEFAULT_BUGFIX_PREFIX}]: " BUGFIX_PREFIX
    BUGFIX_PREFIX="${BUGFIX_PREFIX:-${DEFAULT_BUGFIX_PREFIX}}"

    read -p "Hotfix prefix [${DEFAULT_HOTFIX_PREFIX}]: " HOTFIX_PREFIX
    HOTFIX_PREFIX="${HOTFIX_PREFIX:-${DEFAULT_HOTFIX_PREFIX}}"

    # Generate .project.yaml
    echo ""
    echo "[INFO] Creating .project.yaml..."
    cat > "${project_root}/.project.yaml" << EOF
# Project Configuration
# Generated by agnt-c setup --full

jira:
  base_url: ${JIRA_URL}
  project_key: ${JIRA_PROJECT}
  email: ${JIRA_EMAIL}

gitlab:
  base_url: ${GITLAB_URL}
  project: ${GITLAB_PROJECT}

branch:
  feature_prefix: ${FEATURE_PREFIX}
  bugfix_prefix: ${BUGFIX_PREFIX}
  hotfix_prefix: ${HOTFIX_PREFIX}
EOF

    # Add secrets_path if using global secrets
    if [[ -n "$SECRETS_PATH" ]]; then
        cat >> "${project_root}/.project.yaml" << EOF

# Secrets location (using global secrets)
secrets_path: ${SECRETS_PATH}
EOF
    else
        cat >> "${project_root}/.project.yaml" << EOF

# Authentication:
# Option 1: Environment variables (recommended)
#   export JIRA_TOKEN="your-token"
#   export JIRA_EMAIL="your-email"
#   export GITLAB_TOKEN="your-token"
#
# Option 2: Secret files (gitignored)
#   .secrets/atlassian-api-token
#   .secrets/gitlab-api-token
#
# Option 3: Global secrets (uncomment below)
#   secrets_path: ~/.secrets
EOF
    fi

    # Add .project.yaml to .gitignore
    add_to_gitignore ".project.yaml" "Project configuration (user-specific settings)"

    echo "[OK] .project.yaml created"
}

# Main setup command
agent_setup() {
    local force=false
    local full=false
    local project_only=false

    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            --force|-f)
                force=true
                ;;
            --full)
                full=true
                ;;
            --project)
                project_only=true
                ;;
            --help|-h)
                echo "Usage: agnt-c setup [OPTIONS]"
                echo ""
                echo "Install templates and configure project for agent-context."
                echo ""
                echo "Options:"
                echo "  --force, -f    Overwrite existing files"
                echo "  --full         Full setup: templates + .agent symlink + .project.yaml"
                echo "  --project      Configure .project.yaml only (interactive)"
                echo "  --help, -h     Show this help"
                echo ""
                echo "Files installed (default):"
                echo "  .agent/        Symlink to agent-context (skills, workflows)"
                echo "  .cursorrules   Agent behavior rules"
                echo "  .*             Config dotfiles (.clang-format, .editorconfig, ...)"
                echo "  pyproject.toml Python project configuration"
                echo "  policies/      Domain policy templates"
                echo ""
                echo "With --full:"
                echo "  .project.yaml  JIRA/GitLab configuration (interactive)"
                echo "  .secrets/      API token directory (if not using global)"
                echo ""
                echo "Examples:"
                echo "  agnt-c setup              # Quick setup with templates"
                echo "  agnt-c setup --full       # Full interactive setup"
                echo "  agnt-c setup --project    # Configure JIRA/GitLab only"
                echo "  agnt-c setup --force      # Overwrite existing files"
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
    local project_root="$(pwd)"

    # Project-only mode: just configure .project.yaml
    if [[ "$project_only" == "true" ]]; then
        run_project_config "$agent_root" "$project_root"
        echo ""
        echo "=================================================="
        echo "[OK] Project configuration complete"
        echo "=================================================="
        return 0
    fi

    if [[ ! -d "$templates_dir" ]]; then
        echo "[ERROR] Templates directory not found: $templates_dir" >&2
        return 1
    fi

    echo "Agent context: $agent_root"
    echo "Target: $project_root"
    echo ""

    local total_created=0
    local total_skipped=0

    # 1. Create .agent symlink (Issue #3 fix)
    echo "[INFO] Setting up .agent symlink..."
    if create_agent_symlink "$agent_root" "$force"; then
        total_created=$((total_created + 1))
        # Add .agent to .gitignore
        add_to_gitignore ".agent" "Agent context symlink (points to global installation)"
    else
        total_skipped=$((total_skipped + 1))
    fi
    echo ""

    # 2. Install .cursorrules
    if [[ -f "$templates_dir/.cursorrules.template" ]]; then
        local result
        result=$(install_template "$templates_dir/.cursorrules.template" ".cursorrules" "$force")
        total_created=$((total_created + $(echo "$result" | cut -d' ' -f1)))
        total_skipped=$((total_skipped + $(echo "$result" | cut -d' ' -f2)))
    fi

    # 3. Install config files from templates/configs/
    # All config files go to project root (dotfiles and regular files)
    if [[ -d "$templates_dir/configs" ]]; then
        echo "[INFO] Installing config files..."

        # Use find to get all files including dotfiles
        while IFS= read -r src_file; do
            local filename
            filename=$(basename "$src_file")

            # Skip README
            if [[ "$filename" == "README.md" ]]; then
                continue
            fi

            # All files go to project root
            local dest_file="$filename"

            local result
            result=$(install_template "$src_file" "$dest_file" "$force")
            total_created=$((total_created + $(echo "$result" | cut -d' ' -f1)))
            total_skipped=$((total_skipped + $(echo "$result" | cut -d' ' -f2)))
        done < <(find "$templates_dir/configs" -maxdepth 1 -type f)
    fi

    # 4. Install policies/
    if [[ -d "$templates_dir/policies" ]]; then
        local result
        result=$(install_template "$templates_dir/policies" "policies" "$force")
        total_created=$((total_created + $(echo "$result" | cut -d' ' -f1)))
        total_skipped=$((total_skipped + $(echo "$result" | cut -d' ' -f2)))
    fi

    # 5. Add common gitignore entries
    add_to_gitignore ".context/" "Agent workflow context"
    add_to_gitignore ".worktrees/" "Git worktrees for parallel work"

    echo ""
    echo "[OK] Template setup complete ($total_created created, $total_skipped skipped)"

    # 6. Full mode: run project configuration
    if [[ "$full" == "true" ]]; then
        run_project_config "$agent_root" "$project_root"
    fi

    echo ""
    echo "=================================================="
    echo "Setup Complete!"
    echo "=================================================="
    echo ""
    echo "What was set up:"
    echo "  - .agent/ symlink -> $agent_root"
    echo "  - .cursorrules (agent behavior rules)"
    echo "  - Config files (.clang-format, .editorconfig, pyproject.toml, ...)"
    echo "  - policies/ (domain templates)"
    if [[ "$full" == "true" ]]; then
        echo "  - .project.yaml (JIRA/GitLab settings)"
    fi
    echo ""
    echo "Next steps:"
    if [[ "$full" != "true" ]]; then
        echo "  1. Run 'agnt-c setup --project' to configure JIRA/GitLab"
        echo "  2. Or manually edit .project.yaml"
        echo "  3. Run 'agnt-c dev start TASK-ID' to begin work"
    else
        echo "  1. Verify .project.yaml settings"
        echo "  2. Set up API tokens in .secrets/ or ~/.secrets/"
        echo "  3. Run 'agnt-c dev start TASK-ID' to begin work"
    fi
    echo "=================================================="
}
