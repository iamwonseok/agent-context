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
    --rollback      Restore from last backup (undo --apply)
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

BACKUP & ROLLBACK:
    When --apply is used, a backup is created at .agent/.backup/
    If something goes wrong, use --rollback to restore.
    Only one generation of backup is kept (previous backup is overwritten).

EXAMPLES:
    # Preview changes (default)
    agent-context upgrade

    # Apply changes
    agent-context upgrade --apply

    # Apply changes and remove obsolete files
    agent-context upgrade --apply --prune

    # Restore from backup if something went wrong
    agent-context upgrade --rollback

EXIT CODES:
    0   Upgrade successful (or no changes needed)
    1   Upgrade failed

EOF
}

# ============================================================
# Backup and Rollback Functions
# ============================================================

BACKUP_DIR_NAME=".backup"

create_backup() {
	local project_root="$1"
	local agent_dir="${project_root}/.agent"
	local backup_dir="${agent_dir}/${BACKUP_DIR_NAME}"

	if [[ ! -d "${agent_dir}" ]]; then
		log_error "No .agent directory to backup"
		return 1
	fi

	# Remove old backup (only keep one generation)
	if [[ -d "${backup_dir}" ]]; then
		rm -rf "${backup_dir}"
	fi

	mkdir -p "${backup_dir}"

	# Backup directories
	local dirs_to_backup=("skills" "workflows" "docs" "tools")
	for dir in "${dirs_to_backup[@]}"; do
		if [[ -d "${agent_dir}/${dir}" ]]; then
			cp -r "${agent_dir}/${dir}" "${backup_dir}/${dir}"
		fi
	done

	# Create timestamp file
	echo "backup_time=$(date -Iseconds)" > "${backup_dir}/.backup_info"
	echo "backup_version=$(git -C "$(get_agent_context_dir)" rev-parse --short HEAD 2>/dev/null || echo 'unknown')" >> "${backup_dir}/.backup_info"

	log_ok "Backup created: ${backup_dir}"
	return 0
}

restore_backup() {
	local project_root="$1"
	local agent_dir="${project_root}/.agent"
	local backup_dir="${agent_dir}/${BACKUP_DIR_NAME}"

	if [[ ! -d "${backup_dir}" ]]; then
		log_error "No backup found at ${backup_dir}"
		return 1
	fi

	# Show backup info
	if [[ -f "${backup_dir}/.backup_info" ]]; then
		log_info "Restoring from backup:"
		cat "${backup_dir}/.backup_info" | while read -r line; do
			log_info "  ${line}"
		done
	fi

	# Restore directories
	local dirs_to_restore=("skills" "workflows" "docs" "tools")
	local restored=0

	for dir in "${dirs_to_restore[@]}"; do
		if [[ -d "${backup_dir}/${dir}" ]]; then
			# Remove current
			if [[ -d "${agent_dir:?}/${dir}" ]]; then
				rm -rf "${agent_dir:?}/${dir}"
			fi
			# Restore from backup
			cp -r "${backup_dir}/${dir}" "${agent_dir}/${dir}"
			log_ok "Restored: .agent/${dir}/"
			restored=$((restored + 1))
		fi
	done

	if [[ ${restored} -eq 0 ]]; then
		log_warn "No directories restored (empty backup?)"
		return 1
	fi

	log_ok "Rollback complete: ${restored} directories restored"
	return 0
}

# ============================================================
# Main Upgrade Function
# ============================================================
run_upgrade() {
	local apply=false
	local prune=false
	local rollback=false
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
			--rollback)
				rollback=true
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

	# Find project root first (needed for rollback too)
	local project_root
	project_root=$(find_project_root "${PWD}" 2>/dev/null || true)

	if [[ -z "${project_root}" ]]; then
		log_error "Not in a project directory"
		return 1
	fi

	# Handle rollback
	if [[ "${rollback}" == "true" ]]; then
		log_header "Agent-Context Rollback"
		log_info "Project: ${project_root}"
		restore_backup "${project_root}"
		return $?
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
	local backup_created=false

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
					# Create backup before first change
					if [[ "${backup_created}" == "false" ]]; then
						if create_backup "${project_root}"; then
							backup_created=true
						else
							log_error "Failed to create backup, aborting"
							return 1
						fi
					fi
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
					# Create backup before first change
					if [[ "${backup_created}" == "false" ]]; then
						if create_backup "${project_root}"; then
							backup_created=true
						else
							log_error "Failed to create backup, aborting"
							return 1
						fi
					fi
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

				# Skip backup directory
				if [[ "${rel_path}" == "${BACKUP_DIR_NAME}"* ]]; then
					continue
				fi

				if [[ ! -f "${src_file}" ]]; then
					removed=$((removed + 1))
					if [[ "${quiet}" == "false" ]]; then
						log_warn "[-] .agent/${dir}/${rel_path}"
					fi
					if [[ "${apply}" == "true" ]]; then
						# Create backup before first change
						if [[ "${backup_created}" == "false" ]]; then
							if create_backup "${project_root}"; then
								backup_created=true
							else
								log_error "Failed to create backup, aborting"
								return 1
							fi
						fi
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
			if [[ "${backup_created}" == "true" ]]; then
				log_info "Backup saved to: .agent/${BACKUP_DIR_NAME}/"
				log_info "To rollback: agent-context upgrade --rollback"
			fi
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
