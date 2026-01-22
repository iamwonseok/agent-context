#!/bin/bash
# Test C code with custom rule checks
# Usage: ./test_c.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR="${SCRIPT_DIR}/../c"
PROJECT_ROOT="${SCRIPT_DIR}/../../.."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0
TOTAL_COUNT=0

log_pass() {
	echo -e "${GREEN}[PASS]${NC} $1"
	PASS_COUNT=$((PASS_COUNT + 1))
	TOTAL_COUNT=$((TOTAL_COUNT + 1))
}

log_fail() {
	echo -e "${RED}[FAIL]${NC} $1"
	FAIL_COUNT=$((FAIL_COUNT + 1))
	TOTAL_COUNT=$((TOTAL_COUNT + 1))
}

log_error() {
	echo -e "${RED}[ERROR]${NC} $1"
	FAIL_COUNT=$((FAIL_COUNT + 1))
	TOTAL_COUNT=$((TOTAL_COUNT + 1))
}

# Check C code based on rule ID in filename
check_c_rule() {
	local file="$1"
	local filename
	filename=$(basename "${file}")

	local rule_id
	rule_id=$(echo "${filename}" | grep -oE '^C-[0-9]+-[0-9]+' || echo "")

	case "${rule_id}" in
	C-01-01)
		if grep -qE '^    ' "${file}"; then
			return 1
		fi
		return 0
		;;
	C-01-02)
		if grep -qE '^\t\tcase[[:space:]]' "${file}"; then
			return 1
		fi
		return 0
		;;
	C-01-11)
		# Rule: Function opening brace on new line (not same line)
		# Fail if function definition has { on same line
		if grep -qE '^[a-zA-Z_][a-zA-Z0-9_ *]*\([^)]*\)[[:space:]]*\{' "${file}"; then
			return 1
		fi
		return 0
		;;
	C-01-12)
		if grep -qE '(if|while|for)[[:space:]]*\([^)]*\)[[:space:]]*$' "${file}"; then
			return 1
		fi
		return 0
		;;
	C-01-13)
		# Rule: else on same line as closing brace (} else {)
		# Fail if else is on its own line (preceded by } on previous line)
		if grep -qE '^[[:space:]]*\}[[:space:]]*$' "${file}" && grep -qE '^[[:space:]]*else' "${file}"; then
			return 1
		fi
		return 0
		;;
	C-01-14)
		if grep -qE '(if|while|for)[[:space:]]*\([^)]*\)[[:space:]]*$' "${file}"; then
			return 1
		fi
		if grep -qE '(if|while|for)[[:space:]]*\([^)]*\)[[:space:]]+[^{]' "${file}"; then
			return 1
		fi
		return 0
		;;
	C-01-15)
		if grep -qE 'if[[:space:]]*\([^)]*[^!=<>]=[^=][^)]*\)' "${file}"; then
			return 1
		fi
		return 0
		;;
	C-01-18)
		if grep -qE '[a-zA-Z_]\*[[:space:]]+[a-zA-Z_]' "${file}"; then
			return 1
		fi
		return 0
		;;
	C-02-05)
		if grep -qE '#define.*\\$' "${file}"; then
			if ! grep -qE 'do[[:space:]]*\{' "${file}"; then
				return 1
			fi
		fi
		return 0
		;;
	C-02-08)
		if grep -qE '#define[[:space:]]+\w+\([^)]+\)' "${file}"; then
			if grep -qE '#define[[:space:]]+\w+\((\w+)\)[^(]*\1[^)]' "${file}"; then
				return 1
			fi
		fi
		return 0
		;;
	C-03-04)
		if grep -qE '\b[a-z]+[A-Z][a-z]+[[:space:]]*[=(;]' "${file}"; then
			return 1
		fi
		return 0
		;;
	*)
		if clang-format --style=file:"${PROJECT_ROOT}/.clang-format" --dry-run --Werror "${file}" >/dev/null 2>&1; then
			return 0
		fi
		return 1
		;;
	esac
}

# Test pass cases
echo "Testing PASS cases (should have no issues)..."
for file in "${TEST_DIR}"/pass/*.c; do
	if [[ -f "${file}" ]]; then
		filename=$(basename "${file}")
		if check_c_rule "${file}"; then
			log_pass "${filename}"
		else
			log_error "${filename} - Expected to pass but found issues"
		fi
	fi
done

echo ""

# Test fail cases
echo "Testing FAIL cases (should detect issues)..."
for file in "${TEST_DIR}"/fail/*.c; do
	if [[ -f "${file}" ]]; then
		filename=$(basename "${file}")
		if ! check_c_rule "${file}"; then
			log_pass "${filename} (detected issue)"
		else
			log_fail "${filename} - Expected to detect issue but passed"
		fi
	fi
done

echo ""
echo "========================================="
echo "C Test Summary"
echo "========================================="
echo -e "Passed: ${GREEN}${PASS_COUNT}${NC}"
echo -e "Failed: ${RED}${FAIL_COUNT}${NC}"
echo "Total:  ${TOTAL_COUNT}"
echo ""

if [[ ${FAIL_COUNT} -gt 0 ]]; then
	exit 1
fi
