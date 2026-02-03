#!/bin/bash
# Step 006: Static Tests
# Run repository's built-in verification scripts
#
# Usage:
#   ./006-static-tests.sh run
#   ./006-static-tests.sh verify

source "$(dirname "$0")/lib.sh"

STEP_NUM="006"
STEP_NAME="Static Tests"

step_run() {
	log_step "${STEP_NUM}" "${STEP_NAME}"

	log_info "Running static verification scripts..."

	local failed=0

	# Run skills verification
	log_info "Running: tests/skills/verify.sh"
	if [[ -f "${AGENT_CONTEXT_ROOT}/tests/skills/verify.sh" ]]; then
		if bash "${AGENT_CONTEXT_ROOT}/tests/skills/verify.sh"; then
			log_ok "Skills verification passed"
		else
			log_error "Skills verification failed"
			((failed++)) || true
		fi
	else
		log_warn "Skills verification script not found"
	fi

	# Run workflows verification
	log_info "Running: tests/workflows/verify.sh"
	if [[ -f "${AGENT_CONTEXT_ROOT}/tests/workflows/verify.sh" ]]; then
		if bash "${AGENT_CONTEXT_ROOT}/tests/workflows/verify.sh"; then
			log_ok "Workflows verification passed"
		else
			log_error "Workflows verification failed"
			((failed++)) || true
		fi
	else
		log_warn "Workflows verification script not found"
	fi

	if [[ ${failed} -gt 0 ]]; then
		log_error "Static tests failed: ${failed} test(s)"
		return 1
	fi

	mark_step_done "${STEP_NUM}"
	log_ok "Static tests completed"
}

step_verify() {
	log_info "Verifying step ${STEP_NUM}..."

	local failed=0

	# Re-run verifications to confirm
	if [[ -f "${AGENT_CONTEXT_ROOT}/tests/skills/verify.sh" ]]; then
		if bash "${AGENT_CONTEXT_ROOT}/tests/skills/verify.sh" &>/dev/null; then
			log_ok "Skills verification passes"
		else
			log_error "Skills verification fails"
			((failed++)) || true
		fi
	fi

	if [[ -f "${AGENT_CONTEXT_ROOT}/tests/workflows/verify.sh" ]]; then
		if bash "${AGENT_CONTEXT_ROOT}/tests/workflows/verify.sh" &>/dev/null; then
			log_ok "Workflows verification passes"
		else
			log_error "Workflows verification fails"
			((failed++)) || true
		fi
	fi

	if [[ ${failed} -gt 0 ]]; then
		log_error "Verification failed: ${failed} issue(s)"
		return 1
	fi

	log_ok "Step ${STEP_NUM} verified"
	return 0
}

run_step "$@"
