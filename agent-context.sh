#!/bin/bash
# Agent-Context Global CLI
# Entry point for managing agent-context installation and configuration
#
# Usage:
#   agent-context init      # Initialize global environment
#   agent-context install   # Install to current project
#   agent-context demo      # Run demo installation
#   agent-context pm        # Run project PM CLI (pm)
#   agent-context help      # Show help
#
# Global installation:
#   git clone <repo> ~/.agent-context
#   ~/.agent-context/agent-context.sh init

set -e
set -o pipefail

# Script directory (agent-context source)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================
# Colors
# ============================================================
if [[ -t 1 ]]; then
	RED='\033[0;31m'
	GREEN='\033[0;32m'
	YELLOW='\033[1;33m'
	BLUE='\033[0;34m'
	CYAN='\033[0;36m'
	BOLD='\033[1m'
	NC='\033[0m'
else
	RED=''
	GREEN=''
	YELLOW=''
	BLUE=''
	CYAN=''
	BOLD=''
	NC=''
fi

log_info() {
	echo -e "${BLUE}[i]${NC} $1"
}

log_ok() {
	echo -e "${GREEN}[V]${NC} $1"
}

log_warn() {
	echo -e "${YELLOW}[!]${NC} $1" >&2
}

log_error() {
	echo -e "${RED}[X]${NC} $1" >&2
}

log_header() {
	echo ""
	echo -e "${BOLD}${CYAN}$1${NC}"
	echo ""
}

# ============================================================
# Shell Configuration Block
# ============================================================
SHELL_MARKER_BEGIN="# BEGIN AGENT_CONTEXT"
SHELL_MARKER_END="# END AGENT_CONTEXT"

generate_shell_block() {
	cat <<'SHELL_BLOCK'
# BEGIN AGENT_CONTEXT
# Agent-context CLI and environment setup
# Added by: agent-context init
alias agent-context="~/.agent-context/agent-context.sh"
[[ -f ~/.secrets/atlassian-api-token ]] && export ATLASSIAN_API_TOKEN="$(cat ~/.secrets/atlassian-api-token)"
[[ -f ~/.secrets/gitlab-api-token ]] && export GITLAB_API_TOKEN="$(cat ~/.secrets/gitlab-api-token)"
[[ -f ~/.secrets/github-api-token ]] && export GITHUB_API_TOKEN="$(cat ~/.secrets/github-api-token)"
# END AGENT_CONTEXT
SHELL_BLOCK
}

# ============================================================
# Usage
# ============================================================
usage() {
	cat <<EOF
Agent-Context Global CLI

USAGE:
    $(basename "$0") <command> [options]

COMMANDS:
    init        Initialize global environment
                - Check dependencies (bash, git, curl, jq)
                - Create ~/.secrets directory
                - Show token setup guide
                - Add shell configuration (alias + env vars)

    install     Install agent-context to a project
                Wrapper for ./install.sh with current directory as target
                See: ./install.sh --help

    demo        Run demo installation
                Wrapper for ./demo/install.sh
                See: ./demo/install.sh --help

    pm          Run project PM CLI (pm)
                Delegates to ./.agent/tools/pm/bin/pm in the current project
                Example: agent-context pm config show

    help        Show this help message

GLOBAL INSTALLATION:
    # Clone to ~/.agent-context
    git clone <repo-url> ~/.agent-context

    # Initialize environment
    ~/.agent-context/agent-context.sh init

    # Restart shell or source config
    source ~/.bashrc   # or ~/.zshrc

    # Install to a project
    cd /path/to/project
    agent-context install

EXAMPLES:
    # Initialize global environment
    $(basename "$0") init

    # Install to current directory
    $(basename "$0") install

    # Install with options
    $(basename "$0") install --force --profile minimal

    # Run demo
    $(basename "$0") demo --skip-e2e

    # Run pm in current project
    $(basename "$0") pm config show

EOF
}

# ============================================================
# Command: init
# ============================================================
cmd_init() {
	log_header "Agent-Context Global Initialization"

	local has_issues=false

	# Step 1: Check dependencies
	log_info "Checking dependencies..."
	local required_cmds=(bash git curl jq)
	for cmd in "${required_cmds[@]}"; do
		if command -v "${cmd}" &>/dev/null; then
			log_ok "Found: ${cmd}"
		else
			log_error "Missing: ${cmd}"
			has_issues=true
		fi
	done

	# Check optional commands
	log_info "Checking optional commands..."
	local optional_cmds=(yq glab pre-commit)
	for cmd in "${optional_cmds[@]}"; do
		if command -v "${cmd}" &>/dev/null; then
			log_ok "Found: ${cmd}"
		else
			log_warn "Optional missing: ${cmd}"
		fi
	done

	# Step 2: Create ~/.secrets directory
	log_info "Setting up secrets directory..."
	if [[ -d "${HOME}/.secrets" ]]; then
		log_ok "~/.secrets already exists"
	else
		mkdir -p "${HOME}/.secrets"
		chmod 700 "${HOME}/.secrets"
		log_ok "Created: ~/.secrets (mode 700)"
	fi

	# Step 3: Token setup guide
	echo ""
	log_header "API Token Setup Guide"
	echo "  Store your API tokens in ~/.secrets with proper permissions:"
	echo ""
	echo "  Atlassian (Jira/Confluence):"
	echo "    1. Visit: https://id.atlassian.com/manage-profile/security/api-tokens"
	echo "    2. Click 'Create API token'"
	echo "    3. Save token:"
	echo "       echo 'your-token' > ~/.secrets/atlassian-api-token"
	echo "       chmod 600 ~/.secrets/atlassian-api-token"
	echo ""
	echo "  GitLab:"
	echo "    1. Visit: GitLab > Settings > Access Tokens"
	echo "    2. Create token with 'api' scope"
	echo "    3. Save token:"
	echo "       echo 'your-token' > ~/.secrets/gitlab-api-token"
	echo "       chmod 600 ~/.secrets/gitlab-api-token"
	echo ""
	echo "  GitHub:"
	echo "    1. Visit: https://github.com/settings/tokens"
	echo "    2. Generate new token (classic) with appropriate scopes"
	echo "    3. Save token:"
	echo "       echo 'your-token' > ~/.secrets/github-api-token"
	echo "       chmod 600 ~/.secrets/github-api-token"
	echo ""

	# Step 4: Shell configuration
	log_info "Configuring shell environment..."
	local shell_name
	shell_name=$(basename "${SHELL}")

	local rc_file=""
	case "${shell_name}" in
		bash)
			if [[ "$(uname)" == "Darwin" ]]; then
				rc_file="${HOME}/.bash_profile"
			else
				rc_file="${HOME}/.bashrc"
			fi
			;;
		zsh)
			rc_file="${HOME}/.zshrc"
			;;
		*)
			log_warn "Unsupported shell: ${shell_name}"
			log_info "Supported shells: bash, zsh"
			log_info "Please add the following to your shell config manually:"
			echo ""
			generate_shell_block
			echo ""
			return 0
			;;
	esac

	# Check if already configured
	if [[ -f "${rc_file}" ]] && grep -q "${SHELL_MARKER_BEGIN}" "${rc_file}" 2>/dev/null; then
		log_ok "Shell config already exists in ${rc_file}"
		echo ""
		echo "  To update, remove the existing block and run 'init' again:"
		echo "    sed -i.bak '/${SHELL_MARKER_BEGIN}/,/${SHELL_MARKER_END}/d' ${rc_file}"
		echo ""
	else
		echo ""
		log_info "The following will be added to ${rc_file}:"
		echo "  ----------------------------------------"
		generate_shell_block | sed 's/^/  /'
		echo "  ----------------------------------------"
		echo ""
		echo -n "  Proceed? [y/N]: "
		read -r confirm
		if [[ "${confirm}" =~ ^[Yy]$ ]]; then
			{
				echo ""
				generate_shell_block
			} >> "${rc_file}"
			log_ok "Added shell configuration to ${rc_file}"
			echo ""
			log_info "Restart your shell or run:"
			echo "    source ${rc_file}"
		else
			log_warn "Skipped shell configuration"
			log_info "Add manually to your shell config:"
			echo ""
			generate_shell_block
			echo ""
		fi
	fi

	# Summary
	echo ""
	log_header "Initialization Complete"
	if [[ "${has_issues}" == "true" ]]; then
		log_warn "Some dependencies are missing. Install them and run 'init' again."
	else
		log_ok "All required dependencies found"
	fi
	echo ""
	echo "Next steps:"
	echo "  1. Set up API tokens (see guide above)"
	echo "  2. Restart shell or source config"
	echo "  3. Install to a project:"
	echo "       cd /path/to/project"
	echo "       agent-context install"
	echo ""
}

# ============================================================
# Command: install
# ============================================================
cmd_install() {
	local install_script="${SCRIPT_DIR}/install.sh"

	if [[ ! -f "${install_script}" ]]; then
		log_error "install.sh not found: ${install_script}"
		exit 1
	fi

	# Pass all arguments to install.sh, defaulting to current directory
	if [[ $# -eq 0 ]]; then
		exec bash "${install_script}" .
	else
		exec bash "${install_script}" "$@"
	fi
}

# ============================================================
# Command: demo
# ============================================================
cmd_demo() {
	local demo_script="${SCRIPT_DIR}/demo/install.sh"

	if [[ ! -f "${demo_script}" ]]; then
		log_error "demo/install.sh not found: ${demo_script}"
		exit 1
	fi

	# Pass all arguments to demo/install.sh
	exec bash "${demo_script}" "$@"
}

# ============================================================
# Command: pm
# ============================================================
find_pm_project_root() {
	local dir="${1:-${PWD}}"

	while [[ "${dir}" != "/" ]]; do
		if [[ -x "${dir}/.agent/tools/pm/bin/pm" ]]; then
			echo "${dir}"
			return 0
		fi
		if [[ -f "${dir}/.project.yaml" ]]; then
			# Even if pm is missing, this is a likely project root.
			echo "${dir}"
			return 0
		fi
		if [[ -d "${dir}/.git" ]]; then
			echo "${dir}"
			return 0
		fi
		dir="$(dirname "${dir}")"
	done

	return 1
}

cmd_pm() {
	local root=""
	root=$(find_pm_project_root "${PWD}" 2>/dev/null || true)

	if [[ -z "${root}" ]]; then
		log_error "Cannot find project root (.agent/, .project.yaml, or .git)"
		log_info "Run this inside a project directory, or run: agent-context install"
		exit 1
	fi

	local pm_bin="${root}/.agent/tools/pm/bin/pm"
	if [[ ! -x "${pm_bin}" ]]; then
		log_error "pm not found in project: ${pm_bin}"
		log_info "Install agent-context to this project first:"
		log_info "  cd ${root}"
		log_info "  agent-context install"
		exit 1
	fi

	( cd "${root}" && exec "${pm_bin}" "$@" )
}

# ============================================================
# Main
# ============================================================
main() {
	local command="${1:-}"

	case "${command}" in
		init)
			shift
			cmd_init "$@"
			;;
		install)
			shift
			cmd_install "$@"
			;;
		demo)
			shift
			cmd_demo "$@"
			;;
		pm)
			shift
			cmd_pm "$@"
			;;
		help|--help|-h|"")
			usage
			exit 0
			;;
		*)
			log_error "Unknown command: ${command}"
			echo ""
			usage
			exit 1
			;;
	esac
}

main "$@"
