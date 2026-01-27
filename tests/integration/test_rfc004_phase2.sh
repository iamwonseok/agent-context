#!/bin/bash
# RFC-004 Phase 2: Feedback Loops Layer Tests
# Tests llm_context.md, questions.md, quick-summary.md functionality

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$PROJECT_ROOT/tools/agent/lib"

# Source libraries
source "$LIB_DIR/context.sh"
source "$LIB_DIR/markdown.sh"

# Test results
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helpers
pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "[OK] $1"
}

fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "[NG] $1"
}

run_test() {
    TESTS_RUN=$((TESTS_RUN + 1))
    echo ">> Test $TESTS_RUN: $1"
}

# Setup test environment
setup_test_env() {
    TEST_DIR=$(mktemp -d)
    export TEST_CONTEXT="$TEST_DIR/.context/TEST-123"
    mkdir -p "$TEST_CONTEXT"
    echo "Test environment: $TEST_DIR"
}

# Cleanup test environment
cleanup_test_env() {
    if [[ -n "$TEST_DIR" ]] && [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# ==============================================================================
# Test 1: llm_context.md creation
# ==============================================================================
test_llm_context_creation() {
    run_test "llm_context.md creation"
    
    create_llm_context "$TEST_CONTEXT" "TEST-123"
    
    if [[ -f "$TEST_CONTEXT/llm_context.md" ]]; then
        pass "llm_context.md created"
    else
        fail "llm_context.md not created"
        return 1
    fi
    
    # Check content
    if grep -q "Task: TEST-123" "$TEST_CONTEXT/llm_context.md"; then
        pass "Task ID substituted correctly"
    else
        fail "Task ID not substituted"
    fi
    
    if grep -q "## Technical Decisions" "$TEST_CONTEXT/llm_context.md"; then
        pass "Template structure preserved"
    else
        fail "Template structure missing"
    fi
}

# ==============================================================================
# Test 2: Add technical decision
# ==============================================================================
test_add_technical_decision() {
    run_test "Add technical decision to llm_context.md"
    
    # Ensure llm_context.md exists
    create_llm_context "$TEST_CONTEXT" "TEST-123" 2>/dev/null || true
    
    add_technical_decision "$TEST_CONTEXT" \
        "Use PostgreSQL" \
        "Selected PostgreSQL for JSONB support" \
        "Better JSON handling than MySQL"
    
    if grep -q "Decision: Use PostgreSQL" "$TEST_CONTEXT/llm_context.md"; then
        pass "Technical decision added"
    else
        fail "Technical decision not added"
    fi
    
    if grep -q "Better JSON handling" "$TEST_CONTEXT/llm_context.md"; then
        pass "Rationale included"
    else
        fail "Rationale missing"
    fi
}

# ==============================================================================
# Test 3: questions.md creation
# ==============================================================================
test_questions_creation() {
    run_test "questions.md creation"
    
    create_questions "$TEST_CONTEXT" "TEST-123"
    
    if [[ -f "$TEST_CONTEXT/questions.md" ]]; then
        pass "questions.md created"
    else
        fail "questions.md not created"
        return 1
    fi
    
    # Check structure
    if grep -q "## High Priority Questions" "$TEST_CONTEXT/questions.md"; then
        pass "Questions structure present"
    else
        fail "Questions structure missing"
    fi
    
    if grep -q "Status: pending_questions" "$TEST_CONTEXT/questions.md"; then
        pass "Initial status set correctly"
    else
        fail "Initial status incorrect"
    fi
}

# ==============================================================================
# Test 4: Add question
# ==============================================================================
test_add_question() {
    run_test "Add question to questions.md"
    
    # Ensure questions.md exists
    create_questions "$TEST_CONTEXT" "TEST-123" 2>/dev/null || true
    
    add_question "$TEST_CONTEXT" \
        "Architecture" \
        "Database Choice" \
        "High" \
        "Need to store JSON data" \
        "Should we use PostgreSQL or MongoDB?"
    
    if grep -q "Q1:.*Database Choice" "$TEST_CONTEXT/questions.md"; then
        pass "Question added with correct numbering"
    else
        fail "Question not added correctly"
    fi
    
    if grep -q "Priority: High" "$TEST_CONTEXT/questions.md"; then
        pass "Priority set correctly"
    else
        fail "Priority not set"
    fi
}

# ==============================================================================
# Test 5: Process questions
# ==============================================================================
test_process_questions() {
    run_test "Process answered questions"
    
    # Create questions.md with a mock answered question
    create_questions "$TEST_CONTEXT" "TEST-123" 2>/dev/null || true
    
    # Simulate an answered question (simplified)
    echo "**Answer**: Use PostgreSQL for JSONB support" >> "$TEST_CONTEXT/questions.md"
    
    process_questions "$TEST_CONTEXT"
    
    if grep -q "Status: answered" "$TEST_CONTEXT/questions.md"; then
        pass "Status updated to answered"
    else
        fail "Status not updated"
    fi
}

# ==============================================================================
# Test 6: mode.txt creation and update
# ==============================================================================
test_mode_file() {
    run_test "mode.txt creation and update"
    
    create_mode_file "$TEST_CONTEXT" "planning"
    
    if [[ -f "$TEST_CONTEXT/mode.txt" ]]; then
        pass "mode.txt created"
    else
        fail "mode.txt not created"
        return 1
    fi
    
    local mode
    mode=$(get_current_mode "$TEST_CONTEXT")
    
    if [[ "$mode" == "planning" ]]; then
        pass "Initial mode set correctly"
    else
        fail "Initial mode incorrect: $mode"
    fi
    
    # Update mode
    update_mode "$TEST_CONTEXT" "implementation"
    mode=$(get_current_mode "$TEST_CONTEXT")
    
    if [[ "$mode" == "implementation" ]]; then
        pass "Mode updated correctly"
    else
        fail "Mode update failed: $mode"
    fi
}

# ==============================================================================
# Test 7: quick-summary.md generation
# ==============================================================================
test_quick_summary_generation() {
    run_test "quick-summary.md generation"
    
    # Setup git repository
    cd "$TEST_DIR"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create some commits
    echo "test" > test.txt
    git add test.txt
    git commit -q -m "Initial commit"
    
    git checkout -b main -q 2>/dev/null || true
    echo "feature" > feature.txt
    git add feature.txt
    git commit -q -m "feat: add feature"
    
    # Create llm_context.md for technical decisions
    create_llm_context "$TEST_CONTEXT" "TEST-123" 2>/dev/null || true
    add_technical_decision "$TEST_CONTEXT" \
        "Test Decision" \
        "Use test framework" \
        "Better testing"
    
    # Generate quick summary
    generate_quick_summary "$TEST_CONTEXT"
    
    if [[ -f "$TEST_CONTEXT/quick-summary.md" ]]; then
        pass "quick-summary.md created"
    else
        fail "quick-summary.md not created"
        return 1
    fi
    
    # Check content
    if grep -q "## Task: TEST-123" "$TEST_CONTEXT/quick-summary.md"; then
        pass "Task ID in summary"
    else
        fail "Task ID missing from summary"
    fi
    
    if grep -q "## Changes at a Glance" "$TEST_CONTEXT/quick-summary.md"; then
        pass "Summary structure present"
    else
        fail "Summary structure missing"
    fi
}

# ==============================================================================
# Main test execution
# ==============================================================================
echo "=========================================="
echo "RFC-004 Phase 2: Feedback Loops Tests"
echo "=========================================="
echo ""

# Setup
setup_test_env
trap cleanup_test_env EXIT

# Run all tests
test_llm_context_creation
echo ""
test_add_technical_decision
echo ""
test_questions_creation
echo ""
test_add_question
echo ""
test_process_questions
echo ""
test_mode_file
echo ""
test_quick_summary_generation
echo ""

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Total:  $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo "=========================================="

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "[OK] All tests passed"
    exit 0
else
    echo "[NG] Some tests failed"
    exit 1
fi
