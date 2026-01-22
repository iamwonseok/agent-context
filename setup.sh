#!/bin/bash
# setup.sh
# Setup script for agent-context installation
#
# Usage:
#   ./setup.sh                    # Interactive setup in current project
#   ./setup.sh --global           # Install to ~/.agent
#   ./setup.sh --non-interactive  # Skip interactive prompts

set -e

# Parse arguments
GLOBAL_INSTALL=false
NON_INTERACTIVE=false
for arg in "$@"; do
    case $arg in
        --global)
            GLOBAL_INSTALL=true
            ;;
        --non-interactive)
            NON_INTERACTIVE=true
            ;;
        --help|-h)
            echo "Usage: setup.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --global           Install to ~/.agent (global installation)"
            echo "  --non-interactive  Skip interactive prompts (use defaults)"
            echo "  --help, -h         Show this help message"
            exit 0
            ;;
    esac
done

# Get directories
AGENT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ "$GLOBAL_INSTALL" == "true" ]]; then
    # Global installation: copy to ~/.agent
    echo "========================================="
    echo "Agent Context Global Installation"
    echo "========================================="
    echo ""
    
    if [[ -d "$HOME/.agent" ]]; then
        echo "[WARN] ~/.agent already exists"
        if [[ "$NON_INTERACTIVE" == "false" ]]; then
            read -p "Overwrite? [y/N]: " OVERWRITE
            if [[ "$OVERWRITE" != "y" && "$OVERWRITE" != "Y" ]]; then
                echo "[INFO] Installation cancelled"
                exit 0
            fi
        fi
        rm -rf "$HOME/.agent"
    fi
    
    echo "[INFO] Installing to ~/.agent..."
    cp -r "$AGENT_DIR" "$HOME/.agent"
    
    # Remove _dev if it exists (development only)
    rm -rf "$HOME/.agent/_dev" 2>/dev/null || true
    
    echo "[OK] Installed to ~/.agent"
    echo ""
    echo "Add to your shell profile (~/.bashrc or ~/.zshrc):"
    echo "  export AGENT_CONTEXT_PATH=\"\$HOME/.agent\""
    echo "  export PATH=\"\$PATH:\$HOME/.agent/tools/agent/bin:\$HOME/.agent/tools/pm/bin:\$HOME/.agent/tools/lint/bin\""
    echo ""
    exit 0
fi

# Project-level installation
# Determine PROJECT_ROOT based on where setup.sh is called from
if [[ "$(basename "$AGENT_DIR")" == ".agent" ]]; then
    # Called from .agent/ (symlink or copied)
    PROJECT_ROOT="$(dirname "$AGENT_DIR")"
else
    # Called from repo root directly (development mode)
    PROJECT_ROOT="$(pwd)"
    AGENT_DIR="$PROJECT_ROOT"
fi

echo "========================================="
echo "Agent Context Setup"
echo "========================================="
echo ""
echo "Agent dir: ${AGENT_DIR}"
echo "Project root: ${PROJECT_ROOT}"
echo ""

# Resolve agent context path for templates
resolve_template_path() {
    local template_name="$1"
    
    # Check local first
    if [[ -f "${AGENT_DIR}/templates/${template_name}" ]]; then
        echo "${AGENT_DIR}/templates/${template_name}"
        return 0
    fi
    
    # Check global
    if [[ -f "$HOME/.agent/templates/${template_name}" ]]; then
        echo "$HOME/.agent/templates/${template_name}"
        return 0
    fi
    
    echo "[ERROR] Template not found: ${template_name}" >&2
    return 1
}

# 1. .cursorrules handling
echo "[INFO] Processing .cursorrules..."
CURSORRULES_TEMPLATE=$(resolve_template_path ".cursorrules.template")
if [[ -f "${PROJECT_ROOT}/.cursorrules" ]]; then
    echo "[INFO] .cursorrules already exists, skipping"
else
    echo "[INFO] Creating .cursorrules from template"
    cp "$CURSORRULES_TEMPLATE" "${PROJECT_ROOT}/.cursorrules"
fi

# 2. configs/ handling
if [[ ! -d "${PROJECT_ROOT}/configs" ]]; then
    CONFIGS_TEMPLATE=$(resolve_template_path "configs")
    if [[ -d "$CONFIGS_TEMPLATE" ]]; then
        echo "[INFO] Creating configs/ directory from template"
        cp -r "$CONFIGS_TEMPLATE" "${PROJECT_ROOT}/configs"
    fi
else
    echo "[INFO] configs/ already exists, skipping"
fi

# 3. .secrets/ handling
if [[ ! -d "${PROJECT_ROOT}/.secrets" ]]; then
    echo "[INFO] Creating .secrets/ directory from template"
    mkdir -p "${PROJECT_ROOT}/.secrets"
    SECRETS_TEMPLATE=$(resolve_template_path ".secrets")
    if [[ -d "$SECRETS_TEMPLATE" ]]; then
        cp "${SECRETS_TEMPLATE}/"*.example "${PROJECT_ROOT}/.secrets/" 2>/dev/null || true
        cp "${SECRETS_TEMPLATE}/README.md" "${PROJECT_ROOT}/.secrets/" 2>/dev/null || true
    fi
else
    echo "[INFO] .secrets/ already exists, skipping"
fi

# 4. .gitignore handling
if [[ -f "${PROJECT_ROOT}/.gitignore" ]]; then
    # Add .secrets/ exclusion
    if ! grep -q "^\.secrets/\*" "${PROJECT_ROOT}/.gitignore"; then
        echo "[INFO] Adding .secrets/ exclusion to .gitignore"
        {
            echo ""
            echo "# Secrets (keep examples only)"
            echo ".secrets/*"
            echo "!.secrets/*.example"
            echo "!.secrets/README.md"
        } >> "${PROJECT_ROOT}/.gitignore"
    fi
    # Add .project.yaml exclusion
    if ! grep -q "^\.project\.yaml$" "${PROJECT_ROOT}/.gitignore"; then
        echo "[INFO] Adding .project.yaml exclusion to .gitignore"
        {
            echo ""
            echo "# Project configuration (user-specific settings)"
            echo ".project.yaml"
        } >> "${PROJECT_ROOT}/.gitignore"
    fi
    # Add .context/ exclusion
    if ! grep -q "^\.context/" "${PROJECT_ROOT}/.gitignore"; then
        echo "[INFO] Adding .context/ exclusion to .gitignore"
        {
            echo ""
            echo "# Agent workflow context"
            echo ".context/"
            echo ".worktrees/"
        } >> "${PROJECT_ROOT}/.gitignore"
    fi
else
    GITIGNORE_TEMPLATE=$(resolve_template_path ".gitignore.template")
    if [[ -f "$GITIGNORE_TEMPLATE" ]]; then
        echo "[INFO] Creating .gitignore from template"
        cp "$GITIGNORE_TEMPLATE" "${PROJECT_ROOT}/.gitignore"
    fi
fi

# 5. .project.yaml configuration
if [[ "$NON_INTERACTIVE" == "true" ]]; then
    echo "[INFO] Non-interactive mode: skipping .project.yaml configuration"
    echo "[INFO] You can configure later by editing .project.yaml"
else
    echo ""
    echo "========================================="
    echo "Project Configuration"
    echo "========================================="
    echo ""
    echo "Configure your project settings."
    echo "Press Enter to use default values shown in [brackets]."
    echo ""

    # Default values
    DEFAULT_JIRA_URL="https://fadutec.atlassian.net"
    DEFAULT_JIRA_PROJECT="SVI"
    DEFAULT_GITLAB_URL="https://gitlab.fadutec.dev"
    DEFAULT_FEATURE_PREFIX="feat/"
    DEFAULT_BUGFIX_PREFIX="fix/"
    DEFAULT_HOTFIX_PREFIX="hotfix/"

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
    cat > "${PROJECT_ROOT}/.project.yaml" << EOF
# Project Configuration
# Generated by setup.sh

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

# Agent context path (optional, defaults to .agent/ or ~/.agent)
# agent_context: ~/.agent

# Authentication:
# Option 1: Environment variables (recommended)
#   export JIRA_TOKEN="your-token"
#   export JIRA_EMAIL="your-email"
#   export GITLAB_TOKEN="your-token"
#
# Option 2: Secret files (gitignored)
#   .secrets/atlassian-api-token
#   .secrets/gitlab-api-token
EOF

    echo "[INFO] .project.yaml created successfully"
fi

# Determine agent path for PATH instructions
if [[ -d "${PROJECT_ROOT}/.agent" ]]; then
    AGENT_PATH="\$PWD/.agent"
elif [[ -d "$HOME/.agent" ]]; then
    AGENT_PATH="\$HOME/.agent"
else
    AGENT_PATH="${AGENT_DIR}"
fi

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Next Steps:"
echo ""
echo "1. Add tools to PATH:"
echo "   export PATH=\"\$PATH:${AGENT_PATH}/tools/agent/bin:${AGENT_PATH}/tools/pm/bin:${AGENT_PATH}/tools/lint/bin\""
echo "   # Or add to ~/.bashrc or ~/.zshrc for permanent setup"
echo ""
echo "2. Configure secrets (.secrets/):"
echo "   - Edit .secrets/atlassian-api-token (add your Jira API token)"
echo "   - Edit .secrets/gitlab-api-token (add your GitLab token)"
echo "   - See .secrets/README.md for details"
echo ""
echo "3. Verify setup:"
echo "   agent --version"
echo "   pm --help"
echo "   lint --help"
echo ""
echo "4. Start working:"
echo "   agent dev start TASK-123"
echo ""
echo "========================================="
