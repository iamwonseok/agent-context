#!/bin/bash
# Test Verification Script
# Run project tests and verify results

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Default values
COVERAGE_THRESHOLD=${TEST_COVERAGE_THRESHOLD:-80}
BRANCH_COVERAGE_THRESHOLD=${TEST_BRANCH_COVERAGE_THRESHOLD:-70}
FAIL_ON_COVERAGE=${TEST_FAIL_ON_COVERAGE:-true}
OUTPUT_DIR="${PROJECT_ROOT}/test-results"

# Create output directory
mkdir -p "${OUTPUT_DIR}"

echo "=========================================="
echo "Test Verification"
echo "=========================================="
echo "Project Root: ${PROJECT_ROOT}"
echo "Output Dir: ${OUTPUT_DIR}"
echo ""

# Detect project type
detect_project_type() {
    if [ -f "${PROJECT_ROOT}/pytest.ini" ] || [ -f "${PROJECT_ROOT}/pyproject.toml" ] || [ -f "${PROJECT_ROOT}/setup.py" ]; then
        echo "python"
    elif [ -f "${PROJECT_ROOT}/package.json" ]; then
        echo "nodejs"
    elif [ -f "${PROJECT_ROOT}/CMakeLists.txt" ]; then
        echo "cmake"
    elif [ -f "${PROJECT_ROOT}/Makefile" ]; then
        echo "make"
    else
        echo "unknown"
    fi
}

# Run Python tests
run_python_tests() {
    echo "Running Python tests with pytest..."

    cd "${PROJECT_ROOT}"

    pytest \
        --junit-xml="${OUTPUT_DIR}/junit.xml" \
        --cov=src \
        --cov-report=html:"${OUTPUT_DIR}/coverage" \
        --cov-report=xml:"${OUTPUT_DIR}/coverage.xml" \
        --cov-report=term-missing \
        tests/ \
        2>&1 | tee "${OUTPUT_DIR}/test-output.txt"

    return ${PIPESTATUS[0]}
}

# Run Node.js tests
run_nodejs_tests() {
    echo "Running Node.js tests..."

    cd "${PROJECT_ROOT}"

    npm test -- \
        --coverage \
        --coverageDirectory="${OUTPUT_DIR}/coverage" \
        --reporters=default \
        --reporters=jest-junit \
        2>&1 | tee "${OUTPUT_DIR}/test-output.txt"

    return ${PIPESTATUS[0]}
}

# Run CMake tests
run_cmake_tests() {
    echo "Running CMake tests..."

    cd "${PROJECT_ROOT}/build"

    ctest \
        --output-junit "${OUTPUT_DIR}/junit.xml" \
        --output-on-failure \
        2>&1 | tee "${OUTPUT_DIR}/test-output.txt"

    return ${PIPESTATUS[0]}
}

# Print summary
print_summary() {
    local test_result=$1

    echo ""
    echo "=========================================="
    echo "Test Verification Summary"
    echo "=========================================="

    if [ -f "${OUTPUT_DIR}/junit.xml" ]; then
        # Parse JUnit XML (simple version)
        total=$(grep -oP 'tests="\K[0-9]+' "${OUTPUT_DIR}/junit.xml" | head -1)
        failures=$(grep -oP 'failures="\K[0-9]+' "${OUTPUT_DIR}/junit.xml" | head -1)
        errors=$(grep -oP 'errors="\K[0-9]+' "${OUTPUT_DIR}/junit.xml" | head -1)
        skipped=$(grep -oP 'skipped="\K[0-9]+' "${OUTPUT_DIR}/junit.xml" | head -1)

        passed=$((total - failures - errors - skipped))

        echo "Total Tests:    ${total:-0}"
        echo "Passed:         ${passed:-0}"
        echo "Failed:         ${failures:-0}"
        echo "Skipped:        ${skipped:-0}"
    fi

    echo ""
    echo "Quality Gates:"

    if [ "${test_result}" -eq 0 ]; then
        echo "  (v) All tests pass"
    else
        echo "  (x) Some tests failed"
    fi

    echo ""
    if [ "${test_result}" -eq 0 ]; then
        echo "Status: PASSED"
        echo "=========================================="
        echo ""
        echo "Next: Run code-review skill"
    else
        echo "Status: FAILED"
        echo "=========================================="
        echo ""
        echo "Fix failing tests before proceeding."
    fi
}

# Main
main() {
    local project_type
    project_type=$(detect_project_type)

    echo "Detected project type: ${project_type}"
    echo ""

    local test_result=0

    case "${project_type}" in
        python)
            run_python_tests || test_result=$?
            ;;
        nodejs)
            run_nodejs_tests || test_result=$?
            ;;
        cmake)
            run_cmake_tests || test_result=$?
            ;;
        *)
            echo "Unknown project type. Please configure test command."
            exit 1
            ;;
    esac

    print_summary "${test_result}"

    exit "${test_result}"
}

main "$@"
