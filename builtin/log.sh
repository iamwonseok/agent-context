#!/bin/bash
# Agent-Context Log Command
# Show command execution logs
#
# Usage:
#   agent-context log [command] [options]
#
# This script is sourced by bin/agent-context.sh

# ============================================================
# Usage
# ============================================================
log_cmd_usage() {
	cat <<EOF
Agent-Context Log

USAGE:
    agent-context log [command] [options]

ARGUMENTS:
    command         Filter by command name (install, doctor, etc.)

OPTIONS:
    --list          List available log files
    --global        Show global logs only
    --project       Show project logs only
    --tail N        Show last N lines (default: 50)
    --follow        Real-time tracking (tail -f)
    --level LEVEL   Filter by level (info, warn, error)
    --raw           Show without masking sensitive data
    -v, --verbose   Show full log content
    -q, --quiet     Show only filenames
    -h, --help      Show this help

DESCRIPTION:
    View agent-context command execution logs.

    Logs are stored in:
    - Global: ~/.local/state/agent-context/logs/
    - Project: .agent/state/logs/

    Log format follows .cursorrules Output Style:
    [V] pass, [X] fail, [!] warn, [i] info, [-] skip, [*] progress

EXAMPLES:
    # Show most recent log
    agent-context log

    # List available logs
    agent-context log --list

    # Show install logs
    agent-context log install

    # Follow logs in real-time
    agent-context log --follow

    # Show only errors
    agent-context log --level error

EOF
}

# ============================================================
# Log Utilities
# ============================================================

get_log_dirs() {
	local global_only="$1"
	local project_only="$2"
	local dirs=()

	local global_log="${XDG_STATE_HOME:-${HOME}/.local/state}/agent-context/logs"
	local project_root
	project_root=$(find_project_root "${PWD}" 2>/dev/null || true)
	local project_log=""
	if [[ -n "${project_root}" ]]; then
		project_log="${project_root}/.agent/state/logs"
	fi

	if [[ "${global_only}" == "true" ]]; then
		dirs+=("${global_log}")
	elif [[ "${project_only}" == "true" ]]; then
		if [[ -n "${project_log}" ]]; then
			dirs+=("${project_log}")
		fi
	else
		if [[ -n "${project_log}" ]] && [[ -d "${project_log}" ]]; then
			dirs+=("${project_log}")
		fi
		if [[ -d "${global_log}" ]]; then
			dirs+=("${global_log}")
		fi
	fi

	echo "${dirs[*]}"
}

list_logs() {
	local log_dirs="$1"
	local filter="$2"
	local quiet="$3"

	local found=0

	for dir in ${log_dirs}; do
		if [[ ! -d "${dir}" ]]; then
			continue
		fi

		local context="global"
		if [[ "${dir}" == *".agent"* ]]; then
			context="project"
		fi

		if [[ "${quiet}" == "false" ]]; then
			echo ""
			log_info "Logs in ${dir}:"
		fi

		while IFS= read -r -d '' log_file; do
			local filename
			filename=$(basename "${log_file}")

			# Apply filter if specified
			if [[ -n "${filter}" ]] && [[ "${filename}" != "${filter}"* ]]; then
				continue
			fi

			found=$((found + 1))

			local size
			size=$(stat -f%z "${log_file}" 2>/dev/null || stat -c%s "${log_file}" 2>/dev/null || echo "0")
			local mtime
			mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "${log_file}" 2>/dev/null || \
			        stat -c "%y" "${log_file}" 2>/dev/null | cut -d. -f1 || echo "unknown")

			if [[ "${quiet}" == "true" ]]; then
				echo "${log_file}"
			else
				printf "  %-40s %8s  %s\n" "${filename}" "${size}B" "${mtime}"
			fi
		done < <(find "${dir}" -name "*.log" -type f -print0 2>/dev/null | sort -rz)
	done

	if [[ ${found} -eq 0 ]]; then
		log_info "No log files found"
	fi

	return 0
}

get_latest_log() {
	local log_dirs="$1"
	local filter="$2"

	for dir in ${log_dirs}; do
		if [[ ! -d "${dir}" ]]; then
			continue
		fi

		local pattern="*.log"
		if [[ -n "${filter}" ]]; then
			pattern="${filter}-*.log"
		fi

		local latest
		latest=$(find "${dir}" -name "${pattern}" -type f -print0 2>/dev/null | \
		         xargs -0 ls -t 2>/dev/null | head -1)

		if [[ -n "${latest}" ]]; then
			echo "${latest}"
			return 0
		fi
	done

	return 1
}

mask_sensitive() {
	local line="$1"
	# Mask common token patterns
	line=$(echo "${line}" | sed -E 's/(glpat-|ghp_|xoxb-)[A-Za-z0-9_-]+/\1********/g')
	line=$(echo "${line}" | sed -E 's/(Bearer )[A-Za-z0-9._-]+/\1********/g')
	line=$(echo "${line}" | sed -E 's/(api[_-]?key[=:]["'"'"']?)[A-Za-z0-9_-]+/\1********/gi')
	line=$(echo "${line}" | sed -E 's/(token[=:]["'"'"']?)[A-Za-z0-9_-]{20,}/\1********/gi')
	echo "${line}"
}

show_log() {
	local log_file="$1"
	local tail_lines="$2"
	local level_filter="$3"
	local raw="$4"
	local follow="$5"

	if [[ ! -f "${log_file}" ]]; then
		log_error "Log file not found: ${log_file}"
		return 1
	fi

	local filename
	filename=$(basename "${log_file}")

	echo ""
	echo "=== Log: ${filename} ==="

	# Show header if exists
	if head -1 "${log_file}" | grep -q "^#"; then
		head -10 "${log_file}" | grep "^#" | sed 's/^# //'
		echo "---"
	fi

	local level_pattern=""
	case "${level_filter}" in
		error)   level_pattern='\[X\]' ;;
		warn)    level_pattern='\[!\]' ;;
		info)    level_pattern='\[i\]' ;;
		*)       level_pattern="" ;;
	esac

	if [[ "${follow}" == "true" ]]; then
		if [[ -n "${level_pattern}" ]]; then
			tail -f "${log_file}" | grep --line-buffered "${level_pattern}"
		else
			tail -f "${log_file}"
		fi
	else
		local content
		if [[ -n "${level_pattern}" ]]; then
			content=$(tail -n "${tail_lines}" "${log_file}" | grep "${level_pattern}")
		else
			content=$(tail -n "${tail_lines}" "${log_file}")
		fi

		if [[ "${raw}" == "true" ]]; then
			echo "${content}"
		else
			while IFS= read -r line; do
				mask_sensitive "${line}"
			done <<< "${content}"
		fi
	fi
}

# ============================================================
# Main Log Function
# ============================================================
run_log() {
	local command_filter=""
	local list_mode=false
	local global_only=false
	local project_only=false
	local tail_lines=50
	local follow=false
	local level_filter=""
	local raw=false
	local verbose=false
	local quiet=false

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--list)
				list_mode=true
				;;
			--global)
				global_only=true
				;;
			--project)
				project_only=true
				;;
			--tail)
				tail_lines="$2"
				shift
				;;
			--follow|-f)
				follow=true
				;;
			--level)
				level_filter="$2"
				shift
				;;
			--raw)
				raw=true
				;;
			-v|--verbose)
				verbose=true
				;;
			-q|--quiet)
				quiet=true
				;;
			-h|--help)
				log_cmd_usage
				return 0
				;;
			-*)
				log_error "Unknown option: $1"
				log_cmd_usage
				return 2
				;;
			*)
				command_filter="$1"
				;;
		esac
		shift
	done

	local log_dirs
	log_dirs=$(get_log_dirs "${global_only}" "${project_only}")

	if [[ -z "${log_dirs}" ]]; then
		log_info "No log directories found"
		return 0
	fi

	if [[ "${list_mode}" == "true" ]]; then
		list_logs "${log_dirs}" "${command_filter}" "${quiet}"
		return 0
	fi

	# Get latest log
	local log_file
	log_file=$(get_latest_log "${log_dirs}" "${command_filter}")

	if [[ -z "${log_file}" ]]; then
		log_info "No log files found"
		if [[ -n "${command_filter}" ]]; then
			log_info "Try: agent-context log --list"
		fi
		return 0
	fi

	show_log "${log_file}" "${tail_lines}" "${level_filter}" "${raw}" "${follow}"
	return 0
}

# Allow direct execution for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
	source "${SCRIPT_DIR}/lib/logging.sh"
	source "${SCRIPT_DIR}/lib/platform.sh"
	run_log "$@"
fi
