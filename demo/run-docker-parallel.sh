#!/bin/bash
# Agent-Context Demo: Parallel Docker Test Runner
# Runs installation + E2E tests on Ubuntu and UBI9 simultaneously
#
# Usage:
#   ./demo/run-docker-parallel.sh [options]
#
# Options:
#   --skip-e2e          Skip E2E tests (run offline installation only)
#   --only N            Run only up to step N
#   --run-id ID         Use specific run ID (default: timestamp)
#   --workdir DIR       Base working directory
#   -h, --help          Show help
#
# Environment Variables (optional overrides):
#   JIRA_EMAIL          Atlassian account email (required for E2E)
#   JIRA_PROJECT_KEY    Jira project key (default: SVI4)
#   DEMO_GITLAB_GROUP   GitLab group (default: soc-ip/agentic-ai)

set -e
set -o pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_CONTEXT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

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

log_info() { echo -e "${BLUE}[i]${NC} $1"; }
log_ok() { echo -e "${GREEN}[V]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1" >&2; }
log_error() { echo -e "${RED}[X]${NC} $1" >&2; }
log_header() {
	echo ""
	echo -e "${BOLD}${CYAN}$1${NC}"
	echo ""
}

# ============================================================
# Default Configuration
# ============================================================
RUN_ID="${RUN_ID:-$(date +%Y%m%d_%H%M%S)}"
BASE_WORKDIR=""
SKIP_E2E=false
ONLY_STEP=""
SERIAL_MODE=false

# Load demo/.env (if exists)
# Priority: explicit export > demo/.env > script defaults
_ENV_FILE="${SCRIPT_DIR}/.env"
if [[ -f "${_ENV_FILE}" ]]; then
	while IFS= read -r _line || [[ -n "${_line}" ]]; do
		# Skip comments and empty lines
		[[ "${_line}" =~ ^[[:space:]]*($|#) ]] && continue
		_key="${_line%%=*}"
		_val="${_line#*=}"
		# Only export if not already set in environment
		if [[ -z "${!_key+x}" ]]; then
			export "${_key}=${_val}"
		fi
	done < "${_ENV_FILE}"
fi

# Default platform settings
: "${JIRA_EMAIL:=}"
: "${JIRA_BASE_URL:=https://wonseokko.atlassian.net}"
: "${JIRA_PROJECT_KEY:=SVI4}"
: "${CONFLUENCE_BASE_URL:=https://wonseokko.atlassian.net/wiki}"
: "${CONFLUENCE_SPACE_KEY:=~wonseok}"
: "${GITLAB_BASE_URL:=https://gitlab.com}"
: "${DEMO_GITLAB_GROUP:=soc-ip/agentic-ai}"
: "${DEMO_JIRA_PROJECT:=${JIRA_PROJECT_KEY}}"
: "${DEMO_CONFLUENCE_SPACE:=${CONFLUENCE_SPACE_KEY}}"
: "${RECREATE_REPO:=true}"
: "${RECREATE_BOARD:=true}"
: "${RECREATE_ISSUES:=true}"
: "${RECREATE_PAGES:=true}"

# ============================================================
# Usage
# ============================================================
usage() {
	cat <<EOF
Agent-Context Demo: Docker Test Runner

Runs installation + E2E tests on Ubuntu and UBI9.

USAGE:
    $(basename "$0") [options]

OPTIONS:
    --serial            Run tests sequentially (ubuntu first, then ubi9)
    --skip-e2e          Skip E2E tests (run offline installation only)
    --only N            Run only up to step N
    --run-id ID         Use specific run ID (default: timestamp)
    --workdir DIR       Base working directory (default: /tmp/agent-context-parallel-<run-id>)
    -h, --help          Show this help

ENVIRONMENT VARIABLES:
    JIRA_EMAIL          Atlassian account email (required for E2E)
    JIRA_PROJECT_KEY    Jira project key (default: SVI4)
    DEMO_GITLAB_GROUP   GitLab group (default: soc-ip/agentic-ai)

OUTPUT:
    <workdir>/
    ├── ubuntu/                    # Ubuntu test results
    │   ├── docker-build.log
    │   ├── docker-run.log
    │   ├── installation-report.md
    │   └── demo-output/
    ├── ubi9/                      # UBI9 test results
    │   ├── docker-build.log
    │   ├── docker-run.log
    │   ├── installation-report.md
    │   └── demo-output/
    └── parallel-summary.md        # Combined summary

EXAMPLES:
    # Run full E2E tests on both OS
    export JIRA_EMAIL="your-email@example.com"
    $(basename "$0")

    # Run offline tests only
    $(basename "$0") --skip-e2e

    # Run specific steps
    $(basename "$0") --only 6 --skip-e2e

EOF
}

# ============================================================
# Argument Parsing
# ============================================================
while [[ $# -gt 0 ]]; do
	case "$1" in
		--serial)
			SERIAL_MODE=true
			;;
		--skip-e2e)
			SKIP_E2E=true
			;;
		--only)
			ONLY_STEP="$2"
			shift
			;;
		--run-id)
			RUN_ID="$2"
			shift
			;;
		--workdir)
			BASE_WORKDIR="$2"
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

# Set default base workdir
: "${BASE_WORKDIR:=/tmp/agent-context-parallel-${RUN_ID}}"

# ============================================================
# Preflight Checks
# ============================================================
preflight_check() {
	log_header "Preflight Checks"

	local failed=0

	# Check Docker
	if ! command -v docker &>/dev/null; then
		log_error "Docker is not installed"
		((failed++)) || true
	elif ! docker info &>/dev/null; then
		log_error "Docker daemon is not running"
		((failed++)) || true
	else
		log_ok "Docker is available"
	fi

	# Check secrets for E2E
	if [[ "${SKIP_E2E}" != "true" ]]; then
		if [[ -z "${JIRA_EMAIL}" ]]; then
			log_error "JIRA_EMAIL is required for E2E tests"
			log_info "  Set: export JIRA_EMAIL='your-email@example.com'"
			log_info "  Or use: --skip-e2e"
			((failed++)) || true
		else
			log_ok "JIRA_EMAIL is set: ${JIRA_EMAIL}"
		fi

		if [[ ! -f "${HOME}/.secrets/atlassian-api-token" ]]; then
			log_error "Atlassian token not found: ~/.secrets/atlassian-api-token"
			((failed++)) || true
		else
			log_ok "Atlassian token found"
		fi

		if [[ ! -f "${HOME}/.secrets/gitlab-api-token" ]]; then
			log_warn "GitLab token not found: ~/.secrets/gitlab-api-token"
		else
			log_ok "GitLab token found"
		fi
	else
		log_info "E2E tests skipped (--skip-e2e)"
	fi

	if [[ ${failed} -gt 0 ]]; then
		log_error "Preflight check failed"
		exit 1
	fi

	log_ok "Preflight checks passed"
}

# ============================================================
# Run Single OS Test
# ============================================================
run_os_test() {
	local os="$1"
	local workdir="${BASE_WORKDIR}/${os}"

	log_info "Starting ${os} test..."

	mkdir -p "${workdir}"

	# Build environment variables for demo scenario
	# Git user config: derive from JIRA_EMAIL if not explicitly set
	local git_user_name="${GIT_USER_NAME:-${JIRA_EMAIL%%@*}}"
	local git_user_email="${GIT_USER_EMAIL:-${JIRA_EMAIL}}"

	local env_args=(
		"RUN_ID=${RUN_ID}"
		"JIRA_EMAIL=${JIRA_EMAIL}"
		"JIRA_BASE_URL=${JIRA_BASE_URL}"
		"JIRA_PROJECT_KEY=${JIRA_PROJECT_KEY}"
		"CONFLUENCE_BASE_URL=${CONFLUENCE_BASE_URL}"
		"CONFLUENCE_SPACE_KEY=${CONFLUENCE_SPACE_KEY}"
		"GITLAB_BASE_URL=${GITLAB_BASE_URL}"
		"DEMO_JIRA_PROJECT=${DEMO_JIRA_PROJECT}"
		"DEMO_CONFLUENCE_SPACE=${DEMO_CONFLUENCE_SPACE}"
		"DEMO_GITLAB_GROUP=${DEMO_GITLAB_GROUP}"
		"DEMO_REPO_NAME=demo-agent-context-install-${os}"
		"RECREATE_REPO=${RECREATE_REPO}"
		"RECREATE_BOARD=${RECREATE_BOARD}"
		"RECREATE_ISSUES=${RECREATE_ISSUES}"
		"RECREATE_PAGES=${RECREATE_PAGES}"
		"SKIP_CLEANUP=true"
		"HITL_ENABLED=false"
		"GIT_USER_NAME=${git_user_name}"
		"GIT_USER_EMAIL=${git_user_email}"
	)

	# Build command (pass --workdir explicitly for reliability)
	local cmd="${SCRIPT_DIR}/install.sh --os ${os} --workdir ${workdir} --run-id ${RUN_ID}"
	[[ "${SKIP_E2E}" == "true" ]] && cmd+=" --skip-e2e"
	[[ -n "${ONLY_STEP}" ]] && cmd+=" --only ${ONLY_STEP}"

	# Run with environment
	local start_time
	start_time=$(date +%s)

	local exit_code=0
	(
		for env_var in "${env_args[@]}"; do
			export "${env_var?}"
		done
		${cmd}
	) > "${workdir}/parallel-runner.log" 2>&1 || exit_code=$?

	local end_time
	end_time=$(date +%s)
	local duration=$((end_time - start_time))

	# Write result marker
	echo "${exit_code}" > "${workdir}/.exit_code"
	echo "${duration}" > "${workdir}/.duration"

	if [[ ${exit_code} -eq 0 ]]; then
		log_ok "${os} test completed (${duration}s)"
	else
		log_error "${os} test failed with exit code ${exit_code} (${duration}s)"
	fi

	return ${exit_code}
}

# ============================================================
# Generate Summary Report
# ============================================================
generate_summary() {
	local summary_file="${BASE_WORKDIR}/parallel-summary.md"
	local timestamp
	timestamp=$(date '+%Y-%m-%d %H:%M:%S')

	log_info "Generating summary report..."

	cat > "${summary_file}" <<EOF
# Parallel Docker Test Summary

Run ID: ${RUN_ID}
Generated: ${timestamp}
Base Directory: ${BASE_WORKDIR}

## Configuration

| Setting | Value |
|---------|-------|
| Skip E2E | ${SKIP_E2E} |
| Only Step | ${ONLY_STEP:-all} |
| Jira Project | ${JIRA_PROJECT_KEY} |
| GitLab Group | ${DEMO_GITLAB_GROUP} |

## Results

| OS | Status | Duration | Exit Code |
|----|--------|----------|-----------|
EOF

	local overall_success=true

	for os in ubuntu ubi9; do
		local workdir="${BASE_WORKDIR}/${os}"
		local status="N/A"
		local duration="N/A"
		local exit_code="N/A"

		if [[ -f "${workdir}/.exit_code" ]]; then
			exit_code=$(cat "${workdir}/.exit_code")
			if [[ "${exit_code}" == "0" ]]; then
				status="PASS"
			else
				status="FAIL"
				overall_success=false
			fi
		else
			status="NOT RUN"
			overall_success=false
		fi

		if [[ -f "${workdir}/.duration" ]]; then
			duration="$(cat "${workdir}/.duration")s"
		fi

		echo "| ${os} | ${status} | ${duration} | ${exit_code} |" >> "${summary_file}"
	done

	cat >> "${summary_file}" <<EOF

## Output Files

### Ubuntu

- Build Log: [ubuntu/docker-build.log](ubuntu/docker-build.log)
- Run Log: [ubuntu/docker-run.log](ubuntu/docker-run.log)
- Runner Log: [ubuntu/parallel-runner.log](ubuntu/parallel-runner.log)
- Installation Report: [ubuntu/installation-report.md](ubuntu/installation-report.md)
- Demo Output: [ubuntu/demo-output/](ubuntu/demo-output/)

### UBI9

- Build Log: [ubi9/docker-build.log](ubi9/docker-build.log)
- Run Log: [ubi9/docker-run.log](ubi9/docker-run.log)
- Runner Log: [ubi9/parallel-runner.log](ubi9/parallel-runner.log)
- Installation Report: [ubi9/installation-report.md](ubi9/installation-report.md)
- Demo Output: [ubi9/demo-output/](ubi9/demo-output/)

## Quick Review Commands

\`\`\`bash
# View Ubuntu results
cat ${BASE_WORKDIR}/ubuntu/docker-run.log | tail -100

# View UBI9 results
cat ${BASE_WORKDIR}/ubi9/docker-run.log | tail -100

# Check for errors
grep -i "error\|fail\|NG" ${BASE_WORKDIR}/*/docker-run.log
\`\`\`

---
*Generated by run-docker-parallel.sh*
EOF

	log_ok "Summary written to: ${summary_file}"

	if [[ "${overall_success}" == "true" ]]; then
		return 0
	else
		return 1
	fi
}

# ============================================================
# Main
# ============================================================
main() {
	log_header "Agent-Context Docker Test Runner"

	echo "Configuration:"
	echo "  Run ID:        ${RUN_ID}"
	echo "  Base Workdir:  ${BASE_WORKDIR}"
	echo "  Serial Mode:   ${SERIAL_MODE}"
	echo "  Skip E2E:      ${SKIP_E2E}"
	echo "  Only Step:     ${ONLY_STEP:-all}"
	echo "  Jira Project:  ${JIRA_PROJECT_KEY}"
	echo "  GitLab Group:  ${DEMO_GITLAB_GROUP}"
	echo ""

	# Preflight
	preflight_check

	# Create base workdir
	mkdir -p "${BASE_WORKDIR}"

	local ubuntu_exit=0 ubi9_exit=0

	if [[ "${SERIAL_MODE}" == "true" ]]; then
		log_header "Running Tests Sequentially (Serial Mode)"

		run_os_test "ubuntu" || ubuntu_exit=$?

		if [[ ${ubuntu_exit} -eq 0 ]]; then
			log_ok "Ubuntu: PASSED"
			run_os_test "ubi9" || ubi9_exit=$?
		else
			log_error "Ubuntu: FAILED (exit code: ${ubuntu_exit})"
			log_warn "Skipping UBI9 test due to Ubuntu failure"
			ubi9_exit=1
		fi
	else
		log_header "Running Tests in Parallel"

		# Start both tests in background
		local ubuntu_pid ubi9_pid

		run_os_test "ubuntu" &
		ubuntu_pid=$!

		run_os_test "ubi9" &
		ubi9_pid=$!

		log_info "Started Ubuntu test (PID: ${ubuntu_pid})"
		log_info "Started UBI9 test (PID: ${ubi9_pid})"
		log_info "Waiting for both tests to complete..."
		echo ""

		# Wait for both and capture exit codes
		wait ${ubuntu_pid} || ubuntu_exit=$?
		wait ${ubi9_pid} || ubi9_exit=$?
	fi

	log_header "Test Results"

	if [[ ${ubuntu_exit} -eq 0 ]]; then
		log_ok "Ubuntu: PASSED"
	else
		log_error "Ubuntu: FAILED (exit code: ${ubuntu_exit})"
	fi

	if [[ ${ubi9_exit} -eq 0 ]]; then
		log_ok "UBI9: PASSED"
	else
		log_error "UBI9: FAILED (exit code: ${ubi9_exit})"
	fi

	echo ""

	# Generate summary
	local summary_exit=0
	generate_summary || summary_exit=$?

	# Final status
	log_header "Final Summary"

	echo "Results directory: ${BASE_WORKDIR}"
	echo ""
	echo "Quick view commands:"
	echo "  cat ${BASE_WORKDIR}/parallel-summary.md"
	echo "  ls -la ${BASE_WORKDIR}/*/"
	echo ""

	if [[ ${ubuntu_exit} -eq 0 ]] && [[ ${ubi9_exit} -eq 0 ]]; then
		log_ok "All tests passed!"
		exit 0
	else
		log_error "Some tests failed"
		echo ""
		echo "To investigate failures:"
		if [[ ${ubuntu_exit} -ne 0 ]]; then
			echo "  # Ubuntu failure:"
			echo "  cat ${BASE_WORKDIR}/ubuntu/docker-run.log | tail -50"
		fi
		if [[ ${ubi9_exit} -ne 0 ]]; then
			echo "  # UBI9 failure:"
			echo "  cat ${BASE_WORKDIR}/ubi9/docker-run.log | tail -50"
		fi
		exit 1
	fi
}

main "$@"
