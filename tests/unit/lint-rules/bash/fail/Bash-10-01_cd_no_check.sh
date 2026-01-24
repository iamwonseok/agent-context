#!/bin/bash
# Bash-10-01: Handle cd failures - FAIL (no error handling)
# Tool: ShellCheck (SC2164)

set -e

process_directory() {
	local target_dir="$1"

	cd "${target_dir}"

	echo "Now in: $(pwd)"
	ls -la
}

unsafe_cd() {
	local dir="$1"

	cd "${dir}"
}

main() {
	local work_dir="${1:-/tmp}"

	cd "${work_dir}"
	echo "Working in: $(pwd)"
}

main "$@"
