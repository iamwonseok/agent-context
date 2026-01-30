#!/bin/bash
# Hook: beforeSubmitPrompt
# Called before user prompt is submitted
# Purpose: Sync .context via symlink in worktree

set -e

# Read JSON input from stdin
INPUT=$(cat)

# ============================================================
# Helper Functions
# ============================================================

get_main_worktree_path() {
	local git_common_dir
	git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)

	if [[ "${git_common_dir}" == ".git" ]]; then
		# This is main worktree
		pwd
	else
		# This is a linked worktree - git_common_dir is like /path/to/main/.git
		dirname "${git_common_dir}"
	fi
}

setup_context_symlink() {
	local main_path
	main_path=$(get_main_worktree_path)

	# Ensure .context exists in main worktree
	if [[ ! -d "${main_path}/.context" ]]; then
		mkdir -p "${main_path}/.context"
	fi

	# Create symlink in ALL linked worktrees
	while IFS= read -r worktree_line; do
		# Parse worktree path (first field)
		local worktree_path
		worktree_path=$(echo "${worktree_line}" | awk '{print $1}')

		# Skip if empty
		[[ -z "${worktree_path}" ]] && continue

		# Skip main worktree
		[[ "${worktree_path}" == "${main_path}" ]] && continue

		# Skip if already a symlink
		[[ -L "${worktree_path}/.context" ]] && continue

		# Remove existing directory if not a symlink
		if [[ -d "${worktree_path}/.context" ]]; then
			if [[ "$(ls -A "${worktree_path}/.context" 2>/dev/null)" ]]; then
				mv "${worktree_path}/.context" \
					"${worktree_path}/.context.backup.$(date +%Y%m%d%H%M%S)"
			else
				rmdir "${worktree_path}/.context"
			fi
		fi

		# Create symlink
		ln -s "${main_path}/.context" "${worktree_path}/.context"
	done < <(git worktree list 2>/dev/null)
}

# ============================================================
# Main Logic
# ============================================================

# Step 1: Setup .context symlink for worktree
setup_context_symlink
: "${INPUT}"

# Allow prompt to continue
cat << 'EOF'
{
  "continue": true
}
EOF
