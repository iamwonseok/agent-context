#!/bin/bash
# Unified Wiki functions
# Abstracts wiki operations across platforms (GitLab, GitHub)
#
# Note: GitHub Wiki uses a separate Git repository, making it complex
# to manage via API alone. Currently only GitLab Wiki is fully supported.

set -e

# ============================================================
# Unified Wiki Functions
# ============================================================

# List wiki pages using configured provider
# Usage: unified_wiki_list [--limit N]
unified_wiki_list() {
    local limit="${1:-20}"

    local provider
    provider=$(get_wiki_provider)

    case "$provider" in
        gitlab)
            gitlab_wiki_list "$limit"
            ;;
        github)
            echo "[WARN] GitHub Wiki is managed via separate Git repository" >&2
            echo "[INFO] Clone wiki: git clone https://github.com/${GITHUB_REPO}.wiki.git" >&2
            echo "[INFO] Or visit: https://github.com/${GITHUB_REPO}/wiki" >&2
            return 1
            ;;
        none)
            echo "[ERROR] No wiki provider configured (roles.wiki not set)" >&2
            return 1
            ;;
        *)
            echo "[ERROR] Unknown wiki provider: $provider" >&2
            return 1
            ;;
    esac
}

# View wiki page
# Usage: unified_wiki_view <SLUG>
unified_wiki_view() {
    local slug="$1"

    if [[ -z "$slug" ]]; then
        echo "[ERROR] Wiki slug required" >&2
        return 1
    fi

    local provider
    provider=$(get_wiki_provider)

    case "$provider" in
        gitlab)
            gitlab_wiki_view "$slug"
            ;;
        github)
            echo "[WARN] GitHub Wiki is managed via separate Git repository" >&2
            echo "[INFO] View page: https://github.com/${GITHUB_REPO}/wiki/$slug" >&2
            return 1
            ;;
        none)
            echo "[ERROR] No wiki provider configured (roles.wiki not set)" >&2
            return 1
            ;;
        *)
            echo "[ERROR] Unknown wiki provider: $provider" >&2
            return 1
            ;;
    esac
}

# Create wiki page
# Usage: unified_wiki_create <TITLE> [--content <TEXT>] [--file <PATH>]
unified_wiki_create() {
    local title="$1"
    local content="$2"

    if [[ -z "$title" ]]; then
        echo "[ERROR] Title required" >&2
        return 1
    fi

    local provider
    provider=$(get_wiki_provider)

    case "$provider" in
        gitlab)
            local slug
            slug=$(gitlab_wiki_create "$title" "$content")
            if [[ -n "$slug" ]] && [[ "$slug" != "null" ]]; then
                echo "(v) GitLab wiki page created: $title"
                echo "    Slug: $slug"
                echo "    URL: ${GITLAB_BASE_URL}/${GITLAB_PROJECT}/-/wikis/$slug"
            fi
            ;;
        github)
            echo "[WARN] GitHub Wiki is managed via separate Git repository" >&2
            echo "[INFO] To create a wiki page:" >&2
            echo "  1. Clone wiki: git clone https://github.com/${GITHUB_REPO}.wiki.git" >&2
            echo "  2. Create file: ${title// /-}.md" >&2
            echo "  3. Commit and push" >&2
            return 1
            ;;
        none)
            echo "[ERROR] No wiki provider configured (roles.wiki not set)" >&2
            return 1
            ;;
        *)
            echo "[ERROR] Unknown wiki provider: $provider" >&2
            return 1
            ;;
    esac
}

# Update wiki page
# Usage: unified_wiki_update <SLUG> --content <TEXT>
unified_wiki_update() {
    local slug="$1"
    local content="$2"
    local title="$3"

    if [[ -z "$slug" ]]; then
        echo "[ERROR] Wiki slug required" >&2
        return 1
    fi

    if [[ -z "$content" ]]; then
        echo "[ERROR] Content required" >&2
        return 1
    fi

    local provider
    provider=$(get_wiki_provider)

    case "$provider" in
        gitlab)
            gitlab_wiki_update "$slug" "$content" "$title"
            ;;
        github)
            echo "[WARN] GitHub Wiki is managed via separate Git repository" >&2
            echo "[INFO] To update a wiki page:" >&2
            echo "  1. Clone wiki: git clone https://github.com/${GITHUB_REPO}.wiki.git" >&2
            echo "  2. Edit file: ${slug}.md" >&2
            echo "  3. Commit and push" >&2
            return 1
            ;;
        none)
            echo "[ERROR] No wiki provider configured (roles.wiki not set)" >&2
            return 1
            ;;
        *)
            echo "[ERROR] Unknown wiki provider: $provider" >&2
            return 1
            ;;
    esac
}

# Delete wiki page
# Usage: unified_wiki_delete <SLUG>
unified_wiki_delete() {
    local slug="$1"

    if [[ -z "$slug" ]]; then
        echo "[ERROR] Wiki slug required" >&2
        return 1
    fi

    local provider
    provider=$(get_wiki_provider)

    case "$provider" in
        gitlab)
            gitlab_wiki_delete "$slug"
            ;;
        github)
            echo "[WARN] GitHub Wiki is managed via separate Git repository" >&2
            echo "[INFO] To delete a wiki page:" >&2
            echo "  1. Clone wiki: git clone https://github.com/${GITHUB_REPO}.wiki.git" >&2
            echo "  2. Delete file: rm ${slug}.md" >&2
            echo "  3. Commit and push" >&2
            return 1
            ;;
        none)
            echo "[ERROR] No wiki provider configured (roles.wiki not set)" >&2
            return 1
            ;;
        *)
            echo "[ERROR] Unknown wiki provider: $provider" >&2
            return 1
            ;;
    esac
}
