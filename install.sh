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
TEMPLATES_DIR="${SCRIPT_DIR}/templates"

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

escape_sed_replacement() {
	local s="$1"
	s=${s//\\/\\\\}
	s=${s//&/\\&}
	s=${s//|/\\|}
	printf '%s' "${s}"
}

render_template() {
	local template_file="$1"
	local dst_file="$2"
	shift 2

	if [[ ! -f "${template_file}" ]]; then
		log_error "Template not found: ${template_file}"
		return 1
	fi

	# Store key/value args for reuse
	local kv_args=("$@")

	_get_kv_value() {
		local search_key="$1"
		local i=0
		while [[ ${i} -lt ${#kv_args[@]} ]]; do
			if [[ "${kv_args[${i}]}" == "${search_key}" ]]; then
				echo "${kv_args[$((i + 1))]}"
				return 0
			fi
			i=$((i + 2))
		done
		echo ""
	}

	# Handle simple conditional blocks:
	#   {{#KEY}} ... {{/KEY}} included only if KEY value is non-empty.
	local tmp_file
	tmp_file=$(mktemp)
	cp "${template_file}" "${tmp_file}"

	local cond_keys=("CONFLUENCE_SPACE_KEY" "GITLAB_URL" "GITLAB_PROJECT" "GITHUB_REPO")
	for cond_key in "${cond_keys[@]}"; do
		local cond_val
		cond_val=$(_get_kv_value "${cond_key}")

		if [[ -z "${cond_val}" ]]; then
			# Delete block
			sed -i.bak "/{{#${cond_key}}}/,/{{\\/${cond_key}}}/d" "${tmp_file}"
			rm -f "${tmp_file}.bak"
		else
			# Keep block, remove markers
			sed -i.bak "s/{{#${cond_key}}}//g; s/{{\\/${cond_key}}}//g" "${tmp_file}"
			rm -f "${tmp_file}.bak"
		fi
	done

	local sed_args=()
	local idx=0
	while [[ ${idx} -lt ${#kv_args[@]} ]]; do
		local key="${kv_args[${idx}]}"
		local value="${kv_args[$((idx + 1))]}"
		idx=$((idx + 2))

		local escaped_value
		escaped_value=$(escape_sed_replacement "${value}")
		sed_args+=("-e" "s|{{${key}}}|${escaped_value}|g")
	done

	sed "${sed_args[@]}" "${tmp_file}" > "${dst_file}"
	rm -f "${tmp_file}"

	if grep -Eq '\{\{[A-Z0-9_]+\}\}' "${dst_file}"; then
		log_error "Template rendering incomplete (unreplaced placeholders): ${dst_file}"
		return 1
	fi
}

normalize_jira_base_url() {
	local url="$1"

	# Jira Cloud base URL should NOT include /wiki
	url=${url%/}
	if [[ "${url}" == *"/wiki" ]]; then
		url=${url%/wiki}
	fi
	printf '%s' "${url}"
}

normalize_confluence_base_url() {
	local url="$1"

	# Confluence Cloud base URL MUST include /wiki
	url=${url%/}
	if [[ "${url}" != *"/wiki" ]]; then
		url="${url}/wiki"
	fi
	printf '%s' "${url}"
}

parse_gitlab_input() {
	# Accepts one of:
	# - https://gitlab.example.com/group/subgroup/repo(.git)
	# - git@gitlab.example.com:group/subgroup/repo(.git)
	# - gitlab.example.com/group/subgroup/repo(.git)
	#
	# Outputs (via echo): "<base_url>|<project_path>"
	local input="$1"
	input=${input%/}

	local host=""
	local path=""

	# SSH style: git@host:namespace/project(.git)
	if [[ "${input}" =~ ^git@([^:]+):(.+)$ ]]; then
		host="${BASH_REMATCH[1]}"
		path="${BASH_REMATCH[2]}"
	else
		# Strip scheme if present
		local no_scheme="${input}"
		no_scheme="${no_scheme#https://}"
		no_scheme="${no_scheme#http://}"

		# Split host/path
		if [[ "${no_scheme}" == */* ]]; then
			host="${no_scheme%%/*}"
			path="${no_scheme#*/}"
		else
			host="${no_scheme}"
			path=""
		fi
	fi

	# Remove trailing .git
	path="${path%.git}"

	local base_url=""
	if [[ -n "${host}" ]]; then
		base_url="https://${host}"
	fi

	echo "${base_url}|${path}"
}

parse_remote_url() {
	# Accepts one of:
	# - https://host/namespace/.../repo(.git)
	# - http://host/namespace/.../repo(.git)
	# - ssh://git@host/namespace/.../repo(.git)
	# - git@host:namespace/.../repo(.git)
	# - host/namespace/.../repo(.git)
	#
	# Outputs: "<host>|<path>" (path has no leading slash, no trailing .git)
	local input="$1"
	input=${input%/}

	local host=""
	local path=""

	# scp-like SSH: user@host:path
	if [[ "${input}" =~ ^[^@]+@([^:]+):(.+)$ ]]; then
		host="${BASH_REMATCH[1]}"
		path="${BASH_REMATCH[2]}"
	else
		# URL with scheme (https://, http://, ssh://)
		if [[ "${input}" =~ ^[a-zA-Z][a-zA-Z0-9+.-]*://(.+)$ ]]; then
			local rest="${BASH_REMATCH[1]}"

			# Drop optional user@
			rest="${rest#*:@}"
			if [[ "${rest}" == */* ]]; then
				host="${rest%%/*}"
				path="${rest#*/}"
			else
				host="${rest}"
				path=""
			fi
		else
			# No scheme: host/path
			if [[ "${input}" == */* ]]; then
				host="${input%%/*}"
				path="${input#*/}"
			else
				host="${input}"
				path=""
			fi
		fi
	fi

	path="${path%.git}"
	echo "${host}|${path}"
}

derive_platforms_from_git_remotes() {
	# Try to derive GitLab/GitHub settings from target repo remotes.
	# Outputs: "<gitlab_base>|<gitlab_project>|<github_repo>"
	local target_dir="$1"

	local gitlab_base=""
	local gitlab_project=""
	local github_repo=""

	if ! command -v git &>/dev/null; then
		echo "||"
		return 0
	fi

	if ! git -C "${target_dir}" rev-parse --is-inside-work-tree &>/dev/null; then
		echo "||"
		return 0
	fi

	local remotes
	remotes=$(git -C "${target_dir}" remote -v 2>/dev/null || true)

	# Helper: pick best candidate url for a given host substring.
	_pick_remote_url() {
		local host_substr="$1"

		# Prefer upstream, then origin, else first match.
		local url=""
		url=$(echo "${remotes}" | awk '$1=="upstream" && $3=="(fetch)" {print $2}' | head -1)
		if [[ -n "${url}" ]] && [[ "${url}" == *"${host_substr}"* ]]; then
			echo "${url}"
			return 0
		fi

		url=$(echo "${remotes}" | awk '$1=="origin" && $3=="(fetch)" {print $2}' | head -1)
		if [[ -n "${url}" ]] && [[ "${url}" == *"${host_substr}"* ]]; then
			echo "${url}"
			return 0
		fi

		url=$(echo "${remotes}" | awk '$3=="(fetch)" {print $2}' | grep -F "${host_substr}" | head -1)
		echo "${url}"
	}

	# GitHub
	local github_url=""
	github_url=$(_pick_remote_url "github")
	if [[ -n "${github_url}" ]]; then
		local parsed
		parsed=$(parse_remote_url "${github_url}")
		local host="${parsed%%|*}"
		local path="${parsed#*|}"

		# For GitHub, repo is owner/repo (first 2 segments)
		if [[ -n "${path}" ]]; then
			local owner="${path%%/*}"
			local rest="${path#*/}"
			local repo="${rest%%/*}"
			if [[ -n "${owner}" ]] && [[ -n "${repo}" ]] && [[ "${owner}" != "${repo}" ]]; then
				github_repo="${owner}/${repo}"
			fi
		fi
	fi

	# GitLab
	local gitlab_url=""
	gitlab_url=$(_pick_remote_url "gitlab")
	if [[ -n "${gitlab_url}" ]]; then
		local parsed
		parsed=$(parse_remote_url "${gitlab_url}")
		local host="${parsed%%|*}"
		local path="${parsed#*|}"

		if [[ -n "${host}" ]]; then
			gitlab_base="https://${host}"
		fi
		if [[ -n "${path}" ]]; then
			gitlab_project="${path}"
		fi
	fi

	echo "${gitlab_base}|${gitlab_project}|${github_repo}"
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
    --confluence-space KEY  Confluence space key (e.g., DEV or ~user)
    --github-repo REPO  GitHub repo (e.g., owner/repo)

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
ARG_CONFLUENCE_SPACE=""
ARG_GITHUB_REPO=""

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
		--confluence-space)
			ARG_CONFLUENCE_SPACE="$2"
			shift
			;;
		--github-repo)
			ARG_GITHUB_REPO="$2"
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
	local template_file="${TEMPLATES_DIR}/cursorrules.index_map.tmpl"

	if [[ -f "${template_file}" ]]; then
		cat "${template_file}"
		return 0
	fi

	log_error "Missing template: ${template_file}"
	return 1
}

install_cursorrules() {
	local target_file="${TARGET_DIR}/.cursorrules"

	if [[ ! -f "${target_file}" ]]; then
		# Case A: No existing .cursorrules - create new with index map only
		# Note: Source .cursorrules is for agent-context development, not for installed projects
		generate_cursorrules_index_map > "${target_file}"
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
		# Safe merge: prepend index map to existing content
		local temp_file
		temp_file=$(mktemp)
		{
			generate_cursorrules_index_map
			cat "${target_file}"
		} > "${temp_file}"
		mv "${temp_file}" "${target_file}"
		log_ok "Merged: .cursorrules (index map added, existing content preserved)"
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

# Install .agent/docs/ (referenced by .cursorrules)
copy_dir "${SCRIPT_DIR}/docs" "${TARGET_DIR}/.agent/docs" ".agent/docs/"

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
	confluence_space_key="${ARG_CONFLUENCE_SPACE}"
	github_repo="${ARG_GITHUB_REPO}"

	# 2. Try environment variables
	jira_url="${jira_url:-${JIRA_BASE_URL}}"
	jira_email="${jira_email:-${JIRA_EMAIL}}"
	gitlab_url="${gitlab_url:-${GITLAB_BASE_URL}}"
	confluence_space_key="${confluence_space_key:-${CONFLUENCE_SPACE_KEY}}"

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
	[[ "${confluence_space_key}" == "null" ]] && confluence_space_key=""
	[[ "${github_repo}" == "null" ]] && github_repo=""

	# Normalize Jira/Confluence URLs
	if [[ -n "${jira_url}" ]]; then
		jira_url=$(normalize_jira_base_url "${jira_url}")
	fi

	confluence_url="${jira_url}"
	if [[ -n "${confluence_url}" ]]; then
		confluence_url=$(normalize_confluence_base_url "${confluence_url}")
	fi

	# GitLab input can be a base_url OR a remote URL (ssh/https). If it includes a path,
	# try to auto-derive both base_url and namespace/project.
	gitlab_project=""
	if [[ -n "${gitlab_url}" ]] && [[ "${gitlab_url}" == *"/"* || "${gitlab_url}" == git@*:* ]]; then
		parsed=$(parse_gitlab_input "${gitlab_url}")
		parsed_base="${parsed%%|*}"
		parsed_project="${parsed#*|}"

		if [[ -n "${parsed_base}" ]]; then
			gitlab_url="${parsed_base}"
		fi
		if [[ -n "${parsed_project}" ]]; then
			gitlab_project="${parsed_project}"
		fi
	fi

	# If platform settings are still missing, try to derive from git remotes.
	# This helps in mixed SSH/HTTPS environments with multiple remotes (origin/upstream).
	if [[ -z "${gitlab_project}" || -z "${github_repo}" ]]; then
		derived=$(derive_platforms_from_git_remotes "${TARGET_DIR}")
		derived_gitlab_base="${derived%%|*}"
		rest="${derived#*|}"
		derived_gitlab_project="${rest%%|*}"
		derived_github_repo="${rest#*|}"

		[[ -z "${gitlab_url}" ]] && gitlab_url="${derived_gitlab_base}"
		[[ -z "${gitlab_project}" ]] && gitlab_project="${derived_gitlab_project}"
		[[ -z "${github_repo}" ]] && github_repo="${derived_github_repo}"
	fi

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

		# Confluence Space Key (optional)
		if [[ -z "${confluence_space_key}" ]]; then
			echo -n "  Confluence Space Key (optional) [e.g., DEV or ~user]: "
			read -r input_confluence_space_key
			confluence_space_key="${input_confluence_space_key}"
		else
			echo "  Confluence Space Key: ${confluence_space_key}"
		fi

		# GitHub Repo (optional)
		if [[ -z "${github_repo}" ]]; then
			echo -n "  GitHub Repo (optional) [e.g., owner/repo]: "
			read -r input_github_repo
			github_repo="${input_github_repo}"
		else
			echo "  GitHub Repo: ${github_repo}"
		fi

		echo ""
	fi

	# 5. Use defaults for any remaining empty values
	jira_url="${jira_url:-https://CHANGE_ME.atlassian.net}"
	jira_project="${jira_project:-CHANGE_ME}"
	jira_email="${jira_email:-CHANGE_ME@example.com}"
	# Optional platforms: only emit blocks when values are provided or derivable.
	confluence_url="${confluence_url:-}"
	confluence_space_key="${confluence_space_key:-}"
	gitlab_url="${gitlab_url:-}"
	gitlab_project="${gitlab_project:-}"
	github_repo="${github_repo:-}"

	if ! render_template \
		"${TEMPLATES_DIR}/project.yaml.tmpl" \
		"${TARGET_DIR}/.project.yaml" \
		"JIRA_URL" "${jira_url}" \
		"JIRA_PROJECT" "${jira_project}" \
		"JIRA_EMAIL" "${jira_email}" \
		"CONFLUENCE_URL" "${confluence_url}" \
		"CONFLUENCE_SPACE_KEY" "${confluence_space_key}" \
		"GITLAB_URL" "${gitlab_url}" \
		"GITLAB_PROJECT" "${gitlab_project}" \
		"GITHUB_REPO" "${github_repo}"; then
		exit 1
	fi

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
		copy_file \
			"${TEMPLATES_DIR}/secrets.gitkeep" \
			"${TARGET_DIR}/.secrets/.gitkeep" \
			".secrets/.gitkeep"
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
echo "  |   |-- docs/"
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
