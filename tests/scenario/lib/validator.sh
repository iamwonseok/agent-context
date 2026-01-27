#!/bin/bash
# Scenario Result Validator
# Validates command outputs against expected results

# Validate command output
# Usage: validate_output <actual> <expected_pattern>
# Returns: 0 if matches, 1 if not
validate_output() {
    local actual="$1"
    local expected="$2"
    
    # Empty expected means any output is OK
    if [ -z "$expected" ]; then
        return 0
    fi
    
    # Check for exact match first
    if [ "$actual" = "$expected" ]; then
        return 0
    fi
    
    # Check for pattern match (grep-style)
    if echo "$actual" | grep -qE "$expected" 2>/dev/null; then
        return 0
    fi
    
    # Check for substring match
    if [[ "$actual" == *"$expected"* ]]; then
        return 0
    fi
    
    return 1
}

# Validate exit code
# Usage: validate_exit_code <actual> <expected>
validate_exit_code() {
    local actual="$1"
    local expected="${2:-0}"
    
    [ "$actual" -eq "$expected" ]
}

# Validate file exists
# Usage: validate_file_exists <path>
validate_file_exists() {
    local path="$1"
    [ -f "$path" ]
}

# Validate directory exists
# Usage: validate_dir_exists <path>
validate_dir_exists() {
    local path="$1"
    [ -d "$path" ]
}

# Validate output contains all patterns
# Usage: validate_contains_all <output> <pattern1> [pattern2] ...
validate_contains_all() {
    local output="$1"
    shift
    
    for pattern in "$@"; do
        if ! echo "$output" | grep -qE "$pattern" 2>/dev/null; then
            return 1
        fi
    done
    
    return 0
}

# Validate output contains any pattern
# Usage: validate_contains_any <output> <pattern1> [pattern2] ...
validate_contains_any() {
    local output="$1"
    shift
    
    for pattern in "$@"; do
        if echo "$output" | grep -qE "$pattern" 2>/dev/null; then
            return 0
        fi
    done
    
    return 1
}

# Parse expected result string and validate
# Usage: validate_expected <output> <exit_code> <expected_string>
# Expected string formats:
#   "success" - exit code 0
#   "fail" - exit code non-zero
#   "contains: pattern" - output contains pattern
#   "file: path" - file exists
#   "exit: N" - specific exit code
validate_expected() {
    local output="$1"
    local exit_code="$2"
    local expected="$3"
    
    # Normalize expected string
    expected=$(echo "$expected" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    case "$expected" in
        success|Success|OK|ok)
            validate_exit_code "$exit_code" 0
            ;;
        fail|Fail|error|Error)
            ! validate_exit_code "$exit_code" 0
            ;;
        contains:*)
            local pattern="${expected#contains:}"
            pattern=$(echo "$pattern" | sed 's/^[[:space:]]*//')
            validate_output "$output" "$pattern"
            ;;
        file:*)
            local path="${expected#file:}"
            path=$(echo "$path" | sed 's/^[[:space:]]*//')
            validate_file_exists "$path"
            ;;
        dir:*)
            local path="${expected#dir:}"
            path=$(echo "$path" | sed 's/^[[:space:]]*//')
            validate_dir_exists "$path"
            ;;
        exit:*)
            local code="${expected#exit:}"
            code=$(echo "$code" | sed 's/^[[:space:]]*//')
            validate_exit_code "$exit_code" "$code"
            ;;
        *)
            # Default: check if output contains the expected string
            validate_output "$output" "$expected"
            ;;
    esac
}

# Generate validation report
# Usage: generate_report <scenario_name> <passed> <failed> <skipped>
generate_report() {
    local name="$1"
    local passed="$2"
    local failed="$3"
    local skipped="$4"
    local total=$((passed + failed + skipped))
    
    echo ""
    echo "=========================================="
    echo "Scenario: ${name}"
    echo "=========================================="
    echo "Total:   ${total}"
    echo "Passed:  ${passed}"
    echo "Failed:  ${failed}"
    echo "Skipped: ${skipped}"
    echo ""
    
    if [ "$failed" -eq 0 ]; then
        if [ "$skipped" -gt 0 ]; then
            echo "Result: PASS (with skips)"
            return 0
        else
            echo "Result: PASS"
            return 0
        fi
    else
        echo "Result: FAIL"
        return 1
    fi
}

# Create JUnit XML test result
# Usage: create_junit_result <scenario_name> <test_name> <status> [message] [duration]
create_junit_result() {
    local scenario="$1"
    local test_name="$2"
    local status="$3"
    local message="${4:-}"
    local duration="${5:-0}"
    
    echo "  <testcase classname=\"scenario.${scenario}\" name=\"${test_name}\" time=\"${duration}\">"
    
    case "$status" in
        pass)
            # No additional elements needed
            ;;
        fail)
            echo "    <failure message=\"${message}\"/>"
            ;;
        skip)
            echo "    <skipped message=\"${message}\"/>"
            ;;
    esac
    
    echo "  </testcase>"
}
