#!/bin/bash
# Workflow functions for pm init/finish

set -e

# Convert text to URL-friendly slug
slugify() {
    local text="$1"
    local max_length="${2:-50}"

    echo "$text" | \
        tr '[:upper:]' '[:lower:]' | \
        sed 's/[^a-z0-9]/-/g' | \
        sed 's/--*/-/g' | \
        sed 's/^-//' | \
        sed 's/-$//' | \
        cut -c1-"$max_length" | \
        sed 's/-$//'
}

# Get current git branch
get_current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Get default branch (main or master)
get_default_branch() {
    git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"
}

# Check for uncommitted changes
has_uncommitted_changes() {
    [[ -n "$(git status --porcelain 2>/dev/null)" ]]
}

# Create and checkout branch
create_branch() {
    local branch_name="$1"
    local base="${2:-$(get_default_branch)}"

    git checkout -b "$branch_name" "$base"
}

# Push branch with upstream
push_branch() {
    local branch_name="$1"
    git push -u origin "$branch_name"
}

# pm create - Create new feature/task
# Uses unified provider for issue creation (supports JIRA, GitLab, GitHub)
pm_create() {
    local title="$1"
    local issue_type="${2:-Task}"
    local workflow_type="${3:-feature}"

    if [[ -z "$title" ]]; then
        echo "[ERROR] Title required" >&2
        echo "Usage: pm create \"Feature title\" [--type Bug] [--workflow bugfix]" >&2
        return 1
    fi

    local issue_key=""
    local issue_provider=""

    # Get configured issue provider
    issue_provider=$(get_issue_provider)

    # Create issue using unified provider
    if [[ "$issue_provider" != "none" ]]; then
        echo "[INFO] Creating issue via $issue_provider..."

        case "$issue_provider" in
            jira)
                local jira_response
                jira_response=$(jira_api POST "/issue" "$(jq -n \
                    --arg project "$JIRA_PROJECT_KEY" \
                    --arg summary "$title" \
                    --arg type "$issue_type" \
                    '{
                        fields: {
                            project: { key: $project },
                            summary: $summary,
                            issuetype: { name: $type }
                        }
                    }')")

                issue_key=$(echo "$jira_response" | jq -r '.key // empty')
                if [[ -n "$issue_key" ]]; then
                    echo "(v) Jira issue: $issue_key"
                else
                    echo "[WARN] Failed to create Jira issue"
                fi
                ;;
            gitlab)
                local gitlab_iid
                gitlab_iid=$(gitlab_issue_create "$title")
                if [[ -n "$gitlab_iid" ]] && [[ "$gitlab_iid" != "null" ]]; then
                    issue_key="gl-$gitlab_iid"
                    echo "(v) GitLab issue: #$gitlab_iid"
                else
                    echo "[WARN] Failed to create GitLab issue"
                fi
                ;;
            github)
                local github_num
                github_num=$(github_issue_create "$title")
                if [[ -n "$github_num" ]] && [[ "$github_num" != "null" ]]; then
                    issue_key="gh-$github_num"
                    echo "(v) GitHub issue: #$github_num"
                else
                    echo "[WARN] Failed to create GitHub issue"
                fi
                ;;
        esac
    else
        echo "[INFO] No issue provider configured, creating branch only"
    fi

    # Determine branch prefix
    local prefix
    case "$workflow_type" in
        feature) prefix="$BRANCH_FEATURE_PREFIX" ;;
        bugfix)  prefix="$BRANCH_BUGFIX_PREFIX" ;;
        hotfix)  prefix="$BRANCH_HOTFIX_PREFIX" ;;
        *)       prefix="$BRANCH_FEATURE_PREFIX" ;;
    esac

    # Generate branch name
    local slug
    slug=$(slugify "$title")

    local branch_name
    if [[ -n "$issue_key" ]]; then
        branch_name="${prefix}${issue_key}-${slug}"
    else
        branch_name="${prefix}${slug}"
    fi

    # Create git branch
    echo "[INFO] Creating branch..."
    local default_branch
    default_branch=$(get_default_branch)

    if ! create_branch "$branch_name" "$default_branch" 2>/dev/null; then
        echo "[ERROR] Failed to create branch: $branch_name" >&2
        return 1
    fi

    echo "(v) Branch: $branch_name"
    echo ""
    echo "Initialization complete."
}

# pm finish - Finish current feature/task
# Uses unified provider for MR/PR creation (supports GitLab MR and GitHub PR)
pm_finish() {
    local target_branch="${1:-$(get_default_branch)}"
    local skip_lint="${2:-false}"
    local skip_tests="${3:-false}"
    local draft="${4:-false}"

    # Check for uncommitted changes
    if has_uncommitted_changes; then
        echo "[ERROR] You have uncommitted changes. Commit or stash them first." >&2
        return 1
    fi

    # Run lint
    if [[ "$skip_lint" != "true" ]]; then
        echo "[INFO] Running lint checks..."
        if make lint 2>/dev/null; then
            echo "(v) Lint passed"
        else
            echo "[WARN] Lint not configured or failed, skipping"
        fi
    fi

    # Run tests
    if [[ "$skip_tests" != "true" ]]; then
        echo "[INFO] Running tests..."
        if make test 2>/dev/null; then
            echo "(v) Tests passed"
        else
            echo "[WARN] Tests not configured or failed, skipping"
        fi
    fi

    # Get current branch
    local current_branch
    current_branch=$(get_current_branch)

    # Push branch
    echo "[INFO] Pushing $current_branch..."
    if ! push_branch "$current_branch" 2>/dev/null; then
        echo "[ERROR] Failed to push branch" >&2
        return 1
    fi
    echo "(v) Branch pushed"

    # Generate title from branch name
    local title="$current_branch"
    # Remove prefix
    for prefix in "$BRANCH_FEATURE_PREFIX" "$BRANCH_BUGFIX_PREFIX" "$BRANCH_HOTFIX_PREFIX"; do
        if [[ "$title" == "$prefix"* ]]; then
            title="${title#$prefix}"
            break
        fi
    done
    # Convert hyphens to spaces and capitalize
    title=$(echo "$title" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')

    # Get configured review provider
    local review_provider
    review_provider=$(get_review_provider)

    # Create MR/PR using unified provider
    case "$review_provider" in
        gitlab)
            echo "[INFO] Creating GitLab merge request..."
            gitlab_mr_create "$current_branch" "$target_branch" "$title" "" "$draft"
            ;;
        github)
            echo "[INFO] Creating GitHub pull request..."
            github_pr_create "$current_branch" "$target_branch" "$title" "" "$draft"
            ;;
        none)
            echo "[WARN] No code review provider configured, skipping MR/PR creation"
            ;;
    esac

    # Update Jira status (if JIRA is configured as issue provider)
    local issue_provider
    issue_provider=$(get_issue_provider)

    if [[ "$issue_provider" == "jira" ]]; then
        # Try to extract Jira key from branch name
        local jira_key
        jira_key=$(echo "$current_branch" | grep -oE "${JIRA_PROJECT_KEY}-[0-9]+" | head -1)

        if [[ -n "$jira_key" ]]; then
            echo "[INFO] Updating Jira status..."
            if jira_transition "$jira_key" "In Review" 2>/dev/null; then
                echo "(v) Jira updated: $jira_key -> In Review"
            else
                echo "[WARN] Failed to update Jira status (transition may not exist)"
            fi
        fi
    fi

    echo ""
    echo "Feature complete."
}
