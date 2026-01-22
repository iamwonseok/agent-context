#!/bin/bash
# Verify lint results against expected output
# Usage: ./verify_results.sh [c|bash|make|python|yaml|all]
#
# This script runs lint tools and compares output with expected results
# to detect any changes in lint behavior or output format.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."
EXPECTED_DIR="${PROJECT_ROOT}/tests/expected"
RESULT_DIR="${RESULT_DIR:-/tmp/lint-verify}"

source "${SCRIPT_DIR}/junit_helper.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TOTAL_CHECKS=0
TOTAL_PASS=0
TOTAL_FAIL=0
TEST_CASES=""

# Generate actual output for a language
# Args: $1=language
generate_actual_output() {
	local lang="$1"
	local output_file="${RESULT_DIR}/${lang}.actual"
	local test_dir pass_dir fail_dir lint_cmd ext
	
	mkdir -p "${RESULT_DIR}"
	
	case "${lang}" in
		c)
			pass_dir="${PROJECT_ROOT}/tests/c/pass"
			fail_dir="${PROJECT_ROOT}/tests/c/fail"
			lint_cmd="${PROJECT_ROOT}/bin/lint-c"
			ext="*.c"
			;;
		bash)
			pass_dir="${PROJECT_ROOT}/tests/bash/pass"
			fail_dir="${PROJECT_ROOT}/tests/bash/fail"
			lint_cmd="${PROJECT_ROOT}/bin/lint-bash"
			ext="*.sh"
			;;
		make)
			pass_dir="${PROJECT_ROOT}/tests/make/pass"
			fail_dir="${PROJECT_ROOT}/tests/make/fail"
			lint_cmd="${PROJECT_ROOT}/bin/lint-make"
			ext="*.mk"
			;;
		python)
			pass_dir="${PROJECT_ROOT}/tests/python/pass"
			fail_dir="${PROJECT_ROOT}/tests/python/fail"
			lint_cmd="${PROJECT_ROOT}/bin/lint-python"
			ext="*.py"
			;;
		yaml)
			pass_dir="${PROJECT_ROOT}/tests/yaml/pass"
			fail_dir="${PROJECT_ROOT}/tests/yaml/fail"
			lint_cmd="${PROJECT_ROOT}/bin/lint-yaml"
			ext="*.yaml *.Dockerfile"
			;;
		*)
			echo "Unknown language: ${lang}" >&2
			return 1
			;;
	esac
	
	{
		local lang_upper
		lang_upper=$(echo "${lang}" | tr '[:lower:]' '[:upper:]')
		echo "# ${lang_upper} Lint Expected Output"
		echo "# Generated: $(date -Iseconds)"
		echo ""
		
		# Process pass directory
		for pattern in ${ext}; do
			for f in "${pass_dir}"/${pattern}; do
				[ -f "$f" ] || continue
				echo "=== $(basename "$f") ==="
				"${lint_cmd}" "$f" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true
				echo ""
			done
		done
		
		# Process fail directory
		for pattern in ${ext}; do
			for f in "${fail_dir}"/${pattern}; do
				[ -f "$f" ] || continue
				echo "=== $(basename "$f") ==="
				"${lint_cmd}" "$f" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true
				echo ""
			done
		done
	} > "${output_file}"
	
	echo "${output_file}"
}

# Compare actual vs expected for a language
# Args: $1=language
verify_language() {
	local lang="$1"
	local expected_file="${EXPECTED_DIR}/${lang}.expected"
	
	if [[ ! -f "${expected_file}" ]]; then
		echo -e "${YELLOW}[SKIP]${NC} ${lang}: No expected file" >&2
		return 0
	fi
	
	echo "Checking ${lang}..." >&2
	
	local actual_file
	actual_file=$(generate_actual_output "${lang}")
	
	if [[ ! -f "${actual_file}" ]]; then
		echo -e "${RED}[FAIL]${NC} ${lang}: Failed to generate actual output" >&2
		TEST_CASES+="$(junit_fail "verify.${lang}" "output_generation" "Failed to generate output" "1.00")"$'\n'
		TOTAL_FAIL=$((TOTAL_FAIL + 1))
		TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
		return 1
	fi
	
	# Compare files (ignoring header lines and normalizing paths)
	# Remove: header lines (#), absolute paths, trailing whitespace
	local diff_output
	diff_output=$(diff -u \
		<(grep -v "^#" "${expected_file}" | sed 's|/[^ ]*tests/|tests/|g; s/[[:space:]]*$//') \
		<(grep -v "^#" "${actual_file}" | sed 's|/[^ ]*tests/|tests/|g; s/[[:space:]]*$//') 2>&1 || true)
	
	TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
	
	if [[ -z "${diff_output}" ]]; then
		echo -e "${GREEN}[PASS]${NC} ${lang}: Output matches expected" >&2
		TEST_CASES+="$(junit_pass "verify.${lang}" "output_match" "1.00" "Output matches expected")"$'\n'
		TOTAL_PASS=$((TOTAL_PASS + 1))
		return 0
	else
		local diff_lines
		diff_lines=$(echo "${diff_output}" | wc -l)
		echo -e "${RED}[FAIL]${NC} ${lang}: Output differs (${diff_lines} lines)" >&2
		echo "${diff_output}" | head -30 >&2
		if [[ ${diff_lines} -gt 30 ]]; then
			echo "... (${diff_lines} total lines of diff)" >&2
		fi
		TEST_CASES+="$(junit_fail "verify.${lang}" "output_match" "${diff_lines} lines differ" "1.00" "${diff_output}")"$'\n'
		TOTAL_FAIL=$((TOTAL_FAIL + 1))
		return 1
	fi
}

# Regenerate expected files
# Args: $1=language (or "all")
regenerate_expected() {
	local lang="$1"
	
	if [[ "${lang}" == "all" ]]; then
		for l in c bash make python yaml; do
			regenerate_expected "${l}"
		done
		return
	fi
	
	echo "Regenerating ${lang}.expected..." >&2
	local actual_file
	actual_file=$(generate_actual_output "${lang}")
	cp "${actual_file}" "${EXPECTED_DIR}/${lang}.expected"
	echo "Saved to ${EXPECTED_DIR}/${lang}.expected" >&2
}

# Main
main() {
	local cmd="${1:-all}"
	shift || true
	
	case "${cmd}" in
		--regenerate|-r)
			regenerate_expected "${1:-all}"
			exit 0
			;;
		--help|-h)
			echo "Usage: $0 [c|bash|make|python|yaml|all]"
			echo "       $0 --regenerate [language|all]  Regenerate expected files"
			exit 0
			;;
	esac
	
	local languages="${cmd}"
	if [[ "${languages}" == "all" ]]; then
		languages="c bash make python yaml"
	fi
	
	echo "" >&2
	echo "=========================================" >&2
	echo "Verifying lint output against expected..." >&2
	echo "=========================================" >&2
	
	local verify_failed=0
	for lang in ${languages}; do
		verify_language "${lang}" || verify_failed=1
	done
	
	echo "" >&2
	echo "=========================================" >&2
	echo "Verification Summary" >&2
	echo "=========================================" >&2
	echo "Total: ${TOTAL_CHECKS} | Passed: ${TOTAL_PASS} | Failed: ${TOTAL_FAIL}" >&2
	
	# Output JUnit XML
	junit_testsuite "Verify.LintOutput" "${TOTAL_CHECKS}" "${TOTAL_FAIL}" "${TEST_CASES}" "1"
	
	exit ${verify_failed}
}

main "$@"
