#!/bin/bash
# Agent-Context Platform Detection Library
# Source this file to use platform detection functions
#
# Usage:
#   source "${SCRIPT_DIR}/lib/platform.sh"
#
# Functions:
#   detect_os             - Detect OS type (macos/debian/rhel/linux/unknown)
#   detect_arch           - Detect CPU architecture (x86_64/arm64/unknown)
#   has_cmd "cmd"         - Check if command exists
#   get_version "cmd"     - Get command version string
#   check_deps "cmd1" ... - Check multiple dependencies, returns missing ones

# Prevent multiple sourcing
if [[ -n "${_AC_PLATFORM_LOADED:-}" ]]; then
	return 0
fi
_AC_PLATFORM_LOADED=1

# ============================================================
# OS Detection
# ============================================================

# Detect operating system
# Returns: macos, debian, rhel, linux, unknown
detect_os() {
	case "$(uname -s)" in
		Darwin)
			echo "macos"
			;;
		Linux)
			if [[ -f /etc/redhat-release ]]; then
				echo "rhel"
			elif [[ -f /etc/debian_version ]]; then
				echo "debian"
			else
				echo "linux"
			fi
			;;
		MINGW*|MSYS*|CYGWIN*)
			echo "windows"
			;;
		*)
			echo "unknown"
			;;
	esac
}

# Detect CPU architecture
# Returns: x86_64, arm64, unknown
detect_arch() {
	local arch
	arch="$(uname -m)"
	case "${arch}" in
		x86_64|amd64)
			echo "x86_64"
			;;
		aarch64|arm64)
			echo "arm64"
			;;
		*)
			echo "unknown"
			;;
	esac
}

# ============================================================
# Command Detection
# ============================================================

# Check if command exists
# Returns: 0 if exists, 1 if not
has_cmd() {
	command -v "$1" &>/dev/null
}

# Get command version string
# Returns: version string or "not found"
get_version() {
	local cmd="$1"
	if has_cmd "${cmd}"; then
		case "${cmd}" in
			git)
				git --version 2>/dev/null | sed 's/git version //'
				;;
			jq)
				jq --version 2>/dev/null | sed 's/jq-//'
				;;
			yq)
				yq --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'
				;;
			glab)
				glab --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'
				;;
			gh)
				gh --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'
				;;
			pre-commit)
				pre-commit --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'
				;;
			*)
				"${cmd}" --version 2>/dev/null | head -1 || echo "unknown"
				;;
		esac
	else
		echo "not found"
	fi
}

# Check required dependencies
# Usage: check_deps git jq yq
# Returns: space-separated list of missing commands (empty if all found)
# Exit: 0 if all found, 1 if any missing
check_deps() {
	local missing=()
	for cmd in "$@"; do
		has_cmd "${cmd}" || missing+=("${cmd}")
	done
	if [[ ${#missing[@]} -gt 0 ]]; then
		echo "${missing[*]}"
		return 1
	fi
	return 0
}

# ============================================================
# Shell Detection
# ============================================================

# Detect current shell name
# Returns: bash, zsh, sh, or unknown
detect_shell() {
	local shell_name
	shell_name=$(basename "${SHELL:-unknown}")
	case "${shell_name}" in
		bash|zsh|sh|fish|ksh)
			echo "${shell_name}"
			;;
		*)
			echo "unknown"
			;;
	esac
}

# Get shell rc file path
# Returns: path to shell rc file or empty string
get_shell_rc() {
	local shell_name
	shell_name=$(detect_shell)
	local os
	os=$(detect_os)

	case "${shell_name}" in
		bash)
			if [[ "${os}" == "macos" ]]; then
				echo "${HOME}/.bash_profile"
			else
				echo "${HOME}/.bashrc"
			fi
			;;
		zsh)
			echo "${HOME}/.zshrc"
			;;
		fish)
			echo "${HOME}/.config/fish/config.fish"
			;;
		*)
			echo ""
			;;
	esac
}

# ============================================================
# Path Utilities
# ============================================================

# Find project root by looking for markers
# Usage: find_project_root [start_dir]
# Searches for: .agent/, .project.yaml, .git/
# Returns: project root path or empty string
find_project_root() {
	local dir="${1:-${PWD}}"

	while [[ "${dir}" != "/" ]]; do
		if [[ -d "${dir}/.agent" ]]; then
			echo "${dir}"
			return 0
		fi
		if [[ -f "${dir}/.project.yaml" ]]; then
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

# Get agent-context installation directory
# Returns: path to agent-context source (e.g., ~/.agent-context)
get_agent_context_dir() {
	# If AGENT_CONTEXT_DIR is set, use it
	if [[ -n "${AGENT_CONTEXT_DIR:-}" ]]; then
		echo "${AGENT_CONTEXT_DIR}"
		return 0
	fi

	# Default location
	echo "${HOME}/.agent-context"
}

# ============================================================
# Environment Utilities
# ============================================================

# Check if running in CI environment
# Returns: 0 if CI, 1 if not
is_ci() {
	# Check common CI environment variables
	[[ -n "${CI:-}" ]] || \
	[[ -n "${GITLAB_CI:-}" ]] || \
	[[ -n "${GITHUB_ACTIONS:-}" ]] || \
	[[ -n "${JENKINS_URL:-}" ]] || \
	[[ -n "${TRAVIS:-}" ]] || \
	[[ -n "${CIRCLECI:-}" ]]
}

# Check if running interactively
# Returns: 0 if interactive, 1 if not
is_interactive() {
	[[ -t 0 ]] && [[ -t 1 ]] && ! is_ci
}

# Export detection functions for use in subshells
export -f detect_os detect_arch has_cmd get_version check_deps 2>/dev/null || true
export -f detect_shell get_shell_rc find_project_root get_agent_context_dir 2>/dev/null || true
export -f is_ci is_interactive 2>/dev/null || true
