#!/bin/bash
# Agent-Context Update Command
# Update agent-context source repository (like `brew update`)
#
# Usage:
#   agent-context update [options]
#   agent-context up [options]
#
# This script is sourced by bin/agent-context.sh

# ============================================================
# Usage
# ============================================================
update_usage() {
	cat <<EOF
Agent-Context Update

USAGE:
    agent-context update [options]
    agent-context up [options]

OPTIONS:
    --check         Check for updates without applying
    --force         Force update even with local changes (stash)
    -v, --verbose   Show git output
    -q, --quiet     Show only summary
    -h, --help      Show this help

DESCRIPTION:
    Update the agent-context source repository (~/.agent-context).
    This is similar to 'brew update' - it updates the formula list,
    not the installed packages.

    By default, this command will abort if there are uncommitted
    local changes to prevent losing work.

EXAMPLES:
    # Check for available updates
    agent-context update --check

    # Update to latest
    agent-context update

    # Force update (stash local changes)
    agent-context update --force

EXIT CODES:
    0   Update successful (or already up-to-date)
    1   Update failed (dirty tree, merge conflict, etc.)

EOF
}

# ============================================================
# Main Update Function
# ============================================================
run_update() {
	local check_only=false
	local force=false
	local verbose=false
	local quiet=false

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--check)
				check_only=true
				;;
			--force)
				force=true
				;;
			-v|--verbose)
				verbose=true
				;;
			-q|--quiet)
				quiet=true
				;;
			-h|--help)
				update_usage
				return 0
				;;
			*)
				log_error "Unknown option: $1"
				update_usage
				return 2
				;;
		esac
		shift
	done

	local ac_dir
	ac_dir=$(get_agent_context_dir)

	if [[ ! -d "${ac_dir}" ]]; then
		log_error "Agent-context not installed: ${ac_dir}"
		return 1
	fi

	if [[ ! -d "${ac_dir}/.git" ]]; then
		log_error "Not a git repository: ${ac_dir}"
		return 1
	fi

	if [[ "${quiet}" == "false" ]]; then
		log_header "Agent-Context Update"
		log_info "Repository: ${ac_dir}"
	fi

	# Check for uncommitted changes
	local is_dirty=false
	if ! git -C "${ac_dir}" diff --quiet 2>/dev/null || \
	   ! git -C "${ac_dir}" diff --cached --quiet 2>/dev/null; then
		is_dirty=true
	fi

	if [[ "${is_dirty}" == "true" ]]; then
		if [[ "${force}" == "true" ]]; then
			log_warn "Local changes detected, stashing..."
			git -C "${ac_dir}" stash push -m "agent-context update $(date +%Y%m%d-%H%M%S)" 2>/dev/null
		else
			log_error "Uncommitted local changes detected"
			log_info "Options:"
			log_info "  1. Commit or stash your changes first"
			log_info "  2. Use --force to auto-stash"
			echo ""
			git -C "${ac_dir}" status --short
			return 1
		fi
	fi

	# Fetch latest
	if [[ "${quiet}" == "false" ]]; then
		log_progress "Fetching latest changes..."
	fi

	if [[ "${verbose}" == "true" ]]; then
		git -C "${ac_dir}" fetch --all
	else
		git -C "${ac_dir}" fetch --all --quiet 2>/dev/null
	fi

	# Check if updates available
	local local_ref
	local remote_ref
	local_ref=$(git -C "${ac_dir}" rev-parse HEAD 2>/dev/null)
	remote_ref=$(git -C "${ac_dir}" rev-parse '@{u}' 2>/dev/null || echo "")

	if [[ -z "${remote_ref}" ]]; then
		log_warn "No upstream branch configured"
		return 0
	fi

	if [[ "${local_ref}" == "${remote_ref}" ]]; then
		if [[ "${quiet}" == "false" ]]; then
			log_ok "Already up-to-date"
		fi
		echo "Summary: total=1 passed=1 failed=0 warned=0 skipped=0"
		return 0
	fi

	# Show what would be updated
	local behind_count
	behind_count=$(git -C "${ac_dir}" rev-list --count HEAD..@{u} 2>/dev/null || echo "0")

	if [[ "${quiet}" == "false" ]]; then
		log_info "Updates available: ${behind_count} commit(s) behind"
	fi

	if [[ "${check_only}" == "true" ]]; then
		if [[ "${verbose}" == "true" ]]; then
			echo ""
			git -C "${ac_dir}" log --oneline HEAD..@{u}
		fi
		echo "Summary: total=1 passed=0 failed=0 warned=1 skipped=0"
		return 0
	fi

	# Pull updates
	if [[ "${quiet}" == "false" ]]; then
		log_progress "Pulling updates..."
	fi

	local pull_result=0
	if [[ "${verbose}" == "true" ]]; then
		git -C "${ac_dir}" pull --ff-only || pull_result=$?
	else
		git -C "${ac_dir}" pull --ff-only --quiet 2>/dev/null || pull_result=$?
	fi

	if [[ ${pull_result} -ne 0 ]]; then
		log_error "Pull failed (merge conflict or not fast-forward)"
		log_info "Manual intervention required:"
		log_info "  cd ${ac_dir}"
		log_info "  git status"
		echo "Summary: total=1 passed=0 failed=1 warned=0 skipped=0"
		return 1
	fi

	if [[ "${quiet}" == "false" ]]; then
		log_ok "Updated successfully"
		local new_ref
		new_ref=$(git -C "${ac_dir}" rev-parse --short HEAD 2>/dev/null)
		log_info "Now at: ${new_ref}"
	fi

	echo "Summary: total=1 passed=1 failed=0 warned=0 skipped=0"
	return 0
}

# Allow direct execution for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
	source "${SCRIPT_DIR}/lib/logging.sh"
	source "${SCRIPT_DIR}/lib/platform.sh"
	run_update "$@"
fi
