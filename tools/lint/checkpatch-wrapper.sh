#!/bin/bash
# Checkpatch wrapper for pre-commit
#
# Usage (standalone):
#   ./checkpatch-wrapper.sh [files...]
#
# Configuration:
#   Set CHECKPATCH_PATH environment variable to point to checkpatch.pl
#   e.g., export CHECKPATCH_PATH=/path/to/linux/scripts/checkpatch.pl
#
# Note: This hook is DISABLED by default. Enable it in .pre-commit-config.yaml
# for Linux kernel development projects only.

set -e
set -o pipefail

# ============================================================
# Configuration
# ============================================================

# checkpatch.pl location (from environment or common paths)
CHECKPATCH_PATH="${CHECKPATCH_PATH:-}"

# If not set, try common locations
if [[ -z "${CHECKPATCH_PATH}" ]]; then
	# Common kernel source locations
	for path in \
		"/usr/src/linux/scripts/checkpatch.pl" \
		"${HOME}/linux/scripts/checkpatch.pl" \
		"${HOME}/kernel/scripts/checkpatch.pl" \
		"./scripts/checkpatch.pl"; do
		if [[ -x "${path}" ]]; then
			CHECKPATCH_PATH="${path}"
			break
		fi
	done
fi

# checkpatch configuration file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKPATCH_CONF="${SCRIPT_DIR}/checkpatch.conf"

# ============================================================
# Logging
# ============================================================
if [[ -t 1 ]]; then
	RED='\033[0;31m'
	GREEN='\033[0;32m'
	YELLOW='\033[1;33m'
	BLUE='\033[0;34m'
	NC='\033[0m'
else
	RED=''
	GREEN=''
	YELLOW=''
	BLUE=''
	NC=''
fi

log_info() {
	echo -e "${BLUE}[i]${NC} $1"
}

log_ok() {
	echo -e "${GREEN}[V]${NC} $1"
}

log_warn() {
	echo -e "${YELLOW}[!]${NC} $1" >&2
}

log_error() {
	echo -e "${RED}[X]${NC} $1" >&2
}

# ============================================================
# Main
# ============================================================
main() {
	# Check if checkpatch.pl is available
	if [[ -z "${CHECKPATCH_PATH}" ]]; then
		log_warn "checkpatch.pl not found"
		log_info "Set CHECKPATCH_PATH environment variable:"
		log_info "  export CHECKPATCH_PATH=/path/to/linux/scripts/checkpatch.pl"
		log_info "Skipping checkpatch..."
		exit 0
	fi

	if [[ ! -x "${CHECKPATCH_PATH}" ]]; then
		log_error "checkpatch.pl not executable: ${CHECKPATCH_PATH}"
		exit 1
	fi

	# Build checkpatch arguments
	local checkpatch_args=("--no-tree")

	# Add config file if exists
	if [[ -f "${CHECKPATCH_CONF}" ]]; then
		log_info "Using config: ${CHECKPATCH_CONF}"
		# Read config and add to args
		while IFS= read -r line; do
			# Skip empty lines and comments
			[[ -z "${line}" ]] && continue
			[[ "${line}" =~ ^[[:space:]]*# ]] && continue
			checkpatch_args+=("${line}")
		done < "${CHECKPATCH_CONF}"
	fi

	# Check if files were provided
	if [[ $# -eq 0 ]]; then
		log_error "No files provided"
		exit 1
	fi

	# Run checkpatch on each file
	local failed=0
	for file in "$@"; do
		# Skip non-C files
		if [[ ! "${file}" =~ \.(c|h)$ ]]; then
			continue
		fi

		if [[ ! -f "${file}" ]]; then
			log_warn "File not found: ${file}"
			continue
		fi

		log_info "Checking: ${file}"
		if ! "${CHECKPATCH_PATH}" "${checkpatch_args[@]}" -f "${file}"; then
			log_error "Checkpatch failed: ${file}"
			((failed++)) || true
		else
			log_ok "Passed: ${file}"
		fi
	done

	if [[ ${failed} -gt 0 ]]; then
		log_error "Checkpatch found issues in ${failed} file(s)"
		exit 1
	fi

	log_ok "All files passed checkpatch"
}

main "$@"
