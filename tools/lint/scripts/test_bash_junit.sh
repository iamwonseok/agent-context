#!/bin/bash
# Test Bash scripts and output JUnit XML format
# Usage: ./test_bash_junit.sh > junit-bash.xml

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR="${SCRIPT_DIR}/../tests/bash"
PROJECT_ROOT="${SCRIPT_DIR}/../../.."

source "${SCRIPT_DIR}/junit_helper.sh"
source "${SCRIPT_DIR}/rules/bash_rules.sh"

PASS_COUNT=0
FAIL_COUNT=0
TEST_CASES=""
PASSED_RULES=""
FAILED_RULES=""
RESULT_FILE="${RESULT_FILE:-}"

# Test pass cases
for file in "${TEST_DIR}"/pass/*.sh; do
	if [[ -f "${file}" ]]; then
		filename=$(basename "${file}")
		rule_id=$(echo "${filename}" | grep -oE '^Bash-[0-9]+-[0-9]+' || echo "unknown")

		if check_bash_rule "${file}"; then
			TEST_CASES+="$(junit_pass "bash.pass" "${filename}" "0.01" "${CHECK_RESULT}")"$'\n'
			PASS_COUNT=$((PASS_COUNT + 1))
			PASSED_RULES+="${rule_id} (pass): ${filename}"$'\n'
			save_testcase_result "bash.pass" "${filename}" "PASS" "${RESULT_FILE}"
		else
			TEST_CASES+="$(junit_fail "bash.pass" "${filename}" "Expected to pass but found issues" "0.01" "${CHECK_RESULT}")"$'\n'
			FAIL_COUNT=$((FAIL_COUNT + 1))
			FAILED_RULES+="${rule_id} (pass): ${filename} - UNEXPECTED FAILURE"$'\n'
			save_testcase_result "bash.pass" "${filename}" "FAIL" "${RESULT_FILE}"
		fi
	fi
done

# Test fail cases
for file in "${TEST_DIR}"/fail/*.sh; do
	if [[ -f "${file}" ]]; then
		filename=$(basename "${file}")
		rule_id=$(echo "${filename}" | grep -oE '^Bash-[0-9]+-[0-9]+' || echo "unknown")

		if ! check_bash_rule "${file}"; then
			# NG detected - this is expected/intended
			output="${CHECK_RESULT}"
			if [[ "${output}" =~ ^\[NG\] ]]; then
				output="${output}"$'\n'"This Fail is intended."
			fi
			TEST_CASES+="$(junit_pass "bash.fail" "${filename}" "0.01" "${output}")"$'\n'
			PASS_COUNT=$((PASS_COUNT + 1))
			PASSED_RULES+="${rule_id} (fail): ${filename} - violation detected correctly"$'\n'
			save_testcase_result "bash.fail" "${filename}" "PASS" "${RESULT_FILE}"
		else
			TEST_CASES+="$(junit_fail "bash.fail" "${filename}" "Expected to detect issue but passed" "0.01" "${CHECK_RESULT}")"$'\n'
			FAIL_COUNT=$((FAIL_COUNT + 1))
			FAILED_RULES+="${rule_id} (fail): ${filename} - VIOLATION NOT DETECTED"$'\n'
			save_testcase_result "bash.fail" "${filename}" "FAIL" "${RESULT_FILE}"
		fi
	fi
done

TOTAL=$((PASS_COUNT + FAIL_COUNT))

# Print summary to stderr (using common function)
print_summary "Bash" "${TOTAL}" "${PASS_COUNT}" "${FAIL_COUNT}"

# Print detailed rules
{
	echo ""
	if [[ -n "${PASSED_RULES}" ]]; then
		echo "[PASSED RULES]"
		echo "${PASSED_RULES}"
	fi

	if [[ -n "${FAILED_RULES}" ]]; then
		echo "[FAILED RULES]"
		echo "${FAILED_RULES}"
	fi

	if [[ ${FAIL_COUNT} -eq 0 ]]; then
		echo "All tests passed!"
	else
		echo "Some tests failed. Check the JUnit XML for details."
	fi
	echo "=========================================="
} >&2

junit_testsuite "CodingConvention.Bash" "${TOTAL}" "${FAIL_COUNT}" "${TEST_CASES}" "1"
