#!/bin/bash
# CI Test Runner - Runs all available tests locally
# Simulates what GitLab CI would execute
#
# Usage:
#   ./tests/ci/run-all.sh [--skip-docker] [--skip-e2e] [--only STAGE]
#
# Stages:
#   lint    - Pre-commit lint checks
#   unit    - Unit tests (version, help, tests list)
#   smoke   - Smoke tests (Layer 0 + Layer 1 - token-free)
#   docker  - Docker-based install tests (ubuntu, ubi9)
#   e2e     - E2E tests (requires tokens + network)

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Ensure AGENT_CONTEXT_DIR is set for tests to locate agent-context resources
export AGENT_CONTEXT_DIR="${AGENT_CONTEXT_DIR:-${ROOT_DIR}}"

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
	echo -e "${BOLD}${CYAN}========================================${NC}"
	echo -e "${BOLD}${CYAN}  $1${NC}"
	echo -e "${BOLD}${CYAN}========================================${NC}"
	echo ""
}

# ============================================================
# Configuration
# ============================================================
SKIP_DOCKER=false
SKIP_E2E=true
ONLY_STAGE=""
RESULTS_DIR="${ROOT_DIR}/.context/test-results"

# ============================================================
# Argument Parsing
# ============================================================
while [[ $# -gt 0 ]]; do
	case "$1" in
		--skip-docker)
			SKIP_DOCKER=true
			;;
		--skip-e2e)
			SKIP_E2E=true
			;;
		--with-e2e)
			SKIP_E2E=false
			;;
		--only)
			ONLY_STAGE="$2"
			shift
			;;
		-h|--help)
			echo "Usage: $(basename "$0") [--skip-docker] [--skip-e2e] [--with-e2e] [--only STAGE]"
			echo ""
			echo "Stages: lint, unit, smoke, install, docker, e2e"
			exit 0
			;;
		*)
			log_error "Unknown option: $1"
			exit 1
			;;
	esac
	shift
done

# ============================================================
# Result Tracking (bash 3.2 compatible)
# ============================================================
# Store results as "stage:result" entries in a string
STAGE_RESULTS=""
TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_SKIP=0

record_result() {
	local stage="$1"
	local result="$2"
	# Append to results string
	STAGE_RESULTS="${STAGE_RESULTS}${stage}:${result};"
	case "${result}" in
		PASS) TOTAL_PASS=$((TOTAL_PASS + 1)) ;;
		FAIL) TOTAL_FAIL=$((TOTAL_FAIL + 1)) ;;
		SKIP) TOTAL_SKIP=$((TOTAL_SKIP + 1)) ;;
	esac
}

# Get result for a stage (bash 3.2 compatible)
get_result() {
	local stage="$1"
	local entry
	entry=$(echo "${STAGE_RESULTS}" | tr ';' '\n' | grep "^${stage}:" | tail -1)
	if [[ -n "${entry}" ]]; then
		echo "${entry#*:}"
	else
		echo "N/A"
	fi
}

should_run() {
	local stage="$1"
	if [[ -n "${ONLY_STAGE}" ]] && [[ "${ONLY_STAGE}" != "${stage}" ]]; then
		return 1
	fi
	return 0
}

# ============================================================
# Stage: Lint
# ============================================================
run_lint() {
	log_header "Stage: Lint"

	if ! command -v pre-commit &>/dev/null; then
		log_warn "pre-commit not found, skipping lint"
		record_result "lint" "SKIP"
		return 0
	fi

	if pre-commit run --all-files; then
		log_ok "Lint passed"
		record_result "lint" "PASS"
	else
		log_error "Lint failed"
		record_result "lint" "FAIL"
	fi
}

# ============================================================
# Stage: Unit
# ============================================================
run_unit() {
	log_header "Stage: Unit Tests"

	local failed=0

	# Version
	if "${ROOT_DIR}/bin/agent-context.sh" --version 2>&1 | grep -qE '[0-9]+\.[0-9]+\.[0-9]+'; then
		log_ok "version output valid"
	else
		log_error "version output invalid"
		failed=1
	fi

	# Help
	if "${ROOT_DIR}/bin/agent-context.sh" --help 2>&1 | grep -q "USAGE"; then
		log_ok "help output valid"
	else
		log_error "help output invalid"
		failed=1
	fi

	# Tests list (use variable to avoid SIGPIPE with grep -q and pipefail)
	local tests_output
	tests_output=$("${ROOT_DIR}/bin/agent-context.sh" tests list 2>&1) || true
	if echo "${tests_output}" | grep -qE "deps|prereq"; then
		log_ok "tests list contains expected tags"
	else
		log_error "tests list missing expected tags"
		failed=1
	fi

	if [[ ${failed} -eq 0 ]]; then
		log_ok "Unit tests passed"
		record_result "unit" "PASS"
	else
		log_error "Unit tests failed"
		record_result "unit" "FAIL"
	fi
}

# ============================================================
# Stage: Smoke
# ============================================================
run_smoke() {
	log_header "Stage: Smoke Tests"

	if "${ROOT_DIR}/bin/agent-context.sh" tests smoke; then
		log_ok "Smoke tests passed"
		record_result "smoke" "PASS"
	else
		log_error "Smoke tests failed"
		record_result "smoke" "FAIL"
	fi
}

# ============================================================
# Stage: Docker
# ============================================================
run_docker() {
	log_header "Stage: Docker Install Tests"

	if [[ "${SKIP_DOCKER}" == "true" ]]; then
		log_warn "Docker tests skipped (--skip-docker)"
		record_result "docker-ubuntu" "SKIP"
		record_result "docker-ubi9" "SKIP"
		return 0
	fi

	if ! command -v docker &>/dev/null; then
		log_warn "Docker not found, skipping"
		record_result "docker-ubuntu" "SKIP"
		record_result "docker-ubi9" "SKIP"
		return 0
	fi

	if ! docker info &>/dev/null; then
		log_warn "Docker daemon not running, skipping"
		record_result "docker-ubuntu" "SKIP"
		record_result "docker-ubi9" "SKIP"
		return 0
	fi

	# Ubuntu
	log_info "Running Docker install test (Ubuntu)..."
	if "${ROOT_DIR}/demo/install.sh" --os ubuntu --skip-e2e --only 6; then
		log_ok "Docker install (Ubuntu) passed"
		record_result "docker-ubuntu" "PASS"
	else
		log_error "Docker install (Ubuntu) failed"
		record_result "docker-ubuntu" "FAIL"
	fi

	# UBI9
	log_info "Running Docker install test (UBI9)..."
	if "${ROOT_DIR}/demo/install.sh" --os ubi9 --skip-e2e --only 6; then
		log_ok "Docker install (UBI9) passed"
		record_result "docker-ubi9" "PASS"
	else
		log_error "Docker install (UBI9) failed"
		record_result "docker-ubi9" "FAIL"
	fi
}

# ============================================================
# Stage: E2E
# ============================================================
run_e2e() {
	log_header "Stage: E2E Tests"

	if [[ "${SKIP_E2E}" == "true" ]]; then
		log_warn "E2E tests skipped (--skip-e2e)"
		record_result "e2e" "SKIP"
		return 0
	fi

	if "${ROOT_DIR}/demo/install.sh" --e2e-optional; then
		log_ok "E2E tests passed"
		record_result "e2e" "PASS"
	else
		log_error "E2E tests failed"
		record_result "e2e" "FAIL"
	fi
}

# ============================================================
# Summary
# ============================================================
print_summary() {
	log_header "Test Summary"

	printf "%-20s %s\n" "STAGE" "RESULT"
	printf "%-20s %s\n" "-----" "------"

	for stage in lint unit smoke docker-ubuntu docker-ubi9 e2e; do
		local result
		result=$(get_result "${stage}")
		case "${result}" in
			PASS)
				printf "%-20s ${GREEN}%s${NC}\n" "${stage}" "${result}"
				;;
			FAIL)
				printf "%-20s ${RED}%s${NC}\n" "${stage}" "${result}"
				;;
			SKIP)
				printf "%-20s ${YELLOW}%s${NC}\n" "${stage}" "${result}"
				;;
			*)
				printf "%-20s %s\n" "${stage}" "${result}"
				;;
		esac
	done

	echo ""
	echo "Total: pass=${TOTAL_PASS} fail=${TOTAL_FAIL} skip=${TOTAL_SKIP}"

	# Write results to file
	mkdir -p "${RESULTS_DIR}"
	local timestamp
	timestamp=$(date '+%Y%m%d_%H%M%S')
	local result_file="${RESULTS_DIR}/ci-run-${timestamp}.md"

	cat > "${result_file}" <<EOF
# CI Test Results

Date: $(date '+%Y-%m-%d %H:%M:%S')
Branch: $(git -C "${ROOT_DIR}" branch --show-current 2>/dev/null || echo "unknown")
Commit: $(git -C "${ROOT_DIR}" rev-parse --short HEAD 2>/dev/null || echo "unknown")

## Results

| Stage | Result |
|-------|--------|
EOF

	for stage in lint unit smoke docker-ubuntu docker-ubi9 e2e; do
		local result
		result=$(get_result "${stage}")
		echo "| ${stage} | ${result} |" >> "${result_file}"
	done

	cat >> "${result_file}" <<EOF

## Summary

- Pass: ${TOTAL_PASS}
- Fail: ${TOTAL_FAIL}
- Skip: ${TOTAL_SKIP}
EOF

	log_info "Results written to: ${result_file}"
}

# ============================================================
# Main
# ============================================================
main() {
	log_header "Agent-Context CI Test Runner"

	echo "Configuration:"
	echo "  Skip Docker: ${SKIP_DOCKER}"
	echo "  Skip E2E:    ${SKIP_E2E}"
	echo "  Only Stage:  ${ONLY_STAGE:-all}"
	echo ""

	should_run "lint" && run_lint
	should_run "unit" && run_unit
	should_run "smoke" && run_smoke
	# Note: install is now part of smoke (install-non-interactive tag)
	should_run "docker" && run_docker
	should_run "e2e" && run_e2e

	print_summary

	if [[ ${TOTAL_FAIL} -gt 0 ]]; then
		exit 1
	fi
	exit 0
}

main "$@"
