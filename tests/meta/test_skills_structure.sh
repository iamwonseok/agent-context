#!/bin/bash
# Level 1: Skills Structure Validation
# Wrapper around existing skills test suite

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "=========================================="
echo "Level 1: Skills Validation"
echo "=========================================="
echo ""

# Run the existing comprehensive skills test
bash "${PROJECT_ROOT}/tests/unit/skills/test_skills.sh"

echo ""
echo "[LEVEL 1] Skills validation complete"
