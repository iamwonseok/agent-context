#!/bin/bash
# Test YAML and Dockerfile and output JUnit XML format
# Usage: ./test_yaml_junit.sh > junit-yaml.xml

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR="${SCRIPT_DIR}/../tests/yaml"
PROJECT_ROOT="${SCRIPT_DIR}/../../.."

source "${SCRIPT_DIR}/junit_helper.sh"
source "${SCRIPT_DIR}/rules/yaml_rules.sh"

PASS_COUNT=0
FAIL_COUNT=0
TEST_CASES=""
PASSED_RULES=""
FAILED_RULES=""
RESULT_FILE="${RESULT_FILE:-}"

# Test YAML pass cases
for file in "${TEST_DIR}"/pass/*.yaml; do
	if [[ -f "${file}" ]]; then
		filename=$(basename "${file}")
		rule_id=$(echo "${filename}" | grep -oE '^YAML-[0-9]+-[0-9]+' || echo "unknown")

		if check_yaml_rule "${file}"; then
			TEST_CASES+="$(junit_pass "yaml.pass" "${filename}" "0.01" "${CHECK_RESULT}")"$'\n'
			PASS_COUNT=$((PASS_COUNT + 1))
			PASSED_RULES+="${rule_id} (pass): ${filename}"$'\n'
			save_testcase_result "yaml.pass" "${filename}" "PASS" "${RESULT_FILE}"
		else
			TEST_CASES+="$(junit_fail "yaml.pass" "${filename}" "Expected to pass but found issues" "0.01" "${CHECK_RESULT}")"$'\n'
			FAIL_COUNT=$((FAIL_COUNT + 1))
			FAILED_RULES+="${rule_id} (pass): ${filename} - UNEXPECTED FAILURE"$'\n'
			save_testcase_result "yaml.pass" "${filename}" "FAIL" "${RESULT_FILE}"
		fi
	fi
done

# Test YAML fail cases
for file in "${TEST_DIR}"/fail/*.yaml; do
	if [[ -f "${file}" ]]; then
		filename=$(basename "${file}")
		rule_id=$(echo "${filename}" | grep -oE '^YAML-[0-9]+-[0-9]+' || echo "unknown")

		if ! check_yaml_rule "${file}"; then
			output="${CHECK_RESULT}"
			if [[ "${output}" =~ ^\[NG\] ]]; then
				output="${output}"$'\n'"This Fail is intended."
			fi
			TEST_CASES+="$(junit_pass "yaml.fail" "${filename}" "0.01" "${output}")"$'\n'
			PASS_COUNT=$((PASS_COUNT + 1))
			PASSED_RULES+="${rule_id} (fail): ${filename} - violation detected correctly"$'\n'
			save_testcase_result "yaml.fail" "${filename}" "PASS" "${RESULT_FILE}"
		else
			TEST_CASES+="$(junit_fail "yaml.fail" "${filename}" "Expected to detect issue but passed" "0.01" "${CHECK_RESULT}")"$'\n'
			FAIL_COUNT=$((FAIL_COUNT + 1))
			FAILED_RULES+="${rule_id} (fail): ${filename} - VIOLATION NOT DETECTED"$'\n'
			save_testcase_result "yaml.fail" "${filename}" "FAIL" "${RESULT_FILE}"
		fi
	fi
done

# Test Dockerfile pass cases
for file in "${TEST_DIR}"/pass/*.Dockerfile; do
	if [[ -f "${file}" ]]; then
		filename=$(basename "${file}")
		rule_id=$(echo "${filename}" | grep -oE '^Docker-[0-9]+-[0-9]+' || echo "unknown")

		if check_dockerfile_rule "${file}"; then
			TEST_CASES+="$(junit_pass "dockerfile.pass" "${filename}" "0.01" "${CHECK_RESULT}")"$'\n'
			PASS_COUNT=$((PASS_COUNT + 1))
			PASSED_RULES+="${rule_id} (pass): ${filename}"$'\n'
			save_testcase_result "dockerfile.pass" "${filename}" "PASS" "${RESULT_FILE}"
		else
			TEST_CASES+="$(junit_fail "dockerfile.pass" "${filename}" "Expected to pass but found issues" "0.01" "${CHECK_RESULT}")"$'\n'
			FAIL_COUNT=$((FAIL_COUNT + 1))
			FAILED_RULES+="${rule_id} (pass): ${filename} - UNEXPECTED FAILURE"$'\n'
			save_testcase_result "dockerfile.pass" "${filename}" "FAIL" "${RESULT_FILE}"
		fi
	fi
done

# Test Dockerfile fail cases
for file in "${TEST_DIR}"/fail/*.Dockerfile; do
	if [[ -f "${file}" ]]; then
		filename=$(basename "${file}")
		rule_id=$(echo "${filename}" | grep -oE '^Docker-[0-9]+-[0-9]+' || echo "unknown")

		if ! check_dockerfile_rule "${file}"; then
			output="${CHECK_RESULT}"
			if [[ "${output}" =~ ^\[NG\] ]]; then
				output="${output}"$'\n'"This Fail is intended."
			fi
			TEST_CASES+="$(junit_pass "dockerfile.fail" "${filename}" "0.01" "${output}")"$'\n'
			PASS_COUNT=$((PASS_COUNT + 1))
			PASSED_RULES+="${rule_id} (fail): ${filename} - violation detected correctly"$'\n'
			save_testcase_result "dockerfile.fail" "${filename}" "PASS" "${RESULT_FILE}"
		else
			TEST_CASES+="$(junit_fail "dockerfile.fail" "${filename}" "Expected to detect issue but passed" "0.01" "${CHECK_RESULT}")"$'\n'
			FAIL_COUNT=$((FAIL_COUNT + 1))
			FAILED_RULES+="${rule_id} (fail): ${filename} - VIOLATION NOT DETECTED"$'\n'
			save_testcase_result "dockerfile.fail" "${filename}" "FAIL" "${RESULT_FILE}"
		fi
	fi
done

TOTAL=$((PASS_COUNT + FAIL_COUNT))

# Print summary to stderr (using common function)
print_summary "YAML/Dockerfile" "${TOTAL}" "${PASS_COUNT}" "${FAIL_COUNT}"

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

junit_testsuite "CodingConvention.YAML" "${TOTAL}" "${FAIL_COUNT}" "${TEST_CASES}" "1"
