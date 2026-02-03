#!/bin/bash
# Agent-Context Installation Script
# Installs agent-context into a target project directory
#
# Usage:
#   ./install.sh [options] [target_directory]
#   ./install.sh /path/to/my-project
#   ./install.sh --profile full .
#
# This script installs agent-context with the following layout:
#   - .cursorrules (project root)
#   - .project.yaml (project root)
#   - .agent/skills/
#   - .agent/workflows/
#   - .agent/tools/pm/
#   - .agent/templates/ (vimrc, etc.)
#
# Installation Profiles:
#   minimal: Core files only (.cursorrules, .project.yaml, .agent/*)
#   full:    Core + config files (.editorconfig, .pre-commit-config.yaml, etc.)

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
    -f, --force         Overwrite existing files (except .gitignore which merges)
    --profile PROFILE   Installation profile: full (default), minimal
    --non-interactive   Skip prompts (use defaults or provided values)
    --with-python       Include pyproject.toml (for Python projects)
    -h, --help          Show this help

PROFILES:
    minimal   Core files only:
              - .cursorrules, .project.yaml
              - .agent/skills/, .agent/workflows/, .agent/tools/pm/

    full      Core + configuration files:
              - All minimal files
              - .editorconfig, .pre-commit-config.yaml
              - .shellcheckrc, .yamllint.yml, .hadolint.yaml
              - .clang-format, .clang-tidy, .flake8
              - .gitignore (merged safely)
              - .agent/templates/vimrc (as template, not root install)

CONFIGURATION OPTIONS:
    --jira-url URL      Jira base URL (e.g., https://your-domain.atlassian.net)
    --jira-project KEY  Jira project key (e.g., PROJ)
    --jira-email EMAIL  Atlassian account email
    --gitlab-url URL    GitLab base URL (e.g., https://gitlab.example.com)

EXAMPLES:
    # Interactive install with full profile (default)
    $(basename "$0") /path/to/my-project

    # Minimal install (core files only)
    $(basename "$0") --profile minimal /path/to/my-project

    # Full install with force overwrite
    $(basename "$0") --force /path/to/my-project

    # Non-interactive with settings
    $(basename "$0") --non-interactive --force \\
        --jira-url https://mycompany.atlassian.net \\
        --jira-project DEMO \\
        /path/to/my-project

INSTALLED LAYOUT:
    target/
    |-- .cursorrules        # AI agent instructions
    |-- .project.yaml       # Project configuration
    |-- .agent/
    |   |-- skills/         # Skill definitions
    |   |-- workflows/      # Workflow templates
    |   |-- tools/pm/       # PM CLI tools
    |   \`-- templates/      # Templates (vimrc, etc.)
    |-- .editorconfig       # (full profile only)
    |-- .pre-commit-config.yaml
    \`-- ...other configs

EOF
}

# ============================================================
# Argument Parsing
# ============================================================
TARGET_DIR=""
FORCE=false
PROFILE="full"
INTERACTIVE=true
WITH_PYTHON=false
ARG_JIRA_URL=""
ARG_JIRA_PROJECT=""
ARG_JIRA_EMAIL=""
ARG_GITLAB_URL=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		-f|--force)
			FORCE=true
			;;
		--profile)
			PROFILE="$2"
			if [[ "${PROFILE}" != "full" ]] && [[ "${PROFILE}" != "minimal" ]]; then
				log_error "Invalid profile: ${PROFILE}. Use 'full' or 'minimal'."
				exit 1
			fi
			shift
			;;
		--non-interactive)
			INTERACTIVE=false
			;;
		--with-python)
			WITH_PYTHON=true
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
		# Legacy options (backward compatibility)
		--minimal)
			PROFILE="minimal"
			;;
		--with-config)
			PROFILE="full"
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
echo "Source:   ${SCRIPT_DIR}"
echo "Target:   ${TARGET_DIR}"
echo "Profile:  ${PROFILE}"
echo "Force:    ${FORCE}"
echo ""

# ============================================================
# Copy Functions
# ============================================================

# Copy with overwrite check (for files)
copy_file() {
	local src="$1"
	local dst="$2"
	local name="$3"

	if [[ -e "${dst}" ]] && [[ "${FORCE}" != "true" ]]; then
		log_warn "Skipping ${name} (already exists, use --force to overwrite)"
		return 0
	fi

	cp "${src}" "${dst}"
	log_ok "Installed: ${name}"
}

# Copy directory with overwrite check
copy_dir() {
	local src="$1"
	local dst="$2"
	local name="$3"

	if [[ -e "${dst}" ]] && [[ "${FORCE}" != "true" ]]; then
		log_warn "Skipping ${name} (already exists, use --force to overwrite)"
		return 0
	fi

	rm -rf "${dst}" 2>/dev/null || true
	cp -r "${src}" "${dst}"
	log_ok "Installed: ${name}"
}

# ============================================================
# .cursorrules Merge Logic
# ============================================================
# Marker for agent-context index map block
CURSORRULES_MARKER_BEGIN="# BEGIN AGENT_CONTEXT INDEX MAP"
CURSORRULES_MARKER_END="# END AGENT_CONTEXT INDEX MAP"

generate_cursorrules_index_map() {
	cat <<'EOF'
# BEGIN AGENT_CONTEXT INDEX MAP
# Agent-Context Index Map
#
# This block was added by agent-context installer.
# For design philosophy, see .agent/workflows/README.md and docs/ARCHITECTURE.md.
#
# Index:
#   .agent/skills/         - Generic skill templates (analyze, design, implement, test, review)
#   .agent/workflows/      - Context-aware workflow definitions (solo, team, project)
#   .agent/tools/pm/       - PM CLI (Jira/Confluence integration)
#   .project.yaml          - Project configuration (platforms, roles, git workflow)
#
# END AGENT_CONTEXT INDEX MAP

EOF
}

install_cursorrules() {
	local target_file="${TARGET_DIR}/.cursorrules"
	local source_file="${SCRIPT_DIR}/.cursorrules"

	if [[ ! -f "${target_file}" ]]; then
		# Case A: No existing .cursorrules - create new with index map
		{
			generate_cursorrules_index_map
			cat "${source_file}"
		} > "${target_file}"
		log_ok "Created: .cursorrules (with index map)"
	elif grep -q "${CURSORRULES_MARKER_BEGIN}" "${target_file}" 2>/dev/null; then
		# Case C: Already has index map - skip or update
		if [[ "${FORCE}" == "true" ]]; then
			# Remove old block and insert new one
			local temp_file
			temp_file=$(mktemp)
			# Remove existing block
			sed "/${CURSORRULES_MARKER_BEGIN}/,/${CURSORRULES_MARKER_END}/d" "${target_file}" > "${temp_file}"
			# Prepend new block
			{
				generate_cursorrules_index_map
				cat "${temp_file}"
			} > "${target_file}"
			rm -f "${temp_file}"
			log_ok "Updated: .cursorrules (index map refreshed)"
		else
			log_warn "Skipping .cursorrules (index map already exists)"
		fi
	else
		# Case B: Existing .cursorrules without index map - merge
		if [[ "${FORCE}" != "true" ]]; then
			# Safe merge: prepend index map to existing content
			local temp_file
			temp_file=$(mktemp)
			{
				generate_cursorrules_index_map
				cat "${target_file}"
			} > "${temp_file}"
			mv "${temp_file}" "${target_file}"
			log_ok "Merged: .cursorrules (index map added, existing content preserved)"
		else
			# Force: overwrite completely
			{
				generate_cursorrules_index_map
				cat "${source_file}"
			} > "${target_file}"
			log_ok "Replaced: .cursorrules (force mode)"
		fi
	fi
}

# ============================================================
# .gitignore Merge Logic
# ============================================================
GITIGNORE_MARKER_BEGIN="# BEGIN AGENT_CONTEXT"
GITIGNORE_MARKER_END="# END AGENT_CONTEXT"

generate_gitignore_block() {
	cat <<'EOF'
# BEGIN AGENT_CONTEXT
# Agent-context managed entries
.secrets/*
!.secrets/.gitkeep
EOF
}

install_gitignore() {
	local target_file="${TARGET_DIR}/.gitignore"
	local source_file="${SCRIPT_DIR}/.gitignore"

	if [[ ! -f "${target_file}" ]]; then
		# No existing .gitignore - copy source if exists, else create minimal
		if [[ -f "${source_file}" ]]; then
			cp "${source_file}" "${target_file}"
		else
			generate_gitignore_block > "${target_file}"
			echo "${GITIGNORE_MARKER_END}" >> "${target_file}"
		fi
		log_ok "Created: .gitignore"
	elif grep -q "${GITIGNORE_MARKER_BEGIN}" "${target_file}" 2>/dev/null; then
		# Already has agent-context block
		log_warn "Skipping .gitignore (agent-context block already exists)"
	else
		# Existing .gitignore without agent-context block - append
		{
			echo ""
			generate_gitignore_block
			echo "${GITIGNORE_MARKER_END}"
		} >> "${target_file}"
		log_ok "Updated: .gitignore (agent-context entries appended)"
	fi
}

# ============================================================
# Core Installation (.agent/ layout)
# ============================================================
log_info "Installing core files..."

# Create .agent directory
mkdir -p "${TARGET_DIR}/.agent"

# Install .cursorrules (with merge logic)
install_cursorrules

# Install .agent/skills/
copy_dir "${SCRIPT_DIR}/skills" "${TARGET_DIR}/.agent/skills" ".agent/skills/"

# Install .agent/workflows/
copy_dir "${SCRIPT_DIR}/workflows" "${TARGET_DIR}/.agent/workflows" ".agent/workflows/"

# Install .agent/tools/pm/
mkdir -p "${TARGET_DIR}/.agent/tools"
copy_dir "${SCRIPT_DIR}/tools/pm" "${TARGET_DIR}/.agent/tools/pm" ".agent/tools/pm/"

# Create .agent/templates/ and install vimrc template
mkdir -p "${TARGET_DIR}/.agent/templates"
if [[ -f "${SCRIPT_DIR}/.vimrc" ]]; then
	copy_file "${SCRIPT_DIR}/.vimrc" "${TARGET_DIR}/.agent/templates/vimrc" ".agent/templates/vimrc"
fi

# ============================================================
# .project.yaml Configuration
# ============================================================
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
# Git Workflow (project-specific)
# ============================================================
git:
  merge:
    # Strategy options: ff-only | squash | rebase | merge-commit
    strategy: ff-only
    # If true, delete the source branch after it is merged.
    delete_merged_branch: true
  push:
    # If true, do not push unless pre-commit checks pass.
    require_precommit_pass: true

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

# ============================================================
# Full Profile: Configuration Files
# ============================================================
if [[ "${PROFILE}" == "full" ]]; then
	log_info "Installing configuration files (full profile)..."

	# Configuration files to install at project root
	config_files=(
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
		if [[ -f "${SCRIPT_DIR}/${cfg}" ]]; then
			copy_file "${SCRIPT_DIR}/${cfg}" "${TARGET_DIR}/${cfg}" "${cfg}"
		fi
	done

	# .gitignore: always merge safely (never overwrite)
	install_gitignore

	# pyproject.toml: only if --with-python or Python project detected
	if [[ "${WITH_PYTHON}" == "true" ]] || [[ -f "${TARGET_DIR}/setup.py" ]] || [[ -f "${TARGET_DIR}/requirements.txt" ]]; then
		if [[ -f "${SCRIPT_DIR}/pyproject.toml" ]]; then
			copy_file "${SCRIPT_DIR}/pyproject.toml" "${TARGET_DIR}/pyproject.toml" "pyproject.toml"
		fi
	fi
fi

# ============================================================
# Secrets Directory Setup
# ============================================================
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

# ============================================================
# Summary
# ============================================================
echo ""
echo "============================================================"
echo "Installation Complete"
echo "============================================================"
echo ""
echo "Installed to: ${TARGET_DIR}"
echo "Profile:      ${PROFILE}"
echo ""
echo "Layout:"
echo "  ${TARGET_DIR}/"
echo "  |-- .cursorrules"
echo "  |-- .project.yaml"
echo "  |-- .agent/"
echo "  |   |-- skills/"
echo "  |   |-- workflows/"
echo "  |   |-- tools/pm/"
echo "  |   \`-- templates/"
if [[ "${PROFILE}" == "full" ]]; then
	echo "  |-- .editorconfig"
	echo "  |-- .pre-commit-config.yaml"
	echo "  \`-- ...other configs"
fi
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
echo "     ./.agent/tools/pm/bin/pm config show"
echo "     ./.agent/tools/pm/bin/pm jira me"
echo ""
echo "  Troubleshooting:"
echo "     - 'jq parse error' = Wrong email or invalid token"
echo "     - 'Jira not configured' = Missing base_url, email, or token"
echo ""
log_ok "Agent-context installed successfully!"
