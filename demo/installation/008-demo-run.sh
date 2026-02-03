#!/bin/bash
# Step 008: Demo Run (E2E)
# Run demo/demo.sh run for full E2E test
#
# Usage:
#   ./008-demo-run.sh run
#   ./008-demo-run.sh verify

source "$(dirname "$0")/lib.sh"

STEP_NUM="008"
STEP_NAME="Demo E2E Run"

step_run() {
	log_step "${STEP_NUM}" "${STEP_NAME}"

	# Skip if E2E is disabled
	if [[ "${SKIP_E2E}" == "true" ]]; then
		log_info "Skipping E2E demo (--skip-e2e)"
		mark_step_done "${STEP_NUM}"
		return 0
	fi

	local demo_script="${AGENT_CONTEXT_ROOT}/demo/scenario/demo.sh"

	if [[ ! -f "${demo_script}" ]]; then
		log_error "demo.sh not found: ${demo_script}"
		return 1
	fi

	# Check secrets before running
	if ! check_secrets; then
		log_error "Secrets not configured for E2E test"
		return 1
	fi

	log_info "Running: demo.sh run"
	log_warn "This will create real Jira issues and GitLab branches"
	echo ""

	# Run demo with output directory in WORKDIR
	local output_dir="${WORKDIR}/demo-output"
	mkdir -p "${output_dir}"

	# Set environment for demo
	export DEMO_OUTPUT_DIR="${output_dir}"

	if bash "${demo_script}" run; then
		log_ok "Demo E2E completed successfully"
		mark_step_done "${STEP_NUM}"

		# Show output location
		log_info "Demo output saved to: ${output_dir}"
	else
		log_error "Demo E2E failed"
		log_info "Check logs in: ${output_dir}"
		return 1
	fi
}

step_verify() {
	log_info "Verifying step ${STEP_NUM}..."

	# Skip verification if E2E is disabled
	if [[ "${SKIP_E2E}" == "true" ]]; then
		log_info "E2E was skipped"
		log_ok "Step ${STEP_NUM} verified (skipped)"
		return 0
	fi

	local output_dir="${WORKDIR}/demo-output"

	# Check if demo produced output
	if [[ -d "${output_dir}" ]]; then
		log_ok "Demo output directory exists"

		# Check for report file
		local report_count
		report_count=$(find "${output_dir}" -name "*.md" -type f 2>/dev/null | wc -l)
		if [[ ${report_count} -gt 0 ]]; then
			log_ok "Found ${report_count} report file(s)"
		else
			log_warn "No report files found in output"
		fi
	else
		log_error "Demo output directory not found"
		return 1
	fi

	log_ok "Step ${STEP_NUM} verified"
	return 0
}

run_step "$@"
