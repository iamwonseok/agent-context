#!/bin/bash
# Agent-Context Audit Command
# Audit repository/project health (Shared Builtin)
#
# Usage:
#   agent-context audit [subcommand] [options]
#
# This script is sourced by bin/agent-context.sh

# ============================================================
# Usage
# ============================================================
audit_usage() {
	cat <<EOF
Agent-Context Audit

USAGE:
    agent-context audit [subcommand] [options]

SUBCOMMANDS:
    skills      Audit skills directory
    workflows   Audit workflows directory
    project     Audit project structure
    perms       Check file permissions

    (no subcommand) Auto-detect mode based on location

OPTIONS:
    --repo          Force repo audit (developer mode)
    --project       Force project audit (user mode)
    --secrets       Include secrets validity checks
    -v, --verbose   Show detailed output
    -q, --quiet     Show only summary
    -h, --help      Show this help

DESCRIPTION:
    Audit mode is auto-detected based on current working directory:
    - Developer mode: When inside ~/.agent-context (audit templates/assets)
    - User mode: When inside a project (audit .agent/ and .project.yaml)

EXAMPLES:
    # Auto-detect and run appropriate audit
    agent-context audit

    # Audit skills only
    agent-context audit skills

    # Force project audit
    agent-context audit --project

EXIT CODES:
    0   All audits passed
    1   Some audits failed (validation/logic errors)

EOF
}

# ============================================================
# Audit Functions
# ============================================================

audit_skills() {
	local target_dir="$1"
	local verbose="$2"
	local total=0
	local passed=0
	local failed=0

	local skills_dir="${target_dir}/skills"

	if [[ ! -d "${skills_dir}" ]]; then
		log_skip "[skills] Directory not found"
		echo "0:0:0:skip"
		return
	fi

	log_info "Auditing skills..."

	# Check README exists
	total=$((total + 1))
	if [[ -f "${skills_dir}/README.md" ]]; then
		log_ok "[skills] README.md exists"
		passed=$((passed + 1))
	else
		log_warn "[skills] README.md missing"
		passed=$((passed + 1))  # Warning only
	fi

	# Check skill files
	local skill_count=0
	while IFS= read -r -d '' skill_file; do
		skill_count=$((skill_count + 1))
		local filename
		filename=$(basename "${skill_file}")
		total=$((total + 1))

		# Check file is not empty
		if [[ -s "${skill_file}" ]]; then
			log_ok "[skills] ${filename}"
			passed=$((passed + 1))
		else
			log_error "[skills] ${filename} is empty"
			failed=$((failed + 1))
		fi
	done < <(find "${skills_dir}" -name "*.md" -type f ! -name "README.md" -print0 2>/dev/null)

	if [[ ${skill_count} -eq 0 ]]; then
		log_warn "[skills] No skill files found"
	fi

	echo "${total}:${passed}:${failed}"
}

audit_workflows() {
	local target_dir="$1"
	local verbose="$2"
	local total=0
	local passed=0
	local failed=0

	local workflows_dir="${target_dir}/workflows"

	if [[ ! -d "${workflows_dir}" ]]; then
		log_skip "[workflows] Directory not found"
		echo "0:0:0:skip"
		return
	fi

	log_info "Auditing workflows..."

	# Check README exists
	total=$((total + 1))
	if [[ -f "${workflows_dir}/README.md" ]]; then
		log_ok "[workflows] README.md exists"
		passed=$((passed + 1))
	else
		log_warn "[workflows] README.md missing"
		passed=$((passed + 1))
	fi

	# Check workflow subdirectories
	local expected_dirs=("solo" "team" "project")
	for dir in "${expected_dirs[@]}"; do
		total=$((total + 1))
		if [[ -d "${workflows_dir}/${dir}" ]]; then
			log_ok "[workflows] ${dir}/ exists"
			passed=$((passed + 1))
		else
			log_warn "[workflows] ${dir}/ missing"
			passed=$((passed + 1))
		fi
	done

	echo "${total}:${passed}:${failed}"
}

audit_project_structure() {
	local project_root="$1"
	local verbose="$2"
	local total=0
	local passed=0
	local failed=0

	log_info "Auditing project structure..."

	# Check .cursorrules
	total=$((total + 1))
	if [[ -f "${project_root}/.cursorrules" ]]; then
		log_ok "[project] .cursorrules exists"
		passed=$((passed + 1))
	else
		log_warn "[project] .cursorrules missing"
		passed=$((passed + 1))
	fi

	# Check .project.yaml
	total=$((total + 1))
	if [[ -f "${project_root}/.project.yaml" ]]; then
		log_ok "[project] .project.yaml exists"
		passed=$((passed + 1))

		# Validate YAML syntax
		if has_cmd yq; then
			total=$((total + 1))
			if yq eval '.' "${project_root}/.project.yaml" >/dev/null 2>&1; then
				log_ok "[project] .project.yaml valid YAML"
				passed=$((passed + 1))
			else
				log_error "[project] .project.yaml invalid YAML"
				failed=$((failed + 1))
			fi
		fi

		# Check for CHANGE_ME
		total=$((total + 1))
		local change_me
		change_me=$(grep -c "CHANGE_ME" "${project_root}/.project.yaml" 2>/dev/null || echo "0")
		if [[ ${change_me} -eq 0 ]]; then
			log_ok "[project] No CHANGE_ME placeholders"
			passed=$((passed + 1))
		else
			log_warn "[project] ${change_me} CHANGE_ME placeholder(s)"
			passed=$((passed + 1))
		fi
	else
		log_warn "[project] .project.yaml missing"
		passed=$((passed + 1))
	fi

	# Check .agent/ structure
	total=$((total + 1))
	if [[ -d "${project_root}/.agent" ]]; then
		log_ok "[project] .agent/ exists"
		passed=$((passed + 1))

		local agent_dirs=("skills" "workflows" "tools/pm")
		for dir in "${agent_dirs[@]}"; do
			total=$((total + 1))
			if [[ -d "${project_root}/.agent/${dir}" ]]; then
				log_ok "[project] .agent/${dir}/"
				passed=$((passed + 1))
			else
				log_warn "[project] .agent/${dir}/ missing"
				passed=$((passed + 1))
			fi
		done
	else
		log_error "[project] .agent/ missing"
		failed=$((failed + 1))
	fi

	echo "${total}:${passed}:${failed}"
}

audit_perms() {
	local target_dir="$1"
	local verbose="$2"
	local total=0
	local passed=0
	local failed=0

	log_info "Auditing permissions..."

	# Check ~/.secrets permissions
	total=$((total + 1))
	if [[ -d "${HOME}/.secrets" ]]; then
		local mode
		mode=$(stat -f "%OLp" "${HOME}/.secrets" 2>/dev/null || stat -c "%a" "${HOME}/.secrets" 2>/dev/null)
		if [[ "${mode}" == "700" ]]; then
			log_ok "[perms] ~/.secrets (700)"
			passed=$((passed + 1))
		else
			log_warn "[perms] ~/.secrets (${mode}, should be 700)"
			passed=$((passed + 1))
		fi
	else
		log_skip "[perms] ~/.secrets not found"
	fi

	# Check token file permissions
	local tokens=("gitlab-api-token" "atlassian-api-token" "github-api-token")
	for token in "${tokens[@]}"; do
		local token_file="${HOME}/.secrets/${token}"
		if [[ -f "${token_file}" ]]; then
			total=$((total + 1))
			local mode
			mode=$(stat -f "%OLp" "${token_file}" 2>/dev/null || stat -c "%a" "${token_file}" 2>/dev/null)
			if [[ "${mode}" == "600" ]]; then
				log_ok "[perms] ${token} (600)"
				passed=$((passed + 1))
			else
				log_warn "[perms] ${token} (${mode}, should be 600)"
				passed=$((passed + 1))
			fi
		fi
	done

	# Check pm executable
	local pm_bin="${target_dir}/.agent/tools/pm/bin/pm"
	if [[ -f "${pm_bin}" ]]; then
		total=$((total + 1))
		if [[ -x "${pm_bin}" ]]; then
			log_ok "[perms] pm executable"
			passed=$((passed + 1))
		else
			log_error "[perms] pm not executable"
			failed=$((failed + 1))
		fi
	fi

	echo "${total}:${passed}:${failed}"
}

# ============================================================
# Main Audit Function
# ============================================================
run_audit() {
	local subcommand=""
	local force_repo=false
	local force_project=false
	local check_secrets=false
	local verbose=false
	local quiet=false

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case "$1" in
			skills|workflows|project|perms)
				subcommand="$1"
				;;
			--repo)
				force_repo=true
				;;
			--project)
				force_project=true
				;;
			--secrets)
				check_secrets=true
				;;
			-v|--verbose)
				verbose=true
				;;
			-q|--quiet)
				quiet=true
				;;
			-h|--help)
				audit_usage
				return 0
				;;
			*)
				log_error "Unknown option: $1"
				audit_usage
				return 2
				;;
		esac
		shift
	done

	# Detect mode
	local mode="project"
	local target_dir=""
	local ac_dir
	ac_dir=$(get_agent_context_dir)

	if [[ "${force_repo}" == "true" ]]; then
		mode="repo"
		target_dir="${ac_dir}"
	elif [[ "${force_project}" == "true" ]]; then
		mode="project"
		target_dir=$(find_project_root "${PWD}" 2>/dev/null || true)
	else
		# Auto-detect
		if [[ "${PWD}" == "${ac_dir}"* ]]; then
			mode="repo"
			target_dir="${ac_dir}"
		else
			mode="project"
			target_dir=$(find_project_root "${PWD}" 2>/dev/null || true)
		fi
	fi

	if [[ -z "${target_dir}" ]]; then
		log_error "No target found (not in repo or project)"
		return 1
	fi

	if [[ "${quiet}" == "false" ]]; then
		log_header "Agent-Context Audit"
		log_info "Mode: ${mode}"
		log_info "Target: ${target_dir}"
		echo ""
	fi

	local total=0
	local passed=0
	local failed=0
	local skipped=0

	parse_result() {
		local result="$1"
		local t p f
		t=$(echo "${result}" | cut -d: -f1)
		p=$(echo "${result}" | cut -d: -f2)
		f=$(echo "${result}" | cut -d: -f3)
		if echo "${result}" | grep -q "skip"; then
			skipped=$((skipped + 1))
		else
			total=$((total + t))
			passed=$((passed + p))
			failed=$((failed + f))
		fi
	}

	case "${subcommand}" in
		skills)
			result=$(audit_skills "${target_dir}" "${verbose}" 2>&1 | tee /dev/stderr | tail -1)
			parse_result "${result}"
			;;
		workflows)
			result=$(audit_workflows "${target_dir}" "${verbose}" 2>&1 | tee /dev/stderr | tail -1)
			parse_result "${result}"
			;;
		project)
			result=$(audit_project_structure "${target_dir}" "${verbose}" 2>&1 | tee /dev/stderr | tail -1)
			parse_result "${result}"
			;;
		perms)
			result=$(audit_perms "${target_dir}" "${verbose}" 2>&1 | tee /dev/stderr | tail -1)
			parse_result "${result}"
			;;
		"")
			# Run all relevant audits
			if [[ "${mode}" == "repo" ]]; then
				result=$(audit_skills "${target_dir}" "${verbose}" 2>&1 | tee /dev/stderr | tail -1)
				parse_result "${result}"
				echo ""
				result=$(audit_workflows "${target_dir}" "${verbose}" 2>&1 | tee /dev/stderr | tail -1)
				parse_result "${result}"
			else
				result=$(audit_project_structure "${target_dir}" "${verbose}" 2>&1 | tee /dev/stderr | tail -1)
				parse_result "${result}"
				echo ""
				result=$(audit_perms "${target_dir}" "${verbose}" 2>&1 | tee /dev/stderr | tail -1)
				parse_result "${result}"
			fi
			;;
	esac

	# Summary
	if [[ "${quiet}" == "false" ]]; then
		echo ""
		echo "============================================"
		if [[ ${failed} -gt 0 ]]; then
			log_error "Audit failed"
		else
			log_ok "Audit passed"
		fi
	fi

	local warned=0
	echo "Summary: total=${total} passed=${passed} failed=${failed} warned=${warned} skipped=${skipped}"

	if [[ ${failed} -gt 0 ]]; then
		return 1
	fi
	return 0
}

# Allow direct execution for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
	source "${SCRIPT_DIR}/lib/logging.sh"
	source "${SCRIPT_DIR}/lib/platform.sh"
	run_audit "$@"
fi
