#!/bin/bash
# Mock mode library for testing without real API calls
#
# Usage:
#   AGENT_MOCK=1 agnt-c dev start TASK-123
#
# Or source this file and use mock_* functions

# ============================================================
# Mock Mode Detection
# ============================================================

# Check if mock mode is enabled
is_mock_mode() {
    [[ "${AGENT_MOCK:-0}" == "1" ]]
}

# Enable mock mode
mock_enable() {
    export AGENT_MOCK=1
    echo "[MOCK] Mock mode enabled - no real API calls will be made"
}

# Disable mock mode
mock_disable() {
    unset AGENT_MOCK
    echo "[INFO] Mock mode disabled - real API calls will be made"
}

# ============================================================
# Mock Responses
# ============================================================

# Mock JIRA issue creation
mock_jira_issue_create() {
    local title="$1"
    local type="${2:-Task}"

    echo "[MOCK] Would create JIRA issue:"
    echo "  Type:  $type"
    echo "  Title: $title"
    echo ""
    echo "MOCK-123"  # Return fake issue key
}

# Mock JIRA status transition
mock_jira_transition() {
    local issue="$1"
    local status="$2"

    echo "[MOCK] Would transition $issue to '$status'"
    return 0
}

# Mock GitLab MR creation
mock_gitlab_mr_create() {
    local source="$1"
    local target="${2:-main}"
    local title="$3"

    echo "[MOCK] Would create GitLab MR:"
    echo "  Source: $source"
    echo "  Target: $target"
    echo "  Title:  $title"
    echo ""
    echo "https://gitlab.example.com/project/-/merge_requests/123"
}

# Mock GitHub PR creation
mock_github_pr_create() {
    local source="$1"
    local target="${2:-main}"
    local title="$3"

    echo "[MOCK] Would create GitHub PR:"
    echo "  Source: $source"
    echo "  Target: $target"
    echo "  Title:  $title"
    echo ""
    echo "https://github.com/owner/repo/pull/123"
}

# Mock Confluence page creation
mock_confluence_page_create() {
    local title="$1"
    local space="${2:-}"

    echo "[MOCK] Would create Confluence page:"
    echo "  Title: $title"
    echo "  Space: ${space:-(default)}"
    echo ""
    echo "https://confluence.example.com/pages/123"
}

# Mock git push
mock_git_push() {
    local branch="${1:-HEAD}"

    echo "[MOCK] Would push branch: $branch"
    return 0
}

# Mock git branch creation
mock_git_branch() {
    local branch="$1"

    echo "[MOCK] Would create branch: $branch"
    return 0
}

# ============================================================
# Wrapper Functions
# ============================================================

# Execute command or mock it
# Usage: mock_or_exec <command> <args...>
mock_or_exec() {
    if is_mock_mode; then
        echo "[MOCK] Would execute: $*"
        return 0
    else
        "$@"
    fi
}

# Execute API call or return mock response
# Usage: mock_or_api <mock_response> <command> <args...>
mock_or_api() {
    local mock_response="$1"
    shift

    if is_mock_mode; then
        echo "[MOCK] $*"
        echo "$mock_response"
        return 0
    else
        "$@"
    fi
}

# ============================================================
# Test Utilities
# ============================================================

# Run a test with mock mode
# Usage: mock_test "test name" command args...
mock_test() {
    local test_name="$1"
    shift

    echo "=== Test: $test_name ==="

    local old_mock="${AGENT_MOCK:-}"
    export AGENT_MOCK=1

    if "$@"; then
        echo "[PASS] $test_name"
        local result=0
    else
        echo "[FAIL] $test_name"
        local result=1
    fi

    if [[ -n "$old_mock" ]]; then
        export AGENT_MOCK="$old_mock"
    else
        unset AGENT_MOCK
    fi

    return $result
}

# Show mock mode status
mock_status() {
    echo "=== Mock Mode Status ==="
    if is_mock_mode; then
        echo "Status: ENABLED"
        echo ""
        echo "All API calls will be simulated:"
        echo "  - JIRA operations"
        echo "  - GitLab/GitHub operations"
        echo "  - Confluence operations"
        echo "  - Git push/remote operations"
    else
        echo "Status: DISABLED"
        echo ""
        echo "Real API calls will be made."
        echo "To enable mock mode: export AGENT_MOCK=1"
    fi
}
