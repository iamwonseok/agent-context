#!/bin/bash
# Agent-Context Upgrade Command
# Upgrade installed project (like `brew upgrade`)
#
# Usage:
#   agent-context upgrade [options]
#
# This script is sourced by bin/agent-context.sh

# ============================================================
# Usage
# ============================================================
upgrade_usage() {
	cat <<EOF
Agent-Context Upgrade

USAGE:
    agent-context upgrade [options]

OPTIONS:
    --apply         Apply changes (default: diff-only)
    --prune         Remove files no longer in source (requires --apply)
    --dry-run       Show what would change (same as default)
    -v, --verbose   Show detailed diff
    -q, --quiet     Show only summary
    -h, --help      Show this help

DESCRIPTION:
    Upgrade project installation (.agent/) to match the latest source.
    This is similar to 'brew upgrade' - it upgrades installed packages.

    By default, this command only shows what would change (diff-only).
    Use --apply to actually make changes.
    Use --apply --prune to also remove obsolete files.

EXAMPLES:
    # Preview changes (default)
    agent-context upgrade

    # Apply changes
    agent-context upgrade --apply

    # Apply changes and remove obsolete files
    agent-context upgrade --apply --prune

EXIT CODES:
    0   Upgrade successful (or no changes needed)
    1   Upgrade failed

EOF
}

# ============================================================
# Main Upgrade Function
# ============================================================
run_upgrade() {
	local apply=false
	local prune=false
	local dry_run=false
	local verbose=false
	local quiet=false

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--apply)
				apply=true
				;;
			--prune)
				prune=true
				;;
			--dry-run)
				dry_run=true
				;;
			-v|--verbose)
				verbose=true
				;;
			-q|--quiet)
				quiet=true
				;;
			-h|--help)
				upgrade_usage
				return 0
				;;
			*)
				log_error "Unknown option: $1"
				upgrade_usage
				return 2
				;;
		esac
		shift
	done

	# --prune requires --apply
	if [[ "${prune}" == "true" ]] && [[ "${apply}" == "false" ]]; then
		log_error "--prune requires --apply"
		return 1
	fi

	# Find project root
	local project_root
	project_root=$(find_project_root "${PWD}" 2>/dev/null || true)

	if [[ -z "${project_root}" ]]; then
		log_error "Not in a project directory"
		return 1
	fi

	local ac_dir
	ac_dir=$(get_agent_context_dir)

	if [[ ! -d "${ac_dir}" ]]; then
		log_error "Agent-context not installed: ${ac_dir}"
		return 1
	fi

	if [[ "${quiet}" == "false" ]]; then
		log_header "Agent-Context Upgrade"
		log_info "Source: ${ac_dir}"
		log_info "Target: ${project_root}"
	fi

	local total=0
	local updated=0
	local added=0
	local removed=0
	local unchanged=0

	# Compare and upgrade .agent/ contents
	local agent_dirs=("skills" "workflows" "docs" "tools/pm")

	for dir in "${agent_dirs[@]}"; do
		local src="${ac_dir}/${dir}"
		local dst="${project_root}/.agent/${dir}"

		if [[ ! -d "${src}" ]]; then
			continue
		fi

		# Find all files in source
		while IFS= read -r -d '' src_file; do
			total=$((total + 1))
			local rel_path="${src_file#${src}/}"
			local dst_file="${dst}/${rel_path}"

			if [[ ! -f "${dst_file}" ]]; then
				# New file
				added=$((added + 1))
				if [[ "${quiet}" == "false" ]]; then
					log_info "[+] .agent/${dir}/${rel_path}"
				fi
				if [[ "${apply}" == "true" ]]; then
					mkdir -p "$(dirname "${dst_file}")"
					cp "${src_file}" "${dst_file}"
				fi
			elif ! diff -q "${src_file}" "${dst_file}" >/dev/null 2>&1; then
				# Modified
				updated=$((updated + 1))
				if [[ "${quiet}" == "false" ]]; then
					log_info "[~] .agent/${dir}/${rel_path}"
				fi
				if [[ "${verbose}" == "true" ]]; then
					diff -u "${dst_file}" "${src_file}" | head -20 || true
				fi
				if [[ "${apply}" == "true" ]]; then
					cp "${src_file}" "${dst_file}"
				fi
			else
				# Unchanged
				unchanged=$((unchanged + 1))
			fi
		done < <(find "${src}" -type f -print0 2>/dev/null)

		# Find files to prune (in dst but not in src)
		if [[ "${prune}" == "true" ]] && [[ -d "${dst}" ]]; then
			while IFS= read -r -d '' dst_file; do
				local rel_path="${dst_file#${dst}/}"
				local src_file="${src}/${rel_path}"

				if [[ ! -f "${src_file}" ]]; then
					removed=$((removed + 1))
					if [[ "${quiet}" == "false" ]]; then
						log_warn "[-] .agent/${dir}/${rel_path}"
					fi
					if [[ "${apply}" == "true" ]]; then
						rm -f "${dst_file}"
					fi
				fi
			done < <(find "${dst}" -type f -print0 2>/dev/null)
		fi
	done

	# Summary
	if [[ "${quiet}" == "false" ]]; then
		echo ""
		if [[ "${apply}" == "true" ]]; then
			log_ok "Upgrade applied"
		else
			log_info "Upgrade preview (use --apply to apply)"
		fi
		echo ""
		echo "Changes: ${added} added, ${updated} modified, ${removed} removed, ${unchanged} unchanged"
	fi

	echo "Summary: total=${total} passed=$((added + updated)) failed=0 warned=${removed} skipped=${unchanged}"
	return 0
}

# Allow direct execution for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
	source "${SCRIPT_DIR}/lib/logging.sh"
	source "${SCRIPT_DIR}/lib/platform.sh"
	run_upgrade "$@"
fi
