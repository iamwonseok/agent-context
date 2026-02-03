#!/bin/bash
# Step 002: Prepare Working Directory
# Create working directory and clone agent-context if needed
#
# Usage:
#   ./002-workdir.sh run
#   ./002-workdir.sh verify

source "$(dirname "$0")/lib.sh"

STEP_NUM="002"
STEP_NAME="Prepare Working Directory"

step_run() {
	log_step "${STEP_NUM}" "${STEP_NAME}"

	# Create working directory
	log_info "Creating working directory: ${WORKDIR}"
	mkdir -p "${WORKDIR}"

	# Create any-project directory
	local any_project="${WORKDIR}/any-project"
	log_info "Creating target project directory: ${any_project}"
	mkdir -p "${any_project}"

	# Initialize as git repo
	if [[ ! -d "${any_project}/.git" ]]; then
		log_info "Initializing git repository..."
		(cd "${any_project}" && git init --quiet)
		log_ok "Git repository initialized"
	else
		log_ok "Git repository already exists"
	fi

	# Create a sample file to make it a "real" project
	if [[ ! -f "${any_project}/README.md" ]]; then
		cat > "${any_project}/README.md" <<'EOF'
# Sample Project

This is a sample project for agent-context demo installation.
EOF
		log_ok "Created sample README.md"
	fi

	# Save paths to state
	echo "ANY_PROJECT=${any_project}" >> "${STATE_FILE}"
	echo "AGENT_CONTEXT_ROOT=${AGENT_CONTEXT_ROOT}" >> "${STATE_FILE}"

	log_ok "Working directory prepared: ${WORKDIR}"
	mark_step_done "${STEP_NUM}"
}

step_verify() {
	log_info "Verifying step ${STEP_NUM}..."

	local failed=0
	local any_project="${WORKDIR}/any-project"

	# Check working directory
	if ! verify_dir_exists "${WORKDIR}" "Working directory"; then
		((failed++)) || true
	fi

	# Check any-project directory
	if ! verify_dir_exists "${any_project}" "Target project directory"; then
		((failed++)) || true
	fi

	# Check git repo
	if [[ -d "${any_project}/.git" ]]; then
		log_ok "Git repository exists"
	else
		log_error "Git repository not initialized"
		((failed++)) || true
	fi

	if [[ ${failed} -gt 0 ]]; then
		log_error "Verification failed: ${failed} issue(s)"
		return 1
	fi

	log_ok "Step ${STEP_NUM} verified"
	return 0
}

run_step "$@"
