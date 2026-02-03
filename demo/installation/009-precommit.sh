#!/bin/bash
# Step 009: Pre-commit (Best Effort)
# Run pre-commit checks - failures are logged but don't block
#
# Usage:
#   ./009-precommit.sh run
#   ./009-precommit.sh verify

source "$(dirname "$0")/lib.sh"

STEP_NUM="009"
STEP_NAME="Pre-commit (Best Effort)"

step_run() {
	log_step "${STEP_NUM}" "${STEP_NAME}"

	local any_project="${WORKDIR}/any-project"

	# Check if pre-commit is available
	if ! command -v pre-commit &>/dev/null; then
		log_warn "pre-commit not installed"
		log_info "Install: pip install pre-commit"
		log_info "Skipping pre-commit checks (best-effort)"
		mark_step_done "${STEP_NUM}"
		return 0
	fi

	log_ok "pre-commit is available: $(pre-commit --version)"

	# Check if target has pre-commit config
	if [[ ! -f "${any_project}/.pre-commit-config.yaml" ]]; then
		log_warn "No .pre-commit-config.yaml in target project"
		log_info "Profile 'full' includes pre-commit config"
		mark_step_done "${STEP_NUM}"
		return 0
	fi

	# Change to project directory
	cd "${any_project}" || exit 1

	# Install pre-commit hooks (optional, for info)
	log_info "Installing pre-commit hooks..."
	if pre-commit install 2>/dev/null; then
		log_ok "Pre-commit hooks installed"
	else
		log_warn "Could not install pre-commit hooks"
	fi

	# Run pre-commit (best-effort)
	log_info "Running: pre-commit run --all-files"
	log_warn "This is best-effort: failures will be logged but won't block"
	echo ""

	local precommit_log="${WORKDIR}/precommit.log"

	if pre-commit run --all-files 2>&1 | tee "${precommit_log}"; then
		log_ok "Pre-commit checks passed"
	else
		log_warn "Pre-commit checks had failures"
		log_info "See log: ${precommit_log}"
		log_info ""
		log_info "Common fixes:"
		log_info "  - Install missing tools (shellcheck, black, etc.)"
		log_info "  - Run auto-formatters: pre-commit run --all-files"
		log_info "  - Some hooks may require manual fixes"
		# Don't return error - this is best-effort
	fi

	mark_step_done "${STEP_NUM}"
	log_ok "Pre-commit step completed (best-effort)"
}

step_verify() {
	log_info "Verifying step ${STEP_NUM}..."

	# This step is always considered passed (best-effort)
	# We just check if pre-commit was attempted

	if is_step_done "${STEP_NUM}"; then
		log_ok "Pre-commit step was executed"
	else
		log_warn "Pre-commit step was not executed"
	fi

	# Check if there's a log file
	local precommit_log="${WORKDIR}/precommit.log"
	if [[ -f "${precommit_log}" ]]; then
		local fail_count
		fail_count=$(grep -c "Failed" "${precommit_log}" 2>/dev/null | head -1 || echo "0")
		fail_count="${fail_count:-0}"
		if [[ "${fail_count}" =~ ^[0-9]+$ ]] && [[ "${fail_count}" -gt 0 ]]; then
			log_warn "Pre-commit had ${fail_count} failure(s) (best-effort, not blocking)"
		else
			log_ok "Pre-commit log exists, no failures found"
		fi
	fi

	# Always pass - this is best-effort
	log_ok "Step ${STEP_NUM} verified (best-effort)"
	return 0
}

run_step "$@"
