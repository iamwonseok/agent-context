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

# ============================================================
# Milestone Functions
# ============================================================

# List milestones
gitlab_milestone_list() {
    local state="${1:-active}"
    local max_results="${2:-20}"

    if ! gitlab_configured; then
        echo "[ERROR] GitLab not configured" >&2
        return 1
    fi

    local project_encoded
    project_encoded=$(gitlab_encode_project)

    local response
    response=$(gitlab_api GET "/projects/${project_encoded}/milestones?state=${state}&per_page=${max_results}")

    if [[ "$(echo "$response" | jq 'length')" == "0" ]]; then
        echo "No milestones found."
        return 0
    fi

    echo "------------------------------------------------------------------------"
    printf "%-6s | %-10s | %-12s | %s\n" "ID" "State" "Due Date" "Title"
    echo "------------------------------------------------------------------------"

    echo "$response" | jq -r '.[] | [(.id | tostring), .state, (.due_date // "N/A"), .title] | @tsv' | \
    while IFS=$'\t' read -r id state due_date title; do
        if [[ ${#title} -gt 40 ]]; then
            title="${title:0:37}..."
        fi
        printf "%-6s | %-10s | %-12s | %s\n" "$id" "$state" "$due_date" "$title"
    done

    echo "------------------------------------------------------------------------"
    local total
    total=$(echo "$response" | jq 'length')
    echo "Total: $total milestones"
}

# View milestone detail
gitlab_milestone_view() {
    local id="$1"

    if [[ -z "$id" ]]; then
        echo "[ERROR] Milestone ID required" >&2
        return 1
    fi

    if ! gitlab_configured; then
        echo "[ERROR] GitLab not configured" >&2
        return 1
    fi

    local project_encoded
    project_encoded=$(gitlab_encode_project)

    local response
    response=$(gitlab_api GET "/projects/${project_encoded}/milestones/${id}")

    echo "============================================================"
    echo "Milestone: $(echo "$response" | jq -r '.title')"
    echo "============================================================"
    echo "ID:        $(echo "$response" | jq -r '.id')"
    echo "State:     $(echo "$response" | jq -r '.state')"
    echo "Due Date:  $(echo "$response" | jq -r '.due_date // "N/A"')"
    echo "Start:     $(echo "$response" | jq -r '.start_date // "N/A"')"
    echo "URL:       $(echo "$response" | jq -r '.web_url')"
    echo "------------------------------------------------------------"
    echo "Description:"
    echo "$response" | jq -r '.description // "(No description)"'
    echo "============================================================"
}

# Create milestone
gitlab_milestone_create() {
    local title="$1"
    local due_date="$2"
    local description="$3"

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
        --arg due_date "$due_date" \
        --arg desc "$description" \
        '{
            title: $title,
            due_date: (if $due_date != "" then $due_date else null end),
            description: (if $desc != "" then $desc else null end)
        }')

    local response
    response=$(gitlab_api POST "/projects/${project_encoded}/milestones" "$payload")

    local id
    id=$(echo "$response" | jq -r '.id')

    if [[ -z "$id" ]] || [[ "$id" == "null" ]]; then
        echo "[ERROR] Failed to create milestone:" >&2
        echo "$response" | jq -r '.message // .error // .' >&2
        return 1
    fi

    echo "$id"
}

# Close milestone
gitlab_milestone_close() {
    local id="$1"

    if [[ -z "$id" ]]; then
        echo "[ERROR] Milestone ID required" >&2
        return 1
    fi

    if ! gitlab_configured; then
        echo "[ERROR] GitLab not configured" >&2
        return 1
    fi

    local project_encoded
    project_encoded=$(gitlab_encode_project)

    local payload='{"state_event": "close"}'

    local response
    response=$(gitlab_api PUT "/projects/${project_encoded}/milestones/${id}" "$payload")

    local state
    state=$(echo "$response" | jq -r '.state')

    if [[ "$state" == "closed" ]]; then
        echo "(v) Milestone #$id closed"
    else
        echo "[ERROR] Failed to close milestone:" >&2
        echo "$response" | jq -r '.message // .error // .' >&2
        return 1
    fi
}

# ============================================================
# Label Functions
# ============================================================

# List labels
gitlab_label_list() {
    local max_results="${1:-50}"

    if ! gitlab_configured; then
        echo "[ERROR] GitLab not configured" >&2
        return 1
    fi

    local project_encoded
    project_encoded=$(gitlab_encode_project)

    local response
    response=$(gitlab_api GET "/projects/${project_encoded}/labels?per_page=${max_results}")

    if [[ "$(echo "$response" | jq 'length')" == "0" ]]; then
        echo "No labels found."
        return 0
    fi

    echo "------------------------------------------------------------------------"
    printf "%-6s | %-8s | %s\n" "ID" "Color" "Name"
    echo "------------------------------------------------------------------------"

    echo "$response" | jq -r '.[] | [(.id | tostring), .color, .name] | @tsv' | \
    while IFS=$'\t' read -r id color name; do
        printf "%-6s | %-8s | %s\n" "$id" "$color" "$name"
    done

    echo "------------------------------------------------------------------------"
    local total
    total=$(echo "$response" | jq 'length')
    echo "Total: $total labels"
}

# Create label
gitlab_label_create() {
    local name="$1"
    local color="${2:-#428BCA}"
    local description="$3"

    if [[ -z "$name" ]]; then
        echo "[ERROR] Name required" >&2
        return 1
    fi

    if ! gitlab_configured; then
        echo "[ERROR] GitLab not configured" >&2
        return 1
    fi

    local project_encoded
    project_encoded=$(gitlab_encode_project)

    # Ensure color starts with #
    if [[ "$color" != \#* ]]; then
        color="#$color"
    fi

    local payload
    payload=$(jq -n \
        --arg name "$name" \
        --arg color "$color" \
        --arg desc "$description" \
        '{
            name: $name,
            color: $color,
            description: (if $desc != "" then $desc else null end)
        }')

    local response
    response=$(gitlab_api POST "/projects/${project_encoded}/labels" "$payload")

    local id
    id=$(echo "$response" | jq -r '.id')

    if [[ -z "$id" ]] || [[ "$id" == "null" ]]; then
        echo "[ERROR] Failed to create label:" >&2
        echo "$response" | jq -r '.message // .error // .' >&2
        return 1
    fi

    echo "$id"
}

# Delete label
gitlab_label_delete() {
    local name="$1"

    if [[ -z "$name" ]]; then
        echo "[ERROR] Label name required" >&2
        return 1
    fi

    if ! gitlab_configured; then
        echo "[ERROR] GitLab not configured" >&2
        return 1
    fi

    local project_encoded
    project_encoded=$(gitlab_encode_project)

    # URL encode the label name (using printf to avoid newline issues)
    local name_encoded
    name_encoded=$(printf '%s' "$name" | jq -sRr @uri)

    local response
    response=$(gitlab_api DELETE "/projects/${project_encoded}/labels/${name_encoded}")

    # DELETE returns 204 with no content on success
    if [[ -z "$response" ]]; then
        echo "(v) Label '$name' deleted"
    else
        local error
        error=$(echo "$response" | jq -r '.message // .error // .' 2>/dev/null)
        if [[ -n "$error" ]] && [[ "$error" != "null" ]]; then
            echo "[ERROR] Failed to delete label: $error" >&2
            return 1
        fi
        echo "(v) Label '$name' deleted"
    fi
}

# ============================================================
# Wiki Functions
# ============================================================

# List wiki pages
gitlab_wiki_list() {
    local max_results="${1:-20}"

    if ! gitlab_configured; then
        echo "[ERROR] GitLab not configured" >&2
        return 1
    fi

    local project_encoded
    project_encoded=$(gitlab_encode_project)

    local response
    response=$(gitlab_api GET "/projects/${project_encoded}/wikis?per_page=${max_results}")

    if [[ "$(echo "$response" | jq 'length')" == "0" ]]; then
        echo "No wiki pages found."
        return 0
    fi

    echo "------------------------------------------------------------------------"
    printf "%-30s | %s\n" "Slug" "Title"
    echo "------------------------------------------------------------------------"

    echo "$response" | jq -r '.[] | [.slug, .title] | @tsv' | \
    while IFS=$'\t' read -r slug title; do
        if [[ ${#slug} -gt 28 ]]; then
            slug="${slug:0:25}..."
        fi
        printf "%-30s | %s\n" "$slug" "$title"
    done

    echo "------------------------------------------------------------------------"
    local total
    total=$(echo "$response" | jq 'length')
    echo "Total: $total wiki pages"
}

# View wiki page
gitlab_wiki_view() {
    local slug="$1"

    if [[ -z "$slug" ]]; then
        echo "[ERROR] Wiki slug required" >&2
        return 1
    fi

    if ! gitlab_configured; then
        echo "[ERROR] GitLab not configured" >&2
        return 1
    fi

    local project_encoded
    project_encoded=$(gitlab_encode_project)

    # URL encode the slug
    local slug_encoded
    slug_encoded=$(printf '%s' "$slug" | jq -sRr @uri)

    local response
    response=$(gitlab_api GET "/projects/${project_encoded}/wikis/${slug_encoded}")

    local title
    title=$(echo "$response" | jq -r '.title')

    if [[ -z "$title" ]] || [[ "$title" == "null" ]]; then
        echo "[ERROR] Wiki page not found: $slug" >&2
        return 1
    fi

    echo "============================================================"
    echo "Wiki: $title"
    echo "============================================================"
    echo "Slug:   $(echo "$response" | jq -r '.slug')"
    echo "Format: $(echo "$response" | jq -r '.format')"
    echo "------------------------------------------------------------"
    echo "Content:"
    echo ""
    echo "$response" | jq -r '.content'
    echo "============================================================"
}

# Create wiki page
gitlab_wiki_create() {
    local title="$1"
    local content="$2"
    local format="${3:-markdown}"

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

    # Default content if not provided
    if [[ -z "$content" ]]; then
        content="# $title\n\nThis page was created automatically."
    fi

    local payload
    payload=$(jq -n \
        --arg title "$title" \
        --arg content "$content" \
        --arg format "$format" \
        '{
            title: $title,
            content: $content,
            format: $format
        }')

    local response
    response=$(gitlab_api POST "/projects/${project_encoded}/wikis" "$payload")

    local slug
    slug=$(echo "$response" | jq -r '.slug')

    if [[ -z "$slug" ]] || [[ "$slug" == "null" ]]; then
        echo "[ERROR] Failed to create wiki page:" >&2
        echo "$response" | jq -r '.message // .error // .' >&2
        return 1
    fi

    echo "$slug"
}

# Update wiki page
gitlab_wiki_update() {
    local slug="$1"
    local content="$2"
    local title="$3"

    if [[ -z "$slug" ]]; then
        echo "[ERROR] Wiki slug required" >&2
        return 1
    fi

    if ! gitlab_configured; then
        echo "[ERROR] GitLab not configured" >&2
        return 1
    fi

    local project_encoded
    project_encoded=$(gitlab_encode_project)

    # URL encode the slug
    local slug_encoded
    slug_encoded=$(printf '%s' "$slug" | jq -sRr @uri)

    local payload
    if [[ -n "$title" ]]; then
        payload=$(jq -n \
            --arg content "$content" \
            --arg title "$title" \
            '{
                content: $content,
                title: $title
            }')
    else
        payload=$(jq -n \
            --arg content "$content" \
            '{
                content: $content
            }')
    fi

    local response
    response=$(gitlab_api PUT "/projects/${project_encoded}/wikis/${slug_encoded}" "$payload")

    local new_slug
    new_slug=$(echo "$response" | jq -r '.slug')

    if [[ -z "$new_slug" ]] || [[ "$new_slug" == "null" ]]; then
        echo "[ERROR] Failed to update wiki page:" >&2
        echo "$response" | jq -r '.message // .error // .' >&2
        return 1
    fi

    echo "(v) Wiki page '$slug' updated"
}

# Delete wiki page
gitlab_wiki_delete() {
    local slug="$1"

    if [[ -z "$slug" ]]; then
        echo "[ERROR] Wiki slug required" >&2
        return 1
    fi

    if ! gitlab_configured; then
        echo "[ERROR] GitLab not configured" >&2
        return 1
    fi

    local project_encoded
    project_encoded=$(gitlab_encode_project)

    # URL encode the slug
    local slug_encoded
    slug_encoded=$(printf '%s' "$slug" | jq -sRr @uri)

    local response
    response=$(gitlab_api DELETE "/projects/${project_encoded}/wikis/${slug_encoded}")

    # DELETE returns 204 with no content on success
    if [[ -z "$response" ]]; then
        echo "(v) Wiki page '$slug' deleted"
    else
        local error
        error=$(echo "$response" | jq -r '.message // .error // .' 2>/dev/null)
        if [[ -n "$error" ]] && [[ "$error" != "null" ]]; then
            echo "[ERROR] Failed to delete wiki page: $error" >&2
            return 1
        fi
        echo "(v) Wiki page '$slug' deleted"
    fi
}
