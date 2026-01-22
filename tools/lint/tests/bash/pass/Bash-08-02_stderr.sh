#!/bin/bash
# Bash-08-02: Error messages to stderr - PASS
# Tool: ShellCheck

set -e

log_error() {
	echo "[ERROR] $*" >&2
}

log_warning() {
	echo "[WARN] $*" >&2
}

validate_input() {
	local input="$1"

	if [[ -z "${input}" ]]; then
		log_error "Input is required"
		return 1
	fi

	if [[ ! -f "${input}" ]]; then
		log_error "File not found: ${input}"
		return 1
	fi

	echo "Input validated: ${input}"
}

main() {
	if [[ $# -lt 1 ]]; then
		log_error "Usage: $0 <file>"
		exit 1
	fi

	validate_input "$1"
}

main "$@"
