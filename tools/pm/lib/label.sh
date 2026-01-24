#!/bin/bash
# Unified Label functions
# Abstracts label operations across platforms (GitLab, GitHub, JIRA)

set -e

# ============================================================
# Provider Selection for Labels
# ============================================================

# Get label provider (follows issue provider by default)
get_label_provider() {
    # Labels typically follow the issue provider
    get_issue_provider
}

# ============================================================
# Unified Label Functions
# ============================================================

# List labels using configured provider
# Usage: unified_label_list [--limit N]
unified_label_list() {
    local limit="${1:-50}"

    local provider
    provider=$(get_label_provider)

    case "$provider" in
        github)
            github_label_list "$limit"
            ;;
        gitlab)
            gitlab_label_list "$limit"
            ;;
        jira)
            echo "[WARN] JIRA Label listing not yet implemented" >&2
            echo "[INFO] Use JIRA web interface to view labels" >&2
            return 1
            ;;
        none)
            echo "[ERROR] No issue provider configured (roles.issue not set)" >&2
            return 1
            ;;
        *)
            echo "[ERROR] Unknown issue provider: $provider" >&2
            return 1
            ;;
    esac
}

# Create label
# Usage: unified_label_create <NAME> [--color <HEX>] [--description <TEXT>]
unified_label_create() {
    local name="$1"
    local color="${2:-428BCA}"
    local description="$3"

    if [[ -z "$name" ]]; then
        echo "[ERROR] Name required" >&2
        return 1
    fi

    local provider
    provider=$(get_label_provider)

    case "$provider" in
        github)
            local id
            id=$(github_label_create "$name" "$color" "$description")
            if [[ -n "$id" ]] && [[ "$id" != "null" ]]; then
                echo "(v) GitHub label created: $name"
                echo "    Color: #${color#\#}"
            fi
            ;;
        gitlab)
            local id
            id=$(gitlab_label_create "$name" "$color" "$description")
            if [[ -n "$id" ]] && [[ "$id" != "null" ]]; then
                echo "(v) GitLab label created: $name"
                echo "    Color: ${color}"
            fi
            ;;
        jira)
            echo "[WARN] JIRA Label creation not yet implemented" >&2
            echo "[INFO] Use JIRA web interface to create labels" >&2
            return 1
            ;;
        none)
            echo "[ERROR] No issue provider configured (roles.issue not set)" >&2
            return 1
            ;;
        *)
            echo "[ERROR] Unknown issue provider: $provider" >&2
            return 1
            ;;
    esac
}

# Delete label
# Usage: unified_label_delete <NAME>
unified_label_delete() {
    local name="$1"

    if [[ -z "$name" ]]; then
        echo "[ERROR] Name required" >&2
        return 1
    fi

    local provider
    provider=$(get_label_provider)

    case "$provider" in
        github)
            github_label_delete "$name"
            ;;
        gitlab)
            gitlab_label_delete "$name"
            ;;
        jira)
            echo "[WARN] JIRA Label deletion not yet implemented" >&2
            echo "[INFO] Use JIRA web interface to delete labels" >&2
            return 1
            ;;
        none)
            echo "[ERROR] No issue provider configured (roles.issue not set)" >&2
            return 1
            ;;
        *)
            echo "[ERROR] Unknown issue provider: $provider" >&2
            return 1
            ;;
    esac
}
