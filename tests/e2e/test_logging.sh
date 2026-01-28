#!/bin/bash
# Logging E2E Test
# Tests the logging system including worktree log separation
#
# Tests:
#   1. Basic logging (log_init, log_cmd_start, log_cmd_end)
#   2. Workflow logging (log_workflow_start, log_skill_start, etc.)
#   3. Log file location detection
#   4. Worktree logging (symlink + separate subdirectories)
#   5. Log query functions
#   6. Expected log format validation
#
# Usage:
#   ./test_logging.sh              # Run all tests
#   ./test_logging.sh --verbose    # Show all log output
#
# This test runs entirely in Docker without external dependencies.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_CONTEXT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Options
VERBOSE=false
[[ "$1" == "--verbose" ]] && VERBOSE=true

# Colors (disabled in non-tty)
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

# Counters
TOTAL=0
PASSED=0
FAILED=0

test_ok() {
    echo -e "  ${GREEN}[OK]${NC} $1"
    ((TOTAL++)) || true
    ((PASSED++)) || true
}

test_ng() {
    echo -e "  ${RED}[NG]${NC} $1"
    ((TOTAL++)) || true
    ((FAILED++)) || true
}

section() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
}

debug() {
    if [[ "$VERBOSE" == "true" ]]; then echo -e "  ${YELLOW}[>>]${NC} $1"; fi
}

# =============================================================================
# Environment Detection
# =============================================================================

detect_env() {
    local env_summary=""
    
    # [D] Docker
    if [[ -f "/.dockerenv" ]] || grep -q docker /proc/1/cgroup 2>/dev/null; then
        env_summary+="[D] "
    fi
    
    # [G] Git
    if command -v git &>/dev/null; then
        local git_ver=$(git --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
        env_summary+="[G:$git_ver] "
    fi
    
    # [B] Bash
    env_summary+="[B:${BASH_VERSION%%(*}] "
    
    # [J] jq
    if command -v jq &>/dev/null; then
        local jq_ver=$(jq --version 2>/dev/null | grep -oE '[0-9.]+' | head -1)
        env_summary+="[J:$jq_ver] "
    fi
    
    # [C] curl
    if command -v curl &>/dev/null; then
        env_summary+="[C] "
    fi
    
    echo "$env_summary"
}

# ============================================
# Setup Test Environment
# ============================================

section "Logging E2E Tests"

# Print environment summary
ENV_INFO=$(detect_env)
echo "ENV: ${ENV_INFO}"
echo "SRC: ${AGENT_CONTEXT_DIR}"

# Create test workspace (use /workspace in Docker, /tmp locally)
if [[ -d "/workspace" && -w "/workspace" ]]; then
    TEST_WORKSPACE="/workspace/logging-test-$$"
else
    TEST_WORKSPACE="/tmp/logging-test-$$"
fi
mkdir -p "$TEST_WORKSPACE"
cd "$TEST_WORKSPACE"

# Initialize git repo
git init --quiet
git commit --allow-empty -m "Initial commit" --quiet

# Create .context directory structure
mkdir -p .context/logs

debug "Test workspace: $TEST_WORKSPACE"

# Source logging library
source "${AGENT_CONTEXT_DIR}/tools/agent/lib/logging.sh" 2>&1

# ============================================
# Test 1: Basic CLI Logging
# ============================================

section "1. Basic CLI Logging"

# Test log_cmd_start
log_cmd_start "agnt-c test command"
sleep 0.1

if [[ -f ".context/logs/agent.log" ]]; then
    test_ok "agent.log created"
else
    test_ng "agent.log not created"
fi

# Check log content
if grep -q "CMD: agnt-c test command" .context/logs/agent.log 2>/dev/null; then
    test_ok "log_cmd_start writes CMD entry"
else
    test_ng "log_cmd_start did not write CMD entry"
fi

# Check PID in log
if grep -q "PID:$$" .context/logs/agent.log 2>/dev/null; then
    test_ok "PID included in log"
else
    test_ng "PID not included in log"
fi

# Check branch in log
if grep -q "branch:" .context/logs/agent.log 2>/dev/null; then
    test_ok "Branch included in log"
else
    test_ng "Branch not included in log"
fi

# Test log_cmd_end
log_cmd_end 0 "success"

if grep -q "EXIT: 0 (success)" .context/logs/agent.log 2>/dev/null; then
    test_ok "log_cmd_end writes EXIT entry"
else
    test_ng "log_cmd_end did not write EXIT entry"
fi

# Test log_info, log_warn, log_error
log_info "Test info message"
log_warn "Test warning message"
log_error "Test error message"

if grep -q "INFO: Test info message" .context/logs/agent.log 2>/dev/null; then
    test_ok "log_info writes INFO entry"
else
    test_ng "log_info did not write INFO entry"
fi

if grep -q "WARN: Test warning message" .context/logs/agent.log 2>/dev/null; then
    test_ok "log_warn writes WARN entry"
else
    test_ng "log_warn did not write WARN entry"
fi

if grep -q "ERR: Test error message" .context/logs/agent.log 2>/dev/null; then
    test_ok "log_error writes ERR entry"
else
    test_ng "log_error did not write ERR entry"
fi

debug "agent.log content:"
[[ "$VERBOSE" == "true" ]] && cat .context/logs/agent.log

# ============================================
# Test 2: Workflow/Skill Logging
# ============================================

section "2. Workflow/Skill Logging"

export AGENT_TASK_ID="TEST-001"

log_workflow_start "developer/feature"

if [[ -f ".context/logs/workflow.log" ]]; then
    test_ok "workflow.log created"
else
    test_ng "workflow.log not created"
fi

if grep -q "WORKFLOW_START: developer/feature" .context/logs/workflow.log 2>/dev/null; then
    test_ok "log_workflow_start writes WORKFLOW_START"
else
    test_ng "log_workflow_start did not write WORKFLOW_START"
fi

if grep -q "TASK:TEST-001" .context/logs/workflow.log 2>/dev/null; then
    test_ok "TASK ID included in workflow log"
else
    test_ng "TASK ID not included in workflow log"
fi

if grep -q "session:" .context/logs/workflow.log 2>/dev/null; then
    test_ok "Session ID included in workflow log"
else
    test_ng "Session ID not included in workflow log"
fi

# Test skill logging
log_skill_start "analyze/parse-requirement"
sleep 1
log_skill_end "analyze/parse-requirement" "OK"

if grep -q "SKILL_START: analyze/parse-requirement" .context/logs/workflow.log 2>/dev/null; then
    test_ok "log_skill_start writes SKILL_START"
else
    test_ng "log_skill_start did not write SKILL_START"
fi

if grep -q "SKILL_END: analyze/parse-requirement - OK" .context/logs/workflow.log 2>/dev/null; then
    test_ok "log_skill_end writes SKILL_END"
else
    test_ng "log_skill_end did not write SKILL_END"
fi

# Test skill error and retry
log_skill_error "execute/write-code" "lint failed"
log_skill_retry "execute/write-code" 2

if grep -q "SKILL_ERROR: execute/write-code - lint failed" .context/logs/workflow.log 2>/dev/null; then
    test_ok "log_skill_error writes SKILL_ERROR"
else
    test_ng "log_skill_error did not write SKILL_ERROR"
fi

if grep -q "SKILL_RETRY: execute/write-code (attempt 2)" .context/logs/workflow.log 2>/dev/null; then
    test_ok "log_skill_retry writes SKILL_RETRY"
else
    test_ng "log_skill_retry did not write SKILL_RETRY"
fi

log_workflow_end "developer/feature" "completed"

if grep -q "WORKFLOW_END: developer/feature (completed)" .context/logs/workflow.log 2>/dev/null; then
    test_ok "log_workflow_end writes WORKFLOW_END"
else
    test_ng "log_workflow_end did not write WORKFLOW_END"
fi

debug "workflow.log content:"
[[ "$VERBOSE" == "true" ]] && cat .context/logs/workflow.log

# ============================================
# Test 3: Worktree Logging (Simulated)
# ============================================

section "3. Worktree Logging"

# Create simulated worktree structure
WORKTREE_DIR="$TEST_WORKSPACE/.worktrees/TASK-123"
mkdir -p "$WORKTREE_DIR"
cd "$WORKTREE_DIR"

# Initialize as git worktree (simulated)
git init --quiet 2>/dev/null || true
git commit --allow-empty -m "Worktree init" --quiet 2>/dev/null || true

# Create symlink to main .context
ln -sf "$TEST_WORKSPACE/.context" "$WORKTREE_DIR/.context"

if [[ -L "$WORKTREE_DIR/.context" ]]; then
    test_ok "Worktree .context symlink created"
else
    test_ng "Worktree .context symlink not created"
fi

# Verify symlink target
SYMLINK_TARGET=$(readlink "$WORKTREE_DIR/.context")
if [[ "$SYMLINK_TARGET" == "$TEST_WORKSPACE/.context" ]]; then
    test_ok "Symlink points to main .context"
else
    test_ng "Symlink target incorrect: $SYMLINK_TARGET"
fi

# Create worktree log directory
mkdir -p "$TEST_WORKSPACE/.context/TASK-123/logs"

# Write log from worktree context
export AGENT_TASK_ID="TASK-123"
cd "$WORKTREE_DIR"

# Manually write to worktree-specific log
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [PID:$$] [branch:feature/TASK-123] CMD: agnt-c dev start TASK-123" \
    >> "$TEST_WORKSPACE/.context/TASK-123/logs/agent.log"

if [[ -f "$TEST_WORKSPACE/.context/TASK-123/logs/agent.log" ]]; then
    test_ok "Worktree log file created in main/.context/TASK-123/"
else
    test_ng "Worktree log file not created"
fi

# Verify directory structure from main
cd "$TEST_WORKSPACE"
if [[ -d ".context/TASK-123/logs" ]]; then
    test_ok "Worktree logs visible from main"
else
    test_ng "Worktree logs not visible from main"
fi

# List all log locations
debug "Log structure:"
if [[ "$VERBOSE" == "true" ]]; then
    find .context -name "*.log" -type f
fi

# ============================================
# Test 4: Multiple Worktrees
# ============================================

section "4. Multiple Worktrees"

# Create second worktree
WORKTREE2_DIR="$TEST_WORKSPACE/.worktrees/TASK-456"
mkdir -p "$WORKTREE2_DIR"
ln -sf "$TEST_WORKSPACE/.context" "$WORKTREE2_DIR/.context"
mkdir -p "$TEST_WORKSPACE/.context/TASK-456/logs"

# Write logs for second worktree
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [PID:$$] [branch:feature/TASK-456] CMD: agnt-c dev start TASK-456" \
    >> "$TEST_WORKSPACE/.context/TASK-456/logs/agent.log"

# Verify both worktree logs exist
if [[ -f "$TEST_WORKSPACE/.context/TASK-123/logs/agent.log" ]] && \
   [[ -f "$TEST_WORKSPACE/.context/TASK-456/logs/agent.log" ]]; then
    test_ok "Multiple worktree logs created"
else
    test_ng "Multiple worktree logs not created"
fi

# Test grep across all logs
GREP_RESULT=$(grep -r "CMD:" "$TEST_WORKSPACE/.context" 2>/dev/null | wc -l)
if [[ "$GREP_RESULT" -ge 3 ]]; then
    test_ok "grep -r finds logs across all worktrees ($GREP_RESULT entries)"
else
    test_ng "grep -r did not find expected logs ($GREP_RESULT entries)"
fi

# ============================================
# Test 5: Log Query Functions
# ============================================

section "5. Log Query Functions"

cd "$TEST_WORKSPACE"

# Test log_path
AGENT_LOG_PATH=$(log_path)
if [[ "$AGENT_LOG_PATH" == *"agent.log" ]]; then
    test_ok "log_path returns agent.log path"
else
    test_ng "log_path returned unexpected: $AGENT_LOG_PATH"
fi

WORKFLOW_LOG_PATH=$(log_path --workflow)
if [[ "$WORKFLOW_LOG_PATH" == *"workflow.log" ]]; then
    test_ok "log_path --workflow returns workflow.log path"
else
    test_ng "log_path --workflow returned unexpected: $WORKFLOW_LOG_PATH"
fi

# Test log_show (basic)
LOG_OUTPUT=$(log_show 10 2>/dev/null)
if [[ -n "$LOG_OUTPUT" ]]; then
    test_ok "log_show returns log content"
else
    test_ng "log_show returned empty"
fi

# ============================================
# Test 6: Logged Exec Wrapper
# ============================================

section "6. Logged Exec Wrapper"

cd "$TEST_WORKSPACE"

# Test logged_exec
logged_exec "echo test" echo "hello world" >/dev/null 2>&1

if grep -q "CMD: echo test: echo hello world" .context/logs/agent.log 2>/dev/null; then
    test_ok "logged_exec logs command"
else
    test_ng "logged_exec did not log command"
fi

# Test logged_exec with failing command
logged_exec "false command" false 2>/dev/null || true

if grep -q "EXIT: 1" .context/logs/agent.log 2>/dev/null; then
    test_ok "logged_exec logs failed command exit code"
else
    test_ng "logged_exec did not log failed command"
fi

# ============================================
# Test 7: Log Disable/Enable
# ============================================

section "7. Log Enable/Disable"

cd "$TEST_WORKSPACE"

# Count current logs
BEFORE_COUNT=$(wc -l < .context/logs/agent.log)

# Disable logging
export AGENT_LOGGING=0
log_info "This should not be logged"

AFTER_COUNT=$(wc -l < .context/logs/agent.log)

if [[ "$BEFORE_COUNT" -eq "$AFTER_COUNT" ]]; then
    test_ok "AGENT_LOGGING=0 disables logging"
else
    test_ng "AGENT_LOGGING=0 did not disable logging"
fi

# Re-enable
export AGENT_LOGGING=1
log_info "This should be logged"

FINAL_COUNT=$(wc -l < .context/logs/agent.log)

if [[ "$FINAL_COUNT" -gt "$AFTER_COUNT" ]]; then
    test_ok "AGENT_LOGGING=1 enables logging"
else
    test_ng "AGENT_LOGGING=1 did not enable logging"
fi

# ============================================
# Test 8: Expected Log Format Validation
# ============================================

section "8. Log Format Validation"

cd "$TEST_WORKSPACE"

# Define expected log patterns
EXPECTED_CLI_PATTERN='^\[.+\] \[PID:[0-9]+\] \[branch:.+\] (CMD|EXIT|INFO|WARN|ERR): .+'
EXPECTED_WORKFLOW_PATTERN='^\[.+\] \[TASK:.+\] \[session:[a-f0-9]+\] (WORKFLOW_START|WORKFLOW_END|SKILL_START|SKILL_END|SKILL_ERROR|SKILL_RETRY|SKILL_SKIP): .+'

# Validate CLI log format
CLI_LINES=$(wc -l < .context/logs/agent.log | tr -d ' ')
CLI_VALID=$(grep -cE "$EXPECTED_CLI_PATTERN" .context/logs/agent.log 2>/dev/null || echo "0")

if [[ "$CLI_VALID" -gt 0 ]]; then
    test_ok "CLI log format valid ($CLI_VALID/$CLI_LINES lines match)"
else
    test_ng "CLI log format invalid"
fi

# Validate Workflow log format
WF_LINES=$(wc -l < .context/logs/workflow.log | tr -d ' ')
WF_VALID=$(grep -cE "$EXPECTED_WORKFLOW_PATTERN" .context/logs/workflow.log 2>/dev/null || echo "0")

if [[ "$WF_VALID" -gt 0 ]]; then
    test_ok "Workflow log format valid ($WF_VALID/$WF_LINES lines match)"
else
    test_ng "Workflow log format invalid"
fi

# Show sample log entries
debug "Sample CLI log:"
if [[ "$VERBOSE" == "true" ]]; then
    head -3 .context/logs/agent.log | while read line; do
        echo "    $line"
    done
fi

debug "Sample Workflow log:"
if [[ "$VERBOSE" == "true" ]]; then
    head -3 .context/logs/workflow.log | while read line; do
        echo "    $line"
    done
fi

# ============================================
# Cleanup
# ============================================

section "Cleanup"

cd /
rm -rf "$TEST_WORKSPACE"
echo "  Removed test workspace"

# ============================================
# Summary
# ============================================

echo ""
echo "=========================================="
echo "Logging E2E Test Results"
echo "=========================================="
echo "Total: ${TOTAL} | OK: ${PASSED} | NG: ${FAILED}"
echo ""

if [[ "$FAILED" -eq 0 ]]; then
    echo "[OK] All logging tests passed"
    exit 0
else
    echo "[NG] Some logging tests failed"
    exit 1
fi
