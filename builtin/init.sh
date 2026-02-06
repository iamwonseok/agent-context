#!/bin/bash
# Agent-Context Init Command
# Initialize global environment for agent-context
#
# Usage:
#   agent-context init [options]
#
# This script is sourced by bin/agent-context.sh

# ============================================================
# Shell Configuration Block
# ============================================================
SHELL_MARKER_BEGIN="# BEGIN AGENT_CONTEXT"
SHELL_MARKER_END="# END AGENT_CONTEXT"

_generate_shell_block() {
	cat <<'SHELL_BLOCK'
# BEGIN AGENT_CONTEXT
# Agent-context CLI and environment setup
# Added by: agent-context init
alias agent-context="~/.agent-context/bin/agent-context.sh"
[[ -f ~/.secrets/atlassian-api-token ]] && export ATLASSIAN_API_TOKEN="$(cat ~/.secrets/atlassian-api-token)"
[[ -f ~/.secrets/gitlab-api-token ]] && export GITLAB_API_TOKEN="$(cat ~/.secrets/gitlab-api-token)"
[[ -f ~/.secrets/github-api-token ]] && export GITHUB_API_TOKEN="$(cat ~/.secrets/github-api-token)"
# END AGENT_CONTEXT
SHELL_BLOCK
}

# ============================================================
# Usage
# ============================================================
init_usage() {
	cat <<EOF
Agent-Context Init

USAGE:
    agent-context init [options]

OPTIONS:
    --skip-gitlab       Skip GitLab SSH/PAT setup
    --skip-atlassian    Skip Atlassian token setup
    --non-interactive   Skip all prompts (use defaults)
    -h, --help          Show this help

DESCRIPTION:
    Initialize global environment for agent-context:
    1. Check required dependencies (git, jq, etc.)
    2. Create ~/.secrets directory
    3. Setup GitLab SSH key and PAT (interactive)
    4. Setup Atlassian API token (interactive)
    5. Add shell configuration (alias + env vars)

EXAMPLES:
    # Full interactive setup
    agent-context init

    # Skip GitLab setup
    agent-context init --skip-gitlab

    # Non-interactive (CI mode)
    agent-context init --non-interactive

EOF
}

# ============================================================
# Main Init Function
# ============================================================
run_init() {
	local skip_gitlab=false
	local skip_atlassian=false
	local non_interactive=false

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--skip-gitlab)
				skip_gitlab=true
				;;
			--skip-atlassian)
				skip_atlassian=true
				;;
			--non-interactive)
				non_interactive=true
				;;
			-h|--help)
				init_usage
				return 0
				;;
			*)
				log_error "Unknown option: $1"
				init_usage
				return 1
				;;
		esac
		shift
	done

	log_header "Agent-Context Global Initialization"

	local has_issues=false
	local total=0
	local passed=0
	local warned=0

	# ============================================================
	# [1/5] Dependencies
	# ============================================================
	log_info "[1/5] Checking dependencies..."
	local required_cmds=(bash git curl jq)
	for cmd in "${required_cmds[@]}"; do
		total=$((total + 1))
		if has_cmd "${cmd}"; then
			log_ok "${cmd} $(get_version "${cmd}")"
			passed=$((passed + 1))
		else
			log_error "Missing: ${cmd}"
			has_issues=true
		fi
	done

	# Check optional commands
	local optional_cmds=(yq glab gh pre-commit)
	for cmd in "${optional_cmds[@]}"; do
		total=$((total + 1))
		if has_cmd "${cmd}"; then
			log_ok "${cmd} $(get_version "${cmd}")"
			passed=$((passed + 1))
		else
			log_warn "Optional missing: ${cmd}"
			warned=$((warned + 1))
		fi
	done

	# ============================================================
	# [2/5] GitLab SSH Setup
	# ============================================================
	if [[ "${skip_gitlab}" == "false" ]]; then
		echo ""
		log_info "[2/5] GitLab SSH setup..."
		total=$((total + 1))

		local ssh_key="${HOME}/.ssh/id_ed25519"
		if [[ -f "${ssh_key}.pub" ]]; then
			log_ok "SSH key exists: ${ssh_key}"
			passed=$((passed + 1))

			# Test SSH connection
			if [[ "${non_interactive}" == "false" ]] && is_interactive; then
				echo -n "  Test SSH connection to gitlab.fadutec.dev? [Y/n]: "
				read -r test_ssh
				if [[ ! "${test_ssh}" =~ ^[Nn]$ ]]; then
					total=$((total + 1))
					if ssh -T -o ConnectTimeout=5 -o BatchMode=yes git@gitlab.fadutec.dev 2>&1 | grep -q "Welcome"; then
						log_ok "SSH connection successful"
						passed=$((passed + 1))
					else
						log_warn "SSH connection failed or timed out"
						warned=$((warned + 1))
						echo "  Verify your key is registered at:"
						echo "  https://gitlab.fadutec.dev/-/user_settings/ssh_keys"
					fi
				fi
			fi
		else
			log_warn "SSH key not found: ${ssh_key}"
			warned=$((warned + 1))
			echo "  Generate a new key with:"
			echo "    ssh-keygen -t ed25519 -C \"your-email@fadutec.dev\""
			echo "  Then register at:"
			echo "    https://gitlab.fadutec.dev/-/user_settings/ssh_keys"
		fi
	else
		echo ""
		log_skip "[2/5] GitLab SSH setup (skipped)"
	fi

	# ============================================================
	# [3/5] Secrets Directory & GitLab PAT
	# ============================================================
	echo ""
	log_info "[3/5] Setting up secrets directory..."
	total=$((total + 1))

	if [[ -d "${HOME}/.secrets" ]]; then
		log_ok "${HOME}/.secrets exists"
		passed=$((passed + 1))

		# Check permissions
		local secrets_mode
		secrets_mode=$(stat -f "%OLp" "${HOME}/.secrets" 2>/dev/null || stat -c "%a" "${HOME}/.secrets" 2>/dev/null)
		if [[ "${secrets_mode}" == "700" ]]; then
			log_ok "Permissions correct (700)"
		else
			log_warn "Permissions should be 700 (current: ${secrets_mode})"
			warned=$((warned + 1))
			echo "  Fix with: chmod 700 ~/.secrets"
		fi
	else
		mkdir -p "${HOME}/.secrets"
		chmod 700 "${HOME}/.secrets"
		log_ok "Created: ~/.secrets (mode 700)"
		passed=$((passed + 1))
	fi

	# GitLab PAT check
	if [[ "${skip_gitlab}" == "false" ]]; then
		total=$((total + 1))
		local gitlab_token="${HOME}/.secrets/gitlab-api-token"

		if [[ -f "${gitlab_token}" ]]; then
			local token_size
			token_size=$(wc -c < "${gitlab_token}" | tr -d ' ')
			log_ok "gitlab-api-token (${token_size} bytes)"
			passed=$((passed + 1))
		else
			log_warn "gitlab-api-token not found"
			warned=$((warned + 1))
			echo "  Create PAT at: https://gitlab.fadutec.dev/-/user_settings/personal_access_tokens"
			echo "  Required scopes: api, read_repository, write_repository"

			if [[ "${non_interactive}" == "false" ]] && is_interactive; then
				echo ""
				echo -n "  Enter GitLab PAT (hidden, or press Enter to skip): "
				read -rs gitlab_pat
				echo ""
				if [[ -n "${gitlab_pat}" ]]; then
					echo "${gitlab_pat}" > "${gitlab_token}"
					chmod 600 "${gitlab_token}"
					log_ok "Saved: ${gitlab_token}"
					passed=$((passed + 1))
					warned=$((warned - 1))
				fi
			fi
		fi
	fi

	# ============================================================
	# [4/5] glab Authentication
	# ============================================================
	echo ""
	if [[ "${skip_gitlab}" == "false" ]]; then
		log_info "[4/5] glab authentication..."
		total=$((total + 1))

		if has_cmd glab; then
			local glab_status
			glab_status=$(glab auth status 2>&1 || true)
			if echo "${glab_status}" | grep -q "Logged in"; then
				local glab_user
				glab_user=$(echo "${glab_status}" | grep -oE "Logged in .* as [^ ]+" | sed 's/.*as //')
				log_ok "glab: Logged in as ${glab_user}"
				passed=$((passed + 1))
			else
				log_warn "glab: Not authenticated"
				warned=$((warned + 1))
				echo "  Run: glab auth login --hostname gitlab.fadutec.dev"
			fi
		else
			log_skip "glab not installed"
		fi
	else
		log_skip "[4/5] glab authentication (skipped)"
	fi

	# ============================================================
	# [5/5] Atlassian API Token
	# ============================================================
	echo ""
	if [[ "${skip_atlassian}" == "false" ]]; then
		log_info "[5/5] Atlassian API token setup..."
		total=$((total + 1))

		local atlassian_token="${HOME}/.secrets/atlassian-api-token"
		if [[ -f "${atlassian_token}" ]]; then
			local token_size
			token_size=$(wc -c < "${atlassian_token}" | tr -d ' ')
			log_ok "atlassian-api-token (${token_size} bytes)"
			passed=$((passed + 1))
		else
			log_warn "atlassian-api-token not found"
			warned=$((warned + 1))
			echo "  Create token at: https://id.atlassian.com/manage-profile/security/api-tokens"

			if [[ "${non_interactive}" == "false" ]] && is_interactive; then
				echo ""
				echo -n "  Enter Atlassian API token (hidden, or press Enter to skip): "
				read -rs atlassian_pat
				echo ""
				if [[ -n "${atlassian_pat}" ]]; then
					echo "${atlassian_pat}" > "${atlassian_token}"
					chmod 600 "${atlassian_token}"
					log_ok "Saved: ${atlassian_token}"
					passed=$((passed + 1))
					warned=$((warned - 1))
				fi
			fi
		fi
	else
		log_skip "[5/5] Atlassian API token setup (skipped)"
	fi

	# ============================================================
	# Shell Configuration
	# ============================================================
	echo ""
	log_info "Configuring shell environment..."
	local rc_file
	rc_file=$(get_shell_rc)

	if [[ -z "${rc_file}" ]]; then
		log_warn "Unsupported shell: $(detect_shell)"
		log_info "Add the following to your shell config manually:"
		echo ""
		_generate_shell_block
		echo ""
	elif [[ -f "${rc_file}" ]] && grep -q "${SHELL_MARKER_BEGIN}" "${rc_file}" 2>/dev/null; then
		log_ok "Shell config already exists in ${rc_file}"
	else
		if [[ "${non_interactive}" == "false" ]] && is_interactive; then
			echo ""
			log_info "The following will be added to ${rc_file}:"
			echo "  ----------------------------------------"
			_generate_shell_block | sed 's/^/  /'
			echo "  ----------------------------------------"
			echo ""
			echo -n "  Proceed? [y/N]: "
			read -r confirm
			if [[ "${confirm}" =~ ^[Yy]$ ]]; then
				{
					echo ""
					_generate_shell_block
				} >> "${rc_file}"
				log_ok "Added shell configuration to ${rc_file}"
			else
				log_warn "Skipped shell configuration"
			fi
		else
			log_info "Non-interactive mode: Add manually to ${rc_file}:"
			echo ""
			_generate_shell_block
			echo ""
		fi
	fi

	# ============================================================
	# Summary
	# ============================================================
	echo ""
	echo "============================================"
	local failed=$((total - passed - warned))
	if [[ "${has_issues}" == "true" ]] || [[ ${failed} -gt 0 ]]; then
		log_warn "Initialization completed with issues"
	else
		log_ok "Initialization complete!"
	fi
	echo ""
	echo "Summary: total=${total} passed=${passed} failed=${failed} warned=${warned} skipped=0"
	echo ""
	echo "Next steps:"
	echo "  1. Restart your shell: source ${rc_file:-~/.zshrc}"
	echo "  2. Clone a project and run: agent-context install"
	echo ""

	if [[ ${failed} -gt 0 ]]; then
		return 1
	fi
	return 0
}

# Allow direct execution for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	# When run directly, source required libraries
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
	# shellcheck source=../lib/logging.sh
	source "${SCRIPT_DIR}/lib/logging.sh"
	# shellcheck source=../lib/platform.sh
	source "${SCRIPT_DIR}/lib/platform.sh"
	run_init "$@"
fi
