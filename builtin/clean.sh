#!/bin/bash
# Agent-Context Clean Command
# Clean project caches and logs
#
# Usage:
#   agent-context clean [options]
#
# This script is sourced by bin/agent-context.sh

# ============================================================
# Usage
# ============================================================
clean_usage() {
	cat <<EOF
Agent-Context Clean

USAGE:
    agent-context clean [options]

OPTIONS:
    --logs          Include logs in cleanup
    --global        Clean global logs (~/.local/state/agent-context/)
    --all           Clean all state data (requires --force)
    --force         Skip confirmation prompt
    --dry-run       Show what would be deleted without deleting
    -v, --verbose   Show detailed output
    -q, --quiet     Show only summary
    -h, --help      Show this help

DESCRIPTION:
    Clean up temporary files, caches, and logs created by agent-context.

    Default behavior: Clean .agent/state/* (excludes logs)
    With --logs: Also clean .agent/state/logs/
    With --global: Clean ~/.local/state/agent-context/
    With --all: Clean everything (requires --force for safety)

EXAMPLES:
    # Preview what would be cleaned
    agent-context clean --dry-run

    # Clean project state (safe)
    agent-context clean

    # Clean including logs
    agent-context clean --logs

    # Clean global state
    agent-context clean --global

    # Clean everything (destructive)
    agent-context clean --all --force

EXIT CODES:
    0   Clean successful
    1   Clean failed or aborted

EOF
}

# ============================================================
# Main Clean Function
# ============================================================
run_clean() {
	local include_logs=false
	local clean_global=false
	local clean_all=false
	local force=false
	local dry_run=false
	local verbose=false
	local quiet=false

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--logs)
				include_logs=true
				;;
			--global)
				clean_global=true
				;;
			--all)
				clean_all=true
				;;
			--force)
				force=true
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
				clean_usage
				return 0
				;;
			*)
				log_error "Unknown option: $1"
				clean_usage
				return 2
				;;
		esac
		shift
	done

	# Safety check for --all
	if [[ "${clean_all}" == "true" ]] && [[ "${force}" == "false" ]]; then
		log_error "--all requires --force (destructive operation)"
		return 1
	fi

	if [[ "${quiet}" == "false" ]]; then
		log_header "Agent-Context Clean"
	fi

	local total_cleaned=0
	local total_size=0
	local files_to_clean=()

	# Find project root
	local project_root
	project_root=$(find_project_root "${PWD}" 2>/dev/null || true)

	# Collect files to clean
	# 1. Project state (if in project)
	if [[ -n "${project_root}" ]]; then
		local state_dir="${project_root}/.agent/state"

		if [[ -d "${state_dir}" ]]; then
			if [[ "${clean_all}" == "true" ]] || [[ "${include_logs}" == "false" ]]; then
				# Clean everything except logs
				while IFS= read -r -d '' file; do
					if [[ "${include_logs}" == "false" ]] && [[ "${file}" == *"/logs/"* ]]; then
						continue
					fi
					files_to_clean+=("${file}")
				done < <(find "${state_dir}" -type f -print0 2>/dev/null)
			fi

			if [[ "${include_logs}" == "true" ]] || [[ "${clean_all}" == "true" ]]; then
				local logs_dir="${state_dir}/logs"
				if [[ -d "${logs_dir}" ]]; then
					while IFS= read -r -d '' file; do
						files_to_clean+=("${file}")
					done < <(find "${logs_dir}" -type f -print0 2>/dev/null)
				fi
			fi
		fi
	fi

	# 2. Global state
	if [[ "${clean_global}" == "true" ]] || [[ "${clean_all}" == "true" ]]; then
		local global_state="${XDG_STATE_HOME:-${HOME}/.local/state}/agent-context"

		if [[ -d "${global_state}" ]]; then
			if [[ "${include_logs}" == "true" ]] || [[ "${clean_all}" == "true" ]]; then
				while IFS= read -r -d '' file; do
					files_to_clean+=("${file}")
				done < <(find "${global_state}" -type f -print0 2>/dev/null)
			else
				# Clean everything except logs
				while IFS= read -r -d '' file; do
					if [[ "${file}" == *"/logs/"* ]]; then
						continue
					fi
					files_to_clean+=("${file}")
				done < <(find "${global_state}" -type f -print0 2>/dev/null)
			fi
		fi
	fi

	# Calculate size
	for file in "${files_to_clean[@]}"; do
		if [[ -f "${file}" ]]; then
			local size
			size=$(stat -f%z "${file}" 2>/dev/null || stat -c%s "${file}" 2>/dev/null || echo "0")
			total_size=$((total_size + size))
		fi
	done

	local file_count=${#files_to_clean[@]}

	if [[ ${file_count} -eq 0 ]]; then
		if [[ "${quiet}" == "false" ]]; then
			log_ok "Nothing to clean"
		fi
		echo "Summary: total=0 passed=0 failed=0 warned=0 skipped=0"
		return 0
	fi

	# Format size
	local size_str
	if [[ ${total_size} -gt $((1024 * 1024)) ]]; then
		size_str="$((total_size / 1024 / 1024)) MB"
	elif [[ ${total_size} -gt 1024 ]]; then
		size_str="$((total_size / 1024)) KB"
	else
		size_str="${total_size} bytes"
	fi

	if [[ "${quiet}" == "false" ]]; then
		log_info "Found ${file_count} file(s) (${size_str})"
	fi

	# Dry run: just show files
	if [[ "${dry_run}" == "true" ]]; then
		if [[ "${verbose}" == "true" ]] || [[ "${quiet}" == "false" ]]; then
			echo ""
			log_info "Would delete:"
			for file in "${files_to_clean[@]}"; do
				echo "  ${file}"
			done
		fi
		echo "Summary: total=${file_count} passed=0 failed=0 warned=0 skipped=${file_count}"
		return 0
	fi

	# Confirmation (unless --force)
	if [[ "${force}" == "false" ]] && is_interactive; then
		echo ""
		echo -n "Delete ${file_count} file(s)? [y/N]: "
		read -r confirm
		if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
			log_warn "Aborted"
			return 1
		fi
	fi

	# Delete files
	local deleted=0
	local errors=0

	for file in "${files_to_clean[@]}"; do
		if rm -f "${file}" 2>/dev/null; then
			deleted=$((deleted + 1))
			if [[ "${verbose}" == "true" ]]; then
				log_ok "Deleted: ${file}"
			fi
		else
			errors=$((errors + 1))
			if [[ "${verbose}" == "true" ]]; then
				log_error "Failed: ${file}"
			fi
		fi
	done

	# Clean up empty directories
	if [[ -n "${project_root}" ]] && [[ -d "${project_root}/.agent/state" ]]; then
		find "${project_root}/.agent/state" -type d -empty -delete 2>/dev/null || true
	fi

	if [[ "${clean_global}" == "true" ]] || [[ "${clean_all}" == "true" ]]; then
		local global_state="${XDG_STATE_HOME:-${HOME}/.local/state}/agent-context"
		if [[ -d "${global_state}" ]]; then
			find "${global_state}" -type d -empty -delete 2>/dev/null || true
		fi
	fi

	# Summary
	if [[ "${quiet}" == "false" ]]; then
		echo ""
		if [[ ${errors} -eq 0 ]]; then
			log_ok "Cleaned ${deleted} file(s) (${size_str})"
		else
			log_warn "Cleaned ${deleted} file(s), ${errors} error(s)"
		fi
	fi

	echo "Summary: total=${file_count} passed=${deleted} failed=${errors} warned=0 skipped=0"

	if [[ ${errors} -gt 0 ]]; then
		return 1
	fi
	return 0
}

# Allow direct execution for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
	source "${SCRIPT_DIR}/lib/logging.sh"
	source "${SCRIPT_DIR}/lib/platform.sh"
	run_clean "$@"
fi
