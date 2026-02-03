#!/bin/bash
# Step 003: Run install.sh
# Install agent-context into target project
#
# Usage:
#   ./003-install.sh run
#   ./003-install.sh verify

source "$(dirname "$0")/lib.sh"

STEP_NUM="003"
STEP_NAME="Install agent-context"

step_run() {
	log_step "${STEP_NUM}" "${STEP_NAME}"

	local any_project="${WORKDIR}/any-project"
	local installer="${AGENT_CONTEXT_ROOT}/install.sh"

	# Verify installer exists
	if [[ ! -f "${installer}" ]]; then
		log_error "Installer not found: ${installer}"
		return 1
	fi

	log_info "Running install.sh with profile: ${PROFILE}"
	log_info "Target: ${any_project}"

	# Build install command
	local install_cmd=("bash" "${installer}" "--profile" "${PROFILE}" "--non-interactive")

	# Add force if set
	if [[ "${FORCE:-false}" == "true" ]]; then
		install_cmd+=("--force")
	fi

	# Add Jira settings if available
	if [[ -n "${JIRA_BASE_URL}" ]]; then
		install_cmd+=("--jira-url" "${JIRA_BASE_URL}")
	fi
	if [[ -n "${JIRA_PROJECT_KEY}" ]]; then
		install_cmd+=("--jira-project" "${JIRA_PROJECT_KEY}")
	fi
	if [[ -n "${JIRA_EMAIL}" ]]; then
		install_cmd+=("--jira-email" "${JIRA_EMAIL}")
	fi

	# Add target directory
	install_cmd+=("${any_project}")

	# Run installer
	echo ""
	if "${install_cmd[@]}"; then
		log_ok "Installation completed"
		mark_step_done "${STEP_NUM}"
	else
		log_error "Installation failed"
		return 1
	fi
}

step_verify() {
	log_info "Verifying step ${STEP_NUM}..."

	local any_project="${WORKDIR}/any-project"
	local failed=0

	# Core files (both profiles)
	log_info "Checking core files..."
	if ! verify_file_exists "${any_project}/.cursorrules" ".cursorrules"; then
		((failed++)) || true
	fi
	if ! verify_file_exists "${any_project}/.project.yaml" ".project.yaml"; then
		((failed++)) || true
	fi

	# .agent directory structure
	log_info "Checking .agent directory..."
	if ! verify_dir_exists "${any_project}/.agent" ".agent/"; then
		((failed++)) || true
	fi
	if ! verify_dir_exists "${any_project}/.agent/skills" ".agent/skills/"; then
		((failed++)) || true
	fi
	if ! verify_dir_exists "${any_project}/.agent/workflows" ".agent/workflows/"; then
		((failed++)) || true
	fi
	if ! verify_dir_exists "${any_project}/.agent/tools/pm" ".agent/tools/pm/"; then
		((failed++)) || true
	fi

	# Check pm executable
	local pm_bin="${any_project}/.agent/tools/pm/bin/pm"
	if ! verify_executable "${pm_bin}" "pm CLI"; then
		((failed++)) || true
	fi

	# Full profile: check config files
	if [[ "${PROFILE}" == "full" ]]; then
		log_info "Checking config files (full profile)..."

		local config_files=(
			".editorconfig"
			".pre-commit-config.yaml"
			".shellcheckrc"
			".yamllint.yml"
			".hadolint.yaml"
			".clang-format"
			".clang-tidy"
			".flake8"
		)

		for cfg in "${config_files[@]}"; do
			if [[ -f "${any_project}/${cfg}" ]]; then
				log_ok "Found: ${cfg}"
			else
				log_warn "Missing: ${cfg} (may be optional)"
			fi
		done
	fi

	# Minimal profile: verify config files are NOT present
	if [[ "${PROFILE}" == "minimal" ]]; then
		log_info "Verifying minimal profile (no config files)..."
		if [[ -f "${any_project}/.editorconfig" ]]; then
			log_warn ".editorconfig should not be present in minimal profile"
		else
			log_ok "No .editorconfig (correct for minimal)"
		fi
	fi

	# Check .cursorrules has index map marker
	if grep -q "BEGIN AGENT_CONTEXT INDEX MAP" "${any_project}/.cursorrules" 2>/dev/null; then
		log_ok ".cursorrules has index map"
	else
		log_warn ".cursorrules missing index map marker"
	fi

	if [[ ${failed} -gt 0 ]]; then
		log_error "Verification failed: ${failed} critical issue(s)"
		return 1
	fi

	log_ok "Step ${STEP_NUM} verified"
	return 0
}

run_step "$@"
