#!/bin/bash
# Unit Test Runner
# Runs all unit tests for agent-context framework

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "=========================================="
echo "Running All Unit Tests"
echo "=========================================="
echo "Project: ${PROJECT_ROOT}"
echo ""

# Skills structure tests
echo "[STAGE] Skills Framework Tests"
bash "${SCRIPT_DIR}/skills/test_skills.sh"

# Tools tests (if they exist in the future)
# if [ -f "${SCRIPT_DIR}/tools/test_tools.sh" ]; then
#     echo ""
#     echo "[STAGE] Tools Tests"
#     bash "${SCRIPT_DIR}/tools/test_tools.sh"
# fi

echo ""
echo "=========================================="
echo "All Unit Tests Passed!"
echo "=========================================="
