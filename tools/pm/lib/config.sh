#!/bin/bash
# Configuration loader for project-management
# Supports role-based structure (new) and legacy flat structure
# Sources: Environment variables > .secrets/ files > .project.yaml

set -e

# Find project root (contains .project.yaml or .git)
find_project_root() {
    local dir="${1:-$(pwd)}"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/.project.yaml" ]] || [[ -d "$dir/.git" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    echo "[ERROR] Cannot find project root (.project.yaml or .git)" >&2
    return 1
}

# Load YAML value using yq (mikefarah/yq)
yaml_get() {
    local file="$1"
    local key="$2"

    if ! command -v yq &>/dev/null; then
        echo "[ERROR] yq is required. Install with: brew install yq" >&2
        return 1
    fi

    local result
    result=$(yq -r "$key" "$file" 2>/dev/null)

    # Return empty string for null values
    if [[ "$result" == "null" ]]; then
        echo ""
    else
        echo "$result"
    fi
}

# Detect config format (new role-based or legacy flat)
detect_config_format() {
    local file="$1"
    local has_roles
    has_roles=$(yq -r '.roles' "$file" 2>/dev/null)

    if [[ -n "$has_roles" ]] && [[ "$has_roles" != "null" ]]; then
        echo "role-based"
    else
        echo "legacy"
    fi
}

# Load configuration
load_config() {
    PROJECT_ROOT=$(find_project_root) || return 1
    CONFIG_FILE="$PROJECT_ROOT/.project.yaml"

    # Detect config format
    local config_format="legacy"
    if [[ -f "$CONFIG_FILE" ]]; then
        config_format=$(detect_config_format "$CONFIG_FILE")
    fi

    # Load config based on format
    if [[ -f "$CONFIG_FILE" ]]; then
        if [[ "$config_format" == "role-based" ]]; then
            # New role-based format
            ROLE_VCS=$(yaml_get "$CONFIG_FILE" '.roles.vcs')
            ROLE_ISSUE=$(yaml_get "$CONFIG_FILE" '.roles.issue')
            ROLE_REVIEW=$(yaml_get "$CONFIG_FILE" '.roles.review')
            ROLE_DOCS=$(yaml_get "$CONFIG_FILE" '.roles.docs')
            ROLE_PLANNING=$(yaml_get "$CONFIG_FILE" '.roles.planning')
            ROLE_WIKI=$(yaml_get "$CONFIG_FILE" '.roles.wiki')

            # Default review to vcs if not set
            ROLE_REVIEW="${ROLE_REVIEW:-$ROLE_VCS}"
            # Default planning to issue provider if not set
            ROLE_PLANNING="${ROLE_PLANNING:-$ROLE_ISSUE}"
            # Default wiki to vcs provider if not set
            ROLE_WIKI="${ROLE_WIKI:-$ROLE_VCS}"

            # Load platform configs (environment variables take precedence)
            JIRA_BASE_URL="${JIRA_BASE_URL:-$(yaml_get "$CONFIG_FILE" '.platforms.jira.base_url')}"
            JIRA_PROJECT_KEY="${JIRA_PROJECT_KEY:-$(yaml_get "$CONFIG_FILE" '.platforms.jira.project_key')}"
            JIRA_EMAIL_CONFIG=$(yaml_get "$CONFIG_FILE" '.platforms.jira.email')

            CONFLUENCE_BASE_URL="${CONFLUENCE_BASE_URL:-$(yaml_get "$CONFIG_FILE" '.platforms.confluence.base_url')}"
            CONFLUENCE_SPACE_KEY="${CONFLUENCE_SPACE_KEY:-$(yaml_get "$CONFIG_FILE" '.platforms.confluence.space_key')}"
            CONFLUENCE_EMAIL_CONFIG=$(yaml_get "$CONFIG_FILE" '.platforms.confluence.email')

            GITLAB_BASE_URL="${GITLAB_BASE_URL:-$(yaml_get "$CONFIG_FILE" '.platforms.gitlab.base_url')}"
            GITLAB_PROJECT="${GITLAB_PROJECT:-$(yaml_get "$CONFIG_FILE" '.platforms.gitlab.project')}"

            GITHUB_REPO="${GITHUB_REPO:-$(yaml_get "$CONFIG_FILE" '.platforms.github.repo')}"
        else
            # Legacy flat format (backward compatibility)
            # Environment variables take precedence over config file
            JIRA_BASE_URL="${JIRA_BASE_URL:-$(yaml_get "$CONFIG_FILE" '.jira.base_url')}"
            JIRA_PROJECT_KEY="${JIRA_PROJECT_KEY:-$(yaml_get "$CONFIG_FILE" '.jira.project_key')}"
            JIRA_EMAIL_CONFIG=$(yaml_get "$CONFIG_FILE" '.jira.email')

            CONFLUENCE_BASE_URL="${CONFLUENCE_BASE_URL:-$(yaml_get "$CONFIG_FILE" '.confluence.base_url')}"
            CONFLUENCE_SPACE_KEY="${CONFLUENCE_SPACE_KEY:-$(yaml_get "$CONFIG_FILE" '.confluence.space_key')}"
            CONFLUENCE_EMAIL_CONFIG=$(yaml_get "$CONFIG_FILE" '.confluence.email')

            GITLAB_BASE_URL="${GITLAB_BASE_URL:-$(yaml_get "$CONFIG_FILE" '.gitlab.base_url')}"
            GITLAB_PROJECT="${GITLAB_PROJECT:-$(yaml_get "$CONFIG_FILE" '.gitlab.project')}"

            GITHUB_REPO="${GITHUB_REPO:-$(yaml_get "$CONFIG_FILE" '.github.repo')}"

            # Legacy: no explicit roles
            ROLE_VCS=""
            ROLE_ISSUE=""
            ROLE_REVIEW=""
            ROLE_DOCS=""
            ROLE_PLANNING=""
            ROLE_WIKI=""
        fi

        # Branch prefixes (same for both formats)
        BRANCH_FEATURE_PREFIX=$(yaml_get "$CONFIG_FILE" '.branch.feature_prefix')
        BRANCH_BUGFIX_PREFIX=$(yaml_get "$CONFIG_FILE" '.branch.bugfix_prefix')
        BRANCH_HOTFIX_PREFIX=$(yaml_get "$CONFIG_FILE" '.branch.hotfix_prefix')
    fi

    # Defaults
    BRANCH_FEATURE_PREFIX="${BRANCH_FEATURE_PREFIX:-feat/}"
    BRANCH_BUGFIX_PREFIX="${BRANCH_BUGFIX_PREFIX:-fix/}"
    BRANCH_HOTFIX_PREFIX="${BRANCH_HOTFIX_PREFIX:-hotfix/}"

    # Auth: Environment > Project .secrets > Global ~/.secrets

    # Jira/Atlassian
    if [[ -z "$JIRA_TOKEN" ]] && [[ -f "$PROJECT_ROOT/.secrets/atlassian-api-token" ]]; then
        JIRA_TOKEN=$(cat "$PROJECT_ROOT/.secrets/atlassian-api-token")
    elif [[ -z "$JIRA_TOKEN" ]] && [[ -f "$HOME/.secrets/atlassian-api-token" ]]; then
        JIRA_TOKEN=$(cat "$HOME/.secrets/atlassian-api-token")
    fi
    JIRA_EMAIL="${JIRA_EMAIL:-$JIRA_EMAIL_CONFIG}"

    # Confluence
    if [[ -z "$CONFLUENCE_TOKEN" ]] && [[ -f "$PROJECT_ROOT/.secrets/confluence-api-token" ]]; then
        CONFLUENCE_TOKEN=$(cat "$PROJECT_ROOT/.secrets/confluence-api-token")
    elif [[ -z "$CONFLUENCE_TOKEN" ]] && [[ -f "$PROJECT_ROOT/.secrets/atlassian-api-token" ]]; then
        CONFLUENCE_TOKEN=$(cat "$PROJECT_ROOT/.secrets/atlassian-api-token")
    elif [[ -z "$CONFLUENCE_TOKEN" ]] && [[ -f "$HOME/.secrets/atlassian-api-token" ]]; then
        CONFLUENCE_TOKEN=$(cat "$HOME/.secrets/atlassian-api-token")
    fi
    CONFLUENCE_TOKEN="${CONFLUENCE_TOKEN:-$JIRA_TOKEN}"
    CONFLUENCE_EMAIL="${CONFLUENCE_EMAIL:-${CONFLUENCE_EMAIL_CONFIG:-$JIRA_EMAIL}}"
    CONFLUENCE_BASE_URL="${CONFLUENCE_BASE_URL:-$JIRA_BASE_URL}"

    # GitLab: Environment > Project .secrets > Global ~/.secrets
    if [[ -z "$GITLAB_TOKEN" ]] && [[ -f "$PROJECT_ROOT/.secrets/gitlab-api-token" ]]; then
        GITLAB_TOKEN=$(cat "$PROJECT_ROOT/.secrets/gitlab-api-token")
    elif [[ -z "$GITLAB_TOKEN" ]] && [[ -f "$HOME/.secrets/gitlab-api-token" ]]; then
        GITLAB_TOKEN=$(cat "$HOME/.secrets/gitlab-api-token")
    fi

    # GitHub: Environment > Project .secrets > Global ~/.secrets
    if [[ -z "$GITHUB_TOKEN" ]] && [[ -f "$PROJECT_ROOT/.secrets/github-api-token" ]]; then
        GITHUB_TOKEN=$(cat "$PROJECT_ROOT/.secrets/github-api-token")
    elif [[ -z "$GITHUB_TOKEN" ]] && [[ -f "$HOME/.secrets/github-api-token" ]]; then
        GITHUB_TOKEN=$(cat "$HOME/.secrets/github-api-token")
    fi

    # Export all
    export PROJECT_ROOT CONFIG_FILE
    export ROLE_VCS ROLE_ISSUE ROLE_REVIEW ROLE_DOCS ROLE_PLANNING ROLE_WIKI
    export JIRA_BASE_URL JIRA_PROJECT_KEY JIRA_EMAIL JIRA_TOKEN
    export CONFLUENCE_BASE_URL CONFLUENCE_SPACE_KEY CONFLUENCE_EMAIL CONFLUENCE_TOKEN
    export GITLAB_BASE_URL GITLAB_PROJECT GITLAB_TOKEN
    export GITHUB_REPO GITHUB_TOKEN
    export BRANCH_FEATURE_PREFIX BRANCH_BUGFIX_PREFIX BRANCH_HOTFIX_PREFIX
}

# Check if Jira is configured
jira_configured() {
    [[ -n "$JIRA_BASE_URL" ]] && [[ -n "$JIRA_TOKEN" ]] && [[ -n "$JIRA_EMAIL" ]]
}

# Check if Confluence is configured
confluence_configured() {
    [[ -n "$CONFLUENCE_BASE_URL" ]] && [[ -n "$CONFLUENCE_TOKEN" ]] && [[ -n "$CONFLUENCE_EMAIL" ]]
}

# Check if GitLab is configured
gitlab_configured() {
    [[ -n "$GITLAB_BASE_URL" ]] && [[ -n "$GITLAB_TOKEN" ]] && [[ -n "$GITLAB_PROJECT" ]]
}

# Check if GitHub is configured
github_configured() {
    [[ -n "$GITHUB_TOKEN" ]] && [[ -n "$GITHUB_REPO" ]]
}

# Print configuration
print_config() {
    local config_format="legacy"
    if [[ -f "$CONFIG_FILE" ]]; then
        config_format=$(detect_config_format "$CONFIG_FILE")
    fi

    echo "=================================================="
    echo "Project Configuration"
    echo "=================================================="
    echo "Project Root: $PROJECT_ROOT"
    echo "Config Format: $config_format"
    echo ""

    if [[ "$config_format" == "role-based" ]]; then
        echo "[Roles]"
        echo "  VCS:      ${ROLE_VCS:-(not set)}"
        echo "  Issue:    ${ROLE_ISSUE:-(not set)}"
        echo "  Review:   ${ROLE_REVIEW:-(not set)}"
        echo "  Docs:     ${ROLE_DOCS:-(not set)}"
        echo "  Planning: ${ROLE_PLANNING:-(not set)}"
        echo "  Wiki:     ${ROLE_WIKI:-(not set)}"
        echo ""
    fi

    echo "[Platforms]"
    echo ""
    echo "  [Jira]"
    if jira_configured; then
        echo "    Base URL:    $JIRA_BASE_URL"
        echo "    Project Key: $JIRA_PROJECT_KEY"
        echo "    Email:       $JIRA_EMAIL"
        echo "    Token:       (set)"
    else
        echo "    (not configured)"
    fi
    echo ""
    echo "  [Confluence]"
    if confluence_configured; then
        echo "    Base URL:  $CONFLUENCE_BASE_URL"
        echo "    Space Key: ${CONFLUENCE_SPACE_KEY:-(not set)}"
        echo "    Email:     $CONFLUENCE_EMAIL"
        echo "    Token:     (set)"
    else
        echo "    (not configured)"
    fi
    echo ""
    echo "  [GitLab]"
    if gitlab_configured; then
        echo "    Base URL: $GITLAB_BASE_URL"
        echo "    Project:  $GITLAB_PROJECT"
        echo "    Token:    (set)"
    else
        echo "    (not configured)"
    fi
    echo ""
    echo "  [GitHub]"
    if github_configured; then
        echo "    Repo:  $GITHUB_REPO"
        echo "    Token: (set)"
    else
        echo "    (not configured)"
    fi
    echo ""
    echo "[Branch Prefixes]"
    echo "  Feature: $BRANCH_FEATURE_PREFIX"
    echo "  Bugfix:  $BRANCH_BUGFIX_PREFIX"
    echo "  Hotfix:  $BRANCH_HOTFIX_PREFIX"
    echo "=================================================="
}

# Create default config file (new role-based format)
create_default_config() {
    local target="${1:-.project.yaml}"
    cat > "$target" << 'EOF'
# Project Configuration
# Role-based platform assignment

# ============================================================
# Role Assignment (which platform handles what)
# ============================================================
roles:
  vcs: gitlab           # Version Control: github | gitlab
  issue: jira           # Issue Tracking: jira | github | gitlab
  review: gitlab        # Code Review: github | gitlab (follows vcs if not set)
  docs: confluence      # Documentation: confluence | github | gitlab

# ============================================================
# Platform Configurations
# ============================================================
platforms:
  github:
    repo: owner/repo

  gitlab:
    base_url: https://gitlab.example.com
    project: namespace/project

  jira:
    base_url: https://your-domain.atlassian.net
    project_key: PROJ
    email: your-email@example.com

  confluence:
    base_url: https://your-domain.atlassian.net
    space_key: SPACE

# ============================================================
# Branch Naming Convention
# ============================================================
branch:
  feature_prefix: feat/
  bugfix_prefix: fix/
  hotfix_prefix: hotfix/
EOF
    echo "(v) Created $target"
}
