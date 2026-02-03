#!/bin/bash
# Agent-Context Demo Installation Runner
# Single entrypoint for running the installation demo
#
# Usage:
#   ./demo/install.sh [options]
#
# This script runs installation steps sequentially with gate verification.
# Each step must PASS (exit 0) before proceeding to the next step.

set -e
set -o pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLATION_DIR="${SCRIPT_DIR}/demo/installation"

# ============================================================
# Colors
# ============================================================
if [[ -t 1 ]]; then
	RED='\033[0;31m'
	GREEN='\033[0;32m'
	YELLOW='\033[1;33m'
	BLUE='\033[0;34m'
	CYAN='\033[0;36m'
	BOLD='\033[1m'
	NC='\033[0m'
else
	RED=''
	GREEN=''
	YELLOW=''
	BLUE=''
	CYAN=''
	BOLD=''
	NC=''
fi

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

log_header() {
	echo ""
	echo -e "${BOLD}${CYAN}$1${NC}"
	echo ""
}

# ============================================================
# Default Configuration
# ============================================================
PROFILE="full"
FORCE=false
OS_TARGET=""
RUN_ID="$(date +%Y%m%d_%H%M%S)"
SKIP_E2E=false
ONLY_STEP=""
SECRETS_MODE="mount"
DOCKER_MODE=false
WORKDIR=""

# ============================================================
# Usage
# ============================================================
usage() {
	cat <<EOF
Agent-Context Demo Installation Runner

USAGE:
    $(basename "$0") [options]

OPTIONS:
    --profile PROFILE   Installation profile: full (default), minimal
    -f, --force         Force overwrite existing files
    --os OS             Run in Docker: ubuntu, ubi9
    --run-id ID         Unique run identifier (default: timestamp)
    --skip-e2e          Skip E2E tests (online API calls)
    --only N            Run only up to step N (e.g., --only 5)
    --secrets-mode MODE How to handle secrets: mount (default), copy
    --workdir DIR       Working directory (default: /tmp/agent-context-demo-<run-id>)
    -h, --help          Show this help

ENVIRONMENT VARIABLES:
    JIRA_EMAIL          Atlassian account email (required for E2E)
    JIRA_BASE_URL       Jira base URL (optional, has default)
    JIRA_PROJECT_KEY    Jira project key (optional, default: SVI4)

STEPS:
    001 - Prerequisites check
    002 - Prepare working directory
    003 - Run install.sh
    004 - Configure .project.yaml
    005 - PM connectivity test
    006 - Static tests
    007 - Demo prerequisites check
    008 - Demo E2E run
    009 - Pre-commit (best-effort)
    010 - Summary report

EXAMPLES:
    # Run all steps locally
    $(basename "$0")

    # Run minimal profile, skip E2E
    $(basename "$0") --profile minimal --skip-e2e

    # Run only first 5 steps
    $(basename "$0") --only 5

    # Run in Docker (Ubuntu)
    $(basename "$0") --os ubuntu

    # Run in Docker (UBI9) with force
    $(basename "$0") --os ubi9 --force

GATE RULES:
    - Each step runs 'run' then 'verify'
    - If verify FAILS (non-zero), runner stops immediately
    - Exception: Step 009 (pre-commit) is best-effort

EOF
}

# ============================================================
# Argument Parsing
# ============================================================
while [[ $# -gt 0 ]]; do
	case "$1" in
		--profile)
			PROFILE="$2"
			if [[ "${PROFILE}" != "full" ]] && [[ "${PROFILE}" != "minimal" ]]; then
				log_error "Invalid profile: ${PROFILE}. Use 'full' or 'minimal'."
				exit 1
			fi
			shift
			;;
		-f|--force)
			FORCE=true
			;;
		--os)
			OS_TARGET="$2"
			if [[ "${OS_TARGET}" != "ubuntu" ]] && [[ "${OS_TARGET}" != "ubi9" ]]; then
				log_error "Invalid OS: ${OS_TARGET}. Use 'ubuntu' or 'ubi9'."
				exit 1
			fi
			DOCKER_MODE=true
			shift
			;;
		--run-id)
			RUN_ID="$2"
			shift
			;;
		--skip-e2e)
			SKIP_E2E=true
			;;
		--only)
			ONLY_STEP="$2"
			shift
			;;
		--secrets-mode)
			SECRETS_MODE="$2"
			if [[ "${SECRETS_MODE}" != "mount" ]] && [[ "${SECRETS_MODE}" != "copy" ]]; then
				log_error "Invalid secrets-mode: ${SECRETS_MODE}. Use 'mount' or 'copy'."
				exit 1
			fi
			shift
			;;
		--workdir)
			WORKDIR="$2"
			shift
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			log_error "Unknown option: $1"
			usage
			exit 1
			;;
	esac
	shift
done

# Set default workdir
: "${WORKDIR:=/tmp/agent-context-demo-${RUN_ID}}"

# ============================================================
# Export Environment
# ============================================================
export RUN_ID
export WORKDIR
export PROFILE
export SKIP_E2E
export SECRETS_MODE
export FORCE
export DOCKER_MODE

# Default Jira settings for demo
: "${JIRA_BASE_URL:=https://fadutec.atlassian.net}"
: "${JIRA_PROJECT_KEY:=SVI4}"
export JIRA_BASE_URL
export JIRA_PROJECT_KEY

# ============================================================
# Docker Mode
# ============================================================
run_in_docker() {
	local os="$1"
	local dockerfile="${SCRIPT_DIR}/demo/docker/${os}/Dockerfile"
	local image_name="agent-context-demo-${os}:${RUN_ID}"

	if [[ ! -f "${dockerfile}" ]]; then
		log_error "Dockerfile not found: ${dockerfile}"
		exit 1
	fi

	log_header "Running in Docker (${os})"

	# Build Docker image
	log_info "Building Docker image: ${image_name}"
	if ! docker build -t "${image_name}" -f "${dockerfile}" "${SCRIPT_DIR}/demo/docker/${os}"; then
		log_error "Docker build failed"
		exit 1
	fi
	log_ok "Docker image built"

	# Prepare docker run arguments
	local docker_args=(
		"--rm"
		"-e" "RUN_ID=${RUN_ID}"
		"-e" "PROFILE=${PROFILE}"
		"-e" "SKIP_E2E=${SKIP_E2E}"
		"-e" "FORCE=${FORCE}"
		"-e" "JIRA_BASE_URL=${JIRA_BASE_URL}"
		"-e" "JIRA_PROJECT_KEY=${JIRA_PROJECT_KEY}"
	)

	# Add JIRA_EMAIL if set
	if [[ -n "${JIRA_EMAIL}" ]]; then
		docker_args+=("-e" "JIRA_EMAIL=${JIRA_EMAIL}")
	fi

	# Handle secrets
	if [[ "${SECRETS_MODE}" == "mount" ]]; then
		if [[ -d "${HOME}/.secrets" ]]; then
			docker_args+=("-v" "${HOME}/.secrets:/root/.secrets:ro")
			log_info "Mounting secrets: ~/.secrets -> /root/.secrets (read-only)"
		else
			# shellcheck disable=SC2088
			log_warn "~/.secrets not found, skipping mount"
		fi
	fi

	# Mount agent-context source
	docker_args+=("-v" "${SCRIPT_DIR}:/agent-context:ro")

	# Build internal command
	local internal_cmd="/agent-context/demo/install.sh --profile ${PROFILE}"
	[[ "${FORCE}" == "true" ]] && internal_cmd+=" --force"
	[[ "${SKIP_E2E}" == "true" ]] && internal_cmd+=" --skip-e2e"
	[[ -n "${ONLY_STEP}" ]] && internal_cmd+=" --only ${ONLY_STEP}"

	# Run container
	log_info "Running container..."
	echo ""
	docker run "${docker_args[@]}" "${image_name}" bash -c "${internal_cmd}"
}

# ============================================================
# Local Mode: Run Steps
# ============================================================
run_step() {
	local step_num="$1"
	local step_script="${INSTALLATION_DIR}/${step_num}-*.sh"

	# Find the script
	local script
	script=$(ls ${step_script} 2>/dev/null | head -1)

	if [[ -z "${script}" ]] || [[ ! -f "${script}" ]]; then
		log_error "Step script not found: ${step_script}"
		return 1
	fi

	local step_name
	step_name=$(basename "${script}" .sh | sed 's/^[0-9]*-//')

	echo ""
	echo "============================================================"
	echo -e "${BOLD}Step ${step_num}: ${step_name}${NC}"
	echo "============================================================"

	# Run step
	log_info "Running step ${step_num}..."
	if ! bash "${script}" run; then
		log_error "Step ${step_num} run failed"
		return 1
	fi

	# Verify step (except for best-effort steps)
	log_info "Verifying step ${step_num}..."
	if ! bash "${script}" verify; then
		# Step 009 (pre-commit) is best-effort
		if [[ "${step_num}" == "009" ]]; then
			log_warn "Step ${step_num} verification failed (best-effort, continuing)"
			return 0
		fi
		log_error "Step ${step_num} verification failed"
		return 1
	fi

	log_ok "Step ${step_num} completed"
	return 0
}

run_local() {
	log_header "Agent-Context Demo Installation"

	echo "Configuration:"
	echo "  Run ID:       ${RUN_ID}"
	echo "  Profile:      ${PROFILE}"
	echo "  Force:        ${FORCE}"
	echo "  Skip E2E:     ${SKIP_E2E}"
	echo "  Secrets Mode: ${SECRETS_MODE}"
	echo "  Working Dir:  ${WORKDIR}"
	echo ""

	# List of steps
	local steps=(001 002 003 004 005 006 007 008 009 010)

	# Filter by --only if specified
	if [[ -n "${ONLY_STEP}" ]]; then
		local filtered_steps=()
		for step in "${steps[@]}"; do
			filtered_steps+=("${step}")
			if [[ "${step}" == "${ONLY_STEP}" ]] || [[ "${step}" == "0${ONLY_STEP}" ]] || [[ "${step}" == "00${ONLY_STEP}" ]]; then
				break
			fi
		done
		steps=("${filtered_steps[@]}")
		log_info "Running steps: ${steps[*]}"
	fi

	# Run each step
	local failed_step=""
	for step in "${steps[@]}"; do
		if ! run_step "${step}"; then
			failed_step="${step}"
			break
		fi
	done

	# Final summary
	echo ""
	echo "============================================================"
	if [[ -n "${failed_step}" ]]; then
		log_error "Demo installation failed at step ${failed_step}"
		echo ""
		echo "To retry from this step:"
		echo "  WORKDIR=${WORKDIR} ./demo/install.sh --only ${failed_step}"
		echo ""
		echo "Working directory preserved at: ${WORKDIR}"
		exit 1
	else
		log_ok "Demo installation completed successfully!"
		echo ""
		echo "Installation report: ${WORKDIR}/installation-report.md"
		echo "Target project: ${WORKDIR}/any-project"
		echo ""
		exit 0
	fi
}

# ============================================================
# Main
# ============================================================
main() {
	# Check installation directory exists
	if [[ ! -d "${INSTALLATION_DIR}" ]]; then
		log_error "Installation directory not found: ${INSTALLATION_DIR}"
		exit 1
	fi

	# Run in Docker or locally
	if [[ "${DOCKER_MODE}" == "true" ]]; then
		run_in_docker "${OS_TARGET}"
	else
		run_local
	fi
}

main
