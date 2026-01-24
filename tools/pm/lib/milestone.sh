#!/bin/bash
# Unified Milestone functions
# Abstracts milestone operations across platforms (GitLab, GitHub, JIRA)

set -e

# ============================================================
# Unified Milestone Functions
# ============================================================

# List milestones using configured provider
# Usage: unified_milestone_list [--state <active|closed|all>] [--limit N]
unified_milestone_list() {
    local state="${1:-active}"
    local limit="${2:-20}"

    local provider
    provider=$(get_planning_provider)

    case "$provider" in
        github)
            # GitHub uses "open" instead of "active"
            local gh_state="open"
            [[ "$state" == "active" ]] && gh_state="open"
            [[ "$state" == "closed" ]] && gh_state="closed"
            [[ "$state" == "all" ]] && gh_state="all"
            github_milestone_list "$gh_state" "$limit"
            ;;
        gitlab)
            gitlab_milestone_list "$state" "$limit"
            ;;
        jira)
            # JIRA uses Sprints (requires board_id)
            echo "[WARN] JIRA Sprint listing requires board ID" >&2
            echo "[INFO] Use 'pm jira sprint list [BOARD_ID]' instead" >&2
            jira_sprint_list ""
            ;;
        none)
            echo "[ERROR] No planning provider configured (roles.planning not set)" >&2
            return 1
            ;;
        *)
            echo "[ERROR] Unknown planning provider: $provider" >&2
            return 1
            ;;
    esac
}

# View milestone details
# Usage: unified_milestone_view <ID>
unified_milestone_view() {
    local id="$1"

    if [[ -z "$id" ]]; then
        echo "[ERROR] Milestone ID required" >&2
        return 1
    fi

    local provider
    provider=$(get_planning_provider)

    case "$provider" in
        github)
            github_milestone_view "$id"
            ;;
        gitlab)
            gitlab_milestone_view "$id"
            ;;
        jira)
            echo "[WARN] JIRA Sprint view not yet implemented" >&2
            echo "[INFO] Use JIRA web interface to view sprint details" >&2
            return 1
            ;;
        none)
            echo "[ERROR] No planning provider configured (roles.planning not set)" >&2
            return 1
            ;;
        *)
            echo "[ERROR] Unknown planning provider: $provider" >&2
            return 1
            ;;
    esac
}

# Create milestone
# Usage: unified_milestone_create <TITLE> [--due <DATE>] [--description <TEXT>]
unified_milestone_create() {
    local title="$1"
    local due_date="$2"
    local description="$3"

    if [[ -z "$title" ]]; then
        echo "[ERROR] Title required" >&2
        return 1
    fi

    local provider
    provider=$(get_planning_provider)

    case "$provider" in
        github)
            local number
            number=$(github_milestone_create "$title" "$due_date" "$description")
            if [[ -n "$number" ]] && [[ "$number" != "null" ]]; then
                echo "(v) GitHub milestone created: #$number"
                echo "    URL: https://github.com/${GITHUB_REPO}/milestone/$number"
            fi
            ;;
        gitlab)
            local id
            id=$(gitlab_milestone_create "$title" "$due_date" "$description")
            if [[ -n "$id" ]] && [[ "$id" != "null" ]]; then
                echo "(v) GitLab milestone created: #$id"
                echo "    URL: ${GITLAB_BASE_URL}/${GITLAB_PROJECT}/-/milestones/$id"
            fi
            ;;
        jira)
            echo "[WARN] JIRA Sprint creation requires board context" >&2
            echo "[INFO] Use JIRA web interface to create sprints" >&2
            return 1
            ;;
        none)
            echo "[ERROR] No planning provider configured (roles.planning not set)" >&2
            return 1
            ;;
        *)
            echo "[ERROR] Unknown planning provider: $provider" >&2
            return 1
            ;;
    esac
}

# Close milestone
# Usage: unified_milestone_close <ID>
unified_milestone_close() {
    local id="$1"

    if [[ -z "$id" ]]; then
        echo "[ERROR] Milestone ID required" >&2
        return 1
    fi

    local provider
    provider=$(get_planning_provider)

    case "$provider" in
        github)
            github_milestone_close "$id"
            ;;
        gitlab)
            gitlab_milestone_close "$id"
            ;;
        jira)
            echo "[WARN] JIRA Sprint completion not yet implemented" >&2
            echo "[INFO] Use JIRA web interface to complete sprints" >&2
            return 1
            ;;
        none)
            echo "[ERROR] No planning provider configured (roles.planning not set)" >&2
            return 1
            ;;
        *)
            echo "[ERROR] Unknown planning provider: $provider" >&2
            return 1
            ;;
    esac
}
