#!/bin/bash
# Jira Synchronization Library for AITL Demo
# Provides state transition and blocker link management functions
#
# This library is sourced by demo.sh and provides:
#   - State transition helpers
#   - Blocker link management
#   - GitLab-Jira synchronization

# Ensure pm CLI path is set
: "${PM_CMD:=${PROJECT_ROOT}/tools/pm/bin/pm}"

# State constants (Jira basic workflow)
readonly STATE_TODO="To Do"
readonly STATE_IN_PROGRESS="In Progress"
readonly STATE_DONE="Done"
readonly STATE_ON_HOLD="On Hold"

# Link type constants
readonly LINK_BLOCKS="Blocks"
readonly LINK_RELATES="Relates"
readonly LINK_DUPLICATE="Duplicate"

# Transition issue to new state
# Returns 0 on success, 1 on failure (transition may not be available)
jira_transition() {
	local issue_key="$1"
	local target_state="$2"

	if [[ -z "${issue_key}" ]] || [[ -z "${target_state}" ]]; then
		log_error "Usage: jira_transition <issue_key> <target_state>"
		return 1
	fi

	log_info "Transitioning ${issue_key} to ${target_state}..."

	if ${PM_CMD} jira issue transition "${issue_key}" "${target_state}" 2>/dev/null; then
		log_ok "${issue_key} -> ${target_state}"
		return 0
	else
		log_warn "Transition to ${target_state} not available for ${issue_key}"
		return 1
	fi
}

# Start work on an issue
# Transitions to In Progress and optionally creates GitLab branch
jira_start_work() {
	local issue_key="$1"
	local create_branch="${2:-false}"

	if [[ -z "${issue_key}" ]]; then
		log_error "Usage: jira_start_work <issue_key> [create_branch]"
		return 1
	fi

	# Transition to In Progress
	jira_transition "${issue_key}" "${STATE_IN_PROGRESS}"

	# Optionally create branch
	if [[ "${create_branch}" == "true" ]]; then
		local summary
		summary=$(${PM_CMD} jira issue view "${issue_key}" 2>/dev/null | \
			grep "Summary:" | sed 's/Summary:[[:space:]]*//')

		if [[ -n "${summary}" ]]; then
			local slug
			slug=$(echo "${summary}" | tr '[:upper:]' '[:lower:]' | \
				tr ' ' '-' | tr -cd '[:alnum:]-' | cut -c1-40)

			local branch="feat/${issue_key}-${slug}"
			log_info "Suggested branch: ${branch}"

			if command -v git &>/dev/null; then
				git checkout -b "${branch}" 2>/dev/null || \
					log_warn "Could not create branch (may already exist)"
			fi
		fi
	fi
}

# Complete work on an issue
# Transitions to Done
jira_complete_work() {
	local issue_key="$1"

	if [[ -z "${issue_key}" ]]; then
		log_error "Usage: jira_complete_work <issue_key>"
		return 1
	fi

	jira_transition "${issue_key}" "${STATE_DONE}"
}

# Put issue on hold (for blocker scenarios)
# Falls back to staying In Progress if On Hold is not available
jira_hold_work() {
	local issue_key="$1"
	local reason="$2"

	if [[ -z "${issue_key}" ]]; then
		log_error "Usage: jira_hold_work <issue_key> [reason]"
		return 1
	fi

	# Try On Hold first
	if jira_transition "${issue_key}" "${STATE_ON_HOLD}"; then
		return 0
	fi

	# Fallback: add comment and stay In Progress
	if [[ -n "${reason}" ]]; then
		log_info "Adding hold comment to ${issue_key}..."
		# Note: pm CLI may not support comments yet
	fi

	log_warn "${issue_key} remains In Progress (On Hold not available)"
	return 0
}

# Create blocker link between two issues
# BLOCKED_KEY is blocked by BLOCKER_KEY
jira_create_blocker() {
	local blocked_key="$1"
	local blocker_key="$2"

	if [[ -z "${blocked_key}" ]] || [[ -z "${blocker_key}" ]]; then
		log_error "Usage: jira_create_blocker <blocked_key> <blocker_key>"
		return 1
	fi

	log_info "Creating blocker link: ${blocked_key} is blocked by ${blocker_key}"

	if ${PM_CMD} jira link create "${blocked_key}" "${blocker_key}" "${LINK_BLOCKS}" 2>/dev/null; then
		log_ok "Blocker link created"
		return 0
	else
		log_error "Failed to create blocker link"
		return 1
	fi
}

# View existing links for an issue
jira_view_links() {
	local issue_key="$1"

	if [[ -z "${issue_key}" ]]; then
		log_error "Usage: jira_view_links <issue_key>"
		return 1
	fi

	${PM_CMD} jira link view "${issue_key}"
}

# Handle hotfix scenario
# - Puts current work on hold
# - Creates blocker link
# - Starts hotfix work
jira_handle_hotfix() {
	local current_key="$1"
	local hotfix_key="$2"

	if [[ -z "${current_key}" ]] || [[ -z "${hotfix_key}" ]]; then
		log_error "Usage: jira_handle_hotfix <current_key> <hotfix_key>"
		return 1
	fi

	log_info "Handling hotfix scenario..."
	log_info "  Current work: ${current_key}"
	log_info "  Hotfix:       ${hotfix_key}"

	# Step 1: Create blocker link
	jira_create_blocker "${current_key}" "${hotfix_key}"

	# Step 2: Hold current work
	jira_hold_work "${current_key}" "Blocked by hotfix ${hotfix_key}"

	# Step 3: Stash git changes (if in git repo)
	if git rev-parse --git-dir &>/dev/null; then
		if git diff --quiet && git diff --cached --quiet; then
			log_info "No uncommitted changes to stash"
		else
			log_info "Stashing current changes..."
			git stash push -m "WIP: ${current_key} - blocked by ${hotfix_key}"
			log_ok "Changes stashed"
		fi
	fi

	# Step 4: Start hotfix work
	jira_start_work "${hotfix_key}" "true"

	log_ok "Hotfix scenario handled. Working on ${hotfix_key}"
}

# Resume work after hotfix
# - Completes hotfix
# - Returns to original work
jira_resume_after_hotfix() {
	local hotfix_key="$1"
	local original_key="$2"

	if [[ -z "${hotfix_key}" ]] || [[ -z "${original_key}" ]]; then
		log_error "Usage: jira_resume_after_hotfix <hotfix_key> <original_key>"
		return 1
	fi

	log_info "Resuming work after hotfix..."

	# Step 1: Complete hotfix
	jira_complete_work "${hotfix_key}"

	# Step 2: Pop stashed changes
	if git rev-parse --git-dir &>/dev/null; then
		local stash_entry
		stash_entry=$(git stash list | grep "${original_key}" | head -1 | cut -d: -f1)

		if [[ -n "${stash_entry}" ]]; then
			log_info "Restoring stashed changes for ${original_key}..."
			git stash pop "${stash_entry}" 2>/dev/null || \
				git stash pop 0 2>/dev/null || \
				log_warn "Could not pop stash automatically"
		fi
	fi

	# Step 3: Resume original work
	jira_start_work "${original_key}"

	log_ok "Resumed work on ${original_key}"
}

# Get current status of an issue
jira_get_status() {
	local issue_key="$1"

	if [[ -z "${issue_key}" ]]; then
		return 1
	fi

	${PM_CMD} jira issue view "${issue_key}" 2>/dev/null | \
		grep "Status:" | sed 's/Status:[[:space:]]*//'
}

# Check if issue is blocked
jira_is_blocked() {
	local issue_key="$1"

	if [[ -z "${issue_key}" ]]; then
		return 1
	fi

	local links
	links=$(${PM_CMD} jira link view "${issue_key}" 2>/dev/null)

	if echo "${links}" | grep -q "is blocked by"; then
		return 0
	fi

	return 1
}

# Get list of available transitions for an issue
jira_get_transitions() {
	local issue_key="$1"

	if [[ -z "${issue_key}" ]]; then
		log_error "Usage: jira_get_transitions <issue_key>"
		return 1
	fi

	${PM_CMD} jira workflow transitions "${issue_key}"
}

# Sync GitLab issue state with Jira
# This is a simplified version - full sync would require GitLab API calls
gitlab_sync_state() {
	local jira_key="$1"
	local gitlab_issue_id="$2"

	if [[ -z "${jira_key}" ]] || [[ -z "${gitlab_issue_id}" ]]; then
		log_error "Usage: gitlab_sync_state <jira_key> <gitlab_issue_id>"
		return 1
	fi

	local jira_status
	jira_status=$(jira_get_status "${jira_key}")

	log_info "Syncing GitLab #${gitlab_issue_id} with Jira ${jira_key} (${jira_status})"

	case "${jira_status}" in
		"${STATE_DONE}")
			log_info "Would close GitLab issue #${gitlab_issue_id}"
			# glab issue close "${gitlab_issue_id}"
			;;
		"${STATE_ON_HOLD}")
			log_info "Would add 'blocked' label to GitLab issue #${gitlab_issue_id}"
			# glab issue update "${gitlab_issue_id}" --label "blocked"
			;;
		*)
			log_info "GitLab issue remains open"
			;;
	esac
}

# Create a branch name from issue details
generate_branch_name() {
	local issue_key="$1"
	local issue_type="${2:-feat}"
	local summary="$3"

	if [[ -z "${issue_key}" ]]; then
		return 1
	fi

	# Get summary if not provided
	if [[ -z "${summary}" ]]; then
		summary=$(${PM_CMD} jira issue view "${issue_key}" 2>/dev/null | \
			grep "Summary:" | sed 's/Summary:[[:space:]]*//')
	fi

	# Create slug from summary
	local slug
	slug=$(echo "${summary}" | \
		tr '[:upper:]' '[:lower:]' | \
		tr ' ' '-' | \
		tr -cd '[:alnum:]-' | \
		cut -c1-40 | \
		sed 's/-$//')

	# Determine prefix based on type
	local prefix
	case "${issue_type}" in
		bug|fix)
			prefix="fix"
			;;
		hotfix)
			prefix="hotfix"
			;;
		*)
			prefix="feat"
			;;
	esac

	echo "${prefix}/${issue_key}-${slug}"
}

# Export functions
export -f jira_transition
export -f jira_start_work
export -f jira_complete_work
export -f jira_hold_work
export -f jira_create_blocker
export -f jira_view_links
export -f jira_handle_hotfix
export -f jira_resume_after_hotfix
export -f jira_get_status
export -f jira_is_blocked
export -f jira_get_transitions
export -f gitlab_sync_state
export -f generate_branch_name
