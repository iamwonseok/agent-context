#!/bin/bash
# Step 010: Summary Report
# Generate and display installation summary
#
# Usage:
#   ./010-summary.sh run
#   ./010-summary.sh verify

source "$(dirname "$0")/lib.sh"

STEP_NUM="010"
STEP_NAME="Summary Report"

step_run() {
	log_step "${STEP_NUM}" "${STEP_NAME}"

	local any_project="${WORKDIR}/any-project"
	local report_file="${WORKDIR}/installation-report.md"

	log_info "Generating installation report..."

	# Generate report
	cat > "${report_file}" <<EOF
# Agent-Context Installation Report

**Run ID:** ${RUN_ID}
**Date:** $(date -Iseconds)
**Profile:** ${PROFILE}

## Installation Location

- Working Directory: \`${WORKDIR}\`
- Target Project: \`${any_project}\`

## Installed Files

### Core Files
EOF

	# List core files
	local core_files=(".cursorrules" ".project.yaml")
	for f in "${core_files[@]}"; do
		if [[ -f "${any_project}/${f}" ]]; then
			echo "- [x] \`${f}\`" >> "${report_file}"
		else
			echo "- [ ] \`${f}\` (missing)" >> "${report_file}"
		fi
	done

	echo "" >> "${report_file}"
	echo "### .agent Directory" >> "${report_file}"

	local agent_dirs=(".agent/skills" ".agent/workflows" ".agent/tools/pm" ".agent/templates")
	for d in "${agent_dirs[@]}"; do
		if [[ -d "${any_project}/${d}" ]]; then
			echo "- [x] \`${d}/\`" >> "${report_file}"
		else
			echo "- [ ] \`${d}/\` (missing)" >> "${report_file}"
		fi
	done

	# Config files (full profile)
	if [[ "${PROFILE}" == "full" ]]; then
		echo "" >> "${report_file}"
		echo "### Configuration Files (Full Profile)" >> "${report_file}"

		local config_files=(
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
			if [[ -f "${any_project}/${cfg}" ]]; then
				echo "- [x] \`${cfg}\`" >> "${report_file}"
			else
				echo "- [ ] \`${cfg}\`" >> "${report_file}"
			fi
		done
	fi

	# Step completion status
	echo "" >> "${report_file}"
	echo "## Step Completion" >> "${report_file}"
	echo "" >> "${report_file}"

	for step in 001 002 003 004 005 006 007 008 009 010; do
		if is_step_done "${step}"; then
			echo "- [x] Step ${step}" >> "${report_file}"
		else
			echo "- [ ] Step ${step}" >> "${report_file}"
		fi
	done

	# E2E status
	echo "" >> "${report_file}"
	echo "## E2E Status" >> "${report_file}"
	echo "" >> "${report_file}"

	if [[ "${SKIP_E2E}" == "true" ]]; then
		echo "E2E tests were skipped (\`--skip-e2e\`)" >> "${report_file}"
	else
		if [[ -d "${WORKDIR}/demo-output" ]]; then
			echo "E2E tests completed. Output: \`${WORKDIR}/demo-output\`" >> "${report_file}"
		else
			echo "E2E tests may not have been run." >> "${report_file}"
		fi
	fi

	# Display report
	echo ""
	cat "${report_file}"
	echo ""

	log_ok "Report saved to: ${report_file}"
	mark_step_done "${STEP_NUM}"
}

step_verify() {
	log_info "Verifying step ${STEP_NUM}..."

	local report_file="${WORKDIR}/installation-report.md"

	if [[ -f "${report_file}" ]]; then
		log_ok "Installation report exists"
		return 0
	else
		log_error "Installation report not found"
		return 1
	fi
}

run_step "$@"
