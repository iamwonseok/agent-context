#!/bin/bash
# Upload functions for agent CLI
# Uploads context logs to Issue/MR

# Source markdown helper
UPLOAD_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$UPLOAD_SCRIPT_DIR/markdown.sh"

# Upload context to JIRA issue
# Usage: upload_to_jira <task_id> <context_path>
upload_to_jira() {
    local task_id="$1"
    local context_path="$2"

    # Check if pm CLI is available
    local pm_cmd
    pm_cmd=$(find_pm_cli) || {
        echo "[WARN] pm CLI not found, skipping JIRA upload"
        return 1
    }

    # Check if JIRA is configured
    if ! "$pm_cmd" jira configured 2>/dev/null; then
        echo "[WARN] JIRA not configured, skipping upload"
        return 1
    fi

    # Generate comment content
    local comment
    comment=$(generate_issue_comment "$context_path")

    echo "[INFO] Uploading context to JIRA issue: $task_id"

    # Use pm CLI to add comment
    if "$pm_cmd" jira comment "$task_id" "$comment" 2>/dev/null; then
        echo "[OK] Context uploaded to JIRA: $task_id"
        return 0
    else
        echo "[WARN] Failed to upload to JIRA (issue may not exist)"
        return 1
    fi
}

# Upload context to GitLab issue/MR
# Usage: upload_to_gitlab <mr_iid> <context_path>
upload_to_gitlab_mr() {
    local mr_iid="$1"
    local context_path="$2"

    # Check if pm CLI is available
    local pm_cmd
    pm_cmd=$(find_pm_cli) || {
        echo "[WARN] pm CLI not found, skipping GitLab upload"
        return 1
    }

    # Check if GitLab is configured
    if ! "$pm_cmd" gitlab configured 2>/dev/null; then
        echo "[WARN] GitLab not configured, skipping upload"
        return 1
    fi

    # Generate description content
    local description
    description=$(generate_mr_description "$context_path")

    echo "[INFO] Updating GitLab MR description: !$mr_iid"

    # Use pm CLI to update MR
    if "$pm_cmd" gitlab mr update "$mr_iid" --description "$description" 2>/dev/null; then
        echo "[OK] MR description updated: !$mr_iid"
        return 0
    else
        echo "[WARN] Failed to update MR description"
        return 1
    fi
}

# Find pm CLI
find_pm_cli() {
    local pm_cmd

    # Check relative path first (from agent CLI)
    pm_cmd="$UPLOAD_SCRIPT_DIR/../../pm/bin/pm"
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

# Check if task ID looks like an issue key
# Returns 0 if it's a valid issue key format
is_issue_key() {
    local task_id="$1"

    # Common patterns: PROJ-123, ABC-1, etc.
    if [[ "$task_id" =~ ^[A-Z]+-[0-9]+$ ]]; then
        return 0
    fi

    # Also accept lowercase
    if [[ "$task_id" =~ ^[a-zA-Z]+-[0-9]+$ ]]; then
        return 0
    fi

    return 1
}

# Smart upload: decides where to upload based on task ID
# Usage: smart_upload <task_id> <context_path>
smart_upload() {
    local task_id="$1"
    local context_path="$2"

    local uploaded=false

    # Try JIRA if task ID looks like an issue key
    if is_issue_key "$task_id"; then
        if upload_to_jira "$task_id" "$context_path"; then
            uploaded=true
        fi
    fi

    # Return upload status
    if [[ "$uploaded" == "true" ]]; then
        return 0
    else
        echo "[INFO] Context will be included in MR description instead"
        return 1
    fi
}

# Include context in MR description (fallback when no issue)
# Returns the markdown to include
get_mr_context_markdown() {
    local context_path="$1"

    if [[ -d "$context_path" ]]; then
        generate_mr_description "$context_path"
    else
        echo "## Summary"
        echo ""
        echo "$(git log -1 --format=%s 2>/dev/null)"
        echo ""
        echo "## Changes"
        echo ""
        echo "\`\`\`"
        git log origin/main..HEAD --oneline 2>/dev/null || echo "(no commits)"
        echo "\`\`\`"
    fi
}
