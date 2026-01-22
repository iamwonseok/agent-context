#!/bin/bash
# Bash-10-01: Handle cd failures - PASS
# Tool: ShellCheck (SC2164)

set -e

process_directory() {
	local target_dir="$1"

	cd "${target_dir}" || {
		echo "Failed to cd to ${target_dir}" >&2
		return 1
	}

	echo "Now in: $(pwd)"
	ls -la
}

safe_cd() {
	local dir="$1"

	if [[ ! -d "${dir}" ]]; then
		echo "Directory does not exist: ${dir}" >&2
		return 1
	fi

	cd "${dir}" || exit 1
}

main() {
	local work_dir="${1:-/tmp}"

	safe_cd "${work_dir}"
	echo "Working in: $(pwd)"
}

main "$@"
