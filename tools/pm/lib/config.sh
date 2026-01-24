#!/bin/bash
# Configuration loader for project-management
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

# Load YAML value using yq or grep fallback
yaml_get() {
    local file="$1"
    local key="$2"
    
    if command -v yq &>/dev/null; then
        yq -r "$key // empty" "$file" 2>/dev/null
    else
        # Simple grep-based fallback for flat YAML
        # Converts "jira.base_url" to search pattern
        local section="${key%%.*}"
        local field="${key#*.}"
        awk -v section="$section" -v field="$field" '
            /^[a-z]/ { current_section = $1; gsub(/:/, "", current_section) }
            current_section == section && $1 == field":" { 
                gsub(/^[^:]+:[ ]*/, ""); 
                gsub(/^["'\'']|["'\'']$/, "");
                print; exit
            }
        ' "$file" 2>/dev/null
    fi
}

# Load configuration
load_config() {
    PROJECT_ROOT=$(find_project_root) || return 1
    CONFIG_FILE="$PROJECT_ROOT/.project.yaml"
    
    # Load config from file
    if [[ -f "$CONFIG_FILE" ]]; then
        # Jira config
        JIRA_BASE_URL=$(yaml_get "$CONFIG_FILE" "jira.base_url")
        JIRA_PROJECT_KEY=$(yaml_get "$CONFIG_FILE" "jira.project_key")
        JIRA_EMAIL_CONFIG=$(yaml_get "$CONFIG_FILE" "jira.email")
        
        # GitLab config
        GITLAB_BASE_URL=$(yaml_get "$CONFIG_FILE" "gitlab.base_url")
        GITLAB_PROJECT=$(yaml_get "$CONFIG_FILE" "gitlab.project")
        
        # GitHub config
        GITHUB_REPO=$(yaml_get "$CONFIG_FILE" "github.repo")
        
        # Branch prefixes
        BRANCH_FEATURE_PREFIX=$(yaml_get "$CONFIG_FILE" "branch.feature_prefix")
        BRANCH_BUGFIX_PREFIX=$(yaml_get "$CONFIG_FILE" "branch.bugfix_prefix")
        BRANCH_HOTFIX_PREFIX=$(yaml_get "$CONFIG_FILE" "branch.hotfix_prefix")
    fi
    
    # Defaults
    BRANCH_FEATURE_PREFIX="${BRANCH_FEATURE_PREFIX:-feat/}"
    BRANCH_BUGFIX_PREFIX="${BRANCH_BUGFIX_PREFIX:-fix/}"
    BRANCH_HOTFIX_PREFIX="${BRANCH_HOTFIX_PREFIX:-hotfix/}"
    
    # Auth: Environment > .secrets files
    # Jira
    if [[ -z "$JIRA_TOKEN" ]] && [[ -f "$PROJECT_ROOT/.secrets/atlassian-api-token" ]]; then
        JIRA_TOKEN=$(cat "$PROJECT_ROOT/.secrets/atlassian-api-token")
    fi
    JIRA_EMAIL="${JIRA_EMAIL:-$JIRA_EMAIL_CONFIG}"
    
    # GitLab
    if [[ -z "$GITLAB_TOKEN" ]] && [[ -f "$PROJECT_ROOT/.secrets/gitlab-api-token" ]]; then
        GITLAB_TOKEN=$(cat "$PROJECT_ROOT/.secrets/gitlab-api-token")
    fi
    
    # GitHub
    if [[ -z "$GITHUB_TOKEN" ]] && [[ -f "$PROJECT_ROOT/.secrets/github-api-token" ]]; then
        GITHUB_TOKEN=$(cat "$PROJECT_ROOT/.secrets/github-api-token")
    fi
    
    export PROJECT_ROOT CONFIG_FILE
    export JIRA_BASE_URL JIRA_PROJECT_KEY JIRA_EMAIL JIRA_TOKEN
    export GITLAB_BASE_URL GITLAB_PROJECT GITLAB_TOKEN
    export GITHUB_REPO GITHUB_TOKEN
    export BRANCH_FEATURE_PREFIX BRANCH_BUGFIX_PREFIX BRANCH_HOTFIX_PREFIX
}

# Check if Jira is configured
jira_configured() {
    [[ -n "$JIRA_BASE_URL" ]] && [[ -n "$JIRA_TOKEN" ]] && [[ -n "$JIRA_EMAIL" ]]
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
    echo "=================================================="
    echo "Project Configuration"
    echo "=================================================="
    echo "Project Root: $PROJECT_ROOT"
    echo ""
    echo "[Jira]"
    if jira_configured; then
        echo "  Base URL:    $JIRA_BASE_URL"
        echo "  Project Key: $JIRA_PROJECT_KEY"
        echo "  Email:       $JIRA_EMAIL"
        echo "  Token:       (set)"
    else
        echo "  (not configured)"
    fi
    echo ""
    echo "[GitLab]"
    if gitlab_configured; then
        echo "  Base URL: $GITLAB_BASE_URL"
        echo "  Project:  $GITLAB_PROJECT"
        echo "  Token:    (set)"
    else
        echo "  (not configured)"
    fi
    echo ""
    echo "[GitHub]"
    if github_configured; then
        echo "  Repo:  $GITHUB_REPO"
        echo "  Token: (set)"
    else
        echo "  (not configured)"
    fi
    echo ""
    echo "[Branch Prefixes]"
    echo "  Feature: $BRANCH_FEATURE_PREFIX"
    echo "  Bugfix:  $BRANCH_BUGFIX_PREFIX"
    echo "  Hotfix:  $BRANCH_HOTFIX_PREFIX"
    echo "=================================================="
}

# Create default config file
create_default_config() {
    local target="${1:-.project.yaml}"
    cat > "$target" << 'EOF'
# Project Configuration
# See: project-management/README.md

# Issue Tracker (optional)
jira:
  base_url: https://your-domain.atlassian.net
  project_key: PROJ
  email: your-email@example.com

# Git Platform (choose one: gitlab or github)
gitlab:
  base_url: https://gitlab.example.com
  project: namespace/project

github:
  repo: owner/repo

branch:
  feature_prefix: feat/
  bugfix_prefix: fix/
  hotfix_prefix: hotfix/
EOF
    echo "(v) Created $target"
}
