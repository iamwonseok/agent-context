#!/bin/bash
# Pre-push hook: check all pushed commits are signed.
#
# This hook checks that each commit to be pushed contains a signature payload
# (gpgsig header). It does NOT attempt to verify trust locally.
#
# NOTE:
# - GitLab push rules may require commits to be signed and verified server-side.
# - If a commit has no signature payload, it will always be rejected when
#   "Reject unsigned commits" is enabled.

set -e
set -o pipefail

# ============================================================
# Logging
# ============================================================
if [[ -t 1 ]]; then
	RED='\033[0;31m'
	GREEN='\033[0;32m'
	YELLOW='\033[1;33m'
	BLUE='\033[0;34m'
	NC='\033[0m'
else
	RED=''
	GREEN=''
	YELLOW=''
	BLUE=''
	NC=''
fi

log_info() {
	echo -e "${BLUE}[i]${NC} $1"
}

log_ok() {
	echo -e "${GREEN}[V]${NC} $1"
}

log_warn() {
	echo -e "${YELLOW}[!]${NC} $1" >&2
}

log_error() {
	echo -e "${RED}[X]${NC} $1" >&2
}

usage() {
	cat <<EOF
Check signed commits (pre-push)

This hook reads ref updates from stdin (git pre-push format) and checks that
all commits being pushed contain a signature payload (gpgsig header).

EOF
}

is_all_zeros_sha() {
	local sha="$1"
	[[ "${sha}" =~ ^0{40}$ ]]
}

list_commits_to_push() {
	local remote_name="$1"
	local local_sha="$2"
	local remote_sha="$3"

	if is_all_zeros_sha "${local_sha}"; then
		return 0
	fi

	if is_all_zeros_sha "${remote_sha}"; then
		# New ref. Avoid scanning entire history by excluding commits already present
		# in remote-tracking branches when possible.
		if [[ -n "${remote_name}" ]]; then
			git rev-list "${local_sha}" --not --remotes="${remote_name}" 2>/dev/null || \
				git rev-list "${local_sha}" --not --remotes 2>/dev/null || true
		else
			git rev-list "${local_sha}" --not --remotes 2>/dev/null || true
		fi
	else
		git rev-list "${remote_sha}..${local_sha}" 2>/dev/null || true
	fi
}

commit_has_signature_payload() {
	local sha="$1"
	git cat-file -p "${sha}" 2>/dev/null | grep -q '^gpgsig '
}

main() {
	if ! command -v git &>/dev/null; then
		log_error "git not found"
		exit 1
	fi

	local remote_name="${1:-}"
	local remote_url="${2:-}"
	: "${remote_url:=}"

	local any_input=false
	local total_checked=0
	local unsigned=()

	while IFS=$' \t' read -r local_ref local_sha remote_ref remote_sha; do
		# Ignore empty stdin
		if [[ -z "${local_ref}" ]] && [[ -z "${local_sha}" ]] && [[ -z "${remote_ref}" ]] && [[ -z "${remote_sha}" ]]; then
			continue
		fi

		any_input=true

		# Deleting a remote ref: nothing to check
		if is_all_zeros_sha "${local_sha}"; then
			continue
		fi

		local commits
		commits=$(list_commits_to_push "${remote_name}" "${local_sha}" "${remote_sha}")
		if [[ -z "${commits}" ]]; then
			continue
		fi

		local sha
		while IFS= read -r sha; do
			[[ -z "${sha}" ]] && continue
			((total_checked++)) || true
			if ! commit_has_signature_payload "${sha}"; then
				unsigned+=("${sha}")
			fi
		done <<< "${commits}"
	done

	if [[ "${any_input}" != "true" ]]; then
		log_info "No ref updates detected on stdin. Skipping signed commit check."
		return 0
	fi

	if [[ ${#unsigned[@]} -gt 0 ]]; then
		log_error "Unsigned commit(s) detected in push range: ${#unsigned[@]}"
		for sha in "${unsigned[@]}"; do
			log_error "  - ${sha}"
		done

		echo ""
		log_info "Fix options:"
		log_info "  - Sign new commits: git commit -S -m \"message\""
		log_info "  - Sign the last commit: git commit --amend --no-edit -S"
		log_info "  - Sign a range (rewrites history): git rebase <base> --exec 'git commit --amend --no-edit -S'"
		echo ""
		log_info "For SSH signing on GitLab:"
		log_info "  - Ensure your SSH public key is added to GitLab with usage type 'Signing' or 'Authentication & Signing'"
		log_info "  - Ensure commit email matches a verified email on your GitLab account"
		exit 1
	fi

	log_ok "All pushed commits contain signature payload (checked: ${total_checked})"
}

main "$@"
