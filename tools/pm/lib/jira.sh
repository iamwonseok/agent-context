#!/bin/bash
# Jira API functions
# Supports both Jira Cloud (*.atlassian.net) and Jira Server/Data Center

set -e

# Cache for resolved Cloud URL
_JIRA_RESOLVED_URL=""

# Resolve actual Jira URL (handles custom domains for Cloud)
resolve_jira_url() {
    if [[ -n "$_JIRA_RESOLVED_URL" ]]; then
        echo "$_JIRA_RESOLVED_URL"
        return
    fi

    # Try to get serverInfo to find actual baseUrl
    local server_info
    server_info=$(curl -s "${JIRA_BASE_URL}/rest/api/2/serverInfo" 2>/dev/null || echo "{}")

    local base_url
    base_url=$(echo "$server_info" | jq -r '.baseUrl // empty' 2>/dev/null)

    if [[ -n "$base_url" ]] && [[ "$base_url" != "null" ]]; then
        _JIRA_RESOLVED_URL="$base_url"
    else
        _JIRA_RESOLVED_URL="$JIRA_BASE_URL"
    fi

    echo "$_JIRA_RESOLVED_URL"
}

# Detect if Jira Cloud or Server
is_jira_cloud() {
    local url
    url=$(resolve_jira_url)
    [[ "$url" == *".atlassian.net"* ]]
}

# Jira API request
jira_api() {
    local method="$1"
    local endpoint="$2"
    local data="$3"

    local base_url
    base_url=$(resolve_jira_url)

    # Cloud uses API v3, Server uses API v2
    local api_version="2"
    if is_jira_cloud; then
        api_version="3"
    fi
    local url="${base_url}/rest/api/${api_version}${endpoint}"

    local curl_args=(
        -s
        -X "$method"
        -H "Content-Type: application/json"
        -H "Accept: application/json"
    )

    # Authentication: Cloud uses Basic Auth, Server uses Bearer token
    if is_jira_cloud; then
        local auth=$(echo -n "${JIRA_EMAIL}:${JIRA_TOKEN}" | base64)
        curl_args+=(-H "Authorization: Basic $auth")
    else
        # Jira Server/Data Center uses Bearer token (Personal Access Token)
        curl_args+=(-H "Authorization: Bearer $JIRA_TOKEN")
    fi

    if [[ -n "$data" ]]; then
        curl_args+=(-d "$data")
    fi

    curl "${curl_args[@]}" "$url"
}

# Get current user
jira_me() {
    if ! jira_configured; then
        echo "[ERROR] Jira not configured" >&2
        return 1
    fi

    local response
    response=$(jira_api GET "/myself")

    echo "=========================================="
    echo "Current Jira User"
    echo "=========================================="
    echo "Name:  $(echo "$response" | jq -r '.displayName')"
    echo "Email: $(echo "$response" | jq -r '.emailAddress')"
    echo "ID:    $(echo "$response" | jq -r '.accountId')"
    echo "=========================================="
}

# List issues
jira_issue_list() {
    local jql="${1:-project = $JIRA_PROJECT_KEY ORDER BY updated DESC}"
    local max_results="${2:-20}"

    if ! jira_configured; then
        echo "[ERROR] Jira not configured" >&2
        return 1
    fi

    local encoded_jql=$(echo "$jql" | jq -sRr @uri)
    local response

    # Cloud uses new search/jql endpoint, Server uses old search endpoint
    if is_jira_cloud; then
        local base_url
        base_url=$(resolve_jira_url)
        local auth=$(echo -n "${JIRA_EMAIL}:${JIRA_TOKEN}" | base64)
        response=$(curl -s -X GET \
            -H "Authorization: Basic $auth" \
            -H "Accept: application/json" \
            "${base_url}/rest/api/3/search/jql?jql=${encoded_jql}&maxResults=${max_results}&fields=key,summary,status,issuetype")
    else
        response=$(jira_api GET "/search?jql=${encoded_jql}&maxResults=${max_results}")
    fi

    local issues
    issues=$(echo "$response" | jq -r '.issues[]' 2>/dev/null)

    if [[ -z "$issues" ]]; then
        echo "No issues found."
        return 0
    fi

    echo "------------------------------------------------------------------------"
    printf "%-12s | %-8s | %-12s | %s\n" "Key" "Type" "Status" "Summary"
    echo "------------------------------------------------------------------------"

    echo "$response" | jq -r '.issues[] | [.key, .fields.issuetype.name, .fields.status.name, .fields.summary] | @tsv' | \
    while IFS=$'\t' read -r key type status summary; do
        # Truncate summary if too long
        if [[ ${#summary} -gt 40 ]]; then
            summary="${summary:0:37}..."
        fi
        printf "%-12s | %-8s | %-12s | %s\n" "$key" "$type" "$status" "$summary"
    done

    echo "------------------------------------------------------------------------"
    local total
    total=$(echo "$response" | jq -r '.total // .issues | length')
    echo "Total: $total issues"
}

# View issue detail
jira_issue_view() {
    local key="$1"

    if [[ -z "$key" ]]; then
        echo "[ERROR] Issue key required" >&2
        return 1
    fi

    if ! jira_configured; then
        echo "[ERROR] Jira not configured" >&2
        return 1
    fi

    local response
    response=$(jira_api GET "/issue/${key}")

    echo "============================================================"
    echo "Issue: $(echo "$response" | jq -r '.key')"
    echo "============================================================"
    echo "Summary:  $(echo "$response" | jq -r '.fields.summary')"
    echo "Type:     $(echo "$response" | jq -r '.fields.issuetype.name')"
    echo "Status:   $(echo "$response" | jq -r '.fields.status.name')"
    echo "Priority: $(echo "$response" | jq -r '.fields.priority.name // "N/A"')"
    echo "Assignee: $(echo "$response" | jq -r '.fields.assignee.displayName // "Unassigned"')"
    echo "------------------------------------------------------------"
    echo "Description:"
    echo "$response" | jq -r '.fields.description // "(No description)"'
    echo "============================================================"
}

# Create issue
jira_issue_create() {
    local summary="$1"
    local issue_type="${2:-Task}"
    local description="$3"

    if [[ -z "$summary" ]]; then
        echo "[ERROR] Summary required" >&2
        return 1
    fi

    if ! jira_configured; then
        echo "[ERROR] Jira not configured" >&2
        return 1
    fi

    local payload
    # Jira Cloud API v3 requires ADF format for description
    if is_jira_cloud && [[ -n "$description" ]]; then
        payload=$(jq -n \
            --arg project "$JIRA_PROJECT_KEY" \
            --arg summary "$summary" \
            --arg type "$issue_type" \
            --arg desc "$description" \
            '{
                fields: {
                    project: { key: $project },
                    summary: $summary,
                    issuetype: { name: $type },
                    description: {
                        type: "doc",
                        version: 1,
                        content: [
                            {
                                type: "paragraph",
                                content: [
                                    {
                                        type: "text",
                                        text: $desc
                                    }
                                ]
                            }
                        ]
                    }
                }
            }')
    else
        payload=$(jq -n \
            --arg project "$JIRA_PROJECT_KEY" \
            --arg summary "$summary" \
            --arg type "$issue_type" \
            --arg desc "$description" \
            '{
                fields: {
                    project: { key: $project },
                    summary: $summary,
                    issuetype: { name: $type },
                    description: (if $desc != "" then $desc else null end)
                }
            }')
    fi

    local response
    response=$(jira_api POST "/issue" "$payload")

    local key
    key=$(echo "$response" | jq -r '.key')

    if [[ -z "$key" ]] || [[ "$key" == "null" ]]; then
        echo "[ERROR] Failed to create issue:" >&2
        echo "$response" | jq -r '.errors // .errorMessages // .' >&2
        return 1
    fi

    echo "(v) Created: $key"
    jira_issue_view "$key"
}

# Transition issue
jira_transition() {
    local key="$1"
    local transition_name="$2"

    if ! jira_configured; then
        echo "[ERROR] Jira not configured" >&2
        return 1
    fi

    # Get available transitions
    local transitions
    transitions=$(jira_api GET "/issue/${key}/transitions")

    # Find transition ID
    local transition_id
    transition_id=$(echo "$transitions" | jq -r --arg name "$transition_name" \
        '.transitions[] | select(.name | ascii_downcase == ($name | ascii_downcase)) | .id')

    if [[ -z "$transition_id" ]]; then
        echo "[ERROR] Transition '$transition_name' not found" >&2
        echo "Available transitions:"
        echo "$transitions" | jq -r '.transitions[].name'
        return 1
    fi

    # Execute transition
    local payload
    payload=$(jq -n --arg id "$transition_id" '{ transition: { id: $id } }')
    jira_api POST "/issue/${key}/transitions" "$payload" > /dev/null

    echo "(v) Transitioned $key to $transition_name"
}

# Search user by email and return accountId
jira_user_search() {
    local query="$1"

    if [[ -z "$query" ]]; then
        echo "[ERROR] Email or name required" >&2
        return 1
    fi

    if ! jira_configured; then
        echo "[ERROR] Jira not configured" >&2
        return 1
    fi

    local response
    local encoded_query
    encoded_query=$(echo "$query" | jq -sRr @uri)

    if is_jira_cloud; then
        local base_url
        base_url=$(resolve_jira_url)
        local auth=$(echo -n "${JIRA_EMAIL}:${JIRA_TOKEN}" | base64)
        response=$(curl -s -X GET \
            -H "Authorization: Basic $auth" \
            -H "Accept: application/json" \
            "${base_url}/rest/api/3/user/search?query=${encoded_query}&maxResults=10")
    else
        response=$(jira_api GET "/user/search?query=${encoded_query}&maxResults=10")
    fi

    local count
    count=$(echo "$response" | jq 'length')

    if [[ "$count" == "0" ]]; then
        echo "[WARN] No users found for: $query" >&2
        return 1
    fi

    echo "------------------------------------------------------------------------"
    printf "%-36s | %-20s | %s\n" "Account ID" "Display Name" "Email"
    echo "------------------------------------------------------------------------"

    echo "$response" | jq -r '.[] | [.accountId, .displayName, .emailAddress // "N/A"] | @tsv' | \
    while IFS=$'\t' read -r account_id name email; do
        printf "%-36s | %-20s | %s\n" "$account_id" "$name" "$email"
    done

    echo "------------------------------------------------------------------------"
    echo "Total: $count users"
}

# Get accountId by email (silent, returns only ID)
jira_get_account_id() {
    local email="$1"

    if ! jira_configured; then
        return 1
    fi

    local encoded_email
    encoded_email=$(echo "$email" | jq -sRr @uri)

    local response
    if is_jira_cloud; then
        local base_url
        base_url=$(resolve_jira_url)
        local auth=$(echo -n "${JIRA_EMAIL}:${JIRA_TOKEN}" | base64)
        response=$(curl -s -X GET \
            -H "Authorization: Basic $auth" \
            -H "Accept: application/json" \
            "${base_url}/rest/api/3/user/search?query=${encoded_email}&maxResults=1")
    else
        response=$(jira_api GET "/user/search?query=${encoded_email}&maxResults=1")
    fi

    local account_id
    account_id=$(echo "$response" | jq -r '.[0].accountId // empty')

    if [[ -z "$account_id" ]]; then
        return 1
    fi

    echo "$account_id"
}

# Assign issue to user
jira_issue_assign() {
    local key="$1"
    local assignee="$2"

    if [[ -z "$key" ]]; then
        echo "[ERROR] Issue key required" >&2
        return 1
    fi

    if [[ -z "$assignee" ]]; then
        echo "[ERROR] Assignee (email) required" >&2
        return 1
    fi

    if ! jira_configured; then
        echo "[ERROR] Jira not configured" >&2
        return 1
    fi

    # Resolve email to accountId
    local account_id
    account_id=$(jira_get_account_id "$assignee")

    if [[ -z "$account_id" ]]; then
        echo "[ERROR] User not found: $assignee" >&2
        return 1
    fi

    # Assign issue
    local payload
    if is_jira_cloud; then
        payload=$(jq -n --arg id "$account_id" '{ fields: { assignee: { accountId: $id } } }')
    else
        # Jira Server uses 'name' field
        payload=$(jq -n --arg name "$assignee" '{ fields: { assignee: { name: $name } } }')
    fi

    local response
    response=$(jira_api PUT "/issue/${key}" "$payload")

    # Check for errors
    if echo "$response" | jq -e '.errors' > /dev/null 2>&1; then
        echo "[ERROR] Failed to assign issue:" >&2
        echo "$response" | jq -r '.errors // .errorMessages // .' >&2
        return 1
    fi

    echo "(v) Assigned $key to $assignee ($account_id)"
}

# Bulk create issues from CSV
# CSV format: summary,type,assignee_email,description
jira_bulk_create() {
    local csv_file="$1"

    if [[ -z "$csv_file" ]]; then
        echo "[ERROR] CSV file required" >&2
        return 1
    fi

    if [[ ! -f "$csv_file" ]]; then
        echo "[ERROR] File not found: $csv_file" >&2
        return 1
    fi

    if ! jira_configured; then
        echo "[ERROR] Jira not configured" >&2
        return 1
    fi

    echo "=========================================="
    echo "Jira Bulk Create from CSV"
    echo "=========================================="
    echo "File: $csv_file"
    echo "Project: $JIRA_PROJECT_KEY"
    echo ""

    local success=0
    local failed=0
    local line_num=0

    # Read CSV (skip header)
    while IFS=',' read -r summary type assignee_email description || [[ -n "$summary" ]]; do
        ((line_num++))

        # Skip header
        if [[ $line_num -eq 1 ]]; then
            # Validate header
            if [[ "$summary" != "summary" ]]; then
                echo "[WARN] No header detected, processing as data"
                line_num=0
            else
                continue
            fi
        fi

        # Skip empty lines
        if [[ -z "$summary" ]]; then
            continue
        fi

        # Remove quotes if present
        summary=$(echo "$summary" | sed 's/^"//;s/"$//')
        type=$(echo "$type" | sed 's/^"//;s/"$//')
        assignee_email=$(echo "$assignee_email" | sed 's/^"//;s/"$//')
        description=$(echo "$description" | sed 's/^"//;s/"$//')

        # Default type
        type="${type:-Task}"

        echo -n "[$line_num] Creating: ${summary:0:40}..."

        # Create issue (Jira Cloud API v3 requires ADF for description)
        local payload
        if is_jira_cloud && [[ -n "$description" ]]; then
            payload=$(jq -n \
                --arg project "$JIRA_PROJECT_KEY" \
                --arg summary "$summary" \
                --arg type "$type" \
                --arg desc "$description" \
                '{
                    fields: {
                        project: { key: $project },
                        summary: $summary,
                        issuetype: { name: $type },
                        description: {
                            type: "doc",
                            version: 1,
                            content: [
                                {
                                    type: "paragraph",
                                    content: [
                                        {
                                            type: "text",
                                            text: $desc
                                        }
                                    ]
                                }
                            ]
                        }
                    }
                }')
        else
            payload=$(jq -n \
                --arg project "$JIRA_PROJECT_KEY" \
                --arg summary "$summary" \
                --arg type "$type" \
                --arg desc "$description" \
                '{
                    fields: {
                        project: { key: $project },
                        summary: $summary,
                        issuetype: { name: $type },
                        description: (if $desc != "" then $desc else null end)
                    }
                }')
        fi

        local response
        response=$(jira_api POST "/issue" "$payload")

        local key
        key=$(echo "$response" | jq -r '.key')

        if [[ -z "$key" ]] || [[ "$key" == "null" ]]; then
            echo " [FAIL]"
            echo "  Error: $(echo "$response" | jq -r '.errors // .errorMessages // .' 2>/dev/null)"
            ((failed++))
            continue
        fi

        echo -n " $key"

        # Assign if email provided
        if [[ -n "$assignee_email" ]]; then
            local account_id
            account_id=$(jira_get_account_id "$assignee_email")

            if [[ -n "$account_id" ]]; then
                local assign_payload
                if is_jira_cloud; then
                    assign_payload=$(jq -n --arg id "$account_id" '{ fields: { assignee: { accountId: $id } } }')
                else
                    assign_payload=$(jq -n --arg name "$assignee_email" '{ fields: { assignee: { name: $name } } }')
                fi

                jira_api PUT "/issue/${key}" "$assign_payload" > /dev/null 2>&1
                echo " -> $assignee_email"
            else
                echo " -> [WARN] User not found: $assignee_email"
            fi
        else
            echo " (no assignee)"
        fi

        ((success++))
    done < "$csv_file"

    echo ""
    echo "=========================================="
    echo "Result: $success created, $failed failed"
    echo "=========================================="
}

# Update issue fields
jira_issue_update() {
    local key="$1"
    shift

    if [[ -z "$key" ]]; then
        echo "[ERROR] Issue key required" >&2
        return 1
    fi

    if ! jira_configured; then
        echo "[ERROR] Jira not configured" >&2
        return 1
    fi

    local labels=""
    local priority=""
    local due_date=""
    local summary=""
    local components=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --labels) labels="$2"; shift ;;
            --priority) priority="$2"; shift ;;
            --due-date) due_date="$2"; shift ;;
            --summary) summary="$2"; shift ;;
            --components) components="$2"; shift ;;
        esac
        shift
    done

    # Build payload dynamically
    local payload='{"fields":{}}'

    if [[ -n "$labels" ]]; then
        # Convert comma-separated to JSON array
        local labels_json
        labels_json=$(echo "$labels" | tr ',' '\n' | jq -R . | jq -s .)
        payload=$(echo "$payload" | jq --argjson labels "$labels_json" '.fields.labels = $labels')
    fi

    if [[ -n "$priority" ]]; then
        payload=$(echo "$payload" | jq --arg p "$priority" '.fields.priority = {name: $p}')
    fi

    if [[ -n "$due_date" ]]; then
        payload=$(echo "$payload" | jq --arg d "$due_date" '.fields.duedate = $d')
    fi

    if [[ -n "$summary" ]]; then
        payload=$(echo "$payload" | jq --arg s "$summary" '.fields.summary = $s')
    fi

    if [[ -n "$components" ]]; then
        local comp_json
        comp_json=$(echo "$components" | tr ',' '\n' | jq -R '{name: .}' | jq -s .)
        payload=$(echo "$payload" | jq --argjson c "$comp_json" '.fields.components = $c')
    fi

    local response
    response=$(jira_api PUT "/issue/${key}" "$payload")

    # Jira PUT returns empty response on success (204 No Content)
    if [[ -n "$response" ]]; then
        local has_errors
        has_errors=$(echo "$response" | jq -r 'if .errors then "yes" else "no" end' 2>/dev/null || echo "no")
        if [[ "$has_errors" == "yes" ]]; then
            echo "[ERROR] Failed to update issue:" >&2
            echo "$response" | jq -r '.errors // .errorMessages // .' >&2
            return 1
        fi
    fi

    echo "(v) Updated $key"
    
    # Show what was updated
    [[ -n "$labels" ]] && echo "  - labels: $labels"
    [[ -n "$priority" ]] && echo "  - priority: $priority"
    [[ -n "$due_date" ]] && echo "  - due-date: $due_date"
    [[ -n "$summary" ]] && echo "  - summary: $summary"
    [[ -n "$components" ]] && echo "  - components: $components"
    
    return 0
}

# List available sprints for a board
jira_sprint_list() {
    local board_id="$1"

    if ! jira_configured; then
        echo "[ERROR] Jira not configured" >&2
        return 1
    fi

    # If no board_id, try to find boards for the project
    if [[ -z "$board_id" ]]; then
        local base_url
        base_url=$(resolve_jira_url)
        local auth
        if is_jira_cloud; then
            auth=$(echo -n "${JIRA_EMAIL}:${JIRA_TOKEN}" | base64)
        fi

        local boards_response
        boards_response=$(curl -s -X GET \
            -H "Authorization: Basic $auth" \
            -H "Accept: application/json" \
            "${base_url}/rest/agile/1.0/board?projectKeyOrId=${JIRA_PROJECT_KEY}")

        echo "=========================================="
        echo "Boards for project $JIRA_PROJECT_KEY"
        echo "=========================================="
        echo "$boards_response" | jq -r '.values[] | "[\(.id)] \(.name) (\(.type))"'
        echo ""
        echo "Use: pm jira sprint list <board-id>"
        return 0
    fi

    local base_url
    base_url=$(resolve_jira_url)
    local auth
    if is_jira_cloud; then
        auth=$(echo -n "${JIRA_EMAIL}:${JIRA_TOKEN}" | base64)
    fi

    local response
    response=$(curl -s -X GET \
        -H "Authorization: Basic $auth" \
        -H "Accept: application/json" \
        "${base_url}/rest/agile/1.0/board/${board_id}/sprint?state=active,future")

    echo "------------------------------------------------------------------------"
    printf "%-6s | %-10s | %-30s | %s\n" "ID" "State" "Name" "Dates"
    echo "------------------------------------------------------------------------"

    echo "$response" | jq -r '.values[] | [.id, .state, .name, (.startDate // "N/A") + " - " + (.endDate // "N/A")] | @tsv' | \
    while IFS=$'\t' read -r id state name dates; do
        printf "%-6s | %-10s | %-30s | %s\n" "$id" "$state" "${name:0:30}" "$dates"
    done

    echo "------------------------------------------------------------------------"
}

# Move issue to sprint
jira_issue_move_to_sprint() {
    local key="$1"
    local sprint_id="$2"

    if [[ -z "$key" ]]; then
        echo "[ERROR] Issue key required" >&2
        return 1
    fi

    if [[ -z "$sprint_id" ]]; then
        echo "[ERROR] Sprint ID required" >&2
        echo "Use 'pm jira sprint list <board-id>' to find sprint IDs"
        return 1
    fi

    if ! jira_configured; then
        echo "[ERROR] Jira not configured" >&2
        return 1
    fi

    local base_url
    base_url=$(resolve_jira_url)
    local auth
    if is_jira_cloud; then
        auth=$(echo -n "${JIRA_EMAIL}:${JIRA_TOKEN}" | base64)
    fi

    local payload
    payload=$(jq -n --arg key "$key" '{ issues: [$key] }')

    local response
    response=$(curl -s -X POST \
        -H "Authorization: Basic $auth" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        "${base_url}/rest/agile/1.0/sprint/${sprint_id}/issue" \
        -d "$payload")

    if [[ -n "$response" ]] && echo "$response" | jq -e '.errorMessages' > /dev/null 2>&1; then
        echo "[ERROR] Failed to move issue to sprint:" >&2
        echo "$response" | jq -r '.errorMessages[]' >&2
        return 1
    fi

    echo "(v) Moved $key to sprint $sprint_id"
}

# List workflow transitions for an issue
jira_workflow_transitions() {
    local key="$1"

    if [[ -z "$key" ]]; then
        echo "[ERROR] Issue key required" >&2
        return 1
    fi

    if ! jira_configured; then
        echo "[ERROR] Jira not configured" >&2
        return 1
    fi

    local response
    response=$(jira_api GET "/issue/${key}/transitions")

    echo "=========================================="
    echo "Available transitions for $key"
    echo "=========================================="
    echo ""

    echo "$response" | jq -r '.transitions[] | "[\(.id)] \(.name) -> \(.to.name)"'

    echo ""
    echo "Use: pm jira issue transition $key \"<status-name>\""
}

# List workflows in project
jira_workflow_list() {
    if ! jira_configured; then
        echo "[ERROR] Jira not configured" >&2
        return 1
    fi

    local response
    response=$(jira_api GET "/workflow/search?projectId=${JIRA_PROJECT_KEY}&expand=statuses")

    # If project ID doesn't work, try without filter
    if echo "$response" | jq -e '.errorMessages' > /dev/null 2>&1; then
        response=$(jira_api GET "/workflow/search")
    fi

    echo "=========================================="
    echo "Workflows"
    echo "=========================================="
    echo ""

    echo "$response" | jq -r '.values[] | "[\(.id.name)] \(.description // "No description")"' 2>/dev/null || \
    echo "$response" | jq -r '.[] | "[\(.name)] \(.description // "No description")"' 2>/dev/null || \
    echo "[WARN] Could not parse workflow response"

    echo ""
}

# Get workflow statuses
jira_workflow_statuses() {
    if ! jira_configured; then
        echo "[ERROR] Jira not configured" >&2
        return 1
    fi

    local response
    response=$(jira_api GET "/status")

    echo "------------------------------------------------------------------------"
    printf "%-6s | %-15s | %-15s | %s\n" "ID" "Name" "Category" "Description"
    echo "------------------------------------------------------------------------"

    echo "$response" | jq -r '.[] | [.id, .name, .statusCategory.name, .description // ""] | @tsv' | \
    while IFS=$'\t' read -r id name category desc; do
        printf "%-6s | %-15s | %-15s | %s\n" "$id" "${name:0:15}" "${category:0:15}" "${desc:0:30}"
    done

    echo "------------------------------------------------------------------------"
}
