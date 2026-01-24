#!/bin/bash
# Bash-06-05: Use [[ ]] for conditions - FAIL (uses [ ])
# Tool: ShellCheck (recommends [[ ]] for bash)

set -e

check_string() {
	local value="$1"

	if [ -z "${value}" ]; then
		echo "Empty"
		return 1
	fi

	if [ "${value}" = "test" ]; then
		echo "Match exact"
	elif [ "${value}" != "skip" ]; then
		echo "Not skip"
	fi
}

check_file() {
	local path="$1"

	if [ -f "${path}" ] && [ -r "${path}" ]; then
		echo "File exists and readable"
	elif [ -d "${path}" ]; then
		echo "Is directory"
	fi
}
