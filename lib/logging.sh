#!/bin/bash
# Agent-Context Common Logging Library
# Source this file to use logging functions
#
# Usage:
#   source "${SCRIPT_DIR}/lib/logging.sh"
#
# Functions:
#   log_info "message"    - [i] Info message (stdout)
#   log_ok "message"      - [V] Success message (stdout)
#   log_warn "message"    - [!] Warning message (stderr)
#   log_error "message"   - [X] Error message (stderr)
#   log_skip "message"    - [-] Skip message (stdout)
#   log_header "message"  - Bold header (stdout)

# Prevent multiple sourcing
if [[ -n "${_AC_LOGGING_LOADED:-}" ]]; then
	return 0
fi
_AC_LOGGING_LOADED=1

# Colors (auto-detect terminal)
if [[ -t 1 ]]; then
	_AC_RED='\033[0;31m'
	_AC_GREEN='\033[0;32m'
	_AC_YELLOW='\033[1;33m'
	_AC_BLUE='\033[0;34m'
	_AC_CYAN='\033[0;36m'
	_AC_BOLD='\033[1m'
	_AC_NC='\033[0m'
else
	_AC_RED=''
	_AC_GREEN=''
	_AC_YELLOW=''
	_AC_BLUE=''
	_AC_CYAN=''
	_AC_BOLD=''
	_AC_NC=''
fi

# Logging functions following .cursorrules Output Style:
#   [V] pass, [X] fail, [!] warn, [i] info, [-] skip, [*] progress

log_info() {
	echo -e "${_AC_BLUE}[i]${_AC_NC} $1"
}

log_ok() {
	echo -e "${_AC_GREEN}[V]${_AC_NC} $1"
}

log_warn() {
	echo -e "${_AC_YELLOW}[!]${_AC_NC} $1" >&2
}

log_error() {
	echo -e "${_AC_RED}[X]${_AC_NC} $1" >&2
}

log_skip() {
	echo -e "${_AC_BLUE}[-]${_AC_NC} $1"
}

log_progress() {
	echo -e "${_AC_CYAN}[*]${_AC_NC} $1"
}

log_header() {
	echo ""
	echo -e "${_AC_BOLD}${_AC_CYAN}$1${_AC_NC}"
	echo ""
}

# Export color variables for scripts that need direct access
# (prefixed with _AC_ to avoid conflicts)
export _AC_RED _AC_GREEN _AC_YELLOW _AC_BLUE _AC_CYAN _AC_BOLD _AC_NC
