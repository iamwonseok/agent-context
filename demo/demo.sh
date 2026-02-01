#!/bin/bash
# Agent-in-the-Loop (AITL) Grand Scenario Demo
# Demonstrates the full project lifecycle with real infrastructure integration
#
# Prerequisites:
#   - glab CLI (GitLab)
#   - pm CLI (Jira/Confluence)
#   - jq, yq
#   - Valid credentials in ~/.secrets/ or .secrets/

set -e
set -o pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
LIB_DIR="${SCRIPT_DIR}/lib"

# Source libraries
if [[ -f "${LIB_DIR}/jira_sync.sh" ]]; then
	source "${LIB_DIR}/jira_sync.sh"
fi

if [[ -f "${LIB_DIR}/gitlab_flow.sh" ]]; then
	source "${LIB_DIR}/gitlab_flow.sh"
fi

# Configuration
# RUN_ID: unique identifier for this demo run (used to distinguish test runs)
DEMO_RUN_ID="${DEMO_RUN_ID:-$(date +%Y%m%d-%H%M%S)}"
DEMO_REPO_NAME="${DEMO_REPO_NAME:-demo-${DEMO_RUN_ID}}"
DEMO_EPIC_SUMMARY="${DEMO_EPIC_SUMMARY:-[${DEMO_RUN_ID}] AITL Demo Epic}"
DEMO_JIRA_PROJECT="${DEMO_JIRA_PROJECT:-SVI}"
DEMO_JIRA_BASE_URL="${DEMO_JIRA_BASE_URL:-https://fadutec.atlassian.net}"
DEMO_CONFLUENCE_BASE_URL="${DEMO_CONFLUENCE_BASE_URL:-https://fadutec.atlassian.net/wiki}"
DEMO_GITLAB_BASE_URL="${DEMO_GITLAB_BASE_URL:-https://gitlab.fadutec.dev}"
DEMO_JIRA_EMAIL="${DEMO_JIRA_EMAIL:-${JIRA_EMAIL:-}}"
DEMO_BOARD_TYPE="${DEMO_BOARD_TYPE:-kanban}"
DEMO_CONFLUENCE_SPACE="${DEMO_CONFLUENCE_SPACE:-}"
DEMO_GITLAB_GROUP="${DEMO_GITLAB_GROUP:-soc-ip/agentic-ai}"

# State tracking
CREATED_GITLAB_REPO=""
CREATED_JIRA_ISSUES=()
CREATED_CONFLUENCE_PAGES=()
DEMO_WORKSPACE=""

# Colors for output (disabled if not a terminal)
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

# Logging functions (all output to stderr to avoid polluting stdout return values)
log_info() {
	echo -e "${BLUE}[>>]${NC} $1" >&2
}

log_ok() {
	echo -e "${GREEN}[OK]${NC} $1" >&2
}

log_warn() {
	echo -e "${YELLOW}[!!]${NC} $1" >&2
}

log_error() {
	echo -e "${RED}[NG]${NC} $1" >&2
}

log_phase() {
	echo ""
	echo "============================================================"
	echo -e "${BLUE}$1${NC}"
	echo "============================================================"
	echo ""
}

# Run pm command in demo workspace (so it loads workspace .project.yaml)
pm_ws() {
	if [[ -z "${DEMO_WORKSPACE}" ]]; then
		log_error "DEMO_WORKSPACE is not set"
		return 1
	fi
	(
		cd "${DEMO_WORKSPACE}" || exit 1
		"${PROJECT_ROOT}/tools/pm/bin/pm" "$@"
	)
}

# Best-effort: derive Jira email if not provided
ensure_demo_jira_email() {
	if [[ -n "${DEMO_JIRA_EMAIL}" ]]; then
		return 0
	fi

	if command -v git &>/dev/null; then
		local git_email
		git_email=$(git -C "${PROJECT_ROOT}" config user.email 2>/dev/null || true)
		if [[ -n "${git_email}" ]]; then
			DEMO_JIRA_EMAIL="${git_email}"
			return 0
		fi
	fi

	return 0
}

url_encode() {
	local raw="$1"
	python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "${raw}"
}

is_jira_cloud_url() {
	local base_url="$1"
	[[ "${base_url}" == *".atlassian.net"* ]]
}

normalize_demo_jira_base_url() {
	local input="${1:-}"
	if [[ -z "${input}" ]]; then
		echo ""
		return 0
	fi

	if [[ "${input}" == *"atlassian.jira.fadutec.dev"* ]]; then
		echo "https://fadutec.atlassian.net"
		return 0
	fi

	if [[ "${input}" == *"fadutec.atlassian.net"* ]]; then
		echo "https://fadutec.atlassian.net"
		return 0
	fi

	echo "${input}"
	return 0
}

jira_ws_load_auth() {
	if [[ -z "${DEMO_WORKSPACE}" ]]; then
		log_error "DEMO_WORKSPACE is not set"
		return 1
	fi

	if [[ ! -f "${DEMO_WORKSPACE}/.project.yaml" ]]; then
		log_error "Workspace .project.yaml not found: ${DEMO_WORKSPACE}/.project.yaml"
		return 1
	fi

	JIRA_BASE_URL=$(yq -r '.platforms.jira.base_url // .jira.base_url' "${DEMO_WORKSPACE}/.project.yaml")
	JIRA_BASE_URL=$(normalize_demo_jira_base_url "${JIRA_BASE_URL}")
	JIRA_PROJECT_KEY=$(yq -r '.platforms.jira.project_key // .jira.project_key' "${DEMO_WORKSPACE}/.project.yaml")
	JIRA_EMAIL=$(yq -r '.platforms.jira.email // .jira.email' "${DEMO_WORKSPACE}/.project.yaml")

	if [[ -z "${JIRA_TOKEN:-}" ]] && [[ -f "${HOME}/.secrets/atlassian-api-token" ]]; then
		JIRA_TOKEN=$(cat "${HOME}/.secrets/atlassian-api-token")
	fi

	if [[ -z "${JIRA_BASE_URL}" ]] || [[ "${JIRA_BASE_URL}" == "null" ]]; then
		log_error "Jira base_url missing in workspace .project.yaml"
		return 1
	fi
	if [[ -z "${JIRA_PROJECT_KEY}" ]] || [[ "${JIRA_PROJECT_KEY}" == "null" ]]; then
		log_error "Jira project_key missing in workspace .project.yaml"
		return 1
	fi
	if [[ -z "${JIRA_EMAIL}" ]] || [[ "${JIRA_EMAIL}" == "null" ]]; then
		log_error "Jira email missing in workspace .project.yaml"
		return 1
	fi
	if [[ -z "${JIRA_TOKEN:-}" ]]; then
		log_error "Jira token missing (expected at ~/.secrets/atlassian-api-token)"
		return 1
	fi

	export JIRA_BASE_URL JIRA_PROJECT_KEY JIRA_EMAIL JIRA_TOKEN
	return 0
}

jira_ws_api() {
	local method="$1"
	local path="$2"
	local body="${3:-}"

	if ! jira_ws_load_auth; then
		return 1
	fi

	local url="${JIRA_BASE_URL}${path}"

	if is_jira_cloud_url "${JIRA_BASE_URL}"; then
		if [[ -n "${body}" ]]; then
			curl -s -X "${method}" \
				-u "${JIRA_EMAIL}:${JIRA_TOKEN}" \
				-H "Accept: application/json" \
				-H "Content-Type: application/json" \
				"${url}" \
				-d "${body}"
		else
			curl -s -X "${method}" \
				-u "${JIRA_EMAIL}:${JIRA_TOKEN}" \
				-H "Accept: application/json" \
				"${url}"
		fi
	else
		if [[ -n "${body}" ]]; then
			curl -s -X "${method}" \
				-H "Authorization: Bearer ${JIRA_TOKEN}" \
				-H "Accept: application/json" \
				-H "Content-Type: application/json" \
				"${url}" \
				-d "${body}"
		else
			curl -s -X "${method}" \
				-H "Authorization: Bearer ${JIRA_TOKEN}" \
				-H "Accept: application/json" \
				"${url}"
		fi
	fi
}

jira_create_board_best_effort() {
	log_info "Ensuring Jira board exists for project ${DEMO_JIRA_PROJECT} (${DEMO_BOARD_TYPE})..."

	if [[ "${DRY_RUN}" == "true" ]]; then
		log_info "[DRY-RUN] Would create Jira filter + ${DEMO_BOARD_TYPE} board for ${DEMO_JIRA_PROJECT}"
		return 0
	fi

	if ! jira_ws_load_auth; then
		log_warn "Skipping board creation (Jira not configured in workspace)"
		return 0
	fi

	local board_name="[${DEMO_RUN_ID}] AITL Demo Board"
	local encoded_name
	encoded_name=$(url_encode "${board_name}")

	local list_resp
	list_resp=$(jira_ws_api GET "/rest/agile/1.0/board?projectKeyOrId=${JIRA_PROJECT_KEY}&name=${encoded_name}" || echo "")

	local existing_id
	existing_id=$(echo "${list_resp}" | jq -r '.values[0].id // empty' 2>/dev/null || echo "")

	if [[ -n "${existing_id}" ]]; then
		log_ok "Jira board already exists: ${board_name} (id: ${existing_id})"
		DEMO_JIRA_BOARD_ID="${existing_id}"
		return 0
	fi

	# Create filter first (required by Jira Agile board create API)
	local filter_name="[${DEMO_RUN_ID}] AITL Demo Board Filter"
	local filter_jql="project = ${JIRA_PROJECT_KEY} ORDER BY Rank ASC"
	local filter_payload
	filter_payload=$(jq -n \
		--arg name "${filter_name}" \
		--arg jql "${filter_jql}" \
		'{name: $name, jql: $jql, favourite: false}')

	local filter_resp
	filter_resp=$(jira_ws_api POST "/rest/api/3/filter" "${filter_payload}" || echo "")

	local filter_id
	filter_id=$(echo "${filter_resp}" | jq -r '.id // empty' 2>/dev/null || echo "")

	if [[ -z "${filter_id}" ]]; then
		log_warn "Failed to create Jira filter (skipping board creation)"
		echo "${filter_resp}" >&2
		return 0
	fi

	local board_payload
	board_payload=$(jq -n \
		--arg name "${board_name}" \
		--arg type "${DEMO_BOARD_TYPE}" \
		--argjson filterId "${filter_id}" \
		--arg project "${JIRA_PROJECT_KEY}" \
		'{name: $name, type: $type, filterId: $filterId, location: {type: "project", projectKeyOrId: $project}}')

	local board_resp
	board_resp=$(jira_ws_api POST "/rest/agile/1.0/board" "${board_payload}" || echo "")

	local board_id
	board_id=$(echo "${board_resp}" | jq -r '.id // empty' 2>/dev/null || echo "")

	if [[ -z "${board_id}" ]]; then
		log_warn "Failed to create Jira board"
		echo "${board_resp}" >&2
		return 0
	fi

	DEMO_JIRA_BOARD_ID="${board_id}"
	log_ok "Created Jira board: ${board_name} (id: ${board_id})"
	return 0
}

# Show usage
usage() {
	cat <<EOF
AITL Demo - Agent-in-the-Loop Grand Scenario

USAGE:
    $(basename "$0") [command] [options]

COMMANDS:
    run         Run the full demo scenario (default)
    check       Check prerequisites only
    cleanup     Clean up demo resources
    help        Show this help

OPTIONS:
    --run-id ID         Unique run identifier (default: YYYYMMDD-HHMMSS)
                        Used to distinguish test runs in Jira issue names
    --repo NAME         GitLab repository name (default: aitl-demo-RUN_ID)
    --jira-project KEY  Jira project key (required for run)
    --jira-email EMAIL  Jira user email (defaults to git config user.email if set)
    --jira-base-url URL Jira base URL (default: https://fadutec.atlassian.net)
    --board-type TYPE   Jira board type: kanban|scrum (default: kanban)
    --confluence-space  Confluence space key (optional)
    --confluence-base-url URL Confluence base URL (default: https://fadutec.atlassian.net/wiki)
    --gitlab-base-url URL  GitLab base URL (default: https://gitlab.fadutec.dev)
    --gitlab-group      GitLab group/namespace (default: soc-ip/agentic-ai)
    --dry-run           Show what would be done without executing
    --skip-cleanup      Don't prompt for cleanup at the end
    --hitl              Enable Human-in-the-Loop pause points
    --skip-gitlab        Skip all GitLab operations

ENVIRONMENT:
    JIRA_BASE_URL       Jira base URL
    JIRA_EMAIL          Jira user email
    JIRA_TOKEN          Jira API token
    CONFLUENCE_TOKEN    Confluence API token (defaults to JIRA_TOKEN)
    GITLAB_TOKEN        GitLab API token

EXAMPLES:
    # Check prerequisites
    $(basename "$0") check

    # Run demo with Jira project
    $(basename "$0") run --jira-project DEMO

    # Run with all options
    $(basename "$0") run --jira-project SVI --gitlab-group soc-ip/agentic-ai --repo demo-unique-name --skip-cleanup

    # Clean up resources
    $(basename "$0") cleanup
EOF
}

# Check if a command exists
check_command() {
	local cmd="$1"
	local install_hint="$2"

	if command -v "${cmd}" &>/dev/null; then
		log_ok "${cmd} found"
		return 0
	else
		log_error "${cmd} not found"
		if [[ -n "${install_hint}" ]]; then
			echo "    Install: ${install_hint}"
		fi
		return 1
	fi
}

# Check all prerequisites
check_dependencies() {
	log_phase "Step 1: Checking Prerequisites"

	local has_error=0

	# Required commands
	check_command "glab" "https://gitlab.com/gitlab-org/cli" || has_error=1
	check_command "jq" "brew install jq" || has_error=1
	check_command "yq" "brew install yq" || has_error=1
	check_command "curl" "should be pre-installed" || has_error=1

	# pm CLI (local tool)
	if [[ -x "${PROJECT_ROOT}/tools/pm/bin/pm" ]]; then
		log_ok "pm CLI found"
	else
		log_error "pm CLI not found at tools/pm/bin/pm"
		has_error=1
	fi

	# Check credentials
	echo ""
	log_info "Checking credentials..."

	# Jira token
	if [[ -n "${JIRA_TOKEN}" ]] || [[ -f "${HOME}/.secrets/atlassian-api-token" ]]; then
		log_ok "Jira credentials found"
	else
		log_warn "Jira credentials not found (set JIRA_TOKEN or create ~/.secrets/atlassian-api-token)"
	fi

	# Jira email (required for API calls)
	if [[ -n "${JIRA_EMAIL}" ]] || [[ -n "${DEMO_JIRA_EMAIL}" ]]; then
		log_ok "Jira email configured"
	else
		log_warn "JIRA_EMAIL not set (required unless configured in .project.yaml)"
		log_info "  Demo will try: git config user.email"
		log_info "  Set with: export JIRA_EMAIL=\"your-email@example.com\""
		log_info "  Or use:   --jira-email your-email@example.com"
	fi

	# GitLab
	if glab auth status &>/dev/null; then
		log_ok "GitLab authenticated"
	else
		log_warn "GitLab not authenticated (run: glab auth login)"
	fi

	if [[ ${has_error} -eq 1 ]]; then
		log_error "Prerequisites check failed"
		return 1
	fi

	log_ok "All prerequisites met"
	return 0
}

# Validate Jira configuration
validate_jira_config() {
	if [[ "${DRY_RUN}" == "true" ]]; then
		log_warn "Dry-run mode: skipping Jira connection validation"
		return 0
	fi

	log_info "Validating Jira connection..."

	export JIRA_PROJECT_KEY="${DEMO_JIRA_PROJECT}"

	if ! pm_ws jira me &>/dev/null; then
		log_error "Cannot connect to Jira. Check credentials."
		log_info "  Hint: Set JIRA_EMAIL env var or use --jira-email option"
		log_info "  Hint: Ensure ~/.secrets/atlassian-api-token exists"
		return 1
	fi

	log_ok "Jira connection verified (project: ${DEMO_JIRA_PROJECT})"
	return 0
}

# Create GitLab sandbox repository and clone it
setup_gitlab_repo() {
	log_info "Creating GitLab sandbox repository: ${DEMO_REPO_NAME}"

	if [[ "${DRY_RUN}" == "true" ]]; then
		log_info "[DRY-RUN] Would create: ${DEMO_GITLAB_GROUP:-user}/${DEMO_REPO_NAME}"
		log_info "[DRY-RUN] Would clone to: /tmp/${DEMO_REPO_NAME}"
		CREATED_GITLAB_REPO="${DEMO_REPO_NAME}"
		DEMO_WORKSPACE="/tmp/${DEMO_REPO_NAME}"
		return 0
	fi

	local result repo_path clone_url

	# Use GitLab API directly when group is specified (glab repo create --group has issues)
	if [[ -n "${DEMO_GITLAB_GROUP}" ]]; then
		local group_ref="${DEMO_GITLAB_GROUP//\//%2F}"
		local namespace_id
		namespace_id=$(glab api "groups/${group_ref}" 2>/dev/null | jq -r '.id // empty')

		if [[ -z "${namespace_id}" ]]; then
			log_error "Could not find GitLab group: ${DEMO_GITLAB_GROUP}"
			return 1
		fi

		log_info "Creating GitLab project via API (namespace_id=${namespace_id})..."

		result=$(glab api projects -X POST \
			-f "name=${DEMO_REPO_NAME}" \
			-f "namespace_id=${namespace_id}" \
			-f "visibility=private" \
			-f "initialize_with_readme=true" \
			2>&1)

		if echo "${result}" | jq -e '.id' >/dev/null 2>&1; then
			repo_path="${DEMO_GITLAB_GROUP}/${DEMO_REPO_NAME}"
			clone_url=$(echo "${result}" | jq -r '.ssh_url_to_repo // .http_url_to_repo')
			CREATED_GITLAB_REPO="${DEMO_REPO_NAME}"
			log_ok "Repository created: ${repo_path}"
		else
			log_error "Failed to create repository via API"
			echo "${result}" >&2
			return 1
		fi
	else
		# Fallback to glab repo create for personal repos
		if result=$(glab repo create --private --name "${DEMO_REPO_NAME}" 2>&1); then
			CREATED_GITLAB_REPO="${DEMO_REPO_NAME}"
			repo_path="${DEMO_REPO_NAME}"
			clone_url=$(echo "${result}" | grep -oE 'git@[^[:space:]]+\.git|https://[^[:space:]]+\.git' | head -1)
			log_ok "Repository created: ${DEMO_REPO_NAME}"
		else
			log_error "Failed to create repository"
			echo "${result}" >&2
			return 1
		fi
	fi

	# Get clone URL if not already set
	if [[ -z "${clone_url}" ]]; then
		clone_url=$(glab repo view "${repo_path}" --output json 2>/dev/null | jq -r '.ssh_url_to_repo // .http_url_to_repo' || echo "")
	fi

	DEMO_WORKSPACE="/tmp/${DEMO_REPO_NAME}"
	rm -rf "${DEMO_WORKSPACE}" 2>/dev/null || true

	if [[ -n "${clone_url}" ]]; then
		log_info "Cloning repository..."

		if git clone "${clone_url}" "${DEMO_WORKSPACE}" 2>&1; then
			log_ok "Cloned to: ${DEMO_WORKSPACE}"
		else
			log_warn "Could not clone, initializing with remote instead"
			mkdir -p "${DEMO_WORKSPACE}"
			cd "${DEMO_WORKSPACE}" || exit 1
			git init -q
			git remote add origin "${clone_url}" 2>/dev/null || git remote set-url origin "${clone_url}"
			echo "# ${DEMO_REPO_NAME}" > README.md
			git add README.md
			git commit -q -m "Initial commit"
			git push -u origin HEAD:main 2>/dev/null || true
		fi
	else
		log_warn "Could not get clone URL, creating local directory"
		mkdir -p "${DEMO_WORKSPACE}"
		cd "${DEMO_WORKSPACE}" || exit 1
		git init -q
	fi
}

# Initialize project configuration using install.sh
setup_project_config() {
	log_info "Installing agent-context to demo workspace..."

	local install_script="${PROJECT_ROOT}/install.sh"

	if [[ "${DRY_RUN}" == "true" ]]; then
		log_info "[DRY-RUN] Would run: install.sh ${DEMO_WORKSPACE:-/tmp/demo}"
		log_info "[DRY-RUN] Would configure .project.yaml"
		return 0
	fi

	# Determine workspace directory
	if [[ -z "${DEMO_WORKSPACE}" ]]; then
		DEMO_WORKSPACE="/tmp/demo-${DEMO_RUN_ID}"
		rm -rf "${DEMO_WORKSPACE}" 2>/dev/null || true
		mkdir -p "${DEMO_WORKSPACE}"
		log_info "Created demo workspace: ${DEMO_WORKSPACE}"
		cd "${DEMO_WORKSPACE}" || exit 1
		git init -q
	fi

	cd "${DEMO_WORKSPACE}" || exit 1

	ensure_demo_jira_email

	# Run install.sh
	if [[ -x "${install_script}" ]]; then
		log_info "Running install.sh..."
		"${install_script}" --force "${DEMO_WORKSPACE}"
	else
		log_warn "install.sh not found or not executable, copying files manually"
		cp -r "${PROJECT_ROOT}/workflows" .
		cp -r "${PROJECT_ROOT}/skills" .
		mkdir -p tools
		cp -r "${PROJECT_ROOT}/tools/pm" tools/
		cp "${PROJECT_ROOT}/.cursorrules" .
		"${PROJECT_ROOT}/tools/pm/bin/pm" config init --force 2>/dev/null || true
	fi

	# Update .project.yaml with demo settings
	log_info "Configuring project for demo..."

	# Always create/update workspace .project.yaml (do NOT read/modify repo root config)
	"${PROJECT_ROOT}/tools/pm/bin/pm" config init --force >/dev/null 2>&1 || true

	if [[ ! -f ".project.yaml" ]]; then
		log_error "Failed to create .project.yaml in demo workspace"
		return 1
	fi

	# Jira
	DEMO_JIRA_BASE_URL=$(normalize_demo_jira_base_url "${DEMO_JIRA_BASE_URL}")
	yq -i ".platforms.jira.base_url = \"${DEMO_JIRA_BASE_URL}\"" .project.yaml
	yq -i ".platforms.jira.project_key = \"${DEMO_JIRA_PROJECT}\"" .project.yaml
	if [[ -n "${DEMO_JIRA_EMAIL}" ]]; then
		yq -i ".platforms.jira.email = \"${DEMO_JIRA_EMAIL}\"" .project.yaml
	fi

	# Confluence (optional for demo, but keep URLs aligned)
	yq -i ".platforms.confluence.base_url = \"${DEMO_CONFLUENCE_BASE_URL}\"" .project.yaml
	if [[ -n "${DEMO_CONFLUENCE_SPACE}" ]]; then
		yq -i ".platforms.confluence.space_key = \"${DEMO_CONFLUENCE_SPACE}\"" .project.yaml
	fi

	# GitLab (used by demo repo creation + MR flow)
	yq -i ".platforms.gitlab.base_url = \"${DEMO_GITLAB_BASE_URL}\"" .project.yaml
	yq -i ".platforms.gitlab.project = \"${DEMO_GITLAB_GROUP}/${DEMO_REPO_NAME}\"" .project.yaml

	log_ok "Agent-context installed to: ${DEMO_WORKSPACE}"
	echo ""
	echo "Demo workspace contents:"
	ls -la "${DEMO_WORKSPACE}"
	echo ""

	# Return to script directory for subsequent operations
	cd "${SCRIPT_DIR}" || exit 1
}

# Phase 1: Project Layer - Roadmap and initial planning
phase_project() {
	log_phase "Phase 1: Project Layer - Roadmap Creation"

	export JIRA_PROJECT_KEY="${DEMO_JIRA_PROJECT}"

	# Create Epic in Jira
	log_info "Creating Epic in Jira..."

	if [[ "${DRY_RUN}" == "true" ]]; then
		log_info "[DRY-RUN] Would create Epic: ${DEMO_EPIC_SUMMARY}"
		log_info "[DRY-RUN] Would create 3-5 child Tasks"
		return 0
	fi

	local epic_result
	epic_result=$(pm_ws jira issue create "${DEMO_EPIC_SUMMARY}" --type Epic \
		--description "AITL Demo: Automated project lifecycle management demonstration")

	local epic_key
	epic_key=$(echo "${epic_result}" | grep -oE '[A-Z]+-[0-9]+' | head -1)

	if [[ -z "${epic_key}" ]]; then
		log_error "Failed to create Epic"
		echo "${epic_result}" >&2
		return 1
	fi

	CREATED_JIRA_ISSUES+=("${epic_key}")
	log_ok "Created Epic: ${epic_key}"

	# Create child tasks
	log_info "Creating child tasks..."

	local tasks=(
		"[${DEMO_RUN_ID}] Setup development environment"
		"[${DEMO_RUN_ID}] Implement core feature"
		"[${DEMO_RUN_ID}] Write unit tests"
		"[${DEMO_RUN_ID}] Documentation update"
		"[${DEMO_RUN_ID}] Performance optimization"
	)

	for task in "${tasks[@]}"; do
		local task_result
		task_result=$(pm_ws jira issue create "${task}" --type Task \
			--description "Child task of ${epic_key}")

		local task_key
		task_key=$(echo "${task_result}" | grep -oE '[A-Z]+-[0-9]+' | head -1)

		if [[ -n "${task_key}" ]]; then
			CREATED_JIRA_ISSUES+=("${task_key}")
			log_ok "Created Task: ${task_key} - ${task}"
		fi
	done

	# Create Confluence page (if configured)
	if [[ -n "${DEMO_CONFLUENCE_SPACE}" ]]; then
		log_info "Creating Confluence roadmap page..."

		local page_content="<h1>AITL Demo Roadmap</h1>"
		page_content+="<p>This page was auto-generated by the AITL demo.</p>"
		page_content+="<h2>Epic: ${epic_key}</h2>"
		page_content+="<h3>Tasks</h3><ul>"
		for task_key in "${CREATED_JIRA_ISSUES[@]:1}"; do
			page_content+="<li>${task_key}</li>"
		done
		page_content+="</ul>"
		page_content+="<p>Total tasks created: ${#CREATED_JIRA_ISSUES[@]}</p>"
		page_content+="<h3>Timeline</h3>"
		page_content+="<p>Created: $(date '+%Y-%m-%d %H:%M:%S')</p>"

		local page_result
		page_result=$(pm_ws confluence page create \
			--space "${DEMO_CONFLUENCE_SPACE}" \
			--title "[${DEMO_RUN_ID}] AITL Demo Roadmap" \
			--content "${page_content}" 2>&1) || true

		if echo "${page_result}" | grep -q "Created"; then
			log_ok "Confluence page created"
			CREATED_CONFLUENCE_PAGES+=("[${DEMO_RUN_ID}] AITL Demo Roadmap")
		else
			log_warn "Confluence page creation skipped or failed"
		fi
	fi

	# Human-in-the-Loop pause point after roadmap creation
	if [[ "${HITL_ENABLED}" == "true" ]]; then
		log_warn "HITL Pause: Review roadmap in Jira/Confluence"
		log_info "Epic: ${epic_key}"
		log_info "Tasks: ${CREATED_JIRA_ISSUES[*]:1}"
		echo ""
		log_info "Press Enter to continue to Team/Solo phase..."
		read -r
	fi

	log_ok "Phase 1 completed: Epic ${epic_key} with ${#CREATED_JIRA_ISSUES[@]} issues"
}

# Phase 1.5: GitLab Flow - Create issue, branch, commit, MR for selected task
phase_gitlab_flow() {
	log_phase "Phase 1.5: GitLab Flow - Issue/Branch/MR Cycle"

	if [[ "${SKIP_GITLAB}" == "true" ]]; then
		log_warn "GitLab flow skipped (--skip-gitlab)"
		return 0
	fi

	if [[ -z "${DEMO_WORKSPACE}" ]]; then
		log_warn "No demo workspace configured, skipping GitLab flow"
		return 0
	fi

	# Select first task for GitLab flow demonstration
	local demo_task="${CREATED_JIRA_ISSUES[1]:-}"

	if [[ -z "${demo_task}" ]]; then
		log_warn "No tasks available for GitLab flow"
		return 0
	fi

	export JIRA_PROJECT_KEY="${DEMO_JIRA_PROJECT}"

	# Get task summary
	local task_summary
	task_summary=$(pm_ws jira issue view "${demo_task}" 2>/dev/null | \
		grep "Summary:" | sed 's/Summary:[[:space:]]*//' || echo "Demo task")

	if [[ "${DRY_RUN}" == "true" ]]; then
		log_info "[DRY-RUN] Would run GitLab flow for ${demo_task}"
		log_info "[DRY-RUN] - Create GitLab issue"
		log_info "[DRY-RUN] - Create branch feat/${demo_task}-*"
		log_info "[DRY-RUN] - Commit worklog file"
		log_info "[DRY-RUN] - Create and merge MR"
		return 0
	fi

	log_info "Running GitLab flow for task: ${demo_task}"
	log_info "Summary: ${task_summary}"

	# Run full GitLab flow
	if gitlab_full_flow "${demo_task}" "${task_summary}" "feat" "${HITL_ENABLED}"; then
		log_ok "GitLab flow completed for ${demo_task}"

		# Store MR info for reporting
		DEMO_GITLAB_MR_URL="${GITLAB_LAST_MR_URL:-}"
		DEMO_GITLAB_BRANCH="${GITLAB_LAST_BRANCH:-}"

		# Now we can transition Jira to Done (MR merged)
		log_info "Transitioning ${demo_task} to Done (MR merged)..."
		pm_ws jira issue transition "${demo_task}" "Done" || true
		log_ok "${demo_task} marked as Done"
	else
		log_warn "GitLab flow incomplete for ${demo_task}"
		log_info "Task will remain in current state until MR is merged"
	fi

	# Human-in-the-Loop pause point
	if [[ "${HITL_ENABLED}" == "true" ]]; then
		log_warn "HITL Pause: Review GitLab artifacts"
		log_info "MR URL: ${DEMO_GITLAB_MR_URL:-N/A}"
		log_info "Branch: ${DEMO_GITLAB_BRANCH:-N/A}"
		echo ""
		log_info "Press Enter to continue to hotfix scenario..."
		read -r
	fi

	log_ok "Phase 1.5 completed: GitLab flow demonstrated"
}

# Phase 2: Team & Solo Layer - Hotfix scenario
phase_team_solo() {
	log_phase "Phase 2: Team & Solo Layer - Hotfix Scenario"

	export JIRA_PROJECT_KEY="${DEMO_JIRA_PROJECT}"

	if [[ "${DRY_RUN}" == "true" ]]; then
		log_info "[DRY-RUN] Would simulate hotfix scenario"
		log_info "[DRY-RUN] Would create Blocker links"
		log_info "[DRY-RUN] Would transition ticket states"
		return 0
	fi

	# Get first task to simulate "in progress" work
	local current_task="${CREATED_JIRA_ISSUES[1]:-}"

	if [[ -z "${current_task}" ]]; then
		log_warn "No tasks available for hotfix scenario"
		return 0
	fi

	# Use jira_sync library if available, otherwise fallback to direct pm calls
	if type jira_start_work &>/dev/null; then
		# Using jira_sync.sh library

		# Start work on current task
		(cd "${DEMO_WORKSPACE}" && jira_start_work "${current_task}")

		# Simulate hotfix arrival
		log_info "Simulating hotfix scenario..."

		# Create hotfix ticket
		local hotfix_result
		hotfix_result=$(pm_ws jira issue create "[${DEMO_RUN_ID}][HOTFIX] Critical production issue" \
			--type Task \
			--description "Urgent: Production system experiencing critical failure. Requires immediate attention.")

		local hotfix_key
		hotfix_key=$(echo "${hotfix_result}" | grep -oE '[A-Z]+-[0-9]+' | head -1)

		if [[ -z "${hotfix_key}" ]]; then
			log_error "Failed to create hotfix ticket"
			return 1
		fi

		CREATED_JIRA_ISSUES+=("${hotfix_key}")
		log_ok "Created Hotfix: ${hotfix_key}"

		# Set priority to highest
		pm_ws jira issue update "${hotfix_key}" --priority "Highest" || true

		# Handle hotfix using library function
		(cd "${DEMO_WORKSPACE}" && jira_handle_hotfix "${current_task}" "${hotfix_key}")

		# GitLab MR Gate: Hotfix must go through MR before Done
		local hotfix_mr_merged=false
		if [[ "${SKIP_GITLAB}" != "true" ]] && [[ -n "${DEMO_WORKSPACE}" ]]; then
			log_info "Running GitLab flow for hotfix ${hotfix_key}..."

			if gitlab_full_flow "${hotfix_key}" "Critical production issue fix" "hotfix" "${HITL_ENABLED}"; then
				hotfix_mr_merged=true
				HOTFIX_MR_URL="${GITLAB_LAST_MR_URL:-}"
				log_ok "Hotfix MR merged: ${HOTFIX_MR_URL}"
			else
				log_warn "Hotfix MR not merged - Jira Done transition blocked"
			fi
		else
			# Skip GitLab, allow transition
			hotfix_mr_merged=true
		fi

		# Human-in-the-Loop pause point
		if [[ "${HITL_ENABLED}" == "true" ]]; then
			log_warn "HITL Pause: Review hotfix ${hotfix_key} in Jira"
			if [[ -n "${HOTFIX_MR_URL:-}" ]]; then
				log_info "MR URL: ${HOTFIX_MR_URL}"
			fi
			log_info "Press Enter to continue..."
			read -r
		fi

		# Resume after hotfix - only if MR merged (or GitLab skipped)
		if [[ "${hotfix_mr_merged}" == "true" ]]; then
			(cd "${DEMO_WORKSPACE}" && jira_resume_after_hotfix "${hotfix_key}" "${current_task}")
		else
			log_warn "Skipping Jira Done transition for ${hotfix_key} (MR not merged)"
			# Still resume original work
			(cd "${DEMO_WORKSPACE}" && jira_start_work "${current_task}")
		fi
	else
		# Fallback: direct pm calls (original behavior)

		# Transition current task to "In Progress"
		log_info "Starting work on ${current_task}..."
		pm_ws jira issue transition "${current_task}" "In Progress" || true

		# Simulate hotfix arrival
		log_info "Simulating hotfix scenario..."

		# Create hotfix ticket
		local hotfix_result
		hotfix_result=$(pm_ws jira issue create "[${DEMO_RUN_ID}][HOTFIX] Critical production issue" \
			--type Task \
			--description "Urgent: Production system experiencing critical failure. Requires immediate attention.")

		local hotfix_key
		hotfix_key=$(echo "${hotfix_result}" | grep -oE '[A-Z]+-[0-9]+' | head -1)

		if [[ -z "${hotfix_key}" ]]; then
			log_error "Failed to create hotfix ticket"
			return 1
		fi

		CREATED_JIRA_ISSUES+=("${hotfix_key}")
		log_ok "Created Hotfix: ${hotfix_key}"

		# Set priority to highest
		pm_ws jira issue update "${hotfix_key}" --priority "Highest" || true

		# Create blocker link
		log_info "Creating Blocker link: ${current_task} is blocked by ${hotfix_key}..."
		pm_ws jira link create "${current_task}" "${hotfix_key}" "Blocks" || true
		log_ok "Blocker link created"

		# Put current task on hold (if supported)
		log_info "Transitioning ${current_task} to On Hold..."
		pm_ws jira issue transition "${current_task}" "On Hold" 2>/dev/null || \
			log_warn "On Hold status not available, keeping In Progress"

		# Start hotfix work
		log_info "Starting hotfix work on ${hotfix_key}..."
		pm_ws jira issue transition "${hotfix_key}" "In Progress" || true

		# GitLab MR Gate: Hotfix must go through MR before Done
		local hotfix_mr_merged=false
		if [[ "${SKIP_GITLAB}" != "true" ]] && [[ -n "${DEMO_WORKSPACE}" ]]; then
			log_info "Running GitLab flow for hotfix ${hotfix_key}..."

			if gitlab_full_flow "${hotfix_key}" "Critical production issue fix" "hotfix" "${HITL_ENABLED}"; then
				hotfix_mr_merged=true
				HOTFIX_MR_URL="${GITLAB_LAST_MR_URL:-}"
				log_ok "Hotfix MR merged: ${HOTFIX_MR_URL}"
			else
				log_warn "Hotfix MR not merged - Jira Done transition blocked"
			fi
		else
			# Skip GitLab, allow transition
			hotfix_mr_merged=true
		fi

		# Human-in-the-Loop pause point
		if [[ "${HITL_ENABLED}" == "true" ]]; then
			log_warn "HITL Pause: Review hotfix ${hotfix_key} in Jira"
			if [[ -n "${HOTFIX_MR_URL:-}" ]]; then
				log_info "MR URL: ${HOTFIX_MR_URL}"
			fi
			log_info "Press Enter to continue..."
			read -r
		fi

		# Complete hotfix - only if MR merged (or GitLab skipped)
		if [[ "${hotfix_mr_merged}" == "true" ]]; then
			log_info "Completing hotfix..."
			pm_ws jira issue transition "${hotfix_key}" "Done" || true
			log_ok "Hotfix ${hotfix_key} completed"
		else
			log_warn "Hotfix ${hotfix_key} remains In Progress (MR not merged)"
		fi

		# Resume original work
		log_info "Resuming work on ${current_task}..."
		pm_ws jira issue transition "${current_task}" "In Progress" || true
	fi

	log_ok "Phase 2 completed: Hotfix scenario demonstrated"
}

# Phase 2.5: Developer Initiative - Self-assigned task with full flow
phase_dev_initiative() {
	log_phase "Phase 2.5: Developer Initiative - Self-Assigned Task"

	export JIRA_PROJECT_KEY="${DEMO_JIRA_PROJECT}"

	if [[ "${DRY_RUN}" == "true" ]]; then
		log_info "[DRY-RUN] Would create developer initiative task"
		log_info "[DRY-RUN] Would assign to current user"
		log_info "[DRY-RUN] Would run full GitLab flow"
		return 0
	fi

	# Get current user email
	local current_user_email="${JIRA_EMAIL:-}"

	if [[ -z "${current_user_email}" ]]; then
		# Try to get from pm config
		current_user_email=$(pm_ws jira me 2>/dev/null | grep "Email:" | sed 's/Email:[[:space:]]*//' || echo "")
	fi

	if [[ -z "${current_user_email}" ]]; then
		log_warn "Could not determine current user email, skipping developer initiative"
		return 0
	fi

	log_info "Current user: ${current_user_email}"

	# Create developer initiative task
	local dev_summary="[${DEMO_RUN_ID}] Developer Initiative: Improvement idea"
	local dev_description="Developer-initiated improvement task.
This demonstrates the end-to-end flow for a developer's own idea:
1. Create task with self-assignment
2. Full GitLab flow (issue/branch/commit/MR/merge)
3. Complete Jira ticket after MR merge

Assignee: ${current_user_email}
Run ID: ${DEMO_RUN_ID}"

	log_info "Creating developer initiative task..."

	local task_result
	task_result=$(pm_ws jira issue create "${dev_summary}" \
		--type Task \
		--description "${dev_description}")

	local dev_task_key
	dev_task_key=$(echo "${task_result}" | grep -oE '[A-Z]+-[0-9]+' | head -1)

	if [[ -z "${dev_task_key}" ]]; then
		log_error "Failed to create developer initiative task"
		return 1
	fi

	CREATED_JIRA_ISSUES+=("${dev_task_key}")
	log_ok "Created: ${dev_task_key}"

	# Assign to self
	log_info "Assigning ${dev_task_key} to ${current_user_email}..."
	pm_ws jira issue assign "${dev_task_key}" "${current_user_email}" || \
		log_warn "Could not assign task to self"

	# Start work
	log_info "Starting work on ${dev_task_key}..."
	pm_ws jira issue transition "${dev_task_key}" "In Progress" || true

	# Run GitLab flow
	local dev_mr_merged=false
	if [[ "${SKIP_GITLAB}" != "true" ]] && [[ -n "${DEMO_WORKSPACE}" ]]; then
		log_info "Running GitLab flow for developer initiative..."

		if gitlab_full_flow "${dev_task_key}" "Developer improvement idea" "feat" "${HITL_ENABLED}"; then
			dev_mr_merged=true
			DEV_INITIATIVE_MR_URL="${GITLAB_LAST_MR_URL:-}"
			log_ok "Developer initiative MR merged: ${DEV_INITIATIVE_MR_URL}"
		else
			log_warn "Developer initiative MR not merged"
		fi
	else
		dev_mr_merged=true
	fi

	# Complete task if MR merged
	if [[ "${dev_mr_merged}" == "true" ]]; then
		log_info "Completing developer initiative task..."
		pm_ws jira issue transition "${dev_task_key}" "Done" || true
		log_ok "${dev_task_key} completed"
	else
		log_warn "${dev_task_key} remains In Progress (MR not merged)"
	fi

	# Human-in-the-Loop pause point
	if [[ "${HITL_ENABLED}" == "true" ]]; then
		log_warn "HITL Pause: Review developer initiative task"
		log_info "Task: ${dev_task_key}"
		if [[ -n "${DEV_INITIATIVE_MR_URL:-}" ]]; then
			log_info "MR URL: ${DEV_INITIATIVE_MR_URL}"
		fi
		echo ""
		log_info "Press Enter to continue to reporting phase..."
		read -r
	fi

	log_ok "Phase 2.5 completed: Developer initiative demonstrated"
}

# Phase 3: Reporting and Closure
phase_reporting() {
	log_phase "Phase 3: Reporting & Closure"

	export JIRA_PROJECT_KEY="${DEMO_JIRA_PROJECT}"

	if [[ "${DRY_RUN}" == "true" ]]; then
		log_info "[DRY-RUN] Would export Jira issues to Markdown"
		log_info "[DRY-RUN] Would generate metrics report"
		log_info "[DRY-RUN] Would create DASHBOARD.md"
		return 0
	fi

	# Human-in-the-Loop pause point before reporting
	if [[ "${HITL_ENABLED}" == "true" ]]; then
		log_warn "HITL Pause: Review all issues before generating report"
		log_info "Issues created: ${CREATED_JIRA_ISSUES[*]}"
		echo ""
		log_info "Press Enter to generate reports..."
		read -r
	fi

	# Export Jira issues
	log_info "Exporting Jira issues..."

	local export_dir="${SCRIPT_DIR}/export"
	mkdir -p "${export_dir}"

	pm_ws jira export --project "${DEMO_JIRA_PROJECT}" \
		--output "${export_dir}/jira" \
		--limit 50 || true

	log_ok "Issues exported to ${export_dir}/jira"

	# Collect metrics from created issues
	log_info "Collecting metrics..."

	local total_issues=${#CREATED_JIRA_ISSUES[@]}
	local epic_key="${CREATED_JIRA_ISSUES[0]:-N/A}"
	local hotfix_count=0
	local task_count=0
	local done_count=0
	local in_progress_count=0

	for issue_key in "${CREATED_JIRA_ISSUES[@]}"; do
		local status
		status=$(pm_ws jira issue view "${issue_key}" 2>/dev/null | \
			grep "Status:" | sed 's/Status:[[:space:]]*//' || echo "Unknown")

		case "${status}" in
			*Done*|*Closed*)
				((done_count++))
				;;
			*Progress*)
				((in_progress_count++))
				;;
		esac

		# Check if hotfix
		local summary
		summary=$(pm_ws jira issue view "${issue_key}" 2>/dev/null | \
			grep "Summary:" | sed 's/Summary:[[:space:]]*//' || echo "")

		if [[ "${summary}" == *"HOTFIX"* ]] || [[ "${summary}" == *"hotfix"* ]]; then
			((hotfix_count++))
		else
			((task_count++))
		fi
	done

	# Calculate completion rate
	local completion_rate=0
	if [[ ${total_issues} -gt 0 ]]; then
		completion_rate=$(( (done_count * 100) / total_issues ))
	fi

	# Generate detailed report
	log_info "Generating metrics report..."

	local report_file="${export_dir}/DEMO_REPORT.md"
	local demo_end_time=$(date '+%Y-%m-%d %H:%M:%S')

	cat > "${report_file}" <<EOF
# AITL Demo Report

Run ID: ${DEMO_RUN_ID}
Generated: ${demo_end_time}

## Executive Summary

This report summarizes the Agent-in-the-Loop (AITL) demonstration that showcased
automated project lifecycle management using real Jira and GitLab infrastructure.

## Metrics Dashboard

| Metric | Value |
|--------|-------|
| Total Issues Created | ${total_issues} |
| Epic(s) | 1 |
| Regular Tasks | ${task_count} |
| Hotfix(es) | ${hotfix_count} |
| Completed | ${done_count} |
| In Progress | ${in_progress_count} |
| Completion Rate | ${completion_rate}% |

## Issue Breakdown

### Epic
- ${epic_key}

### Created Issues
EOF

	for issue in "${CREATED_JIRA_ISSUES[@]}"; do
		local issue_status
		issue_status=$(pm_ws jira issue view "${issue}" 2>/dev/null | \
			grep "Status:" | sed 's/Status:[[:space:]]*//' || echo "Unknown")
		echo "- ${issue} (${issue_status})" >> "${report_file}"
	done

	cat >> "${report_file}" <<EOF

## Workflow Phases Executed

### Phase 1: Project Layer (Initial Planning)
- Created Epic: ${epic_key}
- Generated ${task_count} child tasks
- Established project roadmap
$(if [[ -n "${DEMO_CONFLUENCE_SPACE}" ]]; then echo "- Created Confluence documentation"; fi)

### Phase 1.5: GitLab Flow (Issue/Branch/MR)
$(if [[ "${SKIP_GITLAB}" != "true" ]]; then echo "- Created GitLab issue linked to Jira task"; echo "- Created feature branch and pushed changes"; echo "- Created and merged MR"; echo "- Added GitLab trace comment to Jira"; else echo "- (Skipped)"; fi)

### Phase 2: Team & Solo Layer (Execution + Hotfix)
- Started work on assigned tasks
- Simulated production hotfix scenario
- Demonstrated blocker link creation
- Showed priority-based work switching
$(if [[ "${SKIP_GITLAB}" != "true" ]]; then echo "- Enforced MR gate before hotfix completion"; fi)
- Completed hotfix and resumed original work

### Phase 2.5: Developer Initiative
- Created self-assigned improvement task
$(if [[ "${SKIP_GITLAB}" != "true" ]]; then echo "- Completed full GitLab flow with MR gate"; fi)
- Demonstrated end-to-end developer workflow

### Phase 3: Reporting & Closure
- Exported all issues to Markdown
- Generated this metrics report
- Calculated completion statistics

## AITL Capabilities Demonstrated

1. **Automated Issue Management**
   - Programmatic Epic and Task creation
   - Status transitions via workflow rules
   - Priority management

2. **Dependency Tracking**
   - Blocker link creation
   - Work interruption handling
   - Resume-after-block workflow

3. **Cross-Platform Coordination**
   - Jira issue tracking
   - GitLab repository management (if configured)
   - Confluence documentation (if configured)

4. **Metrics and Reporting**
   - Automatic data extraction
   - Completion rate calculation
   - Structured report generation

## Configuration Used

| Setting | Value |
|---------|-------|
| Run ID | ${DEMO_RUN_ID} |
| Jira Project | ${DEMO_JIRA_PROJECT} |
| Confluence Space | ${DEMO_CONFLUENCE_SPACE:-N/A} |
| GitLab Group | ${DEMO_GITLAB_GROUP:-N/A} |
| HITL Enabled | ${HITL_ENABLED:-false} |

## Recommendations

Based on this demo, the AITL system can:
- Reduce manual ticket management overhead
- Enforce consistent workflow transitions
- Provide real-time visibility into work status
- Handle priority interruptions gracefully

## Appendix: Raw Data

Issue keys for manual verification:
\`\`\`
${CREATED_JIRA_ISSUES[*]}
\`\`\`

---
*Report generated by AITL Demo v1.0*
EOF

	log_ok "Report generated: ${report_file}"

	# Generate DASHBOARD.md for quick overview
	local dashboard_file="${export_dir}/DASHBOARD.md"

	cat > "${dashboard_file}" <<EOF
# AITL Demo Dashboard

> Quick overview of demo results - Run ID: ${DEMO_RUN_ID}

## Status: COMPLETED

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Issues Created | ${total_issues} | 5+ | OK |
| Completion Rate | ${completion_rate}% | N/A | - |
| Hotfix Handled | ${hotfix_count} | 1 | OK |
| Phases Completed | 3/3 | 3/3 | OK |

## Quick Links

- Epic: ${epic_key}
- Full Report: [DEMO_REPORT.md](./DEMO_REPORT.md)
- Exported Issues: [jira/](./jira/)

---
Updated: ${demo_end_time}
EOF

	log_ok "Dashboard generated: ${dashboard_file}"

	# Display summary
	echo ""
	echo "------------------------------------------------------------"
	cat "${dashboard_file}"
	echo "------------------------------------------------------------"
}

# Cleanup demo resources
cleanup() {
	log_phase "Cleanup: Removing Demo Resources"

	log_warn "This will delete all demo resources!"
	echo ""
	echo "Resources to be deleted:"
	echo "  - GitLab repo: ${CREATED_GITLAB_REPO:-none}"
	echo "  - Jira issues: ${CREATED_JIRA_ISSUES[*]:-none}"
	echo ""

	if [[ "${DRY_RUN}" == "true" ]]; then
		log_info "[DRY-RUN] Would delete above resources"
		return 0
	fi

	read -p "Are you sure? (yes/no): " -r confirm
	if [[ "${confirm}" != "yes" ]]; then
		log_info "Cleanup cancelled"
		return 0
	fi

	# Delete GitLab repo
	if [[ -n "${CREATED_GITLAB_REPO}" ]]; then
		log_info "Deleting GitLab repo..."
		if glab repo delete "${CREATED_GITLAB_REPO}" --yes 2>/dev/null; then
			log_ok "Deleted: ${CREATED_GITLAB_REPO}"
		else
			log_warn "Could not delete GitLab repo (may not exist)"
		fi
	fi

	# Note: Jira issues are typically not deleted programmatically
	# to preserve audit trail
	if [[ ${#CREATED_JIRA_ISSUES[@]} -gt 0 ]]; then
		log_warn "Jira issues are preserved for audit trail:"
		for issue in "${CREATED_JIRA_ISSUES[@]}"; do
			echo "  - ${issue}"
		done
		echo "  Delete manually if needed."
	fi

	log_ok "Cleanup completed"
}

# Run full demo
run_demo() {
	log_phase "AITL Grand Scenario Demo"
	echo "Run ID: ${DEMO_RUN_ID}"
	echo "Repository: ${DEMO_REPO_NAME}"
	echo "Jira Project: ${DEMO_JIRA_PROJECT}"
	echo "Confluence Space: ${DEMO_CONFLUENCE_SPACE:-not configured}"
	echo "Dry Run: ${DRY_RUN:-false}"
	echo "HITL Enabled: ${HITL_ENABLED:-false}"
	echo ""

	# Step 1: Check prerequisites
	check_dependencies || exit 1

	# Step 2: Setup workspace (GitLab repo or local /tmp)
	log_phase "Step 2: Environment Setup"
	if [[ "${SKIP_GITLAB}" != "true" ]]; then
		setup_gitlab_repo || log_warn "GitLab setup skipped"
	fi

	# Step 3: Install + configure workspace (creates workspace .project.yaml)
	log_phase "Step 3: Install agent-context to workspace"
	setup_project_config || exit 1

	# Step 4: Validate configuration (Jira)
	log_phase "Step 4: Validating Configuration"
	validate_jira_config || exit 1

	# Step 5: Create Jira board (best-effort)
	log_phase "Step 5: Jira Board Setup"
	jira_create_board_best_effort || true

	# Phase 1: Project Layer
	phase_project || exit 1

	# Phase 1.5: GitLab Flow (if workspace available)
	phase_gitlab_flow || log_warn "GitLab flow phase skipped"

	# Phase 2: Team & Solo Layer
	phase_team_solo || exit 1

	# Phase 2.5: Developer Initiative
	phase_dev_initiative || log_warn "Developer initiative phase skipped"

	# Phase 3: Reporting
	phase_reporting || exit 1

	# Completion
	log_phase "Demo Completed Successfully"
	echo ""
	echo "Summary:"
	echo "  - Issues created: ${#CREATED_JIRA_ISSUES[@]}"
	echo "  - Report: ${SCRIPT_DIR}/export/DEMO_REPORT.md"
	echo ""

	# Offer cleanup
	if [[ "${SKIP_CLEANUP}" != "true" ]] && [[ "${DRY_RUN}" != "true" ]]; then
		echo ""
		read -p "Clean up demo resources? (yes/no): " -r cleanup_confirm
		if [[ "${cleanup_confirm}" == "yes" ]]; then
			cleanup
		fi
	fi
}

# Main
main() {
	# Parse command (first positional argument)
	local command="${1:-run}"
	shift || true

	# Parse remaining arguments (sets global variables directly)
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--run-id)
			DEMO_RUN_ID="$2"
			# Force update dependent variables with new run ID
			DEMO_REPO_NAME="demo-${DEMO_RUN_ID}"
			DEMO_EPIC_SUMMARY="[${DEMO_RUN_ID}] AITL Demo Epic"
			shift
			;;
			--repo)
				DEMO_REPO_NAME="$2"
				shift
				;;
			--jira-project)
				DEMO_JIRA_PROJECT="$2"
				shift
				;;
			--jira-email)
				DEMO_JIRA_EMAIL="$2"
				shift
				;;
			--jira-base-url)
				DEMO_JIRA_BASE_URL=$(normalize_demo_jira_base_url "$2")
				shift
				;;
			--board-type)
				DEMO_BOARD_TYPE="$2"
				shift
				;;
			--confluence-space)
				DEMO_CONFLUENCE_SPACE="$2"
				shift
				;;
			--confluence-base-url)
				DEMO_CONFLUENCE_BASE_URL="$2"
				shift
				;;
			--gitlab-base-url)
				DEMO_GITLAB_BASE_URL="$2"
				shift
				;;
			--gitlab-group)
				DEMO_GITLAB_GROUP="$2"
				shift
				;;
			--dry-run)
				DRY_RUN="true"
				;;
			--skip-cleanup)
				SKIP_CLEANUP="true"
				;;
			--hitl)
				HITL_ENABLED="true"
				;;
			--skip-gitlab)
				SKIP_GITLAB="true"
				;;
			-h|--help)
				usage
				exit 0
				;;
			*)
				log_error "Unknown option: $1"
				usage
				exit 1
				;;
		esac
		shift
	done

	case "${command}" in
		run)
			run_demo
			;;
		check)
			check_dependencies
			;;
		cleanup)
			cleanup
			;;
		help|-h|--help)
			usage
			;;
		*)
			log_error "Unknown command: ${command}"
			usage
			exit 1
			;;
	esac
}

main "$@"
