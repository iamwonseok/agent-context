#!/bin/bash
# Demo: Sequential Logging System
# Shows how CLI, Skill, Workflow logging works together
#
# Usage:
#   bash tools/agent/examples/demo_logging.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Source logging library
source "${PROJECT_ROOT}/tools/agent/lib/logging.sh" 2>/dev/null

echo "=========================================="
echo "Demo: Sequential Logging System"
echo "=========================================="
echo ""

# =============================================================================
# Example 1: CLI Level - Direct command execution
# =============================================================================
echo "=== Example 1: CLI Level ==="
echo ""

seq_log_start "Demo: Show CLI level logging"
seq_log_workflow_begin "demo/cli-example" "CLI: bash demo_logging.sh"

seq_log_skill_begin "demo/check-environment"
exec_cmd ls -la README.md
exec_cmd git status --short
exec_cmd head -1 .cursorrules
seq_log_add_output ".context/logs/"
seq_log_skill_end "demo/check-environment" "OK"

seq_log_workflow_end "demo/cli-example" "OK" "1/1 skills passed"
log_file=$(seq_log_end "OK")

echo ""
echo "--- Generated Log File ---"
cat "$log_file"
echo ""

# =============================================================================
# Example 2: Skill Level - Simulating a skill execution
# =============================================================================
echo ""
echo "=== Example 2: Skill Level (analyze/parse-requirement simulation) ==="
echo ""

seq_log_start "Add user authentication feature"
seq_log_workflow_begin "developer/feature" '"Add user authentication" → matched "New feature request"'

# Skill: analyze/parse-requirement
seq_log_skill_begin "analyze/parse-requirement"
exec_cmd test -f README.md
exec_cmd grep -c "^#" README.md || true
seq_log_add_output "design/auth-feature.md"
seq_log_skill_end "analyze/parse-requirement" "OK"

# Skill: planning/design-solution
seq_log_skill_begin "planning/design-solution"
exec_cmd mkdir -p /tmp/demo-design
exec_cmd touch /tmp/demo-design/auth-plan.md
seq_log_add_output "design/auth-plan.md"
seq_log_skill_end "planning/design-solution" "OK"

# Skill: validate/run-tests (simulate failure)
seq_log_skill_begin "validate/run-tests"
exec_cmd echo "Running tests..."
# This will fail intentionally
exec_cmd test -f /tmp/nonexistent-file 2>/dev/null || true
seq_log_add_output "test-report.xml"
seq_log_skill_end "validate/run-tests" "NG"

seq_log_workflow_end "developer/feature" "NG" "2/3 skills passed"
log_file2=$(seq_log_end "NG")

echo ""
echo "--- Generated Log File ---"
cat "$log_file2"
echo ""

# =============================================================================
# Example 3: Tool Level - Showing tool execution
# =============================================================================
echo ""
echo "=== Example 3: Tool Level (tools/agent/lib/logging.sh) ==="
echo ""

seq_log_start "Initialize logging system"
seq_log_workflow_begin "tools/init" "CLI: agnt-c init"

seq_log_tool_begin "agent/lib/logging.sh"
exec_cmd test -f tools/agent/lib/logging.sh
exec_cmd head -5 tools/agent/lib/logging.sh
seq_log_tool_end "agent/lib/logging.sh" "OK"

seq_log_tool_begin "agent/lib/branch.sh"
exec_cmd test -f tools/agent/lib/branch.sh
seq_log_tool_end "agent/lib/branch.sh" "OK"

seq_log_workflow_end "tools/init" "OK" "2/2 tools loaded"
log_file3=$(seq_log_end "OK")

echo ""
echo "--- Generated Log File ---"
cat "$log_file3"
echo ""

# =============================================================================
# Summary
# =============================================================================
echo "=========================================="
echo "Summary: Generated Log Files"
echo "=========================================="
echo "1. CLI Example:      $log_file"
echo "2. Skill Example:    $log_file2"
echo "3. Tool Example:     $log_file3"
echo ""
echo "View all logs: ls -la .context/logs/"
