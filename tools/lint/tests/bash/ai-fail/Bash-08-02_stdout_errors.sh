#!/bin/bash
# Bash-08-02: Error messages go to stderr (FAIL)

set -e

# Bad: Error messages to stdout instead of stderr
log_error() {
	echo "[ERROR] $1"
}

main() {
	local config_file="$1"

	if [[ -z "${config_file}" ]]; then
		echo "Error: Config file not specified"
		exit 1
	fi

	if [[ ! -f "${config_file}" ]]; then
		echo "Error: Config file not found: ${config_file}"
		exit 1
	fi

	echo "Processing config file"
}

main "$@"
