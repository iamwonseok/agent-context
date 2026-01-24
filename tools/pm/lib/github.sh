#!/bin/bash
# GitHub API functions

set -e

# GitHub API request
github_api() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    
    local url="${GITHUB_BASE_URL:-https://api.github.com}${endpoint}"
    
    local curl_args=(
        -s
        -X "$method"
        -H "Authorization: Bearer $GITHUB_TOKEN"
        -H "Accept: application/vnd.github+json"
        -H "X-GitHub-Api-Version: 2022-11-28"
    )
    
    if [[ -n "$data" ]]; then
        curl_args+=(-H "Content-Type: application/json" -d "$data")
    fi
    
    curl "${curl_args[@]}" "$url"
}

# Get current user
github_me() {
    if ! github_configured; then
        echo "[ERROR] GitHub not configured" >&2
        return 1
    fi
    
    local response
    response=$(github_api GET "/user")
    
    echo "=========================================="
    echo "Current GitHub User"
    echo "=========================================="
    echo "Name:     $(echo "$response" | jq -r '.name // .login')"
    echo "Username: $(echo "$response" | jq -r '.login')"
    echo "Email:    $(echo "$response" | jq -r '.email // "N/A"')"
    echo "ID:       $(echo "$response" | jq -r '.id')"
    echo "=========================================="
}

# List pull requests
github_pr_list() {
    local state="${1:-open}"
    local max_results="${2:-20}"
    
    if ! github_configured; then
        echo "[ERROR] GitHub not configured" >&2
        return 1
    fi
    
    local response
    response=$(github_api GET "/repos/${GITHUB_REPO}/pulls?state=${state}&per_page=${max_results}")
    
    if [[ "$(echo "$response" | jq 'length')" == "0" ]]; then
        echo "No pull requests found."
        return 0
    fi
    
    echo "------------------------------------------------------------------------"
    printf "%-6s | %-8s | %-12s | %s\n" "#" "State" "Author" "Title"
    echo "------------------------------------------------------------------------"
    
    echo "$response" | jq -r '.[] | ["#" + (.number | tostring), .state, .user.login, .title] | @tsv' | \
    while IFS=$'\t' read -r num state author title; do
        # Truncate title if too long
        if [[ ${#title} -gt 45 ]]; then
            title="${title:0:42}..."
        fi
        printf "%-6s | %-8s | %-12s | %s\n" "$num" "$state" "$author" "$title"
    done
    
    echo "------------------------------------------------------------------------"
    local total
    total=$(echo "$response" | jq 'length')
    echo "Total: $total pull requests"
}

# View PR detail
github_pr_view() {
    local number="$1"
    
    if [[ -z "$number" ]]; then
        echo "[ERROR] PR number required" >&2
        return 1
    fi
    
    if ! github_configured; then
        echo "[ERROR] GitHub not configured" >&2
        return 1
    fi
    
    local response
    response=$(github_api GET "/repos/${GITHUB_REPO}/pulls/${number}")
    
    local draft_status=""
    if [[ "$(echo "$response" | jq -r '.draft')" == "true" ]]; then
        draft_status=" [DRAFT]"
    fi
    
    echo "============================================================"
    echo "Pull Request: #$(echo "$response" | jq -r '.number')${draft_status}"
    echo "============================================================"
    echo "Title:  $(echo "$response" | jq -r '.title')"
    echo "State:  $(echo "$response" | jq -r '.state')"
    echo "Author: $(echo "$response" | jq -r '.user.login')"
    echo "Head:   $(echo "$response" | jq -r '.head.ref')"
    echo "Base:   $(echo "$response" | jq -r '.base.ref')"
    echo "URL:    $(echo "$response" | jq -r '.html_url')"
    echo "------------------------------------------------------------"
    echo "Description:"
    echo "$response" | jq -r '.body // "(No description)"'
    echo "============================================================"
}

# Create PR
github_pr_create() {
    local head_branch="$1"
    local base_branch="${2:-main}"
    local title="$3"
    local body="$4"
    local draft="${5:-false}"
    
    if [[ -z "$head_branch" ]] || [[ -z "$title" ]]; then
        echo "[ERROR] Head branch and title required" >&2
        return 1
    fi
    
    if ! github_configured; then
        echo "[ERROR] GitHub not configured" >&2
        return 1
    fi
    
    local payload
    payload=$(jq -n \
        --arg head "$head_branch" \
        --arg base "$base_branch" \
        --arg title "$title" \
        --arg body "$body" \
        --argjson draft "$draft" \
        '{
            head: $head,
            base: $base,
            title: $title,
            body: (if $body != "" then $body else null end),
            draft: $draft
        }')
    
    local response
    response=$(github_api POST "/repos/${GITHUB_REPO}/pulls" "$payload")
    
    local number
    number=$(echo "$response" | jq -r '.number')
    
    if [[ -z "$number" ]] || [[ "$number" == "null" ]]; then
        echo "[ERROR] Failed to create PR:" >&2
        echo "$response" | jq -r '.message // .errors // .' >&2
        return 1
    fi
    
    echo "(v) Created: #$number"
    echo "    URL: $(echo "$response" | jq -r '.html_url')"
}

# List issues
github_issue_list() {
    local state="${1:-open}"
    local max_results="${2:-20}"
    
    if ! github_configured; then
        echo "[ERROR] GitHub not configured" >&2
        return 1
    fi
    
    local response
    response=$(github_api GET "/repos/${GITHUB_REPO}/issues?state=${state}&per_page=${max_results}")
    
    # Filter out pull requests (GitHub API returns PRs in issues endpoint)
    response=$(echo "$response" | jq '[.[] | select(.pull_request == null)]')
    
    if [[ "$(echo "$response" | jq 'length')" == "0" ]]; then
        echo "No issues found."
        return 0
    fi
    
    echo "------------------------------------------------------------------------"
    printf "%-6s | %-8s | %-12s | %s\n" "#" "State" "Author" "Title"
    echo "------------------------------------------------------------------------"
    
    echo "$response" | jq -r '.[] | ["#" + (.number | tostring), .state, .user.login, .title] | @tsv' | \
    while IFS=$'\t' read -r num state author title; do
        if [[ ${#title} -gt 45 ]]; then
            title="${title:0:42}..."
        fi
        printf "%-6s | %-8s | %-12s | %s\n" "$num" "$state" "$author" "$title"
    done
    
    echo "------------------------------------------------------------------------"
    local total
    total=$(echo "$response" | jq 'length')
    echo "Total: $total issues"
}

# Create GitHub issue
github_issue_create() {
    local title="$1"
    local body="$2"
    
    if [[ -z "$title" ]]; then
        echo "[ERROR] Title required" >&2
        return 1
    fi
    
    if ! github_configured; then
        echo "[ERROR] GitHub not configured" >&2
        return 1
    fi
    
    local payload
    payload=$(jq -n \
        --arg title "$title" \
        --arg body "$body" \
        '{
            title: $title,
            body: (if $body != "" then $body else null end)
        }')
    
    local response
    response=$(github_api POST "/repos/${GITHUB_REPO}/issues" "$payload")
    
    local number
    number=$(echo "$response" | jq -r '.number')
    
    if [[ -z "$number" ]] || [[ "$number" == "null" ]]; then
        echo "[ERROR] Failed to create issue:" >&2
        echo "$response" | jq -r '.message // .errors // .' >&2
        return 1
    fi
    
    echo "$number"
}
