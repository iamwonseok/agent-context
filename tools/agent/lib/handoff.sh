#!/bin/bash
# handoff.sh - Lightweight branch handoff notes

# Convert branch name to a safe filename fragment.
# Git branch names often contain '/', which cannot be used in filenames.
handoff_safe_branch_name() {
    local branch="$1"
    # Replace path separators with a stable token.
    echo "${branch//\//__}"
}

# Build handoff note file path for a branch.
handoff_file_path() {
    local project_root="$1"
    local branch="$2"

    local safe
    safe="$(handoff_safe_branch_name "$branch")"
    echo "${project_root}/.context/handoff-${safe}.md"
}

handoff_is_branch_eligible() {
    local branch="$1"
    [[ -n "$branch" ]] && [[ "$branch" != "HEAD" ]] && [[ "$branch" != "(detached)" ]]
}

handoff_archive_dir() {
    local project_root="$1"
    echo "${project_root}/.context/handoff-archive"
}

handoff_archive_file_path() {
    local project_root="$1"
    local branch="$2"

    local safe
    safe="$(handoff_safe_branch_name "$branch")"

    local timestamp
    timestamp=$(date -u +"%Y%m%dT%H%M%SZ")

    echo "$(handoff_archive_dir "$project_root")/handoff-${safe}-${timestamp}.md"
}

handoff_archive_file() {
    local project_root="$1"
    local branch="$2"
    local file="$3"

    mkdir -p "$(handoff_archive_dir "$project_root")"

    local dest
    dest="$(handoff_archive_file_path "$project_root" "$branch")"

    # Best-effort move. If it fails (e.g., cross-device), fall back to copy+remove.
    if mv "$file" "$dest" 2>/dev/null; then
        return 0
    fi

    cp "$file" "$dest" 2>/dev/null || return 0
    rm -f "$file" 2>/dev/null || true
}

# Prompt user to write a handoff note for the given branch.
handoff_save_interactive() {
    local project_root="$1"
    local branch="$2"

    if ! handoff_is_branch_eligible "$branch"; then
        return 0
    fi

    local file
    file="$(handoff_file_path "$project_root" "$branch")"

    echo ""
    read -p "Create/update a handoff note for '$branch' before switching? [y/N] " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        return 0
    fi

    mkdir -p "$project_root/.context"

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    if [[ -f "$file" ]]; then
        echo "[INFO] Handoff file already exists: $(basename "$file")"
        read -p "Overwrite it? [y/N] " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            echo "[INFO] Keeping existing handoff note."
            return 0
        fi
    fi

    cat > "$file" << EOF
# Handoff: ${branch}

Saved: ${timestamp}

## Where I left off

- TODO

## What remains

- TODO

## Notes

- TODO
EOF

    if [[ -n "${EDITOR:-}" ]]; then
        echo ""
        read -p "Open in editor now? [Y/n] " open_response
        if [[ ! "$open_response" =~ ^[Nn]$ ]]; then
            "$EDITOR" "$file" || true
        fi
    else
        echo ""
        echo "[INFO] EDITOR is not set. Edit the file manually if needed:"
        echo "       $file"
    fi
}

# Display and remove a handoff note if it exists for the given branch.
handoff_show_and_cleanup() {
    local project_root="$1"
    local branch="$2"

    if ! handoff_is_branch_eligible "$branch"; then
        return 0
    fi

    local file_new
    file_new="$(handoff_file_path "$project_root" "$branch")"
    if [[ ! -f "$file_new" ]]; then
        return 0
    fi

    echo ""
    echo "=================================================="
    echo "Handoff note for branch: $branch"
    echo "File: $(basename "$file_new")"
    echo "=================================================="
    cat "$file_new"
    echo "=================================================="
    handoff_archive_file "$project_root" "$branch" "$file_new" || true
}

# Developer command: agent dev handoff <save|show> [branch]
dev_handoff() {
    local action="${1:-}"
    local branch="${2:-}"

    local project_root
    project_root=$(find_project_root) || return 1

    if [[ -z "$branch" ]]; then
        branch=$(get_current_branch 2>/dev/null) || branch=""
    fi

    case "$action" in
        save)
            handoff_save_interactive "$project_root" "$branch"
            ;;
        show)
            handoff_show_and_cleanup "$project_root" "$branch"
            ;;
        help|--help|-h|"")
            echo "Usage: agent dev handoff <save|show> [branch]"
            echo ""
            echo "Examples:"
            echo "  agent dev handoff save"
            echo "  agent dev handoff show"
            echo "  agent dev handoff show feat/TASK-123"
            ;;
        *)
            echo "[ERROR] Unknown handoff action: $action" >&2
            echo "Usage: agent dev handoff <save|show> [branch]" >&2
            return 1
            ;;
    esac
}

