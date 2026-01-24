#!/bin/bash
# init.sh - Project initialization functions

# Find agent-context installation path
find_agent_context() {
    # Check if running from agent-context repo itself
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local agent_root
    agent_root="$(dirname "$(dirname "$(dirname "$script_dir")")")"

    if [[ -f "${agent_root}/setup.sh" && -d "${agent_root}/tools/agent" ]]; then
        echo "$agent_root"
        return 0
    fi

    # Check common locations
    if [[ -d ".agent" ]]; then
        echo "$(cd .agent && pwd)"
    elif [[ -n "$AGENT_CONTEXT_PATH" ]]; then
        echo "$AGENT_CONTEXT_PATH"
    elif [[ -d "$HOME/.agent" ]]; then
        echo "$HOME/.agent"
    else
        return 1
    fi
}

# Validate secrets configuration
validate_secrets() {
    local project_root="$1"
    local errors=0

    echo "[Secrets Validation]"

    # Check JIRA token
    if [[ -n "$JIRA_TOKEN" ]]; then
        echo "  [OK] JIRA_TOKEN (environment variable)"
    elif [[ -f "${project_root}/.secrets/atlassian-api-token" ]]; then
        local token
        token=$(cat "${project_root}/.secrets/atlassian-api-token" 2>/dev/null)
        if [[ -n "$token" && "$token" != "your-api-token-here" ]]; then
            echo "  [OK] JIRA token (.secrets/atlassian-api-token)"
        else
            echo "  [WARN] JIRA token file exists but not configured"
            errors=$((errors + 1))
        fi
    else
        echo "  [WARN] JIRA token not found"
        errors=$((errors + 1))
    fi

    # Check GitLab token
    if [[ -n "$GITLAB_TOKEN" ]]; then
        echo "  [OK] GITLAB_TOKEN (environment variable)"
    elif [[ -f "${project_root}/.secrets/gitlab-api-token" ]]; then
        local token
        token=$(cat "${project_root}/.secrets/gitlab-api-token" 2>/dev/null)
        if [[ -n "$token" && "$token" != "your-api-token-here" ]]; then
            echo "  [OK] GitLab token (.secrets/gitlab-api-token)"
        else
            echo "  [WARN] GitLab token file exists but not configured"
            errors=$((errors + 1))
        fi
    else
        echo "  [WARN] GitLab token not found"
        errors=$((errors + 1))
    fi

    return $errors
}

# Install git hooks
install_git_hooks() {
    local project_root="$1"
    local agent_context="$2"
    local hooks_dir="${project_root}/.git/hooks"

    echo "[Git Hooks]"

    if [[ ! -d "${project_root}/.git" ]]; then
        echo "  [SKIP] Not a git repository"
        return 0
    fi

    mkdir -p "$hooks_dir"

    # Pre-commit hook
    local pre_commit="${hooks_dir}/pre-commit"
    if [[ ! -f "$pre_commit" ]]; then
        cat > "$pre_commit" << 'HOOK'
#!/bin/bash
# Agent pre-commit hook
# Runs basic checks before commit

# Skip if SKIP_HOOKS is set
if [[ -n "$SKIP_HOOKS" ]]; then
    exit 0
fi

# Run lint check if available
if command -v lint >/dev/null 2>&1; then
    echo "[pre-commit] Running lint..."
    lint check || {
        echo "[pre-commit] Lint failed. Use SKIP_HOOKS=1 to bypass."
        exit 1
    }
fi

exit 0
HOOK
        chmod +x "$pre_commit"
        echo "  [OK] Installed pre-commit hook"
    else
        echo "  [SKIP] pre-commit hook already exists"
    fi

    # Commit-msg hook for conventional commits
    local commit_msg="${hooks_dir}/commit-msg"
    if [[ ! -f "$commit_msg" ]]; then
        cat > "$commit_msg" << 'HOOK'
#!/bin/bash
# Agent commit-msg hook
# Validates conventional commit format

# Skip if SKIP_HOOKS is set
if [[ -n "$SKIP_HOOKS" ]]; then
    exit 0
fi

COMMIT_MSG_FILE="$1"
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Conventional commit pattern
# feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert: description
PATTERN="^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\(.+\))?: .+"

if ! echo "$COMMIT_MSG" | grep -qE "$PATTERN"; then
    echo "[commit-msg] Invalid commit message format."
    echo ""
    echo "Expected: <type>[optional scope]: <description>"
    echo "Types: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert"
    echo ""
    echo "Examples:"
    echo "  feat: add user authentication"
    echo "  fix(api): handle null response"
    echo ""
    echo "Your message: $COMMIT_MSG"
    echo ""
    echo "Use SKIP_HOOKS=1 to bypass."
    exit 1
fi

exit 0
HOOK
        chmod +x "$commit_msg"
        echo "  [OK] Installed commit-msg hook"
    else
        echo "  [SKIP] commit-msg hook already exists"
    fi

    # Post-checkout hook for branch handoff notes (optional UX helper)
    local post_checkout="${hooks_dir}/post-checkout"
    if [[ ! -f "$post_checkout" ]]; then
        cat > "$post_checkout" << 'HOOK'
#!/bin/bash
# Agent post-checkout hook
# Shows and removes a branch handoff note on checkout.

# Skip if SKIP_HOOKS is set
if [[ -n "$SKIP_HOOKS" ]]; then
    exit 0
fi

project_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0

if [[ -z "$branch" ]] || [[ "$branch" == "HEAD" ]]; then
    exit 0
fi

safe="${branch//\//__}"
file_new="${project_root}/.context/handoff-${safe}.md"

if [[ -f "$file_new" ]]; then
    echo ""
    echo "=================================================="
    echo "Handoff note for branch: $branch"
    echo "File: $(basename "$file_new")"
    echo "=================================================="
    cat "$file_new"
    echo "=================================================="
    archive_dir="${project_root}/.context/handoff-archive"
    mkdir -p "$archive_dir" 2>/dev/null || true
    ts=$(date -u +"%Y%m%dT%H%M%SZ")
    dest="${archive_dir}/handoff-${safe}-${ts}.md"
    mv "$file_new" "$dest" 2>/dev/null || {
        cp "$file_new" "$dest" 2>/dev/null || true
        rm -f "$file_new" 2>/dev/null || true
    }
fi

exit 0
HOOK
        chmod +x "$post_checkout"
        echo "  [OK] Installed post-checkout hook"
    else
        echo "  [SKIP] post-checkout hook already exists"
    fi
}

# Main init function
agent_init() {
    local force=false
    local skip_hooks=false

    # Parse arguments
    for arg in "$@"; do
        case $arg in
            --force|-f)
                force=true
                ;;
            --no-hooks)
                skip_hooks=true
                ;;
            --help|-h)
                echo "Usage: agent init [OPTIONS]"
                echo ""
                echo "Initialize current project for agent workflow."
                echo ""
                echo "Options:"
                echo "  --force, -f    Overwrite existing configuration"
                echo "  --no-hooks     Skip git hooks installation"
                echo "  --help, -h     Show this help"
                return 0
                ;;
        esac
    done

    echo "========================================="
    echo "Agent Project Initialization"
    echo "========================================="
    echo ""

    # Find project root
    local project_root
    project_root=$(find_project_root 2>/dev/null) || project_root="$(pwd)"
    echo "Project: $project_root"

    # Find agent-context
    local agent_context
    agent_context=$(find_agent_context) || {
        echo "[ERROR] agent-context not found. Run setup.sh first."
        return 1
    }
    echo "Agent Context: $agent_context"
    echo ""

    # Check if already initialized
    if [[ -f "${project_root}/.project.yaml" ]] && [[ "$force" != "true" ]]; then
        echo "[INFO] Project already initialized (.project.yaml exists)"
        echo "[INFO] Use --force to reinitialize"
        echo ""
    else
        # Run setup.sh in non-interactive mode or call its functions
        if [[ -f "${agent_context}/setup.sh" ]]; then
            echo "[INFO] Running project setup..."
            bash "${agent_context}/setup.sh" --non-interactive
            echo ""
        fi
    fi

    # Validate secrets (warnings only, don't fail)
    validate_secrets "$project_root" || true
    echo ""

    # Install git hooks
    if [[ "$skip_hooks" != "true" ]]; then
        install_git_hooks "$project_root" "$agent_context"
        echo ""
    fi

    echo "========================================="
    echo "Initialization Complete"
    echo "========================================="
    echo ""
    echo "Next steps:"
    echo "  1. Configure secrets in .secrets/ or environment variables"
    echo "  2. Edit .project.yaml for your project settings"
    echo "  3. Start working: agent dev start TASK-123"
    echo ""
}
