#!/bin/bash
# Step 005: PM Connectivity Test
# Test that pm CLI can connect to Jira/Confluence
#
# Usage:
#   ./005-pm-test.sh run
#   ./005-pm-test.sh verify

source "$(dirname "$0")/lib.sh"

STEP_NUM="005"
STEP_NAME="PM Connectivity Test"

step_run() {
	log_step "${STEP_NUM}" "${STEP_NAME}"

	local any_project="${WORKDIR}/any-project"
	local pm_bin="${any_project}/.agent/tools/pm/bin/pm"

	if [[ ! -x "${pm_bin}" ]]; then
		log_error "pm CLI not found or not executable: ${pm_bin}"
		return 1
	fi

	# Change to project directory for pm to find .project.yaml
	cd "${any_project}" || exit 1

	log_info "Testing pm CLI..."

	# Test pm config
	log_info "Running: pm config show"
	if "${pm_bin}" config show; then
		log_ok "pm config show succeeded"
	else
		log_warn "pm config show failed (may need configuration)"
	fi

	# Skip API tests if SKIP_E2E is set
	if [[ "${SKIP_E2E}" == "true" ]]; then
		log_info "Skipping E2E API tests (--skip-e2e)"
		mark_step_done "${STEP_NUM}"
		return 0
	fi

	# Check secrets before API calls
	if ! check_secrets; then
		log_error "Secrets not configured. Cannot run E2E tests."
		log_info "Set SKIP_E2E=true to skip API tests"
		return 1
	fi

	# Test Jira connectivity
	log_info "Testing Jira connectivity: pm jira me"
	if "${pm_bin}" jira me; then
		log_ok "Jira connectivity verified"
	else
		log_error "Jira connectivity failed"
		log_info "Troubleshooting:"
		log_info "  - Check JIRA_EMAIL is correct"
		log_info "  - Check ~/.secrets/atlassian-api-token is valid"
		log_info "  - Check .project.yaml has correct base_url"
		return 1
	fi

	# Test Confluence connectivity (optional)
	log_info "Testing Confluence connectivity: pm confluence me"
	if "${pm_bin}" confluence me 2>/dev/null; then
		log_ok "Confluence connectivity verified"
	else
		log_warn "Confluence connectivity failed (may need space_key configuration)"
	fi

	mark_step_done "${STEP_NUM}"
	log_ok "PM connectivity tests completed"
}

step_verify() {
	log_info "Verifying step ${STEP_NUM}..."

	local any_project="${WORKDIR}/any-project"
	local pm_bin="${any_project}/.agent/tools/pm/bin/pm"
	local failed=0

	# Verify pm exists and is executable
	if ! verify_executable "${pm_bin}" "pm CLI"; then
		return 1
	fi

	# Skip E2E verification if requested
	if [[ "${SKIP_E2E}" == "true" ]]; then
		log_info "Skipping E2E verification (--skip-e2e)"
		log_ok "Step ${STEP_NUM} verified (offline mode)"
		return 0
	fi

	# Change to project directory
	cd "${any_project}" || exit 1

	# Verify Jira connectivity
	log_info "Verifying Jira connectivity..."
	if "${pm_bin}" jira me &>/dev/null; then
		log_ok "Jira API accessible"
	else
		log_error "Jira API not accessible"
		((failed++)) || true
	fi

	if [[ ${failed} -gt 0 ]]; then
		log_error "Verification failed: ${failed} issue(s)"
		return 1
	fi

	log_ok "Step ${STEP_NUM} verified"
	return 0
}

run_step "$@"
