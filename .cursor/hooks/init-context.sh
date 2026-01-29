#!/bin/bash
# Hook: sessionStart
# Called when a new composer conversation is created
# Purpose: Initialize .context directory in main worktree

set -e

# Consume stdin (required by hook protocol)
cat > /dev/null

# Get main worktree path
get_main_worktree_path() {
    local git_common_dir
    git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)

    if [[ "$git_common_dir" == ".git" ]]; then
        # This is main worktree
        pwd
    else
        # This is a linked worktree - git_common_dir is like /path/to/main/.git
        dirname "$git_common_dir"
    fi
}

# Initialize .context in main worktree
MAIN_WORKTREE=$(get_main_worktree_path)
CONTEXT_DIR="$MAIN_WORKTREE/.context"

if [[ ! -d "$CONTEXT_DIR" ]]; then
    mkdir -p "$CONTEXT_DIR"
fi

# Output minimal JSON (no env vars needed)
cat << 'EOF'
{
  "continue": true
}
EOF
