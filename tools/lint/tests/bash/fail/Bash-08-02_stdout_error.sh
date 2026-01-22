#!/bin/bash
# Bash-08-02: Error messages to stderr - FAIL (errors to stdout)
# Tool: ShellCheck (no direct check, but best practice)

set -e

log_error() {
	echo "[ERROR] $*"
}

validate_input() {
	local input="$1"

	if [[ -z "${input}" ]]; then
		echo "Error: Input is required"
		return 1
	fi

	if [[ ! -f "${input}" ]]; then
		echo "Error: File not found: ${input}"
		return 1
	fi

	echo "Input validated: ${input}"
}

main() {
	if [[ $# -lt 1 ]]; then
		echo "Error: Usage: $0 <file>"
		exit 1
	fi

	validate_input "$1"
}

main "$@"
