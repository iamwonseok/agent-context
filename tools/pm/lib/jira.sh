#!/bin/bash
# Jira API functions

set -e

# Jira API request
jira_api() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    
    local url="${JIRA_BASE_URL}/rest/api/2${endpoint}"
    local auth=$(echo -n "${JIRA_EMAIL}:${JIRA_TOKEN}" | base64)
    
    local curl_args=(
        -s
        -X "$method"
        -H "Authorization: Basic $auth"
        -H "Content-Type: application/json"
        -H "Accept: application/json"
    )
    
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
    response=$(jira_api GET "/search?jql=${encoded_jql}&maxResults=${max_results}")
    
    local issues
    issues=$(echo "$response" | jq -r '.issues[]')
    
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
    total=$(echo "$response" | jq -r '.total')
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
