#!/bin/bash
# Demo Installation Library
# Common functions for demo/installation step scripts
#
# Usage: source this file from step scripts
#   source "$(dirname "$0")/lib.sh"

set -e
set -o pipefail

# ============================================================
# Environment Variables (set by runner)
# ============================================================
# RUN_ID        - Unique run identifier
# WORKDIR       - Working directory for demo
# PROFILE       - Installation profile (full/minimal)
# SKIP_E2E      - Skip E2E tests if set to "true"
# SECRETS_MODE  - "mount" or "copy"
# JIRA_EMAIL    - Jira email (required for API calls)

# Default values
: "${RUN_ID:=$(date +%Y%m%d_%H%M%S)}"
: "${WORKDIR:=/tmp/agent-context-demo-${RUN_ID}}"
: "${PROFILE:=full}"
: "${SKIP_E2E:=false}"
: "${SECRETS_MODE:=mount}"
: "${DOCKER_MODE:=false}"

# Script directory
DEMO_INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_CONTEXT_ROOT="$(cd "${DEMO_INSTALL_DIR}/../.." && pwd)"

# Export for step scripts
export RUN_ID WORKDIR PROFILE SKIP_E2E SECRETS_MODE DOCKER_MODE
export DEMO_INSTALL_DIR AGENT_CONTEXT_ROOT

# ============================================================
# Colors
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

# ============================================================
# Logging Functions
# ============================================================
log_info() {
	echo -e "${BLUE}[>>]${NC} $1"
}

log_ok() {
	echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
	echo -e "${YELLOW}[!!]${NC} $1" >&2
}

log_error() {
	echo -e "${RED}[NG]${NC} $1" >&2
}

log_step() {
	local step_num="$1"
	local step_name="$2"
	echo ""
	echo "============================================================"
	echo "Step ${step_num}: ${step_name}"
	echo "============================================================"
	echo ""
}

# ============================================================
# State Management
# ============================================================
# State file stores completion status of each step
STATE_FILE="${WORKDIR}/.demo-state"

init_state() {
	mkdir -p "${WORKDIR}"
	if [[ ! -f "${STATE_FILE}" ]]; then
		echo "# Demo installation state" > "${STATE_FILE}"
		echo "RUN_ID=${RUN_ID}" >> "${STATE_FILE}"
		echo "STARTED_AT=$(date -Iseconds)" >> "${STATE_FILE}"
	fi
}

mark_step_done() {
	local step="$1"
	echo "STEP_${step}_DONE=$(date -Iseconds)" >> "${STATE_FILE}"
}

is_step_done() {
	local step="$1"
	grep -q "^STEP_${step}_DONE=" "${STATE_FILE}" 2>/dev/null
}

# ============================================================
# Secret Handling
# ============================================================
# Mask token in output (show only first 4 and last 4 chars)
mask_token() {
	local token="$1"
	if [[ ${#token} -gt 12 ]]; then
		echo "${token:0:4}...${token: -4}"
	else
		echo "****"
	fi
}

# Check if secrets are available
check_secrets() {
	local missing=()

	# Check Atlassian token
	if [[ ! -f "${HOME}/.secrets/atlassian-api-token" ]]; then
		# shellcheck disable=SC2088
		missing+=("~/.secrets/atlassian-api-token")
	fi

	# Check JIRA_EMAIL
	if [[ -z "${JIRA_EMAIL}" ]]; then
		missing+=("JIRA_EMAIL environment variable")
	fi

	if [[ ${#missing[@]} -gt 0 ]]; then
		log_warn "Missing secrets:"
		for item in "${missing[@]}"; do
			log_warn "  - ${item}"
		done
		return 1
	fi

	return 0
}

# ============================================================
# Verification Helpers
# ============================================================
verify_file_exists() {
	local file="$1"
	local desc="${2:-$1}"
	if [[ -f "${file}" ]]; then
		log_ok "${desc} exists"
		return 0
	else
		log_error "${desc} not found: ${file}"
		return 1
	fi
}

verify_dir_exists() {
	local dir="$1"
	local desc="${2:-$1}"
	if [[ -d "${dir}" ]]; then
		log_ok "${desc} exists"
		return 0
	else
		log_error "${desc} not found: ${dir}"
		return 1
	fi
}

verify_executable() {
	local file="$1"
	local desc="${2:-$1}"
	if [[ -x "${file}" ]]; then
		log_ok "${desc} is executable"
		return 0
	else
		log_error "${desc} is not executable: ${file}"
		return 1
	fi
}

verify_command_exists() {
	local cmd="$1"
	if command -v "${cmd}" &>/dev/null; then
		log_ok "Command available: ${cmd}"
		return 0
	else
		log_error "Command not found: ${cmd}"
		return 1
	fi
}

# ============================================================
# Standard Step Script Interface
# ============================================================
# Each step script should implement:
#   step_run()    - Execute the step
#   step_verify() - Verify the step succeeded (exit 0 = PASS, non-0 = FAIL)
#
# Then call run_step at the end:
#   run_step "$@"

run_step() {
	local cmd="${1:-help}"
	shift || true

	case "${cmd}" in
		run)
			step_run "$@"
			;;
		verify)
			step_verify "$@"
			;;
		help|--help|-h)
			echo "Usage: $(basename "$0") <run|verify>"
			echo ""
			echo "Commands:"
			echo "  run     Execute this step"
			echo "  verify  Verify this step succeeded (exit 0 = PASS)"
			;;
		*)
			log_error "Unknown command: ${cmd}"
			echo "Usage: $(basename "$0") <run|verify>"
			exit 1
			;;
	esac
}
