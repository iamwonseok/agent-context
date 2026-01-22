#!/bin/bash
# GitLab API functions

set -e

# URL encode project path
gitlab_encode_project() {
    echo "$GITLAB_PROJECT" | sed 's/\//%2F/g'
}

# GitLab API request
gitlab_api() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    
    local url="${GITLAB_BASE_URL}/api/v4${endpoint}"
    
    local curl_args=(
        -s
        -X "$method"
        -H "PRIVATE-TOKEN: $GITLAB_TOKEN"
        -H "Content-Type: application/json"
        -H "Accept: application/json"
    )
    
    if [[ -n "$data" ]]; then
        curl_args+=(-d "$data")
    fi
    
    curl "${curl_args[@]}" "$url"
}

# Get current user
gitlab_me() {
    if ! gitlab_configured; then
        echo "[ERROR] GitLab not configured" >&2
        return 1
    fi
    
    local response
    response=$(gitlab_api GET "/user")
    
    echo "=========================================="
    echo "Current GitLab User"
    echo "=========================================="
    echo "Name:     $(echo "$response" | jq -r '.name')"
    echo "Username: $(echo "$response" | jq -r '.username')"
    echo "Email:    $(echo "$response" | jq -r '.email // "N/A"')"
    echo "ID:       $(echo "$response" | jq -r '.id')"
    echo "=========================================="
}

# List merge requests
gitlab_mr_list() {
    local state="${1:-opened}"
    local max_results="${2:-20}"
    
    if ! gitlab_configured; then
        echo "[ERROR] GitLab not configured" >&2
        return 1
    fi
    
    local project_encoded
    project_encoded=$(gitlab_encode_project)
    
    local response
    response=$(gitlab_api GET "/projects/${project_encoded}/merge_requests?state=${state}&per_page=${max_results}")
    
    if [[ "$(echo "$response" | jq 'length')" == "0" ]]; then
        echo "No merge requests found."
        return 0
    fi
    
    echo "------------------------------------------------------------------------"
    printf "%-6s | %-8s | %-12s | %s\n" "IID" "State" "Author" "Title"
    echo "------------------------------------------------------------------------"
    
    echo "$response" | jq -r '.[] | ["!" + (.iid | tostring), .state, .author.name, .title] | @tsv' | \
    while IFS=$'\t' read -r iid state author title; do
        # Truncate title if too long
        if [[ ${#title} -gt 45 ]]; then
            title="${title:0:42}..."
        fi
        printf "%-6s | %-8s | %-12s | %s\n" "$iid" "$state" "$author" "$title"
    done
    
    echo "------------------------------------------------------------------------"
    local total
    total=$(echo "$response" | jq 'length')
    echo "Total: $total merge requests"
}

# View MR detail
gitlab_mr_view() {
    local iid="$1"
    
    if [[ -z "$iid" ]]; then
        echo "[ERROR] MR IID required" >&2
        return 1
    fi
    
    if ! gitlab_configured; then
        echo "[ERROR] GitLab not configured" >&2
        return 1
    fi
    
    local project_encoded
    project_encoded=$(gitlab_encode_project)
    
    local response
    response=$(gitlab_api GET "/projects/${project_encoded}/merge_requests/${iid}")
    
    local draft_status=""
    if [[ "$(echo "$response" | jq -r '.draft')" == "true" ]]; then
        draft_status=" [DRAFT]"
    fi
    
    echo "============================================================"
    echo "Merge Request: !$(echo "$response" | jq -r '.iid')${draft_status}"
    echo "============================================================"
    echo "Title:  $(echo "$response" | jq -r '.title')"
    echo "State:  $(echo "$response" | jq -r '.state')"
    echo "Author: $(echo "$response" | jq -r '.author.name')"
    echo "Source: $(echo "$response" | jq -r '.source_branch')"
    echo "Target: $(echo "$response" | jq -r '.target_branch')"
    echo "URL:    $(echo "$response" | jq -r '.web_url')"
    echo "------------------------------------------------------------"
    echo "Description:"
    echo "$response" | jq -r '.description // "(No description)"'
    echo "============================================================"
}

# Create MR
gitlab_mr_create() {
    local source_branch="$1"
    local target_branch="${2:-main}"
    local title="$3"
    local description="$4"
    local draft="${5:-false}"
    
    if [[ -z "$source_branch" ]] || [[ -z "$title" ]]; then
        echo "[ERROR] Source branch and title required" >&2
        return 1
    fi
    
    if ! gitlab_configured; then
        echo "[ERROR] GitLab not configured" >&2
        return 1
    fi
    
    local project_encoded
    project_encoded=$(gitlab_encode_project)
    
    # Add Draft: prefix if draft
    if [[ "$draft" == "true" ]]; then
        title="Draft: $title"
    fi
    
    local payload
    payload=$(jq -n \
        --arg source "$source_branch" \
        --arg target "$target_branch" \
        --arg title "$title" \
        --arg desc "$description" \
        '{
            source_branch: $source,
            target_branch: $target,
            title: $title,
            description: (if $desc != "" then $desc else null end),
            remove_source_branch: true
        }')
    
    local response
    response=$(gitlab_api POST "/projects/${project_encoded}/merge_requests" "$payload")
    
    local iid
    iid=$(echo "$response" | jq -r '.iid')
    
    if [[ -z "$iid" ]] || [[ "$iid" == "null" ]]; then
        echo "[ERROR] Failed to create MR:" >&2
        echo "$response" | jq -r '.message // .error // .' >&2
        return 1
    fi
    
    echo "(v) Created: !$iid"
    echo "    URL: $(echo "$response" | jq -r '.web_url')"
}

# List issues
gitlab_issue_list() {
    local state="${1:-opened}"
    local max_results="${2:-20}"
    
    if ! gitlab_configured; then
        echo "[ERROR] GitLab not configured" >&2
        return 1
    fi
    
    local project_encoded
    project_encoded=$(gitlab_encode_project)
    
    local response
    response=$(gitlab_api GET "/projects/${project_encoded}/issues?state=${state}&per_page=${max_results}")
    
    if [[ "$(echo "$response" | jq 'length')" == "0" ]]; then
        echo "No issues found."
        return 0
    fi
    
    echo "------------------------------------------------------------------------"
    printf "%-6s | %-8s | %-12s | %s\n" "IID" "State" "Author" "Title"
    echo "------------------------------------------------------------------------"
    
    echo "$response" | jq -r '.[] | ["#" + (.iid | tostring), .state, .author.name, .title] | @tsv' | \
    while IFS=$'\t' read -r iid state author title; do
        if [[ ${#title} -gt 45 ]]; then
            title="${title:0:42}..."
        fi
        printf "%-6s | %-8s | %-12s | %s\n" "$iid" "$state" "$author" "$title"
    done
    
    echo "------------------------------------------------------------------------"
    local total
    total=$(echo "$response" | jq 'length')
    echo "Total: $total issues"
}

# Create GitLab issue
gitlab_issue_create() {
    local title="$1"
    local description="$2"
    
    if [[ -z "$title" ]]; then
        echo "[ERROR] Title required" >&2
        return 1
    fi
    
    if ! gitlab_configured; then
        echo "[ERROR] GitLab not configured" >&2
        return 1
    fi
    
    local project_encoded
    project_encoded=$(gitlab_encode_project)
    
    local payload
    payload=$(jq -n \
        --arg title "$title" \
        --arg desc "$description" \
        '{
            title: $title,
            description: (if $desc != "" then $desc else null end)
        }')
    
    local response
    response=$(gitlab_api POST "/projects/${project_encoded}/issues" "$payload")
    
    local iid
    iid=$(echo "$response" | jq -r '.iid')
    
    if [[ -z "$iid" ]] || [[ "$iid" == "null" ]]; then
        echo "[ERROR] Failed to create issue:" >&2
        echo "$response" | jq -r '.message // .error // .' >&2
        return 1
    fi
    
    echo "$iid"
}
