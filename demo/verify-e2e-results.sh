#!/bin/bash
# Agent-Context E2E Test Results Verification Script
# Verifies GitLab, Jira, and Confluence resources after demo.sh execution

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Configuration
: "${JIRA_EMAIL:?JIRA_EMAIL is required}"
: "${JIRA_PROJECT_KEY:=SVI4}"
: "${JIRA_BASE_URL:=https://fadutec.atlassian.net}"
: "${CONFLUENCE_BASE_URL:=https://fadutec.atlassian.net/wiki}"
: "${CONFLUENCE_SPACE_KEY:=~wonseok}"
: "${GITLAB_GROUP:=soc-ip/agentic-ai}"
ATLASSIAN_TOKEN_FILE="${HOME}/.secrets/atlassian-api-token"

# OS targets to verify
OS_TARGETS=("ubuntu" "ubi9")

# ============================================================
# Logging Functions
# ============================================================

log_pass() { echo -e "${GREEN}[V]${NC} $1"; ((++PASS_COUNT)) || true; }
log_fail() { echo -e "${RED}[X]${NC} $1"; ((++FAIL_COUNT)) || true; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; ((++WARN_COUNT)) || true; }
log_info() { echo -e "${BLUE}[i]${NC} $1"; }
log_section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

# ============================================================
# Helper Functions
# ============================================================

get_atlassian_token() {
	if [[ -f "${ATLASSIAN_TOKEN_FILE}" ]]; then
		cat "${ATLASSIAN_TOKEN_FILE}"
	else
		echo ""
	fi
}

jira_api() {
	local endpoint="$1"
	local token
	token=$(get_atlassian_token)
	curl -s -u "${JIRA_EMAIL}:${token}" "${JIRA_BASE_URL}${endpoint}"
}

confluence_api() {
	local endpoint="$1"
	local token
	token=$(get_atlassian_token)
	curl -s -u "${JIRA_EMAIL}:${token}" "${CONFLUENCE_BASE_URL}${endpoint}"
}

gitlab_api() {
	local endpoint="$1"
	glab api "${endpoint}" 2>/dev/null || echo "{}"
}

# ============================================================
# GitLab Verification
# ============================================================

verify_gitlab() {
	local os="$1"
	local repo_name="demo-agent-context-install-${os}"
	local repo_path="${GITLAB_GROUP}/${repo_name}"
	local repo_ref="${repo_path//\//%2F}"

	log_section "GitLab: ${repo_name}"

	# Check repository exists
	local repo_info
	repo_info=$(gitlab_api "projects/${repo_ref}")
	local repo_id
	repo_id=$(echo "${repo_info}" | jq -r '.id // empty')

	if [[ -n "${repo_id}" ]]; then
		log_pass "Repository exists: ${repo_path} (id: ${repo_id})"
	else
		log_fail "Repository not found: ${repo_path}"
		return 1
	fi

	# Check MRs (auto-merge may fail due to CI checks, approvals, etc.)
	local mrs_merged mrs_all
	mrs_merged=$(gitlab_api "projects/${repo_id}/merge_requests?state=merged&per_page=100")
	mrs_all=$(gitlab_api "projects/${repo_id}/merge_requests?state=all&per_page=100")
	local mr_merged_count mr_total_count
	mr_merged_count=$(echo "${mrs_merged}" | jq 'length')
	mr_total_count=$(echo "${mrs_all}" | jq 'length')

	if [[ "${mr_merged_count}" -ge 2 ]]; then
		log_pass "Merged MRs: ${mr_merged_count} (expected >= 2)"
	elif [[ "${mr_total_count}" -ge 2 ]]; then
		log_warn "Merged MRs: ${mr_merged_count} (${mr_total_count} total, auto-merge may require manual approval)"
	else
		log_warn "Total MRs: ${mr_total_count} (expected >= 2, auto-merge may be disabled)"
	fi

	# List MRs
	echo "${mrs_all}" | jq -r '.[] | "  - MR !\(.iid): \(.title) [\(.state)]"' 2>/dev/null || true

	# Check GitLab Issues
	local issues
	issues=$(gitlab_api "projects/${repo_id}/issues?per_page=100")
	local issue_count
	issue_count=$(echo "${issues}" | jq 'length')

	if [[ "${issue_count}" -ge 2 ]]; then
		log_pass "GitLab Issues: ${issue_count} (expected >= 2)"
	else
		log_warn "GitLab Issues: ${issue_count} (expected >= 2)"
	fi

	# List Issues
	echo "${issues}" | jq -r '.[] | "  - Issue #\(.iid): \(.title) [\(.state)]"' 2>/dev/null || true

	# Check commits in main
	local commits
	commits=$(gitlab_api "projects/${repo_id}/repository/commits?ref_name=main&per_page=10")
	local commit_count
	commit_count=$(echo "${commits}" | jq 'length')

	if [[ "${commit_count}" -ge 3 ]]; then
		log_pass "Commits in main: ${commit_count}"
	else
		log_warn "Commits in main: ${commit_count} (expected >= 3)"
	fi
}

# ============================================================
# Jira Verification
# ============================================================

jira_search() {
	# Use new Jira API (POST /rest/api/3/search/jql)
	local jql="$1"
	local token
	token=$(get_atlassian_token)
	curl -s -u "${JIRA_EMAIL}:${token}" \
		-X POST \
		-H "Content-Type: application/json" \
		"${JIRA_BASE_URL}/rest/api/3/search/jql" \
		-d "{\"jql\":\"${jql}\",\"maxResults\":100,\"fields\":[\"key\",\"summary\",\"status\",\"issuetype\",\"priority\"]}"
}

verify_jira() {
	local os="$1"
	local repo_name="demo-agent-context-install-${os}"

	log_section "Jira: ${repo_name}"

	# Check board exists
	local boards
	boards=$(jira_api "/rest/agile/1.0/board?projectKeyOrId=${JIRA_PROJECT_KEY}&maxResults=100")
	local board_id
	board_id=$(echo "${boards}" | jq -r ".values[] | select(.name | contains(\"${repo_name}\")) | .id" | head -1)

	if [[ -n "${board_id}" ]]; then
		local board_name
		board_name=$(echo "${boards}" | jq -r ".values[] | select(.id == ${board_id}) | .name")
		log_pass "Board exists: ${board_name} (id: ${board_id})"
	else
		log_warn "Board not found for: ${repo_name} (may share board with other OS)"
	fi

	# Search for issues using new API
	local jql="project = ${JIRA_PROJECT_KEY} AND summary ~ \\\"${repo_name}\\\" ORDER BY created ASC"
	local issues
	issues=$(jira_search "${jql}")

	local issue_count
	issue_count=$(echo "${issues}" | jq '.issues | length // 0')

	if [[ "${issue_count}" -ge 5 ]]; then
		log_pass "Jira Issues: ${issue_count} (expected >= 5: 1 Epic + 3 Tasks + 1 Hotfix + 1 Initiative)"
	else
		log_fail "Jira Issues: ${issue_count} (expected >= 5)"
	fi

	# Verify issue types
	local epic_count task_count
	epic_count=$(echo "${issues}" | jq '[.issues[]? | select(.fields.issuetype.name == "Epic")] | length')
	task_count=$(echo "${issues}" | jq '[.issues[]? | select(.fields.issuetype.name == "Task" or .fields.issuetype.name == "Story")] | length')

	if [[ "${epic_count}" -ge 1 ]]; then
		log_pass "Epic count: ${epic_count}"
	else
		log_fail "Epic count: ${epic_count} (expected >= 1)"
	fi

	if [[ "${task_count}" -ge 4 ]]; then
		log_pass "Task count: ${task_count} (expected >= 4: 3 tasks + 1 hotfix + 1 initiative)"
	else
		log_warn "Task count: ${task_count} (expected >= 4)"
	fi

	# List issues with status
	echo "  Issues:"
	echo "${issues}" | jq -r '.issues[]? | "  - [\(.fields.issuetype.name)] \(.key): \(.fields.status.name) - \(.fields.summary[0:60])..."' 2>/dev/null || true

	# Verify specific statuses
	local done_count
	done_count=$(echo "${issues}" | jq '[.issues[]? | select(.fields.status.name == "Done" or .fields.status.name == "Closed" or .fields.status.name == "Complete")] | length')

	if [[ "${done_count}" -ge 2 ]]; then
		log_pass "Done issues: ${done_count} (expected >= 2: task + hotfix)"
	else
		log_warn "Done issues: ${done_count} (expected >= 2)"
	fi

	# Check for hotfix with Highest priority
	local hotfix_highest
	hotfix_highest=$(echo "${issues}" | jq '[.issues[]? | select(.fields.summary | contains("HOTFIX")) | select(.fields.priority.name == "Highest")] | length')

	if [[ "${hotfix_highest}" -ge 1 ]]; then
		log_pass "Hotfix with Highest priority: ${hotfix_highest}"
	else
		log_warn "Hotfix with Highest priority not found"
	fi
}

# ============================================================
# Confluence Verification
# ============================================================

verify_confluence() {
	local os="$1"
	local repo_name="demo-agent-context-install-${os}"

	log_section "Confluence: ${repo_name}"

	# Search for pages
	local pages
	pages=$(confluence_api "/rest/api/content?spaceKey=${CONFLUENCE_SPACE_KEY}&limit=100&expand=version")

	local matching_pages
	matching_pages=$(echo "${pages}" | jq "[.results[] | select(.title | contains(\"${repo_name}\"))]")
	local page_count
	page_count=$(echo "${matching_pages}" | jq 'length')

	if [[ "${page_count}" -ge 1 ]]; then
		log_pass "Confluence pages: ${page_count}"
	else
		log_warn "Confluence pages: ${page_count} (expected >= 1)"
	fi

	# List pages
	echo "  Pages:"
	echo "${matching_pages}" | jq -r '.[] | "  - \(.title) (id: \(.id))"' 2>/dev/null || true

	# Check for Project Charter
	local charter_count
	charter_count=$(echo "${matching_pages}" | jq '[.[] | select(.title | contains("Project Charter"))] | length')

	if [[ "${charter_count}" -ge 1 ]]; then
		log_pass "Project Charter page exists"
	else
		log_warn "Project Charter page not found"
	fi
}

# ============================================================
# Summary Report
# ============================================================

print_summary() {
	echo ""
	echo "============================================================"
	echo "                    VERIFICATION SUMMARY"
	echo "============================================================"
	echo ""
	echo -e "  ${GREEN}PASS${NC}: ${PASS_COUNT}"
	echo -e "  ${RED}FAIL${NC}: ${FAIL_COUNT}"
	echo -e "  ${YELLOW}WARN${NC}: ${WARN_COUNT}"
	echo ""

	if [[ "${FAIL_COUNT}" -eq 0 ]]; then
		echo -e "${GREEN}All critical checks passed!${NC}"
		return 0
	else
		echo -e "${RED}Some checks failed. Review the output above.${NC}"
		return 1
	fi
}

# ============================================================
# Main
# ============================================================

main() {
	echo "============================================================"
	echo "       Agent-Context E2E Test Results Verification"
	echo "============================================================"
	echo ""
	echo "Configuration:"
	echo "  Jira Project: ${JIRA_PROJECT_KEY}"
	echo "  Confluence Space: ${CONFLUENCE_SPACE_KEY}"
	echo "  GitLab Group: ${GITLAB_GROUP}"
	echo "  OS Targets: ${OS_TARGETS[*]}"
	echo ""

	# Check prerequisites
	if [[ ! -f "${ATLASSIAN_TOKEN_FILE}" ]]; then
		log_fail "Atlassian token not found: ${ATLASSIAN_TOKEN_FILE}"
		exit 1
	fi

	if ! command -v glab &>/dev/null; then
		log_fail "glab CLI not found"
		exit 1
	fi

	if ! glab auth status &>/dev/null; then
		log_fail "glab not authenticated"
		exit 1
	fi

	log_pass "Prerequisites OK"

	# Verify each OS
	for os in "${OS_TARGETS[@]}"; do
		echo ""
		echo "============================================================"
		echo "                    Verifying: ${os}"
		echo "============================================================"

		verify_gitlab "${os}" || true
		verify_jira "${os}" || true
		verify_confluence "${os}" || true
	done

	print_summary
}

# Run main
main "$@"
