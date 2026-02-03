#!/bin/bash
# Step 004: Configure .project.yaml
# Update .project.yaml with actual values and verify configuration
#
# Usage:
#   ./004-configure.sh run
#   ./004-configure.sh verify

source "$(dirname "$0")/lib.sh"

STEP_NUM="004"
STEP_NAME="Configure project"

# Default test values
: "${JIRA_BASE_URL:=https://fadutec.atlassian.net}"
: "${JIRA_PROJECT_KEY:=SVI4}"
: "${CONFLUENCE_SPACE_KEY:=~712020e8e25da88c5fcd91adb98f91b94e79cf}"

step_run() {
	log_step "${STEP_NUM}" "${STEP_NAME}"

	local any_project="${WORKDIR}/any-project"
	local project_yaml="${any_project}/.project.yaml"

	if [[ ! -f "${project_yaml}" ]]; then
		log_error ".project.yaml not found"
		return 1
	fi

	log_info "Configuring .project.yaml..."
	log_info "  Jira URL: ${JIRA_BASE_URL}"
	log_info "  Jira Project: ${JIRA_PROJECT_KEY}"
	log_info "  Jira Email: ${JIRA_EMAIL:-<not set>}"

	# Check if yq is available
	if ! command -v yq &>/dev/null; then
		log_warn "yq not available, using sed for configuration"

		# Use sed for basic replacements
		if [[ -n "${JIRA_BASE_URL}" ]]; then
			sed -i.bak "s|base_url: https://CHANGE_ME.atlassian.net|base_url: ${JIRA_BASE_URL}|g" "${project_yaml}"
		fi
		if [[ -n "${JIRA_PROJECT_KEY}" ]]; then
			sed -i.bak "s|project_key: CHANGE_ME|project_key: ${JIRA_PROJECT_KEY}|g" "${project_yaml}"
		fi
		if [[ -n "${JIRA_EMAIL}" ]]; then
			sed -i.bak "s|email: CHANGE_ME@example.com|email: ${JIRA_EMAIL}|g" "${project_yaml}"
		fi
		if [[ -n "${CONFLUENCE_SPACE_KEY}" ]]; then
			sed -i.bak "s|space_key: CHANGE_ME|space_key: ${CONFLUENCE_SPACE_KEY}|g" "${project_yaml}"
		fi

		# Clean up backup files
		rm -f "${project_yaml}.bak"
	else
		# Use yq for proper YAML editing
		if [[ -n "${JIRA_BASE_URL}" ]]; then
			yq -i ".platforms.jira.base_url = \"${JIRA_BASE_URL}\"" "${project_yaml}"
			yq -i ".platforms.confluence.base_url = \"${JIRA_BASE_URL}\"" "${project_yaml}"
		fi
		if [[ -n "${JIRA_PROJECT_KEY}" ]]; then
			yq -i ".platforms.jira.project_key = \"${JIRA_PROJECT_KEY}\"" "${project_yaml}"
		fi
		if [[ -n "${JIRA_EMAIL}" ]]; then
			yq -i ".platforms.jira.email = \"${JIRA_EMAIL}\"" "${project_yaml}"
		fi
		if [[ -n "${CONFLUENCE_SPACE_KEY}" ]]; then
			yq -i ".platforms.confluence.space_key = \"${CONFLUENCE_SPACE_KEY}\"" "${project_yaml}"
		fi
	fi

	log_ok "Configuration updated"

	# Show current config
	log_info "Current configuration:"
	if command -v yq &>/dev/null; then
		echo "  Jira URL: $(yq '.platforms.jira.base_url' "${project_yaml}")"
		echo "  Jira Project: $(yq '.platforms.jira.project_key' "${project_yaml}")"
		echo "  Jira Email: $(yq '.platforms.jira.email' "${project_yaml}")"
	else
		grep -E "base_url:|project_key:|email:" "${project_yaml}" | head -5
	fi

	mark_step_done "${STEP_NUM}"
}

step_verify() {
	log_info "Verifying step ${STEP_NUM}..."

	local any_project="${WORKDIR}/any-project"
	local project_yaml="${any_project}/.project.yaml"
	local failed=0

	if [[ ! -f "${project_yaml}" ]]; then
		log_error ".project.yaml not found"
		return 1
	fi

	# Check for CHANGE_ME placeholders
	if grep -q "CHANGE_ME" "${project_yaml}"; then
		log_warn "Configuration still has CHANGE_ME placeholders"
		grep "CHANGE_ME" "${project_yaml}" | while read -r line; do
			log_warn "  ${line}"
		done
		# Not a failure - user may want to configure later
	else
		log_ok "No CHANGE_ME placeholders found"
	fi

	# Verify required fields have values
	if command -v yq &>/dev/null; then
		local jira_url
		jira_url=$(yq '.platforms.jira.base_url' "${project_yaml}")
		if [[ "${jira_url}" == "null" ]] || [[ -z "${jira_url}" ]]; then
			log_error "Jira base_url not configured"
			((failed++)) || true
		else
			log_ok "Jira base_url configured: ${jira_url}"
		fi

		local jira_project
		jira_project=$(yq '.platforms.jira.project_key' "${project_yaml}")
		if [[ "${jira_project}" == "null" ]] || [[ -z "${jira_project}" ]]; then
			log_error "Jira project_key not configured"
			((failed++)) || true
		else
			log_ok "Jira project_key configured: ${jira_project}"
		fi
	else
		# Basic grep check
		if grep -q "base_url:.*atlassian.net" "${project_yaml}"; then
			log_ok "Jira base_url appears configured"
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
