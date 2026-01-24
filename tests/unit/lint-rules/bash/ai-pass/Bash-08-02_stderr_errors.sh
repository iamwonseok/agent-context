#!/bin/bash
# Bash-08-02: Error messages go to stderr (PASS)

set -e

# Good: Error messages to stderr
log_error() {
	echo "[ERROR] $1" >&2
}

log_warning() {
	echo "[WARN] $1" >&2
}

log_info() {
	echo "[INFO] $1"
}

main() {
	local config_file="$1"

	if [[ -z "${config_file}" ]]; then
		log_error "Config file not specified"
		exit 1
	fi

	if [[ ! -f "${config_file}" ]]; then
		log_error "Config file not found: ${config_file}"
		exit 1
	fi

	log_info "Processing config file"
}

main "$@"
