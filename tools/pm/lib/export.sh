#!/bin/bash
# Export functions for JIRA issues and Confluence pages to Markdown
# Requires: pandoc for HTML/ADF to Markdown conversion

set -e

# ============================================================
# Utility Functions
# ============================================================

# Check if pandoc is available
check_pandoc() {
    if ! command -v pandoc &> /dev/null; then
        echo "[ERROR] pandoc is required for export functionality" >&2
        echo "Install with:" >&2
        echo "  macOS:  brew install pandoc" >&2
        echo "  Ubuntu: apt install pandoc" >&2
        return 1
    fi
    return 0
}

# Convert HTML to Markdown using pandoc
html_to_markdown() {
    local html="$1"
    if [[ -z "$html" ]] || [[ "$html" == "null" ]]; then
        echo ""
        return
    fi
    echo "$html" | pandoc -f html -t markdown --wrap=none 2>/dev/null || echo "$html"
}

# Convert ADF (Atlassian Document Format) to Markdown
# ADF is JSON-based, we extract text and convert to Markdown
adf_to_markdown() {
    local adf_json="$1"
    if [[ -z "$adf_json" ]] || [[ "$adf_json" == "null" ]]; then
        echo ""
        return
    fi

    # For simple text content, extract directly
    # ADF structure: { type: "doc", content: [ { type: "paragraph", content: [...] } ] }
    local text
    text=$(echo "$adf_json" | jq -r '
        def extract_text:
            if type == "object" then
                if .type == "text" then .text
                elif .type == "hardBreak" then "\n"
                elif .type == "inlineCard" then "[" + (.attrs.url // "link") + "](" + (.attrs.url // "") + ")"
                elif .content then (.content | map(extract_text) | join(""))
                else ""
                end
            elif type == "array" then (map(extract_text) | join(""))
            else ""
            end;
        extract_text
    ' 2>/dev/null)

    if [[ -n "$text" ]]; then
        echo "$text"
    else
        # Fallback: just extract all text nodes
        echo "$adf_json" | jq -r '.. | .text? // empty' 2>/dev/null | tr '\n' ' '
    fi
}

# Sanitize filename (remove special characters)
sanitize_filename() {
    local name="$1"
    echo "$name" | sed 's/[^a-zA-Z0-9._-]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//'
}

# ============================================================
# JIRA Export Functions
# ============================================================

# Export single JIRA issue to Markdown
jira_issue_to_markdown() {
    local key="$1"
    local include_comments="${2:-false}"
    local output_dir="$3"

    # Get issue details with all fields
    local expand="renderedFields"
    if [[ "$include_comments" == "true" ]]; then
        expand="renderedFields,changelog"
    fi

    local response
    response=$(jira_api GET "/issue/${key}?expand=${expand}")

    local summary type status priority assignee reporter created updated
    summary=$(echo "$response" | jq -r '.fields.summary // "No Title"')
    type=$(echo "$response" | jq -r '.fields.issuetype.name // "Unknown"')
    status=$(echo "$response" | jq -r '.fields.status.name // "Unknown"')
    priority=$(echo "$response" | jq -r '.fields.priority.name // "N/A"')
    assignee=$(echo "$response" | jq -r '.fields.assignee.displayName // "Unassigned"')
    reporter=$(echo "$response" | jq -r '.fields.reporter.displayName // "Unknown"')
    created=$(echo "$response" | jq -r '.fields.created // "N/A"' | cut -d'T' -f1)
    updated=$(echo "$response" | jq -r '.fields.updated // "N/A"' | cut -d'T' -f1)

    # Get description (may be ADF or plain text)
    local description=""
    local desc_raw
    desc_raw=$(echo "$response" | jq -r '.fields.description')
    if [[ "$desc_raw" != "null" ]] && [[ -n "$desc_raw" ]]; then
        # Check if it's ADF (JSON object with type field)
        if echo "$desc_raw" | jq -e '.type' > /dev/null 2>&1; then
            description=$(adf_to_markdown "$desc_raw")
        else
            description="$desc_raw"
        fi
    fi

    # Get labels
    local labels
    labels=$(echo "$response" | jq -r '.fields.labels | join(", ") // ""')

    # Get issue links
    local links=""
    local link_data
    link_data=$(echo "$response" | jq -r '.fields.issuelinks[]?' 2>/dev/null)
    if [[ -n "$link_data" ]]; then
        links=$(echo "$response" | jq -r '.fields.issuelinks[] |
            if .inwardIssue then "- " + .type.inward + ": " + .inwardIssue.key
            else "- " + .type.outward + ": " + .outwardIssue.key
            end' 2>/dev/null)
    fi

    # Build markdown content
    local md_content
    md_content="# ${key}: ${summary}

| Field | Value |
|-------|-------|
| Type | ${type} |
| Status | ${status} |
| Priority | ${priority} |
| Assignee | ${assignee} |
| Reporter | ${reporter} |
| Created | ${created} |
| Updated | ${updated} |"

    if [[ -n "$labels" ]]; then
        md_content="${md_content}
| Labels | ${labels} |"
    fi

    md_content="${md_content}

## Description

${description:-*(No description)*}"

    # Add comments if requested
    if [[ "$include_comments" == "true" ]]; then
        local comments_response
        comments_response=$(jira_api GET "/issue/${key}/comment")
        local comments_count
        comments_count=$(echo "$comments_response" | jq -r '.total // 0')

        if [[ "$comments_count" -gt 0 ]]; then
            md_content="${md_content}

## Comments
"
            local i=0
            while [[ $i -lt $comments_count ]]; do
                local author created_at body
                author=$(echo "$comments_response" | jq -r ".comments[$i].author.displayName // \"Unknown\"")
                created_at=$(echo "$comments_response" | jq -r ".comments[$i].created // \"\"" | cut -d'T' -f1)
                body=$(echo "$comments_response" | jq -r ".comments[$i].body")

                # Convert ADF body if needed
                if echo "$body" | jq -e '.type' > /dev/null 2>&1; then
                    body=$(adf_to_markdown "$body")
                fi

                md_content="${md_content}
### ${author} (${created_at})

${body}
"
                ((i++))
            done
        fi
    fi

    # Add links section
    if [[ -n "$links" ]]; then
        md_content="${md_content}

## Links

${links}"
    fi

    # Write to file
    local filename="${key}.md"
    echo "$md_content" > "${output_dir}/${filename}"
    echo "$key"
}

# Main JIRA export function
jira_export() {
    local project="${1:-$JIRA_PROJECT_KEY}"
    local jql="$2"
    local output_dir="$3"
    local include_comments="${4:-false}"
    local limit="${5:-1000}"

    if ! check_pandoc; then
        return 1
    fi

    if ! jira_configured; then
        echo "[ERROR] Jira not configured" >&2
        return 1
    fi

    # Build JQL
    if [[ -z "$jql" ]]; then
        jql="project = ${project} ORDER BY updated DESC"
    fi

    # Create output directory
    mkdir -p "$output_dir"

    echo "=========================================="
    echo "JIRA Export"
    echo "=========================================="
    echo "JQL:    $jql"
    echo "Output: $output_dir"
    echo ""

    local start_at=0
    local max_results=50
    local total=0
    local exported=0
    local index_content="# JIRA Export Index

| Key | Type | Status | Summary |
|-----|------|--------|---------|"

    # Paginate through all issues
    local encoded_jql
    encoded_jql=$(echo "$jql" | jq -sRr @uri)
    local next_page_token=""
    local is_first_page=true

    while true; do
        local response

        # Use temp file for API responses to avoid bash variable truncation with large JSON
        local tmp_response="/tmp/jira_search_$$.json"

        # JIRA Cloud API v3 uses /search/jql with nextPageToken for pagination
        if is_jira_cloud; then
            local base_url
            base_url=$(resolve_jira_url)
            local auth
            auth=$(echo -n "${JIRA_EMAIL}:${JIRA_TOKEN}" | base64)

            # Use curl -G with --data-urlencode for proper URL encoding of nextPageToken
            local curl_args=(
                -s -G
                -o "$tmp_response"
                -H "Authorization: Basic $auth"
                -H "Accept: application/json"
                --data-urlencode "jql=${jql}"
                --data-urlencode "maxResults=${max_results}"
                --data-urlencode "fields=key,summary,status,issuetype"
            )

            if [[ -n "$next_page_token" ]]; then
                curl_args+=(--data-urlencode "nextPageToken=${next_page_token}")
            fi

            curl "${curl_args[@]}" "${base_url}/rest/api/3/search/jql"
        else
            # JIRA Server/Data Center uses traditional pagination
            jira_api GET "/search?jql=${encoded_jql}&startAt=${start_at}&maxResults=${max_results}&fields=key,summary,status,issuetype" > "$tmp_response"
        fi

        local issues_count
        issues_count=$(jq -r '.issues | length' "$tmp_response")

        if [[ "$is_first_page" == "true" ]]; then
            # For Cloud API, we don't have total count upfront
            if is_jira_cloud; then
                echo "Fetching issues (Cloud API - count will be shown at the end)..."
            else
                total=$(jq -r '.total // 0' "$tmp_response")
                echo "Found $total issues"
            fi
            echo ""
            is_first_page=false
        fi

        if [[ "$issues_count" -eq 0 ]]; then
            rm -f "$tmp_response"
            break
        fi

        # Process each issue
        local i=0
        while [[ $i -lt $issues_count ]]; do
            local key summary type status
            key=$(jq -r ".issues[$i].key" "$tmp_response")
            summary=$(jq -r ".issues[$i].fields.summary // \"No Title\"" "$tmp_response")
            type=$(jq -r ".issues[$i].fields.issuetype.name // \"Unknown\"" "$tmp_response")
            status=$(jq -r ".issues[$i].fields.status.name // \"Unknown\"" "$tmp_response")

            echo -n "Exporting $key..."

            if jira_issue_to_markdown "$key" "$include_comments" "$output_dir" > /dev/null; then
                echo " done"
                # Truncate summary for index
                local short_summary="${summary:0:50}"
                [[ ${#summary} -gt 50 ]] && short_summary="${short_summary}..."
                index_content="${index_content}
| [${key}](${key}.md) | ${type} | ${status} | ${short_summary} |"
                ((exported++))
            else
                echo " failed"
            fi

            ((i++))

            # Check limit
            if [[ $exported -ge $limit ]]; then
                break 2
            fi
        done

        # Check for next page
        if is_jira_cloud; then
            local is_last
            # Note: jq's // operator treats false as falsy, so we can't use '.isLast // true'
            # Instead, we check if isLast is explicitly true or if it's missing (null -> defaults to true)
            is_last=$(jq -r 'if .isLast == null then "true" else (.isLast | tostring) end' "$tmp_response")

            if [[ "$is_last" == "true" ]]; then
                rm -f "$tmp_response"
                break
            fi
            next_page_token=$(jq -r '.nextPageToken // empty' "$tmp_response")
            rm -f "$tmp_response"

            if [[ -z "$next_page_token" ]]; then
                break
            fi
        else
            rm -f "$tmp_response"
            start_at=$((start_at + max_results))
            if [[ $start_at -ge $total ]]; then
                break
            fi
        fi
    done

    # Write index file
    index_content="${index_content}

---
Exported: $(date '+%Y-%m-%d %H:%M:%S')
Total: ${exported} issues"

    echo "$index_content" > "${output_dir}/index.md"

    echo ""
    echo "=========================================="
    echo "Export complete: ${exported} issues"
    echo "Index: ${output_dir}/index.md"
    echo "=========================================="
}

# ============================================================
# Confluence Export Functions
# ============================================================

# Export single Confluence page to Markdown
confluence_page_to_markdown() {
    local page_id="$1"
    local output_dir="$2"
    local use_title_filename="${3:-false}"

    local response
    response=$(confluence_api GET "/content/${page_id}?expand=body.storage,version,space,ancestors")

    local title space version author updated
    title=$(echo "$response" | jq -r '.title // "Untitled"')
    space=$(echo "$response" | jq -r '.space.key // "N/A"')
    version=$(echo "$response" | jq -r '.version.number // 1')
    author=$(echo "$response" | jq -r '.version.by.displayName // "Unknown"')
    updated=$(echo "$response" | jq -r '.version.when // "N/A"' | cut -d'T' -f1)

    # Get HTML content and convert to Markdown
    local html_content
    html_content=$(echo "$response" | jq -r '.body.storage.value // ""')
    local md_body
    md_body=$(html_to_markdown "$html_content")

    # Build markdown content
    local md_content="# ${title}

| Field | Value |
|-------|-------|
| ID | ${page_id} |
| Space | ${space} |
| Version | ${version} |
| Author | ${author} |
| Updated | ${updated} |

---

${md_body}"

    # Determine filename
    local filename
    if [[ "$use_title_filename" == "true" ]]; then
        filename="$(sanitize_filename "$title").md"
    else
        filename="${page_id}.md"
    fi

    echo "$md_content" > "${output_dir}/${filename}"

    # Return page info for index
    echo "${page_id}|${title}|${filename}"
}

# Main Confluence export function
confluence_export() {
    local space="${1:-$CONFLUENCE_SPACE_KEY}"
    local output_dir="$2"
    local preserve_hierarchy="${3:-false}"
    local limit="${4:-1000}"

    if ! check_pandoc; then
        return 1
    fi

    if ! confluence_configured; then
        echo "[ERROR] Confluence not configured" >&2
        return 1
    fi

    if [[ -z "$space" ]]; then
        echo "[ERROR] Space key required" >&2
        return 1
    fi

    # Create output directory
    mkdir -p "$output_dir"

    echo "=========================================="
    echo "Confluence Export"
    echo "=========================================="
    echo "Space:  $space"
    echo "Output: $output_dir"
    echo ""

    local start=0
    local max_results=25
    local exported=0
    local index_content="# Confluence Export Index

Space: **${space}**

| ID | Title | File |
|----|-------|------|"

    # Paginate through all pages
    while true; do
        local response
        response=$(confluence_api GET "/content?spaceKey=${space}&type=page&limit=${max_results}&start=${start}&expand=version")

        local pages_count
        pages_count=$(echo "$response" | jq -r '.results | length')

        if [[ "$pages_count" -eq 0 ]]; then
            break
        fi

        if [[ $start -eq 0 ]]; then
            local total
            total=$(echo "$response" | jq -r '.size // 0')
            echo "Found approximately $total pages"
            echo ""
        fi

        # Process each page
        local i=0
        while [[ $i -lt $pages_count ]]; do
            local page_id page_title
            page_id=$(echo "$response" | jq -r ".results[$i].id")
            page_title=$(echo "$response" | jq -r ".results[$i].title // \"Untitled\"")

            echo -n "Exporting ${page_id}: ${page_title:0:40}..."

            local result
            result=$(confluence_page_to_markdown "$page_id" "$output_dir" "false")

            if [[ -n "$result" ]]; then
                echo " done"
                local filename
                filename=$(echo "$result" | cut -d'|' -f3)
                # Truncate title for index
                local short_title="${page_title:0:50}"
                [[ ${#page_title} -gt 50 ]] && short_title="${short_title}..."
                index_content="${index_content}
| ${page_id} | ${short_title} | [${filename}](${filename}) |"
                ((exported++))
            else
                echo " failed"
            fi

            ((i++))

            # Check limit
            if [[ $exported -ge $limit ]]; then
                break 2
            fi
        done

        start=$((start + max_results))
    done

    # Write index file
    index_content="${index_content}

---
Exported: $(date '+%Y-%m-%d %H:%M:%S')
Total: ${exported} pages"

    echo "$index_content" > "${output_dir}/index.md"

    echo ""
    echo "=========================================="
    echo "Export complete: ${exported} pages"
    echo "Index: ${output_dir}/index.md"
    echo "=========================================="
}
