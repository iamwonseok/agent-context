#!/bin/bash
# Configuration loader for project-management
# Supports role-based structure (new) and legacy flat structure
# Sources: Environment variables > .secrets/ files > .project.yaml

set -e

# Normalize Jira Cloud base URL for fadutec.
# Accepts UI URLs like:
# - https://atlassian.jira.fadutec.dev/jira/software/c
# - https://fadutec.atlassian.net/projects/SVI/boards/1172
# and normalizes them to:
# - https://fadutec.atlassian.net
normalize_jira_base_url() {
    local input="${1:-}"
    if [[ -z "$input" ]]; then
        echo ""
        return 0
    fi

    # Hard mapping for internal proxy -> Jira Cloud.
    if [[ "$input" == *"atlassian.jira.fadutec.dev"* ]]; then
        echo "https://fadutec.atlassian.net"
        return 0
    fi

    # If user pasted a Jira Cloud UI URL, normalize to base origin.
    if [[ "$input" == *"fadutec.atlassian.net"* ]]; then
        echo "https://fadutec.atlassian.net"
        return 0
    fi

    echo "$input"
    return 0
}

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

        # Git workflow (optional)
        GIT_MERGE_STRATEGY=$(yaml_get "$CONFIG_FILE" '.git.merge.strategy')
        GIT_MERGE_DELETE_MERGED_BRANCH=$(yaml_get "$CONFIG_FILE" '.git.merge.delete_merged_branch')
        GIT_PUSH_REQUIRE_PRECOMMIT_PASS=$(yaml_get "$CONFIG_FILE" '.git.push.require_precommit_pass')
    fi

    # Normalize Jira URL after config load.
    JIRA_BASE_URL=$(normalize_jira_base_url "$JIRA_BASE_URL")

    # Defaults
    BRANCH_FEATURE_PREFIX="${BRANCH_FEATURE_PREFIX:-feat/}"
    BRANCH_BUGFIX_PREFIX="${BRANCH_BUGFIX_PREFIX:-fix/}"
    BRANCH_HOTFIX_PREFIX="${BRANCH_HOTFIX_PREFIX:-hotfix/}"

    # Git workflow defaults
    GIT_MERGE_STRATEGY="${GIT_MERGE_STRATEGY:-}"
    GIT_MERGE_DELETE_MERGED_BRANCH="${GIT_MERGE_DELETE_MERGED_BRANCH:-}"
    GIT_PUSH_REQUIRE_PRECOMMIT_PASS="${GIT_PUSH_REQUIRE_PRECOMMIT_PASS:-}"

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
    export GIT_MERGE_STRATEGY GIT_MERGE_DELETE_MERGED_BRANCH GIT_PUSH_REQUIRE_PRECOMMIT_PASS
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
    echo "Project Configuration"
    echo "========================================"
    echo "PROJECT: ${PROJECT_ROOT}"

    local email="${JIRA_EMAIL:-${CONFLUENCE_EMAIL:-}}"
    if [[ -n "${email}" ]]; then
        echo "E-MAIL: ${email}"
    fi
    echo ""

    local has_jira=false
    local has_confluence=false
    local has_gitlab=false
    local has_github=false

    echo "[Summary]"

    if jira_configured; then
        echo "[V] Jira: ${JIRA_BASE_URL%/}/projects/${JIRA_PROJECT_KEY}"
        has_jira=true
    fi

    # Confluence is optional: print only when space key is available and auth is set.
    if confluence_configured && [[ -n "${CONFLUENCE_SPACE_KEY}" ]]; then
        echo "[V] Confluence: ${CONFLUENCE_BASE_URL%/}/spaces/${CONFLUENCE_SPACE_KEY}"
        has_confluence=true
    fi

    # GitLab is optional: print only when base_url and project are available.
    if [[ -n "${GITLAB_BASE_URL}" ]] && [[ -n "${GITLAB_PROJECT}" ]]; then
        local gitlab_host="${GITLAB_BASE_URL}"
        gitlab_host="${gitlab_host#https://}"
        gitlab_host="${gitlab_host#http://}"
        gitlab_host="${gitlab_host%%/*}"
        echo "[V] GitLab: git@${gitlab_host}:${GITLAB_PROJECT}.git"
        has_gitlab=true
    fi

    # GitHub is optional: print only when repo is available.
    if [[ -n "${GITHUB_REPO}" ]]; then
        echo "[V] GitHub: git@github.com:${GITHUB_REPO}.git"
        has_github=true
    fi

    echo ""
    echo "[Usages]"

    # Summarize roles only for providers present in Summary.
    # Default role fallbacks are already applied during load_config.
    if [[ "${has_gitlab}" == "true" ]]; then
        echo "GitLab: VCS, Wiki, Review"
    fi
    if [[ "${has_jira}" == "true" ]]; then
        echo "Jira: Plan, Issue"
    fi
    if [[ "${has_confluence}" == "true" ]]; then
        echo "Confluence: Docs"
    fi
    if [[ "${has_github}" == "true" ]]; then
        echo "GitHub: VCS, Wiki, Review"
    fi
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

# ============================================================
# Git Workflow (project-specific)
# ============================================================
git:
  merge:
    # Strategy options: ff-only | squash | rebase | merge-commit
    strategy: ff-only
    # If true, delete the source branch after it is merged.
    delete_merged_branch: true
  push:
    # If true, do not push unless pre-commit checks pass.
    require_precommit_pass: true
EOF
    echo "(v) Created $target"
}
