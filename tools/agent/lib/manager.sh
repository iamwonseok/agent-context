#!/bin/bash
# Manager commands for agent CLI
# Integrates with pm CLI for GitLab/JIRA operations

# Find pm CLI
find_pm_cli() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Check relative path first
    local pm_cmd="$script_dir/../../pm/bin/pm"
    if [[ -x "$pm_cmd" ]]; then
        echo "$pm_cmd"
        return 0
    fi

    # Check PATH
    pm_cmd=$(command -v pm 2>/dev/null)
    if [[ -n "$pm_cmd" ]]; then
        echo "$pm_cmd"
        return 0
    fi

    return 1
}

# Check if pm CLI is configured
check_pm_configured() {
    local pm_cmd
    pm_cmd=$(find_pm_cli) || {
        echo "[ERROR] pm CLI not found" >&2
        echo "[INFO] Install pm CLI or check PATH" >&2
        return 1
    }

    # Check if config exists
    if [[ ! -f ".project.yaml" ]]; then
        echo "[WARN] .project.yaml not found" >&2
        echo "[INFO] Run 'pm config init' to create configuration" >&2
        return 1
    fi

    echo "$pm_cmd"
}

# List pending MRs for review
mgr_pending() {
    local state="opened"
    local limit=20
    local author=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--limit)
                limit="$2"
                shift
                ;;
            --author)
                author="$2"
                shift
                ;;
            --all)
                state="all"
                ;;
        esac
        shift
    done

    local pm_cmd
    pm_cmd=$(check_pm_configured) || return 1

    echo "=================================================="
    echo "Pending Merge Requests"
    echo "=================================================="
    echo ""

    # Use pm CLI to list MRs
    "$pm_cmd" gitlab mr list --state "$state" --limit "$limit"

    echo ""
    echo "[INFO] Use 'agent mgr review <mr-id>' to review details"
    echo "=================================================="
}

# Review MR details
mgr_review() {
    local mr_id="$1"
    shift || true

    local add_comment=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--comment)
                add_comment="$2"
                shift
                ;;
        esac
        shift
    done

    if [[ -z "$mr_id" ]]; then
        echo "[ERROR] MR ID required" >&2
        echo "Usage: agent mgr review <mr-id> [--comment <message>]" >&2
        return 1
    fi

    # Remove leading ! if present
    mr_id="${mr_id#!}"

    local pm_cmd
    pm_cmd=$(check_pm_configured) || return 1

    echo "=================================================="
    echo "Reviewing Merge Request: !$mr_id"
    echo "=================================================="
    echo ""

    # Show MR details
    "$pm_cmd" gitlab mr view "$mr_id"

    # Show additional info
    echo ""
    echo "[Review Checklist]"
    echo "  [ ] Code follows project conventions"
    echo "  [ ] Tests are adequate and passing"
    echo "  [ ] No security vulnerabilities"
    echo "  [ ] Documentation updated if needed"
    echo ""

    # Add comment if provided
    if [[ -n "$add_comment" ]]; then
        echo "[INFO] Adding review comment..."
        add_mr_comment "$mr_id" "$add_comment"
    fi

    echo "[ACTIONS]"
    echo "  agent mgr approve $mr_id     # Approve this MR"
    echo "  agent mgr review $mr_id --comment 'feedback'"
    echo "=================================================="
}

# Add comment to MR
add_mr_comment() {
    local mr_id="$1"
    local comment="$2"

    local pm_cmd
    pm_cmd=$(find_pm_cli) || return 1

    # Get project info from config
    local project_root
    project_root=$(find_project_root 2>/dev/null) || project_root="."

    # Use GitLab API via pm CLI structure
    local gitlab_token="${GITLAB_TOKEN:-}"
    local gitlab_url="${GITLAB_URL:-}"
    local gitlab_project="${GITLAB_PROJECT:-}"

    # Try to load from .project.yaml if not in env
    if [[ -f "$project_root/.project.yaml" ]]; then
        if command -v yq &>/dev/null; then
            [[ -z "$gitlab_url" ]] && gitlab_url=$(yq -r '.gitlab.url // empty' "$project_root/.project.yaml" 2>/dev/null)
            [[ -z "$gitlab_project" ]] && gitlab_project=$(yq -r '.gitlab.project // empty' "$project_root/.project.yaml" 2>/dev/null)
        fi
    fi

    # Load token from secrets
    if [[ -z "$gitlab_token" ]] && [[ -f "$project_root/.secrets/gitlab-api-token" ]]; then
        gitlab_token=$(cat "$project_root/.secrets/gitlab-api-token" 2>/dev/null)
    fi

    if [[ -z "$gitlab_token" ]] || [[ -z "$gitlab_url" ]] || [[ -z "$gitlab_project" ]]; then
        echo "[WARN] GitLab not fully configured, cannot add comment" >&2
        echo "[INFO] Comment to add: $comment" >&2
        return 1
    fi

    # URL encode project
    local project_encoded
    project_encoded=$(echo "$gitlab_project" | sed 's/\//%2F/g')

    # Create comment via API
    local payload
    payload=$(printf '{"body": "%s"}' "$comment")

    local response
    response=$(curl -s -X POST \
        -H "PRIVATE-TOKEN: $gitlab_token" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "${gitlab_url}/api/v4/projects/${project_encoded}/merge_requests/${mr_id}/notes")

    local note_id
    note_id=$(echo "$response" | jq -r '.id' 2>/dev/null)

    if [[ -n "$note_id" ]] && [[ "$note_id" != "null" ]]; then
        echo "[OK] Comment added to !$mr_id"
    else
        echo "[WARN] Failed to add comment" >&2
        echo "$response" | jq -r '.message // .error // .' 2>/dev/null >&2
    fi
}

# Approve MR
mgr_approve() {
    local mr_id="$1"
    shift || true

    local force=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force)
                force=true
                ;;
        esac
        shift
    done

    if [[ -z "$mr_id" ]]; then
        echo "[ERROR] MR ID required" >&2
        echo "Usage: agent mgr approve <mr-id>" >&2
        return 1
    fi

    # Remove leading ! if present
    mr_id="${mr_id#!}"

    # Check permission
    local executor
    executor=$(detect_executor 2>/dev/null) || executor="human"

    local permission
    permission=$(get_permission "mgr_approve" 2>/dev/null) || permission="human_only"

    if [[ "$permission" == "human_only" ]] && [[ "$executor" == "agent" ]]; then
        echo "[BLOCKED] MR approval requires human execution" >&2
        echo "[INFO] This is a protected action (human_only)" >&2
        return 1
    fi

    local pm_cmd
    pm_cmd=$(check_pm_configured) || return 1

    echo "=================================================="
    echo "Approving Merge Request: !$mr_id"
    echo "=================================================="
    echo ""

    # Get project info
    local project_root
    project_root=$(find_project_root 2>/dev/null) || project_root="."

    local gitlab_token="${GITLAB_TOKEN:-}"
    local gitlab_url="${GITLAB_URL:-}"
    local gitlab_project="${GITLAB_PROJECT:-}"

    # Load from config
    if [[ -f "$project_root/.project.yaml" ]] && command -v yq &>/dev/null; then
        [[ -z "$gitlab_url" ]] && gitlab_url=$(yq -r '.gitlab.url // empty' "$project_root/.project.yaml" 2>/dev/null)
        [[ -z "$gitlab_project" ]] && gitlab_project=$(yq -r '.gitlab.project // empty' "$project_root/.project.yaml" 2>/dev/null)
    fi

    # Load token
    if [[ -z "$gitlab_token" ]] && [[ -f "$project_root/.secrets/gitlab-api-token" ]]; then
        gitlab_token=$(cat "$project_root/.secrets/gitlab-api-token" 2>/dev/null)
    fi

    if [[ -z "$gitlab_token" ]] || [[ -z "$gitlab_url" ]] || [[ -z "$gitlab_project" ]]; then
        echo "[ERROR] GitLab not fully configured" >&2
        return 1
    fi

    # Confirm if not forced
    if [[ "$force" != "true" ]] && [[ "$executor" == "human" ]]; then
        echo "This will approve MR !$mr_id"
        read -p "Continue? [y/N] " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "[CANCELLED] Approval cancelled"
            return 0
        fi
    fi

    # URL encode project
    local project_encoded
    project_encoded=$(echo "$gitlab_project" | sed 's/\//%2F/g')

    # Approve via API
    local response
    response=$(curl -s -X POST \
        -H "PRIVATE-TOKEN: $gitlab_token" \
        "${gitlab_url}/api/v4/projects/${project_encoded}/merge_requests/${mr_id}/approve")

    local approved_by
    approved_by=$(echo "$response" | jq -r '.approved_by[0].user.name // empty' 2>/dev/null)

    if [[ -n "$approved_by" ]]; then
        echo "[OK] MR !$mr_id approved"
        echo ""
        echo "Approved by: $approved_by"
    else
        local error_msg
        error_msg=$(echo "$response" | jq -r '.message // .error // "Unknown error"' 2>/dev/null)

        if [[ "$error_msg" == *"already approved"* ]]; then
            echo "[INFO] MR !$mr_id was already approved"
        else
            echo "[ERROR] Failed to approve MR" >&2
            echo "Error: $error_msg" >&2
            return 1
        fi
    fi

    echo "=================================================="
}

# Show status of initiative/epic/task
mgr_status() {
    local id="$1"
    shift || true

    local verbose=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose)
                verbose=true
                ;;
        esac
        shift
    done

    if [[ -z "$id" ]]; then
        # Show overall status
        show_overall_status
        return
    fi

    local pm_cmd
    pm_cmd=$(check_pm_configured) || return 1

    echo "=================================================="
    echo "Status: $id"
    echo "=================================================="
    echo ""

    # Determine type by prefix
    case "$id" in
        INIT-*|init-*)
            echo "[Type] Initiative"
            show_initiative_status "$id" "$verbose"
            ;;
        EPIC-*|epic-*)
            echo "[Type] Epic"
            show_epic_status "$id" "$verbose"
            ;;
        *)
            # Assume it's a task/issue
            echo "[Type] Task/Issue"
            "$pm_cmd" jira issue view "$id" 2>/dev/null || \
            echo "[INFO] Could not find issue in JIRA"
            ;;
    esac

    echo "=================================================="
}

# Show overall project status
show_overall_status() {
    local pm_cmd
    pm_cmd=$(check_pm_configured) || return 1

    echo "=================================================="
    echo "Project Status Overview"
    echo "=================================================="
    echo ""

    echo "[Open MRs]"
    "$pm_cmd" gitlab mr list --state opened --limit 5 2>/dev/null || \
    echo "  (Could not fetch MRs)"
    echo ""

    echo "[Recent Issues]"
    "$pm_cmd" jira issue list --limit 5 2>/dev/null || \
    echo "  (Could not fetch issues)"
    echo ""

    echo "=================================================="
}

# Show initiative status (placeholder - requires JIRA epic tracking)
show_initiative_status() {
    local id="$1"
    local verbose="$2"

    echo ""
    echo "[INFO] Initiative tracking requires JIRA configuration"
    echo "[INFO] ID: $id"
    echo ""
    echo "To view initiative details:"
    echo "  - Check JIRA dashboard"
    echo "  - Use 'pm jira issue view $id'"
}

# Show epic status (placeholder - requires JIRA epic tracking)
show_epic_status() {
    local id="$1"
    local verbose="$2"

    echo ""
    echo "[INFO] Epic tracking requires JIRA configuration"
    echo "[INFO] ID: $id"
    echo ""
    echo "To view epic details:"
    echo "  - Check JIRA dashboard"
    echo "  - Use 'pm jira issue view $id'"
}
