#!/bin/bash
# Step 001: Prerequisites Check
# Verify that all required tools and secrets are available
#
# Usage:
#   ./001-prereq.sh run
#   ./001-prereq.sh verify

source "$(dirname "$0")/lib.sh"

STEP_NUM="001"
STEP_NAME="Prerequisites"

step_run() {
	log_step "${STEP_NUM}" "${STEP_NAME}"
	log_info "Checking prerequisites..."

	# Initialize state
	init_state

	local failed=0

	# Check Docker (required only for --os option, warn otherwise)
	log_info "Checking Docker..."
	if command -v docker &>/dev/null; then
		if docker info &>/dev/null; then
			log_ok "Docker daemon is running"
		else
			log_warn "Docker is installed but daemon is not accessible"
			log_info "  Try: docker info"
			# Only fail if Docker mode is requested
			if [[ "${DOCKER_MODE:-false}" == "true" ]]; then
				((failed++)) || true
			fi
		fi
	else
		log_warn "Docker is not installed (optional for local testing)"
		if [[ "${DOCKER_MODE:-false}" == "true" ]]; then
			log_error "Docker required for --os option"
			((failed++)) || true
		fi
	fi

	# Check required commands
	log_info "Checking required commands..."
	local required_cmds=(bash git curl jq)
	for cmd in "${required_cmds[@]}"; do
		if command -v "${cmd}" &>/dev/null; then
			log_ok "Found: ${cmd}"
		else
			log_error "Missing: ${cmd}"
			((failed++)) || true
		fi
	done

	# Check optional commands (warn only)
	log_info "Checking optional commands..."
	local optional_cmds=(yq glab pandoc pre-commit)
	for cmd in "${optional_cmds[@]}"; do
		if command -v "${cmd}" &>/dev/null; then
			log_ok "Found: ${cmd}"
		else
			log_warn "Optional missing: ${cmd}"
		fi
	done

	# Check secrets
	log_info "Checking secrets..."
	if [[ -d "${HOME}/.secrets" ]]; then
		log_ok "Secrets directory exists: ~/.secrets"

		# Check file permissions
		local perms
		perms=$(stat -f "%A" "${HOME}/.secrets" 2>/dev/null || stat -c "%a" "${HOME}/.secrets" 2>/dev/null || echo "unknown")
		if [[ "${perms}" == "700" ]] || [[ "${perms}" == "755" ]]; then
			log_ok "Secrets directory permissions OK"
		else
			log_warn "Secrets directory permissions: ${perms} (recommend 700)"
		fi

		# Check Atlassian token
		if [[ -f "${HOME}/.secrets/atlassian-api-token" ]]; then
			local token_perms
			token_perms=$(stat -f "%A" "${HOME}/.secrets/atlassian-api-token" 2>/dev/null || stat -c "%a" "${HOME}/.secrets/atlassian-api-token" 2>/dev/null || echo "unknown")
			if [[ "${token_perms}" == "600" ]] || [[ "${token_perms}" == "400" ]]; then
				log_ok "Atlassian token found (permissions OK)"
			else
				log_warn "Atlassian token found (permissions: ${token_perms}, recommend 600)"
			fi
		else
			log_warn "Atlassian token not found: ~/.secrets/atlassian-api-token"
			log_info "  Create: echo 'your-token' > ~/.secrets/atlassian-api-token && chmod 600 ~/.secrets/atlassian-api-token"
			log_info "  Get token: https://id.atlassian.com/manage-profile/security/api-tokens"
		fi

		# Check GitLab token
		if [[ -f "${HOME}/.secrets/gitlab-api-token" ]]; then
			log_ok "GitLab token found"
		else
			log_warn "GitLab token not found: ~/.secrets/gitlab-api-token"
		fi
	else
		log_warn "Secrets directory not found: ~/.secrets"
		log_info "  Create: mkdir -p ~/.secrets && chmod 700 ~/.secrets"
		((failed++)) || true
	fi

	# Check JIRA_EMAIL
	if [[ -n "${JIRA_EMAIL}" ]]; then
		log_ok "JIRA_EMAIL is set: ${JIRA_EMAIL}"
	else
		log_warn "JIRA_EMAIL is not set"
		log_info "  Set: export JIRA_EMAIL='your-email@example.com'"
	fi

	# Summary
	echo ""
	if [[ ${failed} -gt 0 ]]; then
		log_error "Prerequisites check failed: ${failed} critical issue(s)"
		return 1
	else
		log_ok "Prerequisites check passed"
		mark_step_done "${STEP_NUM}"
		return 0
	fi
}

step_verify() {
	log_info "Verifying step ${STEP_NUM}..."

	local failed=0

	# Docker must be available (only if Docker mode)
	if [[ "${DOCKER_MODE:-false}" == "true" ]]; then
		if ! docker info &>/dev/null; then
			log_error "Docker daemon not accessible"
			((failed++)) || true
		else
			log_ok "Docker daemon accessible"
		fi
	fi

	# ~/.secrets must exist
	if [[ ! -d "${HOME}/.secrets" ]]; then
		log_error "Secrets directory not found"
		((failed++)) || true
	else
		log_ok "Secrets directory exists"
	fi

	# Atlassian token must exist for E2E
	if [[ "${SKIP_E2E}" != "true" ]]; then
		if [[ ! -f "${HOME}/.secrets/atlassian-api-token" ]]; then
			log_error "Atlassian token required for E2E tests"
			((failed++)) || true
		else
			log_ok "Atlassian token available"
		fi

		if [[ -z "${JIRA_EMAIL}" ]]; then
			log_error "JIRA_EMAIL required for E2E tests"
			((failed++)) || true
		else
			log_ok "JIRA_EMAIL is set"
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
