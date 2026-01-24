#!/bin/bash
# Test Report Generator
# Records test results with environment info (commit, user, hostname)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPORT_DIR="${PROJECT_ROOT}/tests/reports"
PM_BIN="${PROJECT_ROOT}/tools/pm/bin/pm"

# Create reports directory
mkdir -p "$REPORT_DIR"

# Generate timestamp
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REPORT_FILE="${REPORT_DIR}/test-report_${TIMESTAMP}.md"

# Get environment info
GIT_COMMIT=$(git -C "$PROJECT_ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH=$(git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
USERNAME=$(whoami)
HOSTNAME=$(hostname)
OS_INFO=$(uname -s -r)

# Colors for terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counters
TOTAL=0
PASSED=0
FAILED=0

# Test result logging
test_result() {
    local name="$1"
    local status="$2"
    local details="$3"
    
    TOTAL=$((TOTAL + 1))
    
    if [[ "$status" == "PASS" ]]; then
        PASSED=$((PASSED + 1))
        echo -e "  ${GREEN}[PASS]${NC} $name"
        echo "| $name | PASS | $details |" >> "$REPORT_FILE"
    else
        FAILED=$((FAILED + 1))
        echo -e "  ${RED}[FAIL]${NC} $name"
        echo "| $name | FAIL | $details |" >> "$REPORT_FILE"
    fi
}

# Start report
cat > "$REPORT_FILE" << EOF
# Test Report

## Environment

| Item | Value |
|------|-------|
| Date | $(date "+%Y-%m-%d %H:%M:%S") |
| User | ${USERNAME}@${HOSTNAME} |
| OS | ${OS_INFO} |
| Git Commit | ${GIT_COMMIT} |
| Git Branch | ${GIT_BRANCH} |

## Configuration

\`\`\`
$("$PM_BIN" config show 2>&1)
\`\`\`

## Provider Setup

\`\`\`
$("$PM_BIN" provider show 2>&1)
\`\`\`

## Test Results

| Test | Status | Details |
|------|--------|---------|
EOF

echo "=========================================="
echo "Test Report Generator"
echo "=========================================="
echo "User: ${USERNAME}@${HOSTNAME}"
echo "Commit: ${GIT_COMMIT} (${GIT_BRANCH})"
echo ""

# ============================================================
# API Connection Tests
# ============================================================
echo "--- API Connection Tests ---"

# GitHub API
output=$("$PM_BIN" github me 2>&1) || true
if echo "$output" | grep -q "Username:"; then
    test_result "GitHub API" "PASS" "Connected"
else
    test_result "GitHub API" "FAIL" "Connection failed"
fi

# GitLab API
output=$("$PM_BIN" gitlab me 2>&1) || true
if echo "$output" | grep -q "Username:"; then
    test_result "GitLab API" "PASS" "Connected"
else
    test_result "GitLab API" "FAIL" "Connection failed"
fi

# JIRA API
output=$("$PM_BIN" jira me 2>&1) || true
if echo "$output" | grep -q "Name:"; then
    test_result "JIRA API" "PASS" "Connected"
else
    test_result "JIRA API" "FAIL" "Connection failed"
fi

# ============================================================
# Unified Command Tests
# ============================================================
echo ""
echo "--- Unified Command Tests ---"

# pm issue list
output=$("$PM_BIN" issue list --limit 3 2>&1) || true
if echo "$output" | grep -qE "(KEY|Total:|No issues|error)"; then
    if echo "$output" | grep -q "ERROR"; then
        test_result "pm issue list" "FAIL" "Error occurred"
    else
        test_result "pm issue list" "PASS" "Listed issues"
    fi
else
    test_result "pm issue list" "FAIL" "Unexpected output"
fi

# pm review list
output=$("$PM_BIN" review list --limit 3 2>&1) || true
if echo "$output" | grep -qE "(#|!|No merge|No pull|error)"; then
    if echo "$output" | grep -q "ERROR"; then
        test_result "pm review list" "FAIL" "Error occurred"
    else
        test_result "pm review list" "PASS" "Listed reviews"
    fi
else
    test_result "pm review list" "FAIL" "Unexpected output"
fi

# pm provider show
output=$("$PM_BIN" provider show 2>&1) || true
if echo "$output" | grep -q "Provider Configuration"; then
    test_result "pm provider show" "PASS" "Shows providers"
else
    test_result "pm provider show" "FAIL" "Failed to show"
fi

# ============================================================
# Platform-specific Tests
# ============================================================
echo ""
echo "--- Platform-specific Tests ---"

# GitHub issue list
output=$("$PM_BIN" github issue list --limit 3 2>&1) || true
if echo "$output" | grep -qE "(#|No issues)"; then
    test_result "pm github issue list" "PASS" "Works"
else
    test_result "pm github issue list" "FAIL" "Failed"
fi

# GitLab issue list
output=$("$PM_BIN" gitlab issue list --limit 3 2>&1) || true
if echo "$output" | grep -qE "(#|No issues)"; then
    test_result "pm gitlab issue list" "PASS" "Works"
else
    test_result "pm gitlab issue list" "FAIL" "Failed"
fi

# GitHub PR list
output=$("$PM_BIN" github pr list --limit 3 2>&1) || true
if echo "$output" | grep -qE "(#|No pull)"; then
    test_result "pm github pr list" "PASS" "Works"
else
    test_result "pm github pr list" "FAIL" "Failed"
fi

# GitLab MR list
output=$("$PM_BIN" gitlab mr list --limit 3 2>&1) || true
if echo "$output" | grep -qE "(!|No merge)"; then
    test_result "pm gitlab mr list" "PASS" "Works"
else
    test_result "pm gitlab mr list" "FAIL" "Failed"
fi

# JIRA issue list
output=$("$PM_BIN" jira issue list --limit 3 2>&1) || true
if echo "$output" | grep -qE "(KEY|Total:|No issues)"; then
    test_result "pm jira issue list" "PASS" "Works"
else
    test_result "pm jira issue list" "FAIL" "Failed"
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Total:  $TOTAL"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"

# Add summary to report
cat >> "$REPORT_FILE" << EOF

## Summary

| Metric | Value |
|--------|-------|
| Total | $TOTAL |
| Passed | $PASSED |
| Failed | $FAILED |
| Success Rate | $(( PASSED * 100 / TOTAL ))% |

---
Generated by \`tests/test-report.sh\`
EOF

echo ""
echo "Report saved: $REPORT_FILE"

# Exit with error if any test failed
[[ $FAILED -eq 0 ]]
