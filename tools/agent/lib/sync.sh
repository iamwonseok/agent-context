#!/bin/bash
# Platform synchronization library
# Orchestrates JIRA, GitLab, and Confluence in a single workflow
#
# Usage: source this file and use sync_* functions

set -e

SYNC_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source dependencies
source "$SYNC_SCRIPT_DIR/progress.sh" 2>/dev/null || true
source "$SYNC_SCRIPT_DIR/../../pm/lib/config.sh" 2>/dev/null || true
source "$SYNC_SCRIPT_DIR/../../pm/lib/provider.sh" 2>/dev/null || true

# ============================================================
# Workflow Start: JIRA + GitLab Branch
# ============================================================

# Start work on a task
# Usage: sync_start TASK-123 ["description"]
sync_start() {
    local task_id="$1"
    local description="${2:-}"
    
    if [[ -z "$task_id" ]]; then
        echo "[ERROR] Task ID required" >&2
        return 1
    fi
    
    progress_init "$task_id" "$description"
    
    echo "=== Starting work on $task_id ==="
    
    # 1. Update JIRA status to "In Progress"
    if jira_configured 2>/dev/null; then
        progress_info "Updating JIRA status to In Progress"
        if [[ "${AGENT_MOCK:-0}" == "1" ]]; then
            echo "[MOCK] Would update JIRA $task_id to In Progress"
        else
            jira_issue_transition "$task_id" "In Progress" 2>/dev/null || \
                echo "[WARN] Could not update JIRA status"
        fi
    fi
    
    # 2. Create feature branch
    local branch_name="feature/${task_id}"
    if [[ -n "$description" ]]; then
        # Slugify description
        local slug
        slug=$(echo "$description" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
        branch_name="feature/${task_id}-${slug:0:30}"
    fi
    
    progress_info "Creating branch: $branch_name"
    if [[ "${AGENT_MOCK:-0}" == "1" ]]; then
        echo "[MOCK] Would create branch: $branch_name"
    else
        git checkout -b "$branch_name" 2>/dev/null || \
            git checkout "$branch_name" 2>/dev/null || \
            echo "[WARN] Could not create/checkout branch"
    fi
    
    # 3. Update state
    local state_file=".context/$task_id/state.yaml"
    if [[ -f "$state_file" ]]; then
        sed -i.bak "s/^branch:.*/branch: \"$branch_name\"/" "$state_file"
        rm -f "$state_file.bak"
    fi
    
    progress_skill "sync/start" "OK"
    echo "[OK] Ready to work on $task_id"
}

# ============================================================
# Workflow Done: MR + JIRA + Reviewers
# ============================================================

# Complete work and create MR
# Usage: sync_done ["MR title"]
sync_done() {
    local title="${1:-}"
    local task_id="${AGENT_TASK_ID:-}"
    
    # Try to get task ID from branch name
    if [[ -z "$task_id" ]]; then
        local branch
        branch=$(git branch --show-current 2>/dev/null)
        task_id=$(echo "$branch" | grep -oE '[A-Z]+-[0-9]+' | head -1)
    fi
    
    if [[ -z "$task_id" ]]; then
        echo "[WARN] Could not determine task ID" >&2
    fi
    
    # Default title from branch
    if [[ -z "$title" ]]; then
        local branch
        branch=$(git branch --show-current 2>/dev/null)
        title="feat($task_id): ${branch#feature/}"
    fi
    
    echo "=== Completing work ==="
    
    # 1. Push branch
    progress_info "Pushing branch"
    if [[ "${AGENT_MOCK:-0}" == "1" ]]; then
        echo "[MOCK] Would push branch"
    else
        git push -u origin HEAD 2>/dev/null || \
            echo "[WARN] Could not push branch"
    fi
    
    # 2. Create MR/PR
    local mr_url=""
    progress_info "Creating merge request"
    if [[ "${AGENT_MOCK:-0}" == "1" ]]; then
        echo "[MOCK] Would create MR: $title"
        mr_url="https://example.com/mr/123"
    else
        local branch
        branch=$(git branch --show-current 2>/dev/null)
        mr_url=$(unified_review_create "$branch" "main" "$title" "" "false" 2>/dev/null) || \
            echo "[WARN] Could not create MR"
    fi
    
    # 3. Update JIRA status to "In Review"
    if [[ -n "$task_id" ]] && jira_configured 2>/dev/null; then
        progress_info "Updating JIRA status to In Review"
        if [[ "${AGENT_MOCK:-0}" == "1" ]]; then
            echo "[MOCK] Would update JIRA $task_id to In Review"
        else
            jira_issue_transition "$task_id" "In Review" 2>/dev/null || \
                jira_issue_transition "$task_id" "Code Review" 2>/dev/null || \
                echo "[WARN] Could not update JIRA status"
            
            # Add MR link as comment
            if [[ -n "$mr_url" ]]; then
                jira_issue_comment "$task_id" "MR created: $mr_url" 2>/dev/null || true
            fi
        fi
    fi
    
    progress_done "MR created: $mr_url"
    echo "[OK] MR created: $mr_url"
}

# ============================================================
# Documentation: Confluence
# ============================================================

# Create/update Confluence documentation
# Usage: sync_document ["page title"]
sync_document() {
    local title="${1:-}"
    local task_id="${AGENT_TASK_ID:-}"
    
    if [[ -z "$title" ]] && [[ -n "$task_id" ]]; then
        title="$task_id Documentation"
    fi
    
    echo "=== Creating documentation ==="
    
    # Check if Confluence is configured
    if ! confluence_configured 2>/dev/null; then
        echo "[WARN] Confluence not configured"
        echo "[INFO] Please create documentation manually"
        return 0
    fi
    
    # Gather content from .context/
    local content=""
    local context_dir=".context/$task_id"
    
    if [[ -d "$context_dir" ]]; then
        # Include progress
        if [[ -f "$context_dir/progress.txt" ]]; then
            content+="h2. Progress Log\n{code}\n"
            content+=$(cat "$context_dir/progress.txt")
            content+="\n{code}\n\n"
        fi
        
        # Include state
        if [[ -f "$context_dir/state.yaml" ]]; then
            content+="h2. Final State\n{code}\n"
            content+=$(cat "$context_dir/state.yaml")
            content+="\n{code}\n"
        fi
    fi
    
    if [[ -z "$content" ]]; then
        content="Documentation for $task_id\n\n(Add details here)"
    fi
    
    progress_info "Creating Confluence page: $title"
    if [[ "${AGENT_MOCK:-0}" == "1" ]]; then
        echo "[MOCK] Would create Confluence page: $title"
    else
        unified_doc_create "$title" "$content" "" 2>/dev/null || \
            echo "[WARN] Could not create Confluence page"
    fi
    
    progress_skill "sync/document" "OK"
    echo "[OK] Documentation created"
}

# ============================================================
# Status Sync
# ============================================================

# Sync status across platforms
# Usage: sync_status TASK-123 "Done"
sync_status() {
    local task_id="$1"
    local status="$2"
    
    if [[ -z "$task_id" ]] || [[ -z "$status" ]]; then
        echo "[ERROR] Usage: sync_status TASK-123 status" >&2
        return 1
    fi
    
    echo "=== Syncing status: $status ==="
    
    # JIRA
    if jira_configured 2>/dev/null; then
        progress_info "Updating JIRA: $status"
        if [[ "${AGENT_MOCK:-0}" == "1" ]]; then
            echo "[MOCK] Would update JIRA $task_id to $status"
        else
            jira_issue_transition "$task_id" "$status" 2>/dev/null || \
                echo "[WARN] Could not update JIRA status"
        fi
    fi
    
    # GitLab MR labels (if MR exists)
    local review_provider
    review_provider=$(get_review_provider 2>/dev/null)
    if [[ "$review_provider" == "gitlab" ]]; then
        progress_info "Updating GitLab MR label"
        if [[ "${AGENT_MOCK:-0}" == "1" ]]; then
            echo "[MOCK] Would update GitLab MR label to $status"
        else
            # Find MR by branch
            local branch
            branch=$(git branch --show-current 2>/dev/null)
            # Note: gitlab_mr_add_label would need to be implemented in gitlab.sh
            echo "[INFO] GitLab label sync not yet implemented"
        fi
    fi
    
    progress_info "Status synced: $status"
}

# ============================================================
# Quick Actions
# ============================================================

# Show current sync status
sync_show() {
    local task_id="${AGENT_TASK_ID:-}"
    
    if [[ -z "$task_id" ]]; then
        local branch
        branch=$(git branch --show-current 2>/dev/null)
        task_id=$(echo "$branch" | grep -oE '[A-Z]+-[0-9]+' | head -1)
    fi
    
    echo "=== Sync Status ==="
    echo ""
    echo "Task ID: ${task_id:-(unknown)}"
    echo "Branch:  $(git branch --show-current 2>/dev/null)"
    echo ""
    
    # Show providers
    echo "Providers:"
    echo "  Issue:  $(get_issue_provider 2>/dev/null || echo 'not configured')"
    echo "  Review: $(get_review_provider 2>/dev/null || echo 'not configured')"
    echo "  Docs:   $(get_document_provider 2>/dev/null || echo 'not configured')"
    echo ""
    
    # Show progress
    if [[ -n "$task_id" ]] && [[ -f ".context/$task_id/progress.txt" ]]; then
        echo "Recent Progress:"
        tail -5 ".context/$task_id/progress.txt" | sed 's/^/  /'
    fi
}
