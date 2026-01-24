#!/bin/bash
# Confluence API functions
# Supports both Confluence Cloud (*.atlassian.net) and Confluence Server/Data Center

set -e

# Cache for resolved Confluence URL
_CONFLUENCE_RESOLVED_URL=""

# Resolve actual Confluence URL
resolve_confluence_url() {
    if [[ -n "$_CONFLUENCE_RESOLVED_URL" ]]; then
        echo "$_CONFLUENCE_RESOLVED_URL"
        return
    fi

    # For Cloud, base URL should include /wiki
    if [[ "$CONFLUENCE_BASE_URL" == *".atlassian.net"* ]] && [[ "$CONFLUENCE_BASE_URL" != *"/wiki"* ]]; then
        _CONFLUENCE_RESOLVED_URL="${CONFLUENCE_BASE_URL}/wiki"
    else
        _CONFLUENCE_RESOLVED_URL="$CONFLUENCE_BASE_URL"
    fi

    echo "$_CONFLUENCE_RESOLVED_URL"
}

# Detect if Confluence Cloud or Server
is_confluence_cloud() {
    [[ "$CONFLUENCE_BASE_URL" == *".atlassian.net"* ]]
}

# Confluence API request
confluence_api() {
    local method="$1"
    local endpoint="$2"
    local data="$3"

    local base_url
    base_url=$(resolve_confluence_url)
    local url="${base_url}/rest/api${endpoint}"

    local curl_args=(
        -s
        -X "$method"
        -H "Content-Type: application/json"
        -H "Accept: application/json"
    )

    # Authentication: Cloud uses Basic Auth, Server uses Bearer token
    if is_confluence_cloud; then
        local auth=$(echo -n "${CONFLUENCE_EMAIL}:${CONFLUENCE_TOKEN}" | base64)
        curl_args+=(-H "Authorization: Basic $auth")
    else
        # Confluence Server/Data Center uses Bearer token (Personal Access Token)
        curl_args+=(-H "Authorization: Bearer $CONFLUENCE_TOKEN")
    fi

    if [[ -n "$data" ]]; then
        curl_args+=(-d "$data")
    fi

    curl "${curl_args[@]}" "$url"
}

# Get current user
confluence_me() {
    if ! confluence_configured; then
        echo "[ERROR] Confluence not configured" >&2
        return 1
    fi

    local response
    response=$(confluence_api GET "/user/current")

    echo "=========================================="
    echo "Current Confluence User"
    echo "=========================================="
    echo "Name:     $(echo "$response" | jq -r '.displayName // .username')"
    echo "Username: $(echo "$response" | jq -r '.username // .accountId')"
    echo "Email:    $(echo "$response" | jq -r '.email // "N/A"')"
    echo "=========================================="
}

# List spaces
confluence_space_list() {
    local limit="${1:-25}"

    if ! confluence_configured; then
        echo "[ERROR] Confluence not configured" >&2
        return 1
    fi

    local response
    response=$(confluence_api GET "/space?limit=${limit}")

    echo "------------------------------------------------------------------------"
    printf "%-12s | %-8s | %s\n" "Key" "Type" "Name"
    echo "------------------------------------------------------------------------"

    echo "$response" | jq -r '.results[] | [.key, .type, .name] | @tsv' | \
    while IFS=$'\t' read -r key type name; do
        # Truncate name if too long
        if [[ ${#name} -gt 50 ]]; then
            name="${name:0:47}..."
        fi
        printf "%-12s | %-8s | %s\n" "$key" "$type" "$name"
    done

    echo "------------------------------------------------------------------------"
    local total
    total=$(echo "$response" | jq -r '.size // (.results | length)')
    echo "Total: $total spaces"
}

# List pages in a space
confluence_page_list() {
    local space_key="${1:-$CONFLUENCE_SPACE_KEY}"
    local limit="${2:-25}"

    if [[ -z "$space_key" ]]; then
        echo "[ERROR] Space key required (use --space or set CONFLUENCE_SPACE_KEY)" >&2
        return 1
    fi

    if ! confluence_configured; then
        echo "[ERROR] Confluence not configured" >&2
        return 1
    fi

    local response
    response=$(confluence_api GET "/content?spaceKey=${space_key}&type=page&limit=${limit}&expand=version")

    local results
    results=$(echo "$response" | jq -r '.results[]' 2>/dev/null)

    if [[ -z "$results" ]]; then
        echo "No pages found in space: $space_key"
        return 0
    fi

    echo "------------------------------------------------------------------------"
    printf "%-12s | %-6s | %s\n" "ID" "Ver" "Title"
    echo "------------------------------------------------------------------------"

    echo "$response" | jq -r '.results[] | [.id, .version.number, .title] | @tsv' | \
    while IFS=$'\t' read -r id version title; do
        # Truncate title if too long
        if [[ ${#title} -gt 55 ]]; then
            title="${title:0:52}..."
        fi
        printf "%-12s | %-6s | %s\n" "$id" "$version" "$title"
    done

    echo "------------------------------------------------------------------------"
    local total
    total=$(echo "$response" | jq -r '.size // (.results | length)')
    echo "Total: $total pages in space $space_key"
}

# View page detail
confluence_page_view() {
    local page_id="$1"
    local expand="${2:-body.storage,version,space}"

    if [[ -z "$page_id" ]]; then
        echo "[ERROR] Page ID required" >&2
        return 1
    fi

    if ! confluence_configured; then
        echo "[ERROR] Confluence not configured" >&2
        return 1
    fi

    local response
    response=$(confluence_api GET "/content/${page_id}?expand=${expand}")

    local error_msg
    error_msg=$(echo "$response" | jq -r '.message // empty' 2>/dev/null)
    if [[ -n "$error_msg" ]]; then
        echo "[ERROR] $error_msg" >&2
        return 1
    fi

    echo "============================================================"
    echo "Page: $(echo "$response" | jq -r '.title')"
    echo "============================================================"
    echo "ID:      $(echo "$response" | jq -r '.id')"
    echo "Space:   $(echo "$response" | jq -r '.space.key // "N/A"') ($(echo "$response" | jq -r '.space.name // "N/A"'))"
    echo "Version: $(echo "$response" | jq -r '.version.number')"
    echo "Author:  $(echo "$response" | jq -r '.version.by.displayName // "N/A"')"
    echo "Updated: $(echo "$response" | jq -r '.version.when // "N/A"')"
    echo "------------------------------------------------------------"

    local base_url
    base_url=$(resolve_confluence_url)
    local self_link
    self_link=$(echo "$response" | jq -r '._links.webui // empty')
    if [[ -n "$self_link" ]]; then
        echo "URL:     ${base_url}${self_link}"
    fi

    echo "------------------------------------------------------------"
    echo "Content (HTML):"
    echo "$response" | jq -r '.body.storage.value // "(No content)"' | head -50
    if [[ $(echo "$response" | jq -r '.body.storage.value // "" | length') -gt 2000 ]]; then
        echo "... (content truncated)"
    fi
    echo "============================================================"
}

# View page as plain text (strip HTML)
confluence_page_text() {
    local page_id="$1"

    if [[ -z "$page_id" ]]; then
        echo "[ERROR] Page ID required" >&2
        return 1
    fi

    if ! confluence_configured; then
        echo "[ERROR] Confluence not configured" >&2
        return 1
    fi

    local response
    response=$(confluence_api GET "/content/${page_id}?expand=body.storage")

    local title
    title=$(echo "$response" | jq -r '.title')
    
    echo "# $title"
    echo ""
    
    # Strip HTML tags (basic)
    echo "$response" | jq -r '.body.storage.value // "(No content)"' | \
        sed 's/<br[^>]*>/\n/g' | \
        sed 's/<\/p>/\n\n/g' | \
        sed 's/<\/h[1-6]>/\n\n/g' | \
        sed 's/<\/li>/\n/g' | \
        sed 's/<li[^>]*>/- /g' | \
        sed 's/<[^>]*>//g' | \
        sed 's/&nbsp;/ /g' | \
        sed 's/&amp;/\&/g' | \
        sed 's/&lt;/</g' | \
        sed 's/&gt;/>/g' | \
        sed 's/&quot;/"/g'
}

# Create page
confluence_page_create() {
    local space_key="$1"
    local title="$2"
    local content="$3"
    local parent_id="$4"

    if [[ -z "$space_key" ]]; then
        space_key="$CONFLUENCE_SPACE_KEY"
    fi

    if [[ -z "$space_key" ]] || [[ -z "$title" ]]; then
        echo "[ERROR] Space key and title required" >&2
        return 1
    fi

    if ! confluence_configured; then
        echo "[ERROR] Confluence not configured" >&2
        return 1
    fi

    # Escape content for JSON
    local escaped_content
    escaped_content=$(echo "$content" | jq -sR .)

    local payload
    if [[ -n "$parent_id" ]]; then
        payload=$(jq -n \
            --arg space "$space_key" \
            --arg title "$title" \
            --argjson content "$escaped_content" \
            --arg parent "$parent_id" \
            '{
                type: "page",
                title: $title,
                space: { key: $space },
                ancestors: [{ id: $parent }],
                body: {
                    storage: {
                        value: $content,
                        representation: "storage"
                    }
                }
            }')
    else
        payload=$(jq -n \
            --arg space "$space_key" \
            --arg title "$title" \
            --argjson content "$escaped_content" \
            '{
                type: "page",
                title: $title,
                space: { key: $space },
                body: {
                    storage: {
                        value: $content,
                        representation: "storage"
                    }
                }
            }')
    fi

    local response
    response=$(confluence_api POST "/content" "$payload")

    local page_id
    page_id=$(echo "$response" | jq -r '.id')

    if [[ -z "$page_id" ]] || [[ "$page_id" == "null" ]]; then
        echo "[ERROR] Failed to create page:" >&2
        echo "$response" | jq -r '.message // .' >&2
        return 1
    fi

    echo "(v) Created page: $title (ID: $page_id)"

    local base_url
    base_url=$(resolve_confluence_url)
    local web_link
    web_link=$(echo "$response" | jq -r '._links.webui // empty')
    if [[ -n "$web_link" ]]; then
        echo "URL: ${base_url}${web_link}"
    fi
}

# Update page
confluence_page_update() {
    local page_id="$1"
    local title="$2"
    local content="$3"

    if [[ -z "$page_id" ]]; then
        echo "[ERROR] Page ID required" >&2
        return 1
    fi

    if ! confluence_configured; then
        echo "[ERROR] Confluence not configured" >&2
        return 1
    fi

    # Get current version
    local current
    current=$(confluence_api GET "/content/${page_id}?expand=version")

    local current_version
    current_version=$(echo "$current" | jq -r '.version.number')
    local current_title
    current_title=$(echo "$current" | jq -r '.title')

    if [[ -z "$current_version" ]] || [[ "$current_version" == "null" ]]; then
        echo "[ERROR] Cannot get current page version" >&2
        return 1
    fi

    # Use current title if not provided
    if [[ -z "$title" ]]; then
        title="$current_title"
    fi

    local new_version=$((current_version + 1))

    # Escape content for JSON
    local escaped_content
    escaped_content=$(echo "$content" | jq -sR .)

    local payload
    payload=$(jq -n \
        --arg title "$title" \
        --argjson content "$escaped_content" \
        --argjson version "$new_version" \
        '{
            type: "page",
            title: $title,
            version: { number: $version },
            body: {
                storage: {
                    value: $content,
                    representation: "storage"
                }
            }
        }')

    local response
    response=$(confluence_api PUT "/content/${page_id}" "$payload")

    local updated_id
    updated_id=$(echo "$response" | jq -r '.id')

    if [[ -z "$updated_id" ]] || [[ "$updated_id" == "null" ]]; then
        echo "[ERROR] Failed to update page:" >&2
        echo "$response" | jq -r '.message // .' >&2
        return 1
    fi

    echo "(v) Updated page: $title (ID: $page_id, version: $new_version)"
}

# Search pages
confluence_search() {
    local cql="$1"
    local limit="${2:-25}"

    if [[ -z "$cql" ]]; then
        echo "[ERROR] CQL query required" >&2
        return 1
    fi

    if ! confluence_configured; then
        echo "[ERROR] Confluence not configured" >&2
        return 1
    fi

    local encoded_cql
    encoded_cql=$(echo "$cql" | jq -sRr @uri)

    local response
    response=$(confluence_api GET "/content/search?cql=${encoded_cql}&limit=${limit}")

    local results
    results=$(echo "$response" | jq -r '.results[]' 2>/dev/null)

    if [[ -z "$results" ]]; then
        echo "No results found for: $cql"
        return 0
    fi

    echo "------------------------------------------------------------------------"
    printf "%-12s | %-12s | %s\n" "ID" "Space" "Title"
    echo "------------------------------------------------------------------------"

    echo "$response" | jq -r '.results[] | [.id, .space.key, .title] | @tsv' | \
    while IFS=$'\t' read -r id space title; do
        # Truncate title if too long
        if [[ ${#title} -gt 50 ]]; then
            title="${title:0:47}..."
        fi
        printf "%-12s | %-12s | %s\n" "$id" "$space" "$title"
    done

    echo "------------------------------------------------------------------------"
    local total
    total=$(echo "$response" | jq -r '.totalSize // .size // (.results | length)')
    echo "Total: $total results"
}

# Create space
confluence_space_create() {
    local key="$1"
    local name="$2"
    local description="$3"

    if [[ -z "$key" ]] || [[ -z "$name" ]]; then
        echo "[ERROR] Space key and name required" >&2
        return 1
    fi

    if ! confluence_configured; then
        echo "[ERROR] Confluence not configured" >&2
        return 1
    fi

    local payload
    payload=$(jq -n \
        --arg key "$key" \
        --arg name "$name" \
        --arg desc "${description:-}" \
        '{
            key: $key,
            name: $name,
            description: {
                plain: {
                    value: $desc,
                    representation: "plain"
                }
            }
        }')

    local response
    response=$(confluence_api POST "/space" "$payload")

    local space_key
    space_key=$(echo "$response" | jq -r '.key')

    if [[ -z "$space_key" ]] || [[ "$space_key" == "null" ]]; then
        echo "[ERROR] Failed to create space:" >&2
        echo "$response" | jq -r '.message // .' >&2
        return 1
    fi

    echo "(v) Created space: $name (Key: $space_key)"

    local base_url
    base_url=$(resolve_confluence_url)
    local web_link
    web_link=$(echo "$response" | jq -r '._links.webui // empty')
    if [[ -n "$web_link" ]]; then
        echo "URL: ${base_url}${web_link}"
    fi
}

# View space details
confluence_space_view() {
    local key="$1"

    if [[ -z "$key" ]]; then
        echo "[ERROR] Space key required" >&2
        return 1
    fi

    if ! confluence_configured; then
        echo "[ERROR] Confluence not configured" >&2
        return 1
    fi

    local response
    response=$(confluence_api GET "/space/${key}?expand=description.plain,homepage")

    local error_msg
    error_msg=$(echo "$response" | jq -r '.message // empty' 2>/dev/null)
    if [[ -n "$error_msg" ]]; then
        echo "[ERROR] $error_msg" >&2
        return 1
    fi

    echo "============================================================"
    echo "Space: $(echo "$response" | jq -r '.name')"
    echo "============================================================"
    echo "Key:         $(echo "$response" | jq -r '.key')"
    echo "Type:        $(echo "$response" | jq -r '.type')"
    echo "Status:      $(echo "$response" | jq -r '.status // "N/A"')"
    echo "Homepage ID: $(echo "$response" | jq -r '.homepage.id // "N/A"')"
    echo "------------------------------------------------------------"
    echo "Description:"
    echo "$response" | jq -r '.description.plain.value // "(No description)"'
    echo "============================================================"
}

# Get space permissions
confluence_space_permissions() {
    local key="$1"

    if [[ -z "$key" ]]; then
        echo "[ERROR] Space key required" >&2
        return 1
    fi

    if ! confluence_configured; then
        echo "[ERROR] Confluence not configured" >&2
        return 1
    fi

    local response
    response=$(confluence_api GET "/space/${key}/permission")

    echo "=========================================="
    echo "Permissions for space: $key"
    echo "=========================================="

    # Cloud v2 API format
    if echo "$response" | jq -e '.results' > /dev/null 2>&1; then
        echo "$response" | jq -r '.results[] | "[\(.operation.operation)] \(.principal.type): \(.principal.displayName // .principal.id)"'
    else
        # Try alternative format
        echo "$response" | jq -r '.[] | "[\(.type)] \(.subjects // "N/A")"' 2>/dev/null || \
        echo "[WARN] Could not parse permissions response"
    fi
}

# Delete space (dangerous!)
confluence_space_delete() {
    local key="$1"
    local force="$2"

    if [[ -z "$key" ]]; then
        echo "[ERROR] Space key required" >&2
        return 1
    fi

    if [[ "$force" != "--force" ]]; then
        echo "[WARN] This will delete space '$key' and ALL its content!"
        echo "Use: pm confluence space delete $key --force"
        return 1
    fi

    if ! confluence_configured; then
        echo "[ERROR] Confluence not configured" >&2
        return 1
    fi

    local response
    response=$(confluence_api DELETE "/space/${key}")

    if [[ -z "$response" ]]; then
        echo "(v) Deleted space: $key"
    else
        local error_msg
        error_msg=$(echo "$response" | jq -r '.message // empty' 2>/dev/null)
        if [[ -n "$error_msg" ]]; then
            echo "[ERROR] $error_msg" >&2
            return 1
        fi
        echo "(v) Deleted space: $key"
    fi
}
