#!/bin/bash
# Docker Entrypoint for Agent-Context Demo
# Handles glab authentication and environment setup

set -e

# ============================================================
# Colors
# ============================================================
if [[ -t 1 ]]; then
	RED='\033[0;31m'
	GREEN='\033[0;32m'
	YELLOW='\033[1;33m'
	BLUE='\033[0;34m'
	NC='\033[0m'
else
	RED=''
	GREEN=''
	YELLOW=''
	BLUE=''
	NC=''
fi

log_info() { echo -e "${BLUE}[i]${NC} $1"; }
log_ok() { echo -e "${GREEN}[V]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[X]${NC} $1" >&2; }

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

			# Ensure the correct GitLab host is used in Docker runs
			# Prefer DEMO_GITLAB_BASE_URL (scenario) then GITLAB_BASE_URL (project config)
			local base_url="${DEMO_GITLAB_BASE_URL:-${GITLAB_BASE_URL:-}}"
			local host="${GITLAB_HOST:-}"
			if [[ -z "${host}" ]] && [[ -n "${base_url}" ]]; then
				# Extract host from URL (e.g., https://gitlab.example.com -> gitlab.example.com)
				host=$(echo "${base_url}" | sed -E 's#^[a-zA-Z]+://##' | sed -E 's#/.*$##')
			fi
			: "${host:=gitlab.fadutec.dev}"
			export GITLAB_HOST="${host}"

			# Write glab config for self-managed host (always overwrite to ensure correct settings)
			local cfg_dir="/root/.config/glab-cli"
			local cfg_file="${cfg_dir}/config.yml"
			mkdir -p "${cfg_dir}"

			cat > "${cfg_file}" <<EOF
git_protocol: ssh
hosts:
  ${host}:
    api_protocol: https
    git_protocol: ssh
    token: ${token}
EOF

			# glab requires strict permissions on config file
			chmod 700 "${cfg_dir}" 2>/dev/null || true
			chmod 600 "${cfg_file}" 2>/dev/null || true

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
# Git User Configuration
# ============================================================
setup_git_user() {
	# Required for git commit to work
	# Use environment variables: GIT_USER_NAME, GIT_USER_EMAIL
	if ! git config --global user.name &>/dev/null; then
		local name="${GIT_USER_NAME:-AITL Demo Bot}"
		git config --global user.name "${name}"
		log_ok "Git user.name configured: ${name}"
	fi
	if ! git config --global user.email &>/dev/null; then
		local email="${GIT_USER_EMAIL:-demo@agent-context.local}"
		git config --global user.email "${email}"
		log_ok "Git user.email configured: ${email}"
	fi
}

# ============================================================
# SSH Key Setup (required for git push via SSH)
# ============================================================
setup_ssh() {
	local ssh_key="/root/.ssh/id_ed25519"
	local ssh_pub_key="/root/.ssh/id_ed25519.pub"
	local gitlab_host="${GITLAB_HOST:-gitlab.fadutec.dev}"

	# Check if SSH key exists (must be mounted from host)
	if [[ ! -f "${ssh_key}" ]]; then
		log_error "SSH key not found: ${ssh_key}"
		log_error "Mount your SSH directory: -v ~/.ssh:/root/.ssh:ro"
		exit 1
	fi

	log_ok "SSH key found: ${ssh_key}"

	# Ensure known_hosts exists for GitLab host
	local known_hosts="/root/.ssh/known_hosts"
	if [[ ! -f "${known_hosts}" ]] || ! grep -q "${gitlab_host}" "${known_hosts}" 2>/dev/null; then
		log_info "Adding ${gitlab_host} to known_hosts..."
		# Create writable copy if mounted read-only
		local tmp_known_hosts="/tmp/known_hosts"
		if [[ -f "${known_hosts}" ]]; then
			cp "${known_hosts}" "${tmp_known_hosts}"
		else
			touch "${tmp_known_hosts}"
		fi
		ssh-keyscan -H "${gitlab_host}" >> "${tmp_known_hosts}" 2>/dev/null
		export GIT_SSH_COMMAND="ssh -i ${ssh_key} -o IdentitiesOnly=yes -o UserKnownHostsFile=${tmp_known_hosts}"
		log_ok "known_hosts updated for ${gitlab_host}"
	else
		export GIT_SSH_COMMAND="ssh -i ${ssh_key} -o IdentitiesOnly=yes"
		log_ok "Using existing known_hosts"
	fi

	log_ok "GIT_SSH_COMMAND configured"

	# Setup SSH commit signing (Git 2.34+)
	# This allows using SSH key instead of GPG for commit signing
	if [[ -f "${ssh_pub_key}" ]]; then
		git config --global gpg.format ssh
		git config --global user.signingkey "${ssh_pub_key}"
		git config --global commit.gpgsign true

		# Create allowed_signers file for verification (optional but recommended)
		local allowed_signers="/tmp/allowed_signers"
		local email="${GIT_USER_EMAIL:-demo@agent-context.local}"
		echo "${email} $(cat "${ssh_pub_key}")" > "${allowed_signers}"
		git config --global gpg.ssh.allowedSignersFile "${allowed_signers}"

		log_ok "SSH commit signing configured"
	else
		log_warn "SSH public key not found: ${ssh_pub_key} - commit signing disabled"
	fi
}

# ============================================================
# SSH Preflight Check
# ============================================================
ssh_preflight() {
	local gitlab_host="${GITLAB_HOST:-gitlab.fadutec.dev}"

	log_info "SSH preflight: testing connection to ${gitlab_host}..."

	# ssh -T returns exit code 1 for GitLab even on success (it prints "Welcome to GitLab")
	local ssh_output
	if ssh_output=$(ssh -T "git@${gitlab_host}" 2>&1); then
		log_ok "SSH preflight passed"
	elif echo "${ssh_output}" | grep -qi "welcome"; then
		log_ok "SSH preflight passed (GitLab welcome message received)"
	else
		log_error "SSH preflight failed"
		log_error "Output: ${ssh_output}"
		exit 1
	fi
}

# ============================================================
# Main
# ============================================================
main() {
	# Setup authentication
	setup_glab_auth
	setup_atlassian_auth
	setup_git_user

	# Setup SSH for git operations
	setup_ssh
	ssh_preflight

	# Print environment info if no arguments
	if [[ $# -eq 0 ]] || [[ "$1" == "bash" ]]; then
		print_env_info
	fi

	# Execute command
	exec "$@"
}

main "$@"
