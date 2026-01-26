#!/bin/bash
# Meta-Validation Suite Runner
# Bottom-up validation: Skills -> Workflows -> .cursorrules

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Meta-Validation Suite (Bottom-up)"
echo "=========================================="
echo ""
echo "Running 3-level validation:"
echo "  Level 1: Skills structure"
echo "  Level 2: Workflows structure"
echo "  Level 3: .cursorrules validity"
echo ""

# Level 1: Skills
echo ""
echo "[LEVEL 1] Skills Validation"
echo "-------------------------------------------"
bash "${SCRIPT_DIR}/test_skills_structure.sh" || {
    echo ""
    echo "[FAIL] Level 1 failed. Cannot proceed to Level 2."
    echo "Fix skills issues first."
    exit 1
}

# Level 2: Workflows
echo ""
echo "[LEVEL 2] Workflows Validation"
echo "-------------------------------------------"
bash "${SCRIPT_DIR}/test_workflows_structure.sh" || {
    echo ""
    echo "[FAIL] Level 2 failed. Cannot proceed to Level 3."
    echo "Fix workflows issues first."
    exit 1
}

# Level 3: .cursorrules
echo ""
echo "[LEVEL 3] .cursorrules Validation"
echo "-------------------------------------------"
bash "${SCRIPT_DIR}/test_cursorrules.sh" || {
    echo ""
    echo "[FAIL] Level 3 failed."
    echo "Fix .cursorrules issues."
    exit 1
}

echo ""
echo "=========================================="
echo "All Meta-Validations Passed!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  Level 1: Skills structure     [PASS]"
echo "  Level 2: Workflows structure  [PASS]"
echo "  Level 3: .cursorrules         [PASS]"
echo ""
echo "Framework is consistent and valid."
