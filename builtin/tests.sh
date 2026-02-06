#!/bin/bash
# Agent-Context Tests Command
# Run test suites (non-interactive, CI-friendly)
#
# Usage:
#   agent-context tests [subcommand] [options]
#
# Subcommands:
#   list      List available tests and tags
#   smoke     Run minimal fast checks (deps, auth, project)
#   e2e       Run end-to-end tests (may require Docker)
#
# This script is sourced by bin/agent-context.sh

# ============================================================
# Test Registry
# ============================================================
# Format: "tag:description:function"
declare -a TEST_REGISTRY=(
	"deps:Check required dependencies:test_deps"
	"auth:Check authentication and secrets:test_auth"
	"global:Check global installation:test_global"
	"project:Check project installation:test_project"
	"connect:Test external connectivity:test_connect"
	"auditRepo:Audit repo templates:test_audit_repo"
	"auditProject:Audit project structure:test_audit_project"
	"installNonInteractive:Test non-interactive install:test_install_non_interactive"
)

# Smoke test includes these tags
SMOKE_TAGS="deps,auth,global,project"

# ============================================================
# Usage
# ============================================================
tests_usage() {
	cat <<EOF
Agent-Context Tests

USAGE:
    agent-context tests [subcommand] [options]

SUBCOMMANDS:
    list            List available tests and tags
    smoke           Run minimal fast checks (deps, auth, global, project)
    e2e             Run end-to-end tests (requires Docker)

OPTIONS:
    --tags <tags>   Run tests matching tags (comma-separated)
    --skip <tags>   Skip tests matching tags (comma-separated)
    -v, --verbose   Show more details
    -q, --quiet     Show only summary
    -h, --help      Show this help

AVAILABLE TAGS:
    deps                    Required dependency checks
    auth                    Authentication and secrets
    global                  Global installation (~/.agent-context)
    project                 Project installation (.agent/)
    connect                 External connectivity (network required)
    auditRepo               Audit repository templates
    auditProject            Audit project structure
    installNonInteractive   Test non-interactive install

EXAMPLES:
    # Run smoke tests (default CI check)
    agent-context tests smoke

    # Run specific tags
    agent-context tests --tags deps,auth

    # Run smoke but skip project check
    agent-context tests smoke --skip project

    # List available tests
    agent-context tests list

EXIT CODES:
    0   All tests passed
    1   Some tests failed
    3   Environmental skip

EOF
}

# ============================================================
# Test Functions
# ============================================================

test_deps() {
	local total=0
	local passed=0
	local failed=0

	# Required
	local required=(git jq)
	for cmd in "${required[@]}"; do
		total=$((total + 1))
		if has_cmd "${cmd}"; then
			log_ok "[deps] ${cmd}"
			passed=$((passed + 1))
		else
			log_error "[deps] ${cmd} missing"
			failed=$((failed + 1))
		fi
	done

	# Recommended
	local recommended=(yq glab curl)
	for cmd in "${recommended[@]}"; do
		total=$((total + 1))
		if has_cmd "${cmd}"; then
			log_ok "[deps] ${cmd}"
			passed=$((passed + 1))
		else
			log_warn "[deps] ${cmd} missing (recommended)"
			# Count as pass but warn
			passed=$((passed + 1))
		fi
	done

	echo "${total}:${passed}:${failed}"
}

test_auth() {
	local total=0
	local passed=0
	local failed=0

	# ~/.secrets directory
	total=$((total + 1))
	if [[ -d "${HOME}/.secrets" ]]; then
		log_ok "[auth] ~/.secrets exists"
		passed=$((passed + 1))
	else
		log_error "[auth] ~/.secrets not found"
		failed=$((failed + 1))
	fi

	# Token files
	local tokens=("gitlab-api-token" "atlassian-api-token")
	for token in "${tokens[@]}"; do
		total=$((total + 1))
		if [[ -f "${HOME}/.secrets/${token}" ]]; then
			log_ok "[auth] ${token}"
			passed=$((passed + 1))
		else
			log_warn "[auth] ${token} not found"
			passed=$((passed + 1))  # Warning, not failure
		fi
	done

	# glab auth
	if has_cmd glab; then
		total=$((total + 1))
		if glab auth status 2>&1 | grep -q "Logged in"; then
			log_ok "[auth] glab authenticated"
			passed=$((passed + 1))
		else
			log_warn "[auth] glab not authenticated"
			passed=$((passed + 1))  # Warning, not failure
		fi
	fi

	echo "${total}:${passed}:${failed}"
}

test_global() {
	local total=0
	local passed=0
	local failed=0

	local ac_dir
	ac_dir=$(get_agent_context_dir)

	# Check directory exists
	total=$((total + 1))
	if [[ -d "${ac_dir}" ]]; then
		log_ok "[global] ${ac_dir} exists"
		passed=$((passed + 1))
	else
		log_error "[global] ${ac_dir} not found"
		failed=$((failed + 1))
		echo "${total}:${passed}:${failed}"
		return
	fi

	# Check bin/agent-context.sh
	total=$((total + 1))
	if [[ -x "${ac_dir}/bin/agent-context.sh" ]]; then
		log_ok "[global] bin/agent-context.sh executable"
		passed=$((passed + 1))
	else
		log_warn "[global] bin/agent-context.sh not executable"
		passed=$((passed + 1))  # May be during migration
	fi

	# Check lib/
	total=$((total + 1))
	if [[ -f "${ac_dir}/lib/logging.sh" ]]; then
		log_ok "[global] lib/logging.sh"
		passed=$((passed + 1))
	else
		log_error "[global] lib/logging.sh missing"
		failed=$((failed + 1))
	fi

	echo "${total}:${passed}:${failed}"
}

test_project() {
	local total=0
	local passed=0
	local failed=0

	local project_root
	project_root=$(find_project_root "${PWD}" 2>/dev/null || true)

	if [[ -z "${project_root}" ]]; then
		log_skip "[project] Not in a project directory"
		echo "0:0:0:skip"
		return
	fi

	# .cursorrules
	total=$((total + 1))
	if [[ -f "${project_root}/.cursorrules" ]]; then
		log_ok "[project] .cursorrules"
		passed=$((passed + 1))
	else
		log_warn "[project] .cursorrules missing"
		passed=$((passed + 1))
	fi

	# .project.yaml
	total=$((total + 1))
	if [[ -f "${project_root}/.project.yaml" ]]; then
		log_ok "[project] .project.yaml"
		passed=$((passed + 1))

		# Check CHANGE_ME
		total=$((total + 1))
		if ! grep -q "CHANGE_ME" "${project_root}/.project.yaml" 2>/dev/null; then
			log_ok "[project] .project.yaml configured"
			passed=$((passed + 1))
		else
			log_warn "[project] .project.yaml has CHANGE_ME"
			passed=$((passed + 1))
		fi
	else
		log_warn "[project] .project.yaml missing"
		passed=$((passed + 1))
	fi

	# .agent/
	total=$((total + 1))
	if [[ -d "${project_root}/.agent" ]]; then
		log_ok "[project] .agent/"
		passed=$((passed + 1))
	else
		log_error "[project] .agent/ missing"
		failed=$((failed + 1))
	fi

	echo "${total}:${passed}:${failed}"
}

test_connect() {
	local total=0
	local passed=0
	local failed=0

	# GitLab SSH
	total=$((total + 1))
	log_progress "[connect] Testing GitLab SSH..."
	if ssh -T -o ConnectTimeout=5 -o BatchMode=yes git@gitlab.fadutec.dev 2>&1 | grep -q "Welcome"; then
		log_ok "[connect] GitLab SSH"
		passed=$((passed + 1))
	else
		log_warn "[connect] GitLab SSH failed"
		passed=$((passed + 1))  # Network issues are warnings
	fi

	# GitLab API
	if [[ -f "${HOME}/.secrets/gitlab-api-token" ]] && has_cmd curl; then
		total=$((total + 1))
		local status
		status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 \
			-H "PRIVATE-TOKEN: $(cat "${HOME}/.secrets/gitlab-api-token")" \
			"https://gitlab.fadutec.dev/api/v4/user" 2>/dev/null || echo "000")
		if [[ "${status}" == "200" ]]; then
			log_ok "[connect] GitLab API"
			passed=$((passed + 1))
		else
			log_warn "[connect] GitLab API HTTP ${status}"
			passed=$((passed + 1))
		fi
	fi

	echo "${total}:${passed}:${failed}"
}

test_audit_repo() {
	local total=0
	local passed=0
	local failed=0

	local ac_dir
	ac_dir=$(get_agent_context_dir)

	if [[ ! -d "${ac_dir}" ]]; then
		log_skip "[auditRepo] Not in agent-context repo"
		echo "0:0:0:skip"
		return
	fi

	# Check templates
	total=$((total + 1))
	if [[ -d "${ac_dir}/templates" ]]; then
		log_ok "[auditRepo] templates/ exists"
		passed=$((passed + 1))
	else
		log_error "[auditRepo] templates/ missing"
		failed=$((failed + 1))
	fi

	# Check skills
	total=$((total + 1))
	if [[ -d "${ac_dir}/skills" ]]; then
		log_ok "[auditRepo] skills/ exists"
		passed=$((passed + 1))
	else
		log_error "[auditRepo] skills/ missing"
		failed=$((failed + 1))
	fi

	# Check workflows
	total=$((total + 1))
	if [[ -d "${ac_dir}/workflows" ]]; then
		log_ok "[auditRepo] workflows/ exists"
		passed=$((passed + 1))
	else
		log_error "[auditRepo] workflows/ missing"
		failed=$((failed + 1))
	fi

	echo "${total}:${passed}:${failed}"
}

test_audit_project() {
	local total=0
	local passed=0
	local failed=0

	local project_root
	project_root=$(find_project_root "${PWD}" 2>/dev/null || true)

	if [[ -z "${project_root}" ]]; then
		log_skip "[auditProject] Not in a project"
		echo "0:0:0:skip"
		return
	fi

	# Check .agent structure
	local agent_dirs=("skills" "workflows" "tools/pm" "docs")
	for dir in "${agent_dirs[@]}"; do
		total=$((total + 1))
		if [[ -d "${project_root}/.agent/${dir}" ]]; then
			log_ok "[auditProject] .agent/${dir}/"
			passed=$((passed + 1))
		else
			log_warn "[auditProject] .agent/${dir}/ missing"
			passed=$((passed + 1))
		fi
	done

	echo "${total}:${passed}:${failed}"
}

test_install_non_interactive() {
	local total=0
	local passed=0
	local failed=0

	# This test creates a temporary directory and tests non-interactive install
	local temp_dir
	temp_dir=$(mktemp -d)
	trap "rm -rf '${temp_dir}'" EXIT

	log_progress "[installNonInteractive] Creating temp project..."

	# Initialize git repo
	git -C "${temp_dir}" init -q 2>/dev/null || true

	# Run install
	local ac_dir
	ac_dir=$(get_agent_context_dir)
	local install_script="${ac_dir}/install.sh"

	if [[ ! -f "${install_script}" ]]; then
		log_error "[installNonInteractive] install.sh not found"
		echo "1:0:1"
		return
	fi

	total=$((total + 1))
	if bash "${install_script}" --non-interactive --force "${temp_dir}" >/dev/null 2>&1; then
		log_ok "[installNonInteractive] Install completed"
		passed=$((passed + 1))
	else
		log_error "[installNonInteractive] Install failed"
		failed=$((failed + 1))
		echo "${total}:${passed}:${failed}"
		return
	fi

	# Verify installation
	total=$((total + 1))
	if [[ -f "${temp_dir}/.cursorrules" ]]; then
		log_ok "[installNonInteractive] .cursorrules created"
		passed=$((passed + 1))
	else
		log_error "[installNonInteractive] .cursorrules missing"
		failed=$((failed + 1))
	fi

	total=$((total + 1))
	if [[ -f "${temp_dir}/.project.yaml" ]]; then
		log_ok "[installNonInteractive] .project.yaml created"
		passed=$((passed + 1))
	else
		log_error "[installNonInteractive] .project.yaml missing"
		failed=$((failed + 1))
	fi

	total=$((total + 1))
	if [[ -d "${temp_dir}/.agent" ]]; then
		log_ok "[installNonInteractive] .agent/ created"
		passed=$((passed + 1))
	else
		log_error "[installNonInteractive] .agent/ missing"
		failed=$((failed + 1))
	fi

	echo "${total}:${passed}:${failed}"
}

# ============================================================
# Test Runner
# ============================================================

list_tests() {
	echo ""
	echo "Available Tests:"
	echo "================"
	echo ""
	printf "%-25s %s\n" "TAG" "DESCRIPTION"
	printf "%-25s %s\n" "---" "-----------"
	for entry in "${TEST_REGISTRY[@]}"; do
		local tag="${entry%%:*}"
		local rest="${entry#*:}"
		local desc="${rest%%:*}"
		printf "%-25s %s\n" "${tag}" "${desc}"
	done
	echo ""
	echo "Smoke tests include: ${SMOKE_TAGS}"
	echo ""
}

run_tests_by_tags() {
	local tags="$1"
	local skip_tags="$2"
	local verbose="$3"

	local total=0
	local passed=0
	local failed=0
	local skipped=0

	# Convert tags to array
	IFS=',' read -ra tag_array <<< "${tags}"
	IFS=',' read -ra skip_array <<< "${skip_tags}"

	for entry in "${TEST_REGISTRY[@]}"; do
		local tag="${entry%%:*}"
		local rest="${entry#*:}"
		local desc="${rest%%:*}"
		local func="${rest#*:}"

		# Check if tag should run
		local should_run=false
		for t in "${tag_array[@]}"; do
			if [[ "${t}" == "${tag}" ]]; then
				should_run=true
				break
			fi
		done

		# Check if tag should skip
		for s in "${skip_array[@]}"; do
			if [[ "${s}" == "${tag}" ]]; then
				should_run=false
				break
			fi
		done

		if [[ "${should_run}" == "true" ]]; then
			if [[ "${verbose}" == "true" ]]; then
				echo ""
				log_info "Running: ${tag} - ${desc}"
			fi

			# Run test function
			local result
			result=$("${func}" 2>&1 | tail -1)

			# Parse result
			local t p f
			t=$(echo "${result}" | cut -d: -f1)
			p=$(echo "${result}" | cut -d: -f2)
			f=$(echo "${result}" | cut -d: -f3)

			# Check for skip
			if echo "${result}" | grep -q "skip"; then
				skipped=$((skipped + 1))
			else
				total=$((total + t))
				passed=$((passed + p))
				failed=$((failed + f))
			fi
		fi
	done

	echo "${total}:${passed}:${failed}:${skipped}"
}

# ============================================================
# Main Tests Function
# ============================================================
run_tests() {
	local subcommand=""
	local tags=""
	local skip_tags=""
	local verbose=false
	local quiet=false

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case "$1" in
			list|smoke|e2e)
				subcommand="$1"
				;;
			--tags)
				tags="$2"
				shift
				;;
			--skip)
				skip_tags="$2"
				shift
				;;
			-v|--verbose)
				verbose=true
				;;
			-q|--quiet)
				quiet=true
				;;
			-h|--help)
				tests_usage
				return 0
				;;
			*)
				log_error "Unknown option: $1"
				tests_usage
				return 2
				;;
		esac
		shift
	done

	case "${subcommand}" in
		list)
			list_tests
			return 0
			;;
		smoke)
			tags="${tags:-${SMOKE_TAGS}}"
			;;
		e2e)
			tags="${tags:-installNonInteractive}"
			;;
		"")
			if [[ -z "${tags}" ]]; then
				# Default to smoke
				tags="${SMOKE_TAGS}"
			fi
			;;
	esac

	if [[ "${quiet}" == "false" ]]; then
		echo ""
		echo "============================================"
		echo "  Agent-Context Tests"
		echo "============================================"
		echo ""
		log_info "Tags: ${tags}"
		if [[ -n "${skip_tags}" ]]; then
			log_info "Skip: ${skip_tags}"
		fi
		echo ""
	fi

	# Run tests
	local result
	result=$(run_tests_by_tags "${tags}" "${skip_tags}" "${verbose}")

	local total passed failed skipped
	total=$(echo "${result}" | cut -d: -f1)
	passed=$(echo "${result}" | cut -d: -f2)
	failed=$(echo "${result}" | cut -d: -f3)
	skipped=$(echo "${result}" | cut -d: -f4)

	# Summary
	if [[ "${quiet}" == "false" ]]; then
		echo ""
		echo "============================================"
	fi

	local warned=0
	local exit_code=0

	if [[ ${failed} -gt 0 ]]; then
		if [[ "${quiet}" == "false" ]]; then
			log_error "Tests failed"
		fi
		exit_code=1
	elif [[ ${skipped} -gt 0 ]] && [[ ${total} -eq 0 ]]; then
		if [[ "${quiet}" == "false" ]]; then
			log_skip "All tests skipped (environmental)"
		fi
		exit_code=3
	else
		if [[ "${quiet}" == "false" ]]; then
			log_ok "All tests passed"
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
	run_tests "$@"
fi
