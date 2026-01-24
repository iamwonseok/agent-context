#!/bin/bash
# Check trailing whitespace (non-Markdown) and output JUnit XML.
# Usage:
#   ./test_whitespace_junit.sh [FILES...]
#
# - If FILES are provided: checks only those files (useful for MR changed files)
# - If no FILES are provided: scans repo files via git (tracked + untracked, non-ignored)
#
# Markdown (*.md) is excluded because trailing spaces can be meaningful.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "${SCRIPT_DIR}/junit_helper.sh"

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
TEST_CASES=""

WHITESPACE_CHECKER="${SCRIPT_DIR}/trailing_whitespace.py"

check_files_mode() {
	declare -A offenders=()

	# Run once and capture offenders list (only prints offenders).
	local output
	output="$(python3 "${WHITESPACE_CHECKER}" --check "$@" 2>&1 || true)"

	while IFS= read -r line; do
		[[ -z "${line}" ]] && continue
		offender_file="${line%%:*}"
		offenders["${offender_file}"]=1
	done <<< "${output}"

	for file in "$@"; do
		[[ -f "${file}" ]] || continue

		local filename
		filename="$(basename "${file}")"

		if [[ "${file}" == *.md ]]; then
			TEST_CASES+="$(junit_skip "whitespace.check" "${filename}" "Markdown excluded")"$'\n'
			SKIP_COUNT=$((SKIP_COUNT + 1))
			continue
		fi

		if [[ -n "${offenders[${file}]:-}" ]]; then
			TEST_CASES+="$(junit_fail "whitespace.check" "${filename}" "Trailing whitespace found" "0.01" "${file}")"$'\n'
			FAIL_COUNT=$((FAIL_COUNT + 1))
		else
			TEST_CASES+="$(junit_pass "whitespace.check" "${filename}" "0.01" "${file}")"$'\n'
			PASS_COUNT=$((PASS_COUNT + 1))
		fi
	done

	# Append offender summary as a single failed testcase (for easier visibility)
	if [[ ${FAIL_COUNT} -gt 0 ]]; then
		TEST_CASES+="$(junit_fail "whitespace.summary" "offenders" "${FAIL_COUNT} file(s) with trailing whitespace" "0.01" "${output}")"$'\n'
	fi
}

check_repo_mode() {
	local output
	if output="$(python3 "${WHITESPACE_CHECKER}" --check 2>&1)"; then
		TEST_CASES+="$(junit_pass "whitespace.repo" "repository" "0.50" "No trailing whitespace found (Markdown excluded).")"$'\n'
		PASS_COUNT=$((PASS_COUNT + 1))
	else
		TEST_CASES+="$(junit_fail "whitespace.repo" "repository" "Trailing whitespace found" "0.50" "${output}")"$'\n'
		FAIL_COUNT=$((FAIL_COUNT + 1))
	fi
}

if [[ $# -gt 0 ]]; then
	check_files_mode "$@"
else
	check_repo_mode
fi

TOTAL=$((PASS_COUNT + FAIL_COUNT + SKIP_COUNT))

# Print summary to stderr (using common function)
print_summary "Whitespace" "${TOTAL}" "${PASS_COUNT}" "${FAIL_COUNT}"

junit_testsuite "CodingConvention.Whitespace" "${TOTAL}" "${FAIL_COUNT}" "${TEST_CASES}" "1"

