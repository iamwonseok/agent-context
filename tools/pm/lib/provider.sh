#!/bin/bash
# Provider abstraction layer for platform-agnostic commands
# Selects appropriate provider based on roles defined in project.yaml

set -e

# ============================================================
# Provider Detection (Role-based)
# ============================================================

# Get issue tracking provider from roles.issue
# Falls back to auto-detection if not set
get_issue_provider() {
    # Check role-based config first
    if [[ -n "$ROLE_ISSUE" ]]; then
        echo "$ROLE_ISSUE"
        return
    fi

    # Auto-detect (legacy mode): priority JIRA > GitLab > GitHub
    if jira_configured; then
        echo "jira"
    elif gitlab_configured; then
        echo "gitlab"
    elif github_configured; then
        echo "github"
    else
        echo "none"
    fi
}

# Get code review provider from roles.review
# Falls back to roles.vcs, then auto-detection
get_review_provider() {
    # Check role-based config first
    if [[ -n "$ROLE_REVIEW" ]]; then
        echo "$ROLE_REVIEW"
        return
    fi
    
    # Fall back to VCS role
    if [[ -n "$ROLE_VCS" ]]; then
        echo "$ROLE_VCS"
        return
    fi

    # Auto-detect (legacy mode): prefer GitLab > GitHub
    if gitlab_configured; then
        echo "gitlab"
    elif github_configured; then
        echo "github"
    else
        echo "none"
    fi
}

# Get VCS provider from roles.vcs
get_vcs_provider() {
    # Check role-based config first
    if [[ -n "$ROLE_VCS" ]]; then
        echo "$ROLE_VCS"
        return
    fi

    # Auto-detect (legacy mode)
    if gitlab_configured; then
        echo "gitlab"
    elif github_configured; then
        echo "github"
    else
        echo "none"
    fi
}

# Get documentation provider from roles.docs
get_document_provider() {
    # Check role-based config first
    if [[ -n "$ROLE_DOCS" ]]; then
        echo "$ROLE_DOCS"
        return
    fi

    # Auto-detect (legacy mode): Confluence > GitLab > GitHub
    if confluence_configured; then
        echo "confluence"
    elif gitlab_configured; then
        echo "gitlab"
    elif github_configured; then
        echo "github"
    else
        echo "none"
    fi
}

# ============================================================
# Unified Issue Functions
# ============================================================

# Create issue using configured provider
# Returns: issue ID/key
unified_issue_create() {
    local title="$1"
    local type="${2:-Task}"
    local description="$3"

    local provider
    provider=$(get_issue_provider)

    case "$provider" in
        jira)
            jira_issue_create "$title" "$type" "$description"
            ;;
        github)
            local number
            number=$(github_issue_create "$title" "$description")
            if [[ -n "$number" ]] && [[ "$number" != "null" ]]; then
                echo "gh-$number"
            fi
            ;;
        gitlab)
            local iid
            iid=$(gitlab_issue_create "$title" "$description")
            if [[ -n "$iid" ]] && [[ "$iid" != "null" ]]; then
                echo "gl-$iid"
            fi
            ;;
        none)
            echo "[ERROR] No issue provider configured (roles.issue not set)" >&2
            return 1
            ;;
        *)
            echo "[ERROR] Unknown issue provider: $provider" >&2
            return 1
            ;;
    esac
}

# List issues using configured provider
unified_issue_list() {
    local status="${1:-open}"
    local limit="${2:-20}"

    local provider
    provider=$(get_issue_provider)

    case "$provider" in
        jira)
            jira_issue_list "" "$limit"
            ;;
        github)
            github_issue_list "$status" "$limit"
            ;;
        gitlab)
            local state="opened"
            [[ "$status" == "closed" ]] && state="closed"
            [[ "$status" == "all" ]] && state="all"
            gitlab_issue_list "$state" "$limit"
            ;;
        none)
            echo "[ERROR] No issue provider configured (roles.issue not set)" >&2
            return 1
            ;;
        *)
            echo "[ERROR] Unknown issue provider: $provider" >&2
            return 1
            ;;
    esac
}

# ============================================================
# Unified Review (MR/PR) Functions
# ============================================================

# Create merge request/pull request using configured provider
unified_review_create() {
    local source_branch="$1"
    local target_branch="${2:-main}"
    local title="$3"
    local description="$4"
    local draft="${5:-false}"

    local provider
    provider=$(get_review_provider)

    case "$provider" in
        github)
            github_pr_create "$source_branch" "$target_branch" "$title" "$description" "$draft"
            ;;
        gitlab)
            gitlab_mr_create "$source_branch" "$target_branch" "$title" "$description" "$draft"
            ;;
        none)
            echo "[ERROR] No code review provider configured (roles.review not set)" >&2
            return 1
            ;;
        *)
            echo "[ERROR] Unknown review provider: $provider" >&2
            return 1
            ;;
    esac
}

# List merge requests/pull requests using configured provider
unified_review_list() {
    local status="${1:-open}"
    local limit="${2:-20}"

    local provider
    provider=$(get_review_provider)

    case "$provider" in
        github)
            github_pr_list "$status" "$limit"
            ;;
        gitlab)
            local state="opened"
            [[ "$status" == "closed" ]] && state="closed"
            [[ "$status" == "merged" ]] && state="merged"
            [[ "$status" == "all" ]] && state="all"
            gitlab_mr_list "$state" "$limit"
            ;;
        none)
            echo "[ERROR] No code review provider configured (roles.review not set)" >&2
            return 1
            ;;
        *)
            echo "[ERROR] Unknown review provider: $provider" >&2
            return 1
            ;;
    esac
}

# View merge request/pull request details
unified_review_view() {
    local id="$1"

    local provider
    provider=$(get_review_provider)

    case "$provider" in
        github)
            github_pr_view "$id"
            ;;
        gitlab)
            gitlab_mr_view "$id"
            ;;
        none)
            echo "[ERROR] No code review provider configured (roles.review not set)" >&2
            return 1
            ;;
        *)
            echo "[ERROR] Unknown review provider: $provider" >&2
            return 1
            ;;
    esac
}

# ============================================================
# Unified Document Functions
# ============================================================

# Create document using configured provider
unified_doc_create() {
    local title="$1"
    local content="$2"
    local space="$3"

    local provider
    provider=$(get_document_provider)

    case "$provider" in
        confluence)
            confluence_page_create "$space" "$title" "$content"
            ;;
        gitlab|github)
            echo "[WARN] Wiki support not yet implemented for $provider" >&2
            echo "[INFO] Please create documentation manually" >&2
            return 1
            ;;
        none)
            echo "[ERROR] No document provider configured (roles.docs not set)" >&2
            return 1
            ;;
        *)
            echo "[ERROR] Unknown document provider: $provider" >&2
            return 1
            ;;
    esac
}

# List documents using configured provider
unified_doc_list() {
    local space="$1"
    local limit="${2:-25}"

    local provider
    provider=$(get_document_provider)

    case "$provider" in
        confluence)
            confluence_page_list "$space" "$limit"
            ;;
        gitlab|github)
            echo "[WARN] Wiki listing not yet implemented for $provider" >&2
            return 1
            ;;
        none)
            echo "[ERROR] No document provider configured (roles.docs not set)" >&2
            return 1
            ;;
        *)
            echo "[ERROR] Unknown document provider: $provider" >&2
            return 1
            ;;
    esac
}

# ============================================================
# Provider Info
# ============================================================

# Show current provider configuration
show_providers() {
    echo "=================================================="
    echo "Provider Configuration (Role-based)"
    echo "=================================================="
    echo ""
    
    # VCS
    echo "[VCS - Version Control]"
    local vcs_provider
    vcs_provider=$(get_vcs_provider)
    echo "  Role:     ${ROLE_VCS:-(auto)}"
    echo "  Provider: $vcs_provider"
    case "$vcs_provider" in
        github) echo "  Platform: GitHub ($GITHUB_REPO)" ;;
        gitlab) echo "  Platform: GitLab ($GITLAB_PROJECT)" ;;
        none)   echo "  Platform: (not configured)" ;;
    esac
    echo ""
    
    # Issue Tracking
    echo "[Issue Tracking]"
    local issue_provider
    issue_provider=$(get_issue_provider)
    echo "  Role:     ${ROLE_ISSUE:-(auto)}"
    echo "  Provider: $issue_provider"
    case "$issue_provider" in
        jira)   echo "  Platform: JIRA ($JIRA_BASE_URL)" ;;
        github) echo "  Platform: GitHub Issues ($GITHUB_REPO)" ;;
        gitlab) echo "  Platform: GitLab Issues ($GITLAB_PROJECT)" ;;
        none)   echo "  Platform: (not configured)" ;;
    esac
    echo ""
    
    # Code Review
    echo "[Code Review]"
    local review_provider
    review_provider=$(get_review_provider)
    echo "  Role:     ${ROLE_REVIEW:-(auto)}"
    echo "  Provider: $review_provider"
    case "$review_provider" in
        github) echo "  Platform: GitHub Pull Requests ($GITHUB_REPO)" ;;
        gitlab) echo "  Platform: GitLab Merge Requests ($GITLAB_PROJECT)" ;;
        none)   echo "  Platform: (not configured)" ;;
    esac
    echo ""
    
    # Documentation
    echo "[Documentation]"
    local doc_provider
    doc_provider=$(get_document_provider)
    echo "  Role:     ${ROLE_DOCS:-(auto)}"
    echo "  Provider: $doc_provider"
    case "$doc_provider" in
        confluence) echo "  Platform: Confluence ($CONFLUENCE_BASE_URL)" ;;
        github)     echo "  Platform: GitHub Wiki ($GITHUB_REPO)" ;;
        gitlab)     echo "  Platform: GitLab Wiki ($GITLAB_PROJECT)" ;;
        none)       echo "  Platform: (not configured)" ;;
    esac
    echo "=================================================="
}
