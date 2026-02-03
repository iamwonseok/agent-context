#!/bin/bash
# Step 007: Demo Check
# Run demo/scenario/demo.sh check to verify demo prerequisites
#
# Usage:
#   ./007-demo-check.sh run
#   ./007-demo-check.sh verify

source "$(dirname "$0")/lib.sh"

STEP_NUM="007"
STEP_NAME="Demo Prerequisites Check"

step_run() {
	log_step "${STEP_NUM}" "${STEP_NAME}"

	local demo_script="${AGENT_CONTEXT_ROOT}/demo/scenario/demo.sh"

	if [[ ! -f "${demo_script}" ]]; then
		log_error "demo.sh not found: ${demo_script}"
		return 1
	fi

	log_info "Running: demo.sh check"
	echo ""

	if bash "${demo_script}" check; then
		log_ok "Demo prerequisites check passed"
		mark_step_done "${STEP_NUM}"
	else
		log_error "Demo prerequisites check failed"
		log_info "Install missing dependencies before continuing"
		return 1
	fi
}

step_verify() {
	log_info "Verifying step ${STEP_NUM}..."

	local demo_script="${AGENT_CONTEXT_ROOT}/demo/scenario/demo.sh"

	if [[ ! -f "${demo_script}" ]]; then
		log_error "demo.sh not found"
		return 1
	fi

	# Run check in quiet mode
	if bash "${demo_script}" check &>/dev/null; then
		log_ok "Demo prerequisites satisfied"
		return 0
	else
		log_error "Demo prerequisites not satisfied"
		return 1
	fi
}

run_step "$@"
