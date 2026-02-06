#!/bin/bash
# Agent-Context Global CLI
# Entry point for managing agent-context installation and configuration
#
# Usage:
#   agent-context <command> [options]
#   agent-context init      # Initialize global environment
#   agent-context install   # Install to current project
#   agent-context doctor    # Diagnose installation health
#   agent-context help      # Show help
#
# Global installation:
#   git clone <repo> ~/.agent-context
#   ~/.agent-context/bin/agent-context.sh init

set -e
set -o pipefail

# Version
VERSION="0.2.0"

# Script directory (agent-context source)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="${SCRIPT_DIR}/bin"
LIB_DIR="${SCRIPT_DIR}/lib"
BUILTIN_DIR="${SCRIPT_DIR}/builtin"

# ============================================================
# Common Libraries
# ============================================================
# shellcheck source=../lib/logging.sh
source "${LIB_DIR}/logging.sh"
# shellcheck source=../lib/platform.sh
source "${LIB_DIR}/platform.sh"

# ============================================================
# Usage
# ============================================================
usage() {
	cat <<EOF
Agent-Context Global CLI v${VERSION}

USAGE:
    $(basename "$0") <command> [options]

COMMANDS:
    init        Initialize global environment
                - Check dependencies (bash, git, curl, jq)
                - Create ~/.secrets directory
                - GitLab SSH/PAT setup (interactive)
                - Atlassian token setup (interactive)
                - Add shell configuration (alias + env vars)

    update      Update agent-context source (like \`brew update\`)
                - Update ~/.agent-context (Repo) only
                - Abort on dirty tree
                Alias: up

    install     Install agent-context to a project
                Wrapper for install.sh with current directory as target
                See: install.sh --help

    upgrade     Upgrade installed project (like \`brew upgrade\`)
                - Default: diff-only (no writes)
                - Use --apply to write; --apply --prune to delete

    clean       Clean project caches/logs
                - Default: .agent/state/* only
                Options: --logs, --global, --all, --force, --dry-run

    doctor      Diagnose installation health (offline by default)
                Subcommands: deps, auth, project, connect
                Alias: dr

    audit       Audit repository/project health
                - Developer mode: ~/.agent-context internal checks
                - User mode: project .agent/ checks

    tests       Run test suites (non-interactive, CI-friendly)
                Subcommands: list, smoke, e2e
                Options: --tags <tags>, --skip <tags>

    log         Show command execution logs
                Options: --list, --global, --project, --tail N

    report      Generate diagnostic report
                Options: --issue (opt-in GitLab issue creation)

    demo        Run demo installation
                Wrapper for demo/install.sh

    pm          Run project PM CLI (pm)
                Delegates to .agent/tools/pm/bin/pm in current project

    help        Show this help message
    --version   Show version information

COMMON OPTIONS:
    -d, --debug     Display debugging information
    -q, --quiet     Reduce output (keep final Summary)
    -v, --verbose   Increase output verbosity
    -h, --help      Show this message

GLOBAL INSTALLATION:
    # Clone to ~/.agent-context
    git clone git@gitlab.fadutec.dev:soc-ip/agentic-ai/agent-context.git ~/.agent-context

    # Initialize environment
    ~/.agent-context/bin/agent-context.sh init

    # Restart shell or source config
    source ~/.zshrc   # or ~/.bashrc

    # Install to a project
    cd /path/to/project
    agent-context install

EXAMPLES:
    # Initialize global environment
    $(basename "$0") init

    # Check installation health
    $(basename "$0") doctor

    # Install to current directory
    $(basename "$0") install

    # Run pm in current project
    $(basename "$0") pm config show

EOF
}

# ============================================================
# Command: version
# ============================================================
cmd_version() {
	echo "agent-context ${VERSION}"
}

# ============================================================
# Command: init
# ============================================================
cmd_init() {
	local init_script="${BUILTIN_DIR}/init.sh"

	if [[ -f "${init_script}" ]]; then
		# shellcheck source=../builtin/init.sh
		source "${init_script}"
		run_init "$@"
	else
		# Fallback: inline init (backward compatibility during migration)
		_inline_init "$@"
	fi
}

# Inline init for backward compatibility
_inline_init() {
	log_header "Agent-Context Global Initialization"

	local has_issues=false

	# Step 1: Check dependencies
	log_info "Checking dependencies..."
	local required_cmds=(bash git curl jq)
	for cmd in "${required_cmds[@]}"; do
		if has_cmd "${cmd}"; then
			log_ok "Found: ${cmd} $(get_version "${cmd}")"
		else
			log_error "Missing: ${cmd}"
			has_issues=true
		fi
	done

	# Check optional commands
	log_info "Checking optional commands..."
	local optional_cmds=(yq glab pre-commit)
	for cmd in "${optional_cmds[@]}"; do
		if has_cmd "${cmd}"; then
			log_ok "Found: ${cmd} $(get_version "${cmd}")"
		else
			log_warn "Optional missing: ${cmd}"
		fi
	done

	# Step 2: Create ~/.secrets directory
	log_info "Setting up secrets directory..."
	if [[ -d "${HOME}/.secrets" ]]; then
		log_ok "${HOME}/.secrets already exists"
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
	local rc_file
	rc_file=$(get_shell_rc)

	if [[ -z "${rc_file}" ]]; then
		log_warn "Unsupported shell: $(detect_shell)"
		log_info "Please add the following to your shell config manually:"
		echo ""
		_generate_shell_block
		echo ""
		return 0
	fi

	# Check if already configured
	if [[ -f "${rc_file}" ]] && grep -q "# BEGIN AGENT_CONTEXT" "${rc_file}" 2>/dev/null; then
		log_ok "Shell config already exists in ${rc_file}"
		echo ""
		echo "  To update, remove the existing block and run 'init' again:"
		echo "    sed -i.bak '/# BEGIN AGENT_CONTEXT/,/# END AGENT_CONTEXT/d' ${rc_file}"
		echo ""
	else
		echo ""
		log_info "The following will be added to ${rc_file}:"
		echo "  ----------------------------------------"
		_generate_shell_block | sed 's/^/  /'
		echo "  ----------------------------------------"
		echo ""

		if is_interactive; then
			echo -n "  Proceed? [y/N]: "
			read -r confirm
			if [[ "${confirm}" =~ ^[Yy]$ ]]; then
				{
					echo ""
					_generate_shell_block
				} >> "${rc_file}"
				log_ok "Added shell configuration to ${rc_file}"
				echo ""
				log_info "Restart your shell or run:"
				echo "    source ${rc_file}"
			else
				log_warn "Skipped shell configuration"
			fi
		else
			log_info "Non-interactive mode: skipping shell configuration"
			log_info "Add manually to your shell config:"
			echo ""
			_generate_shell_block
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
# Command: install
# ============================================================
cmd_install() {
	local install_script="${BUILTIN_DIR}/install.sh"

	# Prefer builtin if exists, else fallback to root install.sh
	if [[ -f "${install_script}" ]]; then
		exec bash "${install_script}" "$@"
	elif [[ -f "${SCRIPT_DIR}/install.sh" ]]; then
		# Pass all arguments to install.sh, defaulting to current directory
		if [[ $# -eq 0 ]]; then
			exec bash "${SCRIPT_DIR}/install.sh" .
		else
			exec bash "${SCRIPT_DIR}/install.sh" "$@"
		fi
	else
		log_error "install.sh not found"
		exit 1
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
cmd_pm() {
	local root
	root=$(find_project_root "${PWD}" 2>/dev/null || true)

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
# Command: doctor
# ============================================================
cmd_doctor() {
	local doctor_script="${BUILTIN_DIR}/doctor.sh"

	if [[ -f "${doctor_script}" ]]; then
		# shellcheck source=../builtin/doctor.sh
		source "${doctor_script}"
		run_doctor "$@"
	else
		log_error "doctor command not yet implemented"
		log_info "Coming soon: agent-context doctor"
		exit 1
	fi
}

# ============================================================
# Command: update
# ============================================================
cmd_update() {
	local update_script="${BUILTIN_DIR}/update.sh"

	if [[ -f "${update_script}" ]]; then
		# shellcheck source=../builtin/update.sh
		source "${update_script}"
		run_update "$@"
	else
		log_error "update command not yet implemented"
		exit 1
	fi
}

# ============================================================
# Command: upgrade
# ============================================================
cmd_upgrade() {
	local upgrade_script="${BUILTIN_DIR}/upgrade.sh"

	if [[ -f "${upgrade_script}" ]]; then
		# shellcheck source=../builtin/upgrade.sh
		source "${upgrade_script}"
		run_upgrade "$@"
	else
		log_error "upgrade command not yet implemented"
		exit 1
	fi
}

# ============================================================
# Command: clean
# ============================================================
cmd_clean() {
	local clean_script="${BUILTIN_DIR}/clean.sh"

	if [[ -f "${clean_script}" ]]; then
		# shellcheck source=../builtin/clean.sh
		source "${clean_script}"
		run_clean "$@"
	else
		log_error "clean command not yet implemented"
		exit 1
	fi
}

# ============================================================
# Command: audit
# ============================================================
cmd_audit() {
	local audit_script="${BUILTIN_DIR}/audit.sh"

	if [[ -f "${audit_script}" ]]; then
		# shellcheck source=../builtin/audit.sh
		source "${audit_script}"
		run_audit "$@"
	else
		log_error "audit command not yet implemented"
		exit 1
	fi
}

# ============================================================
# Command: tests
# ============================================================
cmd_tests() {
	local tests_script="${BUILTIN_DIR}/tests.sh"

	if [[ -f "${tests_script}" ]]; then
		# shellcheck source=../builtin/tests.sh
		source "${tests_script}"
		run_tests "$@"
	else
		log_error "tests command not yet implemented"
		exit 1
	fi
}

# ============================================================
# Command: log
# ============================================================
cmd_log() {
	local log_script="${BUILTIN_DIR}/log.sh"

	if [[ -f "${log_script}" ]]; then
		# shellcheck source=../builtin/log.sh
		source "${log_script}"
		run_log "$@"
	else
		log_error "log command not yet implemented"
		exit 1
	fi
}

# ============================================================
# Command: report
# ============================================================
cmd_report() {
	local report_script="${BUILTIN_DIR}/report.sh"

	if [[ -f "${report_script}" ]]; then
		# shellcheck source=../builtin/report.sh
		source "${report_script}"
		run_report "$@"
	else
		log_error "report command not yet implemented"
		exit 1
	fi
}

# ============================================================
# Main
# ============================================================
main() {
	local command="${1:-}"

	case "${command}" in
		--version|-V|version)
			cmd_version
			exit 0
			;;
		init)
			shift
			cmd_init "$@"
			;;
		update|up)
			shift
			cmd_update "$@"
			;;
		install)
			shift
			cmd_install "$@"
			;;
		upgrade)
			shift
			cmd_upgrade "$@"
			;;
		clean)
			shift
			cmd_clean "$@"
			;;
		doctor|dr)
			shift
			cmd_doctor "$@"
			;;
		audit)
			shift
			cmd_audit "$@"
			;;
		tests)
			shift
			cmd_tests "$@"
			;;
		log)
			shift
			cmd_log "$@"
			;;
		report)
			shift
			cmd_report "$@"
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
