#!/bin/bash
# Agent-Context Doctor Command
# Diagnose installation health (offline by default)
#
# Usage:
#   agent-context doctor [subcommand] [options]
#
# Subcommands:
#   deps      Check dependencies only
#   auth      Check authentication only
#   project   Check project installation only
#   connect   Test external connectivity (read-only)
#
# This script is sourced by bin/agent-context.sh

# ============================================================
# Usage
# ============================================================
doctor_usage() {
	cat <<EOF
Agent-Context Doctor

USAGE:
    agent-context doctor [subcommand] [options]

SUBCOMMANDS:
    deps        Check required and optional dependencies
    auth        Check authentication (secrets, glab)
    project     Check project installation (.agent/, .project.yaml)
    connect     Test external connectivity (read-only API calls)

    (no subcommand) Run all offline checks (deps + auth + project)

OPTIONS:
    -v, --verbose   Show more details
    -q, --quiet     Show only summary
    -h, --help      Show this help

EXAMPLES:
    # Run all offline diagnostics
    agent-context doctor

    # Check dependencies only
    agent-context doctor deps

    # Test connectivity (requires network)
    agent-context doctor connect

EXIT CODES:
    0   All checks passed
    1   Some checks failed
    3   Environmental skip (e.g., no project found)

EOF
}

# ============================================================
# Doctor: Dependencies
# ============================================================
doctor_deps() {
	local verbose="${1:-false}"
	local total=0
	local passed=0
	local warned=0
	local failed=0

	log_info "Checking dependencies..."

	# Required dependencies
	local required_cmds=(git jq)
	for cmd in "${required_cmds[@]}"; do
		total=$((total + 1))
		if has_cmd "${cmd}"; then
			local ver
			ver=$(get_version "${cmd}")
			log_ok "${cmd} ${ver}"
			passed=$((passed + 1))
		else
			log_error "Missing required: ${cmd}"
			failed=$((failed + 1))
		fi
	done

	# Optional but recommended
	local optional_cmds=(yq glab curl)
	for cmd in "${optional_cmds[@]}"; do
		total=$((total + 1))
		if has_cmd "${cmd}"; then
			local ver
			ver=$(get_version "${cmd}")
			log_ok "${cmd} ${ver}"
			passed=$((passed + 1))
		else
			log_warn "Optional missing: ${cmd}"
			warned=$((warned + 1))
		fi
	done

	# Truly optional (nice to have)
	local nice_cmds=(gh pre-commit shellcheck)
	for cmd in "${nice_cmds[@]}"; do
		total=$((total + 1))
		if has_cmd "${cmd}"; then
			local ver
			ver=$(get_version "${cmd}")
			if [[ "${verbose}" == "true" ]]; then
				log_ok "${cmd} ${ver}"
			else
				log_ok "${cmd}"
			fi
			passed=$((passed + 1))
		else
			if [[ "${verbose}" == "true" ]]; then
				log_skip "${cmd} (optional)"
			fi
			# Don't count as warning for nice-to-have
			total=$((total - 1))
		fi
	done

	echo "deps:total=${total}:passed=${passed}:warned=${warned}:failed=${failed}"
}

# ============================================================
# Doctor: Authentication
# ============================================================
doctor_auth() {
	local verbose="${1:-false}"
	local total=0
	local passed=0
	local warned=0
	local failed=0

	log_info "Checking authentication..."

	# Check ~/.secrets directory
	total=$((total + 1))
	if [[ -d "${HOME}/.secrets" ]]; then
		local mode
		mode=$(stat -f "%OLp" "${HOME}/.secrets" 2>/dev/null || stat -c "%a" "${HOME}/.secrets" 2>/dev/null)
		if [[ "${mode}" == "700" ]]; then
			log_ok "~/.secrets (mode: 700)"
			passed=$((passed + 1))
		else
			log_warn "~/.secrets (mode: ${mode}, should be 700)"
			warned=$((warned + 1))
		fi
	else
		log_error "~/.secrets not found"
		failed=$((failed + 1))
	fi

	# Check token files
	local tokens=("gitlab-api-token" "atlassian-api-token")
	for token in "${tokens[@]}"; do
		total=$((total + 1))
		local token_file="${HOME}/.secrets/${token}"
		if [[ -f "${token_file}" ]]; then
			local size
			size=$(wc -c < "${token_file}" | tr -d ' ')
			if [[ ${size} -gt 10 ]]; then
				log_ok "${token} (${size} bytes)"
				passed=$((passed + 1))
			else
				log_warn "${token} (${size} bytes - seems too short)"
				warned=$((warned + 1))
			fi
		else
			log_warn "${token} not found"
			warned=$((warned + 1))
		fi
	done

	# Optional: github-api-token
	total=$((total + 1))
	local github_token="${HOME}/.secrets/github-api-token"
	if [[ -f "${github_token}" ]]; then
		local size
		size=$(wc -c < "${github_token}" | tr -d ' ')
		log_ok "github-api-token (${size} bytes)"
		passed=$((passed + 1))
	else
		if [[ "${verbose}" == "true" ]]; then
			log_skip "github-api-token (optional)"
		fi
		total=$((total - 1))
	fi

	# Check glab authentication
	if has_cmd glab; then
		total=$((total + 1))
		local glab_status
		glab_status=$(glab auth status 2>&1 || true)
		if echo "${glab_status}" | grep -q "Logged in"; then
			local glab_user
			glab_user=$(echo "${glab_status}" | grep -oE "Logged in .* as [^ ]+" | sed 's/.*as //' || echo "user")
			log_ok "glab: authenticated as ${glab_user}"
			passed=$((passed + 1))
		else
			log_warn "glab: not authenticated"
			warned=$((warned + 1))
		fi
	fi

	# Check gh authentication (optional)
	if has_cmd gh; then
		total=$((total + 1))
		local gh_status
		gh_status=$(gh auth status 2>&1 || true)
		if echo "${gh_status}" | grep -q "Logged in"; then
			log_ok "gh: authenticated"
			passed=$((passed + 1))
		else
			if [[ "${verbose}" == "true" ]]; then
				log_skip "gh: not authenticated (optional)"
			fi
			total=$((total - 1))
		fi
	fi

	echo "auth:total=${total}:passed=${passed}:warned=${warned}:failed=${failed}"
}

# ============================================================
# Doctor: Project
# ============================================================
doctor_project() {
	local verbose="${1:-false}"
	local total=0
	local passed=0
	local warned=0
	local failed=0
	local skipped=0

	log_info "Checking project installation..."

	# Find project root
	local project_root
	project_root=$(find_project_root "${PWD}" 2>/dev/null || true)

	if [[ -z "${project_root}" ]]; then
		log_skip "Not in a project directory"
		echo "project:total=0:passed=0:warned=0:failed=0:skipped=1"
		return 3
	fi

	log_info "Project: ${project_root}"

	# Check .cursorrules
	total=$((total + 1))
	if [[ -f "${project_root}/.cursorrules" ]]; then
		log_ok ".cursorrules exists"
		passed=$((passed + 1))
	else
		log_warn ".cursorrules not found"
		warned=$((warned + 1))
	fi

	# Check .project.yaml
	total=$((total + 1))
	if [[ -f "${project_root}/.project.yaml" ]]; then
		log_ok ".project.yaml exists"
		passed=$((passed + 1))

		# Check for CHANGE_ME
		total=$((total + 1))
		local change_me_count
		change_me_count=$(grep -c "CHANGE_ME" "${project_root}/.project.yaml" 2>/dev/null || echo "0")
		if [[ ${change_me_count} -eq 0 ]]; then
			log_ok ".project.yaml fully configured"
			passed=$((passed + 1))
		else
			log_warn ".project.yaml contains CHANGE_ME (${change_me_count} occurrences)"
			warned=$((warned + 1))
		fi
	else
		log_warn ".project.yaml not found"
		warned=$((warned + 1))
	fi

	# Check .agent/ directory
	total=$((total + 1))
	if [[ -d "${project_root}/.agent" ]]; then
		log_ok ".agent/ directory exists"
		passed=$((passed + 1))

		# Check subdirectories
		local agent_dirs=("skills" "workflows" "tools/pm")
		for dir in "${agent_dirs[@]}"; do
			total=$((total + 1))
			if [[ -d "${project_root}/.agent/${dir}" ]]; then
				log_ok ".agent/${dir}/"
				passed=$((passed + 1))
			else
				log_warn ".agent/${dir}/ missing"
				warned=$((warned + 1))
			fi
		done

		# Check pm executable
		total=$((total + 1))
		if [[ -x "${project_root}/.agent/tools/pm/bin/pm" ]]; then
			log_ok ".agent/tools/pm/bin/pm executable"
			passed=$((passed + 1))
		else
			log_warn ".agent/tools/pm/bin/pm not executable"
			warned=$((warned + 1))
		fi
	else
		log_error ".agent/ directory not found"
		failed=$((failed + 1))
	fi

	echo "project:total=${total}:passed=${passed}:warned=${warned}:failed=${failed}:skipped=${skipped}"
}

# ============================================================
# Doctor: Connect (External Connectivity)
# ============================================================
doctor_connect() {
	local verbose="${1:-false}"
	local total=0
	local passed=0
	local warned=0
	local failed=0
	local skipped=0

	log_info "Testing external connectivity (read-only)..."

	# GitLab SSH
	total=$((total + 1))
	log_progress "Testing GitLab SSH..."
	local ssh_result
	ssh_result=$(ssh -T -o ConnectTimeout=5 -o BatchMode=yes git@gitlab.fadutec.dev 2>&1 || true)
	if echo "${ssh_result}" | grep -q "Welcome"; then
		log_ok "GitLab SSH: connected"
		passed=$((passed + 1))
	else
		log_warn "GitLab SSH: connection failed or timed out"
		warned=$((warned + 1))
	fi

	# GitLab API (if token exists)
	local gitlab_token="${HOME}/.secrets/gitlab-api-token"
	if [[ -f "${gitlab_token}" ]] && has_cmd curl; then
		total=$((total + 1))
		log_progress "Testing GitLab API..."
		local api_result
		api_result=$(curl -s -o /dev/null -w "%{http_code}" \
			--connect-timeout 5 \
			-H "PRIVATE-TOKEN: $(cat "${gitlab_token}")" \
			"https://gitlab.fadutec.dev/api/v4/user" 2>/dev/null || echo "000")
		if [[ "${api_result}" == "200" ]]; then
			log_ok "GitLab API: authenticated"
			passed=$((passed + 1))
		elif [[ "${api_result}" == "401" ]]; then
			log_error "GitLab API: unauthorized (invalid token)"
			failed=$((failed + 1))
		else
			log_warn "GitLab API: HTTP ${api_result}"
			warned=$((warned + 1))
		fi
	else
		if [[ "${verbose}" == "true" ]]; then
			log_skip "GitLab API (no token or curl)"
		fi
	fi

	# Atlassian API (if token exists)
	local atlassian_token="${HOME}/.secrets/atlassian-api-token"
	if [[ -f "${atlassian_token}" ]] && has_cmd curl && has_cmd jq; then
		# Try to find Jira URL from .project.yaml
		local project_root
		project_root=$(find_project_root "${PWD}" 2>/dev/null || true)
		local jira_url=""
		if [[ -n "${project_root}" ]] && [[ -f "${project_root}/.project.yaml" ]]; then
			jira_url=$(yq -r '.platforms.jira.base_url // .jira.base_url // ""' "${project_root}/.project.yaml" 2>/dev/null || echo "")
		fi

		if [[ -n "${jira_url}" ]] && [[ "${jira_url}" != *"CHANGE_ME"* ]]; then
			total=$((total + 1))
			log_progress "Testing Jira API..."
			local jira_email
			jira_email=$(yq -r '.platforms.jira.email // .jira.email // ""' "${project_root}/.project.yaml" 2>/dev/null || echo "")
			local auth_header
			auth_header=$(echo -n "${jira_email}:$(cat "${atlassian_token}")" | base64)
			local api_result
			api_result=$(curl -s -o /dev/null -w "%{http_code}" \
				--connect-timeout 5 \
				-H "Authorization: Basic ${auth_header}" \
				"${jira_url}/rest/api/3/myself" 2>/dev/null || echo "000")
			if [[ "${api_result}" == "200" ]]; then
				log_ok "Jira API: authenticated"
				passed=$((passed + 1))
			elif [[ "${api_result}" == "401" ]]; then
				log_error "Jira API: unauthorized"
				failed=$((failed + 1))
			else
				log_warn "Jira API: HTTP ${api_result}"
				warned=$((warned + 1))
			fi
		else
			if [[ "${verbose}" == "true" ]]; then
				log_skip "Jira API (no URL configured)"
			fi
		fi
	fi

	echo "connect:total=${total}:passed=${passed}:warned=${warned}:failed=${failed}:skipped=${skipped}"
}

# ============================================================
# Main Doctor Function
# ============================================================
run_doctor() {
	local subcommand=""
	local verbose=false
	local quiet=false

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case "$1" in
			deps|auth|project|connect)
				subcommand="$1"
				;;
			-v|--verbose)
				verbose=true
				;;
			-q|--quiet)
				quiet=true
				;;
			-h|--help)
				doctor_usage
				return 0
				;;
			*)
				log_error "Unknown option: $1"
				doctor_usage
				return 2
				;;
		esac
		shift
	done

	if [[ "${quiet}" == "false" ]]; then
		echo ""
		echo "============================================"
		echo "  Agent-Context Doctor"
		echo "============================================"
		echo ""
	fi

	local total=0
	local passed=0
	local warned=0
	local failed=0
	local skipped=0
	local exit_code=0

	# Helper to parse results
	parse_result() {
		local result="$1"
		local t p w f s
		t=$(echo "${result}" | grep -oE 'total=[0-9]+' | cut -d= -f2)
		p=$(echo "${result}" | grep -oE 'passed=[0-9]+' | cut -d= -f2)
		w=$(echo "${result}" | grep -oE 'warned=[0-9]+' | cut -d= -f2)
		f=$(echo "${result}" | grep -oE 'failed=[0-9]+' | cut -d= -f2)
		s=$(echo "${result}" | grep -oE 'skipped=[0-9]+' | cut -d= -f2 || echo "0")
		total=$((total + t))
		passed=$((passed + p))
		warned=$((warned + w))
		failed=$((failed + f))
		skipped=$((skipped + s))
	}

	case "${subcommand}" in
		deps)
			result=$(doctor_deps "${verbose}" 2>&1 | tee /dev/stderr | tail -1)
			parse_result "${result}"
			;;
		auth)
			result=$(doctor_auth "${verbose}" 2>&1 | tee /dev/stderr | tail -1)
			parse_result "${result}"
			;;
		project)
			result=$(doctor_project "${verbose}" 2>&1 | tee /dev/stderr | tail -1)
			exit_code=$?
			parse_result "${result}"
			;;
		connect)
			result=$(doctor_connect "${verbose}" 2>&1 | tee /dev/stderr | tail -1)
			parse_result "${result}"
			;;
		"")
			# Run all offline checks
			echo ""
			result=$(doctor_deps "${verbose}" 2>&1 | tee /dev/stderr | tail -1)
			parse_result "${result}"

			echo ""
			result=$(doctor_auth "${verbose}" 2>&1 | tee /dev/stderr | tail -1)
			parse_result "${result}"

			echo ""
			result=$(doctor_project "${verbose}" 2>&1 | tee /dev/stderr | tail -1)
			local project_exit=$?
			parse_result "${result}"

			if [[ "${quiet}" == "false" ]]; then
				echo ""
				log_info "Connectivity (use 'agent-context doctor connect' to test)"
				log_skip "Skipped (offline mode)"
			fi
			;;
	esac

	# Summary
	if [[ "${quiet}" == "false" ]]; then
		echo ""
		echo "============================================"
	fi

	if [[ ${failed} -gt 0 ]]; then
		if [[ "${quiet}" == "false" ]]; then
			log_error "Some checks failed"
		fi
		exit_code=1
	elif [[ ${warned} -gt 0 ]]; then
		if [[ "${quiet}" == "false" ]]; then
			log_warn "Completed with warnings"
		fi
	else
		if [[ "${quiet}" == "false" ]]; then
			log_ok "All checks passed"
		fi
	fi

	echo "Summary: total=${total} passed=${passed} failed=${failed} warned=${warned} skipped=${skipped}"

	return ${exit_code}
}

# Allow direct execution for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	# When run directly, source required libraries
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
	# shellcheck source=../lib/logging.sh
	source "${SCRIPT_DIR}/lib/logging.sh"
	# shellcheck source=../lib/platform.sh
	source "${SCRIPT_DIR}/lib/platform.sh"
	run_doctor "$@"
fi
