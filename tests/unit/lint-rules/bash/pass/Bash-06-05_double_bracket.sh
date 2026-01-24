#!/bin/bash
# Bash-06-05: Use [[ ]] for conditions - PASS
# Tool: ShellCheck (SC2039, SC3010)

set -e

check_string() {
	local value="$1"

	if [[ -z "${value}" ]]; then
		echo "Empty"
		return 1
	fi

	if [[ "${value}" == "test" ]]; then
		echo "Match exact"
	elif [[ "${value}" =~ ^[0-9]+$ ]]; then
		echo "Is number"
	elif [[ "${value}" != "skip" ]]; then
		echo "Not skip"
	fi
}

check_file() {
	local path="$1"

	if [[ -f "${path}" && -r "${path}" ]]; then
		echo "File exists and readable"
	elif [[ -d "${path}" ]]; then
		echo "Is directory"
	fi
}
