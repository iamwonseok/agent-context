#!/bin/bash
# Agent-Context Installation Script
# Installs agent-context into a target project directory
#
# Usage:
#   ./install.sh [target_directory]
#   ./install.sh /path/to/my-project
#   ./install.sh .  # Install to current directory
#
# This script copies the essential agent-context files to the target project:
#   - .cursorrules
#   - skills/
#   - workflows/
#   - tools/pm/
#   - .project.yaml (template)

set -e
set -o pipefail

# Script directory (agent-context source)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
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

log_info() {
	echo -e "${BLUE}[>>]${NC} $1"
}

log_ok() {
	echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
	echo -e "${YELLOW}[!!]${NC} $1" >&2
}

log_error() {
	echo -e "${RED}[NG]${NC} $1" >&2
}

usage() {
	cat <<EOF
Agent-Context Installation Script

USAGE:
    $(basename "$0") [options] [target_directory]

ARGUMENTS:
    target_directory    Directory to install agent-context into
                        (default: current directory)

OPTIONS:
    -f, --force         Overwrite existing files
    --minimal           Install only essential files (no tools)
    --with-config       Also copy .editorconfig, linter configs
    --non-interactive   Skip prompts (use defaults or provided values)
    -h, --help          Show this help

CONFIGURATION OPTIONS:
    --jira-url URL      Jira base URL (e.g., https://your-domain.atlassian.net)
    --jira-project KEY  Jira project key (e.g., PROJ)
    --jira-email EMAIL  Atlassian account email
    --gitlab-url URL    GitLab base URL (e.g., https://gitlab.example.com)

EXAMPLES:
    # Interactive install (prompts for settings)
    $(basename "$0") /path/to/my-project

    # Install with all settings provided
    $(basename "$0") --force \\
        --jira-url https://mycompany.atlassian.net \\
        --jira-project DEMO \\
        --jira-email user@example.com \\
        /path/to/my-project

    # Non-interactive with defaults
    $(basename "$0") --non-interactive --force /path/to/my-project

INSTALLED FILES:
    .cursorrules        AI agent instructions
    skills/             Skill definitions (analyze, design, implement, etc.)
    workflows/          Workflow templates (solo, team, project)
    tools/pm/           Project management CLI (Jira/Confluence)
    .project.yaml       Configuration file

EOF
}

# Parse arguments
TARGET_DIR=""
FORCE=false
MINIMAL=false
WITH_CONFIG=false
INTERACTIVE=true
ARG_JIRA_URL=""
ARG_JIRA_PROJECT=""
ARG_JIRA_EMAIL=""
ARG_GITLAB_URL=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		-f|--force)
			FORCE=true
			;;
		--minimal)
			MINIMAL=true
			;;
		--with-config)
			WITH_CONFIG=true
			;;
		--non-interactive)
			INTERACTIVE=false
			;;
		--jira-url)
			ARG_JIRA_URL="$2"
			shift
			;;
		--jira-project)
			ARG_JIRA_PROJECT="$2"
			shift
			;;
		--jira-email)
			ARG_JIRA_EMAIL="$2"
			shift
			;;
		--gitlab-url)
			ARG_GITLAB_URL="$2"
			shift
			;;
		-h|--help)
			usage
			exit 0
			;;
		-*)
			log_error "Unknown option: $1"
			usage
			exit 1
			;;
		*)
			if [[ -z "${TARGET_DIR}" ]]; then
				TARGET_DIR="$1"
			else
				log_error "Multiple target directories specified"
				exit 1
			fi
			;;
	esac
	shift
done

# Default to current directory
TARGET_DIR="${TARGET_DIR:-.}"

# Resolve to absolute path
TARGET_DIR="$(cd "${TARGET_DIR}" 2>/dev/null && pwd)" || {
	log_error "Target directory does not exist: ${TARGET_DIR}"
	exit 1
}

# Check if target is the source directory
if [[ "${TARGET_DIR}" == "${SCRIPT_DIR}" ]]; then
	log_error "Cannot install into the source directory itself"
	exit 1
fi

# Check if target is a git repository (recommended but not required)
if [[ ! -d "${TARGET_DIR}/.git" ]]; then
	log_warn "Target is not a git repository. Consider running 'git init' first."
fi

echo ""
echo "============================================================"
echo "Agent-Context Installation"
echo "============================================================"
echo ""
echo "Source:  ${SCRIPT_DIR}"
echo "Target:  ${TARGET_DIR}"
echo "Force:   ${FORCE}"
echo "Minimal: ${MINIMAL}"
echo ""

# Copy function with overwrite check
copy_item() {
	local src="$1"
	local dst="$2"
	local name="$3"

	if [[ -e "${dst}" ]] && [[ "${FORCE}" != "true" ]]; then
		log_warn "Skipping ${name} (already exists, use --force to overwrite)"
		return 0
	fi

	if [[ -d "${src}" ]]; then
		rm -rf "${dst}" 2>/dev/null || true
		cp -r "${src}" "${dst}"
	else
		cp "${src}" "${dst}"
	fi

	log_ok "Installed: ${name}"
}

# Install essential files
log_info "Installing essential files..."

# .cursorrules
copy_item "${SCRIPT_DIR}/.cursorrules" "${TARGET_DIR}/.cursorrules" ".cursorrules"

# skills/
copy_item "${SCRIPT_DIR}/skills" "${TARGET_DIR}/skills" "skills/"

# workflows/
copy_item "${SCRIPT_DIR}/workflows" "${TARGET_DIR}/workflows" "workflows/"

# tools/pm/ (unless minimal)
if [[ "${MINIMAL}" != "true" ]]; then
	log_info "Installing tools..."
	mkdir -p "${TARGET_DIR}/tools"
	copy_item "${SCRIPT_DIR}/tools/pm" "${TARGET_DIR}/tools/pm" "tools/pm/"
fi

# Create .project.yaml - get values from args, env, source, or prompt user
if [[ ! -f "${TARGET_DIR}/.project.yaml" ]] || [[ "${FORCE}" == "true" ]]; then
	log_info "Configuring .project.yaml..."

	# Priority: CLI args > Environment vars > Source config > User input > Defaults
	# 1. Try CLI arguments
	jira_url="${ARG_JIRA_URL}"
	jira_project="${ARG_JIRA_PROJECT}"
	jira_email="${ARG_JIRA_EMAIL}"
	gitlab_url="${ARG_GITLAB_URL}"

	# 2. Try environment variables
	jira_url="${jira_url:-${JIRA_BASE_URL}}"
	jira_email="${jira_email:-${JIRA_EMAIL}}"
	gitlab_url="${gitlab_url:-${GITLAB_BASE_URL}}"

	# 3. Try source .project.yaml
	if [[ -f "${SCRIPT_DIR}/.project.yaml" ]]; then
		[[ -z "${jira_url}" ]] && jira_url=$(yq -r '.platforms.jira.base_url // .jira.base_url // ""' "${SCRIPT_DIR}/.project.yaml" 2>/dev/null || echo "")
		[[ -z "${jira_email}" ]] && jira_email=$(yq -r '.platforms.jira.email // .jira.email // ""' "${SCRIPT_DIR}/.project.yaml" 2>/dev/null || echo "")
		[[ -z "${gitlab_url}" ]] && gitlab_url=$(yq -r '.platforms.gitlab.base_url // .gitlab.base_url // ""' "${SCRIPT_DIR}/.project.yaml" 2>/dev/null || echo "")
	fi

	# Clean up null values
	[[ "${jira_url}" == "null" ]] && jira_url=""
	[[ "${jira_email}" == "null" ]] && jira_email=""
	[[ "${gitlab_url}" == "null" ]] && gitlab_url=""

	# 4. Interactive prompts if values still missing
	if [[ "${INTERACTIVE}" == "true" ]] && [[ -t 0 ]]; then
		echo ""
		log_info "Configure your platform settings (press Enter to skip):"
		echo ""

		# Jira URL
		if [[ -z "${jira_url}" ]]; then
			echo -n "  Jira URL [https://your-domain.atlassian.net]: "
			read -r input_jira_url
			jira_url="${input_jira_url}"
		else
			echo "  Jira URL: ${jira_url}"
		fi

		# Jira Project Key
		if [[ -z "${jira_project}" ]]; then
			echo -n "  Jira Project Key [e.g., PROJ]: "
			read -r input_jira_project
			jira_project="${input_jira_project}"
		else
			echo "  Jira Project: ${jira_project}"
		fi

		# Jira Email
		if [[ -z "${jira_email}" ]]; then
			echo -n "  Atlassian Email [your-email@example.com]: "
			read -r input_jira_email
			jira_email="${input_jira_email}"
		else
			echo "  Jira Email: ${jira_email}"
		fi

		# GitLab URL (optional)
		if [[ -z "${gitlab_url}" ]]; then
			echo -n "  GitLab URL (optional) [https://gitlab.example.com]: "
			read -r input_gitlab_url
			gitlab_url="${input_gitlab_url}"
		else
			echo "  GitLab URL: ${gitlab_url}"
		fi

		echo ""
	fi

	# 5. Use defaults for any remaining empty values
	jira_url="${jira_url:-https://CHANGE_ME.atlassian.net}"
	jira_project="${jira_project:-CHANGE_ME}"
	jira_email="${jira_email:-CHANGE_ME@example.com}"
	confluence_url="${jira_url}"  # Same as Jira for Atlassian Cloud
	gitlab_url="${gitlab_url:-https://gitlab.CHANGE_ME.com}"

	cat > "${TARGET_DIR}/.project.yaml" <<EOF
# Project Configuration
# Generated by agent-context install.sh
#
# IMPORTANT: Replace any "CHANGE_ME" values with your actual settings!

# ============================================================
# Role Assignment (which platform handles what)
# ============================================================
roles:
  vcs: gitlab           # Version Control: github | gitlab
  issue: jira           # Issue Tracking: jira | github | gitlab
  review: gitlab        # Code Review: github | gitlab
  docs: confluence      # Documentation: confluence | github | gitlab

# ============================================================
# Platform Configurations
# ============================================================
platforms:
  jira:
    base_url: ${jira_url}
    project_key: ${jira_project}
    email: ${jira_email}

  confluence:
    base_url: ${confluence_url}
    space_key: CHANGE_ME          # Your Confluence space key

  gitlab:
    base_url: ${gitlab_url}
    project: CHANGE_ME/project    # namespace/project

  github:
    repo: owner/repo

# ============================================================
# Branch Naming Convention
# ============================================================
branch:
  feature_prefix: feat/
  bugfix_prefix: fix/
  hotfix_prefix: hotfix/

# ============================================================
# Authentication
# ============================================================
# Tokens are loaded from (in order):
#   1. Environment variables: JIRA_TOKEN, GITLAB_TOKEN
#   2. Project secrets: .secrets/atlassian-api-token
#   3. Global secrets: ~/.secrets/atlassian-api-token
#
# Get Atlassian API token from:
#   https://id.atlassian.com/manage-profile/security/api-tokens
EOF

	# Show what values were used and check for CHANGE_ME
	has_change_me=false
	[[ "${jira_url}" == *"CHANGE_ME"* ]] && has_change_me=true
	[[ "${jira_project}" == *"CHANGE_ME"* ]] && has_change_me=true
	[[ "${jira_email}" == *"CHANGE_ME"* ]] && has_change_me=true

	if [[ "${has_change_me}" == "false" ]]; then
		log_ok "Created: .project.yaml (fully configured)"
		log_info "  Jira: ${jira_url} (${jira_project})"
		log_info "  Email: ${jira_email}"
		[[ "${gitlab_url}" != *"CHANGE_ME"* ]] && log_info "  GitLab: ${gitlab_url}"
	else
		log_warn "Created: .project.yaml (has CHANGE_ME placeholders)"
		[[ "${jira_url}" == *"CHANGE_ME"* ]] && log_warn "  - jira.base_url needs to be set"
		[[ "${jira_project}" == *"CHANGE_ME"* ]] && log_warn "  - jira.project_key needs to be set"
		[[ "${jira_email}" == *"CHANGE_ME"* ]] && log_warn "  - jira.email needs to be set"
		echo ""
		log_info "Edit .project.yaml to complete configuration"
	fi
else
	log_warn "Skipping .project.yaml (already exists)"
fi

# Check for global secrets in ~/.secrets
if [[ -d "${HOME}/.secrets" ]]; then
	log_ok "Found global secrets: ~/.secrets"

	# Check for specific tokens
	if [[ -f "${HOME}/.secrets/atlassian-api-token" ]]; then
		log_ok "  - Atlassian API token found"
	fi
	if [[ -f "${HOME}/.secrets/gitlab-api-token" ]]; then
		log_ok "  - GitLab API token found"
	fi
	if [[ -f "${HOME}/.secrets/github-api-token" ]]; then
		log_ok "  - GitHub API token found"
	fi

	log_info "Using global ~/.secrets (no project .secrets/ needed)"
else
	# Create .secrets directory template only if ~/.secrets doesn't exist
	log_warn "No global ~/.secrets found"

	if [[ ! -d "${TARGET_DIR}/.secrets" ]]; then
		mkdir -p "${TARGET_DIR}/.secrets"
		cat > "${TARGET_DIR}/.secrets/.gitkeep" <<'EOF'
# This directory contains secret files (API tokens, etc.)
# Files in this directory should NOT be committed to git.
#
# Recommended: Use global ~/.secrets instead
#   mkdir -p ~/.secrets
#   echo "your-token" > ~/.secrets/atlassian-api-token
#   echo "your-token" > ~/.secrets/gitlab-api-token
#   chmod 600 ~/.secrets/*
EOF
		log_ok "Created: .secrets/ directory (template)"
	fi
fi

# Add .secrets to .gitignore if not already present
if [[ -f "${TARGET_DIR}/.gitignore" ]]; then
	if ! grep -q "^\.secrets" "${TARGET_DIR}/.gitignore" 2>/dev/null; then
		echo "" >> "${TARGET_DIR}/.gitignore"
		echo "# Agent-context secrets" >> "${TARGET_DIR}/.gitignore"
		echo ".secrets/*" >> "${TARGET_DIR}/.gitignore"
		echo "!.secrets/.gitkeep" >> "${TARGET_DIR}/.gitignore"
		log_ok "Updated: .gitignore"
	fi
else
	cat > "${TARGET_DIR}/.gitignore" <<'EOF'
# Agent-context secrets
.secrets/*
!.secrets/.gitkeep
EOF
	log_ok "Created: .gitignore"
fi

# Install config files if requested
if [[ "${WITH_CONFIG}" == "true" ]]; then
	log_info "Installing config files..."

	config_files=(
		".editorconfig"
		".shellcheckrc"
		".flake8"
		".yamllint.yml"
	)

	for cfg in "${config_files[@]}"; do
		if [[ -f "${SCRIPT_DIR}/${cfg}" ]]; then
			copy_item "${SCRIPT_DIR}/${cfg}" "${TARGET_DIR}/${cfg}" "${cfg}"
		fi
	done
fi

# Summary
echo ""
echo "============================================================"
echo "Installation Complete"
echo "============================================================"
echo ""
echo "Installed to: ${TARGET_DIR}"
echo ""
echo "Next steps:"
echo ""
echo "  1. Edit .project.yaml with your platform settings:"
echo "     vi ${TARGET_DIR}/.project.yaml"
echo ""
echo "     Required settings:"
echo "       platforms.jira.base_url      # e.g., https://your-domain.atlassian.net"
echo "       platforms.jira.project_key   # e.g., PROJ"
echo "       platforms.jira.email         # Your Atlassian account email"
echo ""
if [[ -d "${HOME}/.secrets" ]]; then
	echo "  2. Authentication: Using ~/.secrets (already configured)"
	if [[ -f "${HOME}/.secrets/atlassian-api-token" ]]; then
		echo "     Token: ~/.secrets/atlassian-api-token"
	fi
else
	echo "  2. Set up authentication:"
	echo "     mkdir -p ~/.secrets"
	echo "     echo 'your-api-token' > ~/.secrets/atlassian-api-token"
	echo "     echo 'your-api-token' > ~/.secrets/gitlab-api-token"
	echo "     chmod 600 ~/.secrets/*"
	echo ""
	echo "     Get Atlassian API token from:"
	echo "     https://id.atlassian.com/manage-profile/security/api-tokens"
fi
echo ""
echo "  3. Test configuration:"
echo "     cd ${TARGET_DIR}"
echo "     ./tools/pm/bin/pm config show"
echo "     ./tools/pm/bin/pm jira me"
echo ""
echo "  Troubleshooting:"
echo "     - 'jq parse error' = Wrong email or invalid token"
echo "     - 'Jira not configured' = Missing base_url, email, or token"
echo ""
log_ok "Agent-context installed successfully!"
