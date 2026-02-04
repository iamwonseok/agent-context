#!/bin/bash
# AITL Demo Cleanup Script
# Removes resources created during the demo
#
# Usage:
#   ./cleanup.sh [options]
#
# Options:
#   --repo NAME         GitLab repository to delete
#   --issues KEY1,KEY2  Jira issue keys to list (not deleted automatically)
#   --export-dir PATH   Export directory to clean
#   --force             Skip confirmation prompts
#   --dry-run           Show what would be done

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Logging
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

# Show usage
usage() {
	cat <<EOF
AITL Demo Cleanup Script

USAGE:
    $(basename "$0") [options]

OPTIONS:
    --repo NAME         GitLab repository name to delete
    --issues KEYS       Comma-separated Jira issue keys (for reference)
    --export-dir PATH   Export directory to clean (default: ./export)
    --force             Skip confirmation prompts
    --dry-run           Show what would be done without executing
    -h, --help          Show this help

EXAMPLES:
    # Interactive cleanup
    $(basename "$0")

    # Clean specific repo
    $(basename "$0") --repo aitl-demo-20250130

    # Force cleanup of export directory
    $(basename "$0") --export-dir ./export --force

NOTES:
    - Jira issues are NOT deleted automatically to preserve audit trail
    - GitLab repository deletion requires confirmation
    - Export files are safe to delete

EOF
}

# Parse arguments
GITLAB_REPO=""
JIRA_ISSUES=""
EXPORT_DIR="${SCRIPT_DIR}/export"
FORCE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
	case "$1" in
		--repo)
			GITLAB_REPO="$2"
			shift
			;;
		--issues)
			JIRA_ISSUES="$2"
			shift
			;;
		--export-dir)
			EXPORT_DIR="$2"
			shift
			;;
		--force)
			FORCE=true
			;;
		--dry-run)
			DRY_RUN=true
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

# Confirm action
confirm() {
	local message="$1"

	if [[ "${FORCE}" == "true" ]]; then
		return 0
	fi

	echo -n "${message} (yes/no): "
	read -r response
	[[ "${response}" == "yes" ]]
}

# Clean export directory
clean_export_dir() {
	log_info "Checking export directory: ${EXPORT_DIR}"

	if [[ ! -d "${EXPORT_DIR}" ]]; then
		log_ok "Export directory does not exist, nothing to clean"
		return 0
	fi

	local file_count
	file_count=$(find "${EXPORT_DIR}" -type f 2>/dev/null | wc -l | tr -d ' ')

	if [[ "${file_count}" -eq 0 ]]; then
		log_ok "Export directory is empty"
		return 0
	fi

	log_warn "Found ${file_count} files in export directory"
	echo ""
	ls -la "${EXPORT_DIR}"
	echo ""

	if [[ "${DRY_RUN}" == "true" ]]; then
		log_info "[DRY-RUN] Would delete: ${EXPORT_DIR}/*"
		return 0
	fi

	if confirm "Delete all exported files?"; then
		rm -rf "${EXPORT_DIR:?}"/*
		log_ok "Export directory cleaned"
	else
		log_info "Skipped export cleanup"
	fi
}

# Clean GitLab repository
clean_gitlab_repo() {
	if [[ -z "${GITLAB_REPO}" ]]; then
		log_info "No GitLab repository specified, skipping"
		return 0
	fi

	log_warn "GitLab repository to delete: ${GITLAB_REPO}"

	if [[ "${DRY_RUN}" == "true" ]]; then
		log_info "[DRY-RUN] Would delete: glab repo delete ${GITLAB_REPO}"
		return 0
	fi

	if ! command -v glab &>/dev/null; then
		log_error "glab CLI not found, cannot delete repository"
		return 1
	fi

	if confirm "Delete GitLab repository '${GITLAB_REPO}'? THIS CANNOT BE UNDONE"; then
		if glab repo delete "${GITLAB_REPO}" --yes 2>/dev/null; then
			log_ok "Repository deleted: ${GITLAB_REPO}"
		else
			log_warn "Could not delete repository (may not exist or insufficient permissions)"
		fi
	else
		log_info "Skipped GitLab cleanup"
	fi
}

# Show Jira issues (not deleted)
show_jira_issues() {
	if [[ -z "${JIRA_ISSUES}" ]]; then
		return 0
	fi

	log_warn "Jira issues created during demo (NOT deleted automatically):"
	echo ""

	IFS=',' read -ra issues <<< "${JIRA_ISSUES}"
	for issue in "${issues[@]}"; do
		echo "  - ${issue}"
	done

	echo ""
	log_info "To delete these issues manually:"
	echo "  1. Go to your Jira project"
	echo "  2. Search for the issue keys above"
	echo "  3. Delete if no longer needed"
	echo ""
	log_warn "Note: Jira issues are preserved for audit trail by default"
}

# Clean temporary files
clean_temp_files() {
	log_info "Checking for temporary files..."

	local temp_patterns=(
		"${SCRIPT_DIR}/*.tmp"
		"${SCRIPT_DIR}/.demo_state"
		"/tmp/aitl-demo-*"
	)

	local found=0

	for pattern in "${temp_patterns[@]}"; do
		# shellcheck disable=SC2086
		if ls ${pattern} &>/dev/null; then
			found=1
			if [[ "${DRY_RUN}" == "true" ]]; then
				log_info "[DRY-RUN] Would delete: ${pattern}"
			else
				rm -rf ${pattern} 2>/dev/null || true
			fi
		fi
	done

	if [[ ${found} -eq 0 ]]; then
		log_ok "No temporary files found"
	else
		log_ok "Temporary files cleaned"
	fi
}

# Generate cleanup summary
generate_summary() {
	cat <<EOF

============================================================
Cleanup Summary
============================================================

Export Directory:  ${EXPORT_DIR}
GitLab Repository: ${GITLAB_REPO:-none}
Jira Issues:       ${JIRA_ISSUES:-none}
Dry Run:           ${DRY_RUN}
Force:             ${FORCE}

Actions Completed:
  - Export files:   Cleaned (if confirmed)
  - GitLab repo:    Deleted (if specified and confirmed)
  - Temp files:     Cleaned
  - Jira issues:    Listed (manual deletion required)

============================================================
EOF
}

# Main
main() {
	echo ""
	echo "============================================================"
	echo "AITL Demo Cleanup"
	echo "============================================================"
	echo ""

	if [[ "${DRY_RUN}" == "true" ]]; then
		log_warn "DRY-RUN MODE: No changes will be made"
		echo ""
	fi

	# Run cleanup steps
	clean_temp_files
	echo ""

	clean_export_dir
	echo ""

	clean_gitlab_repo
	echo ""

	show_jira_issues

	generate_summary

	log_ok "Cleanup completed"
}

main "$@"
