#!/bin/bash
# Docker Entrypoint for Agent-Context Demo
# Handles glab authentication and environment setup

set -e

# ============================================================
# Colors
# ============================================================
if [[ -t 1 ]]; then
	GREEN='\033[0;32m'
	YELLOW='\033[1;33m'
	BLUE='\033[0;34m'
	NC='\033[0m'
else
	GREEN=''
	YELLOW=''
	BLUE=''
	NC=''
fi

log_info() { echo -e "${BLUE}[>>]${NC} $1"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!!]${NC} $1"; }

# ============================================================
# GitLab CLI Authentication (Non-interactive)
# ============================================================
setup_glab_auth() {
	local token_file="/root/.secrets/gitlab-api-token"

	if [[ -f "${token_file}" ]]; then
		local token
		token=$(cat "${token_file}")

		if [[ -n "${token}" ]]; then
			log_info "Setting up glab authentication..."

			# Set token via environment (glab respects GITLAB_TOKEN)
			export GITLAB_TOKEN="${token}"

			# Verify authentication
			if glab auth status &>/dev/null; then
				log_ok "glab authenticated"
			else
				log_warn "glab authentication may not be complete"
			fi
		fi
	else
		log_warn "GitLab token not found: ${token_file}"
	fi
}

# ============================================================
# Atlassian Token Setup
# ============================================================
setup_atlassian_auth() {
	local token_file="/root/.secrets/atlassian-api-token"

	if [[ -f "${token_file}" ]]; then
		log_ok "Atlassian token found"

		# Export as environment variable if not already set
		if [[ -z "${JIRA_TOKEN}" ]]; then
			export JIRA_TOKEN
			JIRA_TOKEN=$(cat "${token_file}")
		fi
	else
		log_warn "Atlassian token not found: ${token_file}"
		log_info "Mount your secrets: -v ~/.secrets:/root/.secrets:ro"
	fi
}

# ============================================================
# Environment Information
# ============================================================
print_env_info() {
	echo ""
	echo "============================================================"
	echo "Agent-Context Demo Environment"
	echo "============================================================"
	echo ""
	echo "OS:           $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
	echo "Profile:      ${PROFILE:-full}"
	echo "Skip E2E:     ${SKIP_E2E:-false}"
	echo "Force:        ${FORCE:-false}"
	echo ""
	echo "Tools:"
	echo "  bash:       $(bash --version | head -1)"
	echo "  git:        $(git --version)"
	echo "  jq:         $(jq --version)"
	echo "  yq:         $(yq --version)"
	echo "  glab:       $(glab --version | head -1)"
	echo "  python3:    $(python3 --version)"
	echo "  pre-commit: $(pre-commit --version 2>/dev/null || echo 'not installed')"
	echo ""

	# Check secrets
	echo "Secrets:"
	if [[ -f "/root/.secrets/atlassian-api-token" ]]; then
		echo "  Atlassian:  [configured]"
	else
		echo "  Atlassian:  [not found]"
	fi
	if [[ -f "/root/.secrets/gitlab-api-token" ]]; then
		echo "  GitLab:     [configured]"
	else
		echo "  GitLab:     [not found]"
	fi
	if [[ -n "${JIRA_EMAIL}" ]]; then
		echo "  JIRA_EMAIL: ${JIRA_EMAIL}"
	else
		echo "  JIRA_EMAIL: [not set]"
	fi
	echo ""
}

# ============================================================
# Main
# ============================================================
main() {
	# Setup authentication
	setup_glab_auth
	setup_atlassian_auth

	# Print environment info if no arguments
	if [[ $# -eq 0 ]] || [[ "$1" == "bash" ]]; then
		print_env_info
	fi

	# Execute command
	exec "$@"
}

main "$@"
