#!/bin/bash
# Platform Provider Interface Definition
# Defines required and optional functions for each provider
#
# RFC-007: Architecture Pattern Improvements
# See: docs/rfcs/007-architecture-improvements.md

set -e

# ============================================================
# REQUIRED FUNCTIONS - All providers MUST implement these
# ============================================================
#
# Issue operations (required for issue providers)
#   ${provider}_issue_create(title, [description]) -> issue_id
#   ${provider}_issue_list([state], [limit]) -> formatted list
#   ${provider}_issue_view(issue_id) -> formatted details
#
# Review operations (required for VCS providers)
#   ${provider}_pr_create / ${provider}_mr_create
#   ${provider}_pr_list / ${provider}_mr_list
#   ${provider}_pr_view / ${provider}_mr_view

# ============================================================
# OPTIONAL FUNCTIONS - Providers MAY implement these
# ============================================================
#
# Milestone operations
#   ${provider}_milestone_create(title, [due_date], [description]) -> milestone_id
#   ${provider}_milestone_list([state], [limit]) -> formatted list
#   ${provider}_milestone_view(id) -> formatted details
#   ${provider}_milestone_close(id) -> success
#
# Label operations
#   ${provider}_label_create(name, [color], [description]) -> label_id
#   ${provider}_label_list([limit]) -> formatted list
#   ${provider}_label_delete(name) -> success
#
# Wiki operations (GitLab only currently)
#   ${provider}_wiki_create(title, [content]) -> slug
#   ${provider}_wiki_list([limit]) -> formatted list
#   ${provider}_wiki_view(slug) -> formatted content
#   ${provider}_wiki_update(slug, content, [title]) -> success
#   ${provider}_wiki_delete(slug) -> success

# ============================================================
# INTERFACE DEFINITIONS
# ============================================================

# Required functions by provider type
declare -A REQUIRED_ISSUE_FUNCTIONS=(
    ["create"]="issue_create"
    ["list"]="issue_list"
)

declare -A REQUIRED_VCS_FUNCTIONS=(
    ["pr_create"]="pr_create or mr_create"
    ["pr_list"]="pr_list or mr_list"
)

declare -A OPTIONAL_FUNCTIONS=(
    ["milestone_list"]="Milestone listing"
    ["milestone_create"]="Milestone creation"
    ["milestone_close"]="Milestone closing"
    ["label_list"]="Label listing"
    ["label_create"]="Label creation"
    ["label_delete"]="Label deletion"
    ["wiki_list"]="Wiki listing"
    ["wiki_create"]="Wiki creation"
    ["wiki_view"]="Wiki viewing"
)

# ============================================================
# DEFAULT IMPLEMENTATIONS
# ============================================================

# Default handler for not implemented functions
not_implemented() {
    local func_name="$1"
    local provider="$2"
    echo "[ERROR] Function '$func_name' not implemented for provider '$provider'" >&2
    echo "[HINT] This feature may not be available on your platform" >&2
    return 1
}

# Default handler for unsupported features
not_supported() {
    local feature="$1"
    local provider="$2"
    local alternative="${3:-}"
    echo "[WARN] $feature is not supported by $provider" >&2
    if [[ -n "$alternative" ]]; then
        echo "[INFO] Alternative: $alternative" >&2
    fi
    return 1
}

# ============================================================
# INTERFACE COMPLIANCE CHECK
# ============================================================

# Check if a provider implements required functions for issue tracking
# Usage: check_issue_interface <provider>
# Returns: 0 if compliant, 1 if not
check_issue_interface() {
    local provider="$1"
    local missing=()

    # Check issue_create
    if ! type "${provider}_issue_create" &>/dev/null; then
        missing+=("issue_create")
    fi

    # Check issue_list
    if ! type "${provider}_issue_list" &>/dev/null; then
        missing+=("issue_list")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "[WARN] Provider '$provider' missing required issue functions: ${missing[*]}" >&2
        return 1
    fi

    return 0
}

# Check if a provider implements required functions for VCS/review
# Usage: check_vcs_interface <provider>
# Returns: 0 if compliant, 1 if not
check_vcs_interface() {
    local provider="$1"
    local has_pr=false
    local has_mr=false

    # Check for PR (GitHub style)
    if type "${provider}_pr_create" &>/dev/null && type "${provider}_pr_list" &>/dev/null; then
        has_pr=true
    fi

    # Check for MR (GitLab style)
    if type "${provider}_mr_create" &>/dev/null && type "${provider}_mr_list" &>/dev/null; then
        has_mr=true
    fi

    if [[ "$has_pr" == "false" ]] && [[ "$has_mr" == "false" ]]; then
        echo "[WARN] Provider '$provider' missing required review functions (pr_* or mr_*)" >&2
        return 1
    fi

    return 0
}

# Full interface compliance check
# Usage: check_interface_compliance <provider> [--verbose]
# Returns: 0 if all required functions exist, 1 if not
check_interface_compliance() {
    local provider="$1"
    local verbose="${2:-}"
    local has_issues=false
    local has_vcs=false
    local optional_count=0

    echo "============================================================"
    echo "Interface Compliance Check: $provider"
    echo "============================================================"

    # Check issue interface
    echo ""
    echo "[Issue Interface]"
    if check_issue_interface "$provider" 2>/dev/null; then
        echo "  [v] Issue functions: compliant"
        has_issues=true
    else
        echo "  [ ] Issue functions: not compliant"
    fi

    # Check VCS interface
    echo ""
    echo "[VCS Interface]"
    if check_vcs_interface "$provider" 2>/dev/null; then
        echo "  [v] Review functions: compliant"
        has_vcs=true
    else
        echo "  [ ] Review functions: not compliant"
    fi

    # Check optional functions
    echo ""
    echo "[Optional Functions]"
    for func in milestone_list milestone_create label_list label_create wiki_list wiki_create; do
        if type "${provider}_${func}" &>/dev/null; then
            echo "  [v] ${func}"
            ((optional_count++)) || true
        else
            if [[ -n "$verbose" ]]; then
                echo "  [ ] ${func}"
            fi
        fi
    done

    echo ""
    echo "------------------------------------------------------------"
    echo "Summary:"
    echo "  Issue compliant: $has_issues"
    echo "  VCS compliant:   $has_vcs"
    echo "  Optional:        $optional_count functions"
    echo "============================================================"

    # Return success if at least one interface is compliant
    [[ "$has_issues" == "true" ]] || [[ "$has_vcs" == "true" ]]
}

# List all available providers and their compliance
# Usage: list_providers
list_providers() {
    echo "============================================================"
    echo "Available Providers"
    echo "============================================================"

    for provider in github gitlab jira confluence; do
        echo ""
        echo "[$provider]"

        # Check if provider is configured
        local configured=false
        case "$provider" in
            github)
                github_configured 2>/dev/null && configured=true
                ;;
            gitlab)
                gitlab_configured 2>/dev/null && configured=true
                ;;
            jira)
                jira_configured 2>/dev/null && configured=true
                ;;
            confluence)
                confluence_configured 2>/dev/null && configured=true
                ;;
        esac

        if [[ "$configured" == "true" ]]; then
            echo "  Status: Configured"
        else
            echo "  Status: Not configured"
        fi

        # Check interfaces
        local issue_ok="[ ]"
        local vcs_ok="[ ]"

        check_issue_interface "$provider" 2>/dev/null && issue_ok="[v]"
        check_vcs_interface "$provider" 2>/dev/null && vcs_ok="[v]"

        echo "  Issue: $issue_ok"
        echo "  VCS:   $vcs_ok"
    done

    echo "============================================================"
}
