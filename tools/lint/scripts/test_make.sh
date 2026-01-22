#!/bin/bash
# Test Makefiles with checkmake and custom rules
# Usage: ./test_make.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR="${SCRIPT_DIR}/../make"

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

# Check Makefile based on rule ID in filename
# Returns 0 if file follows the rule, 1 if it violates
check_makefile_rule() {
	local file="$1"
	local filename
	filename=$(basename "${file}")

	# Extract rule ID from filename (e.g., Make-02-01 from Make-02-01_tab_recipe.mk)
	local rule_id
	rule_id=$(echo "${filename}" | grep -oE '^Make-[0-9]+-[0-9]+' || echo "")

	case "${rule_id}" in
	Make-02-01)
		# Rule: Use tab for recipe indentation
		# Check if any recipe line starts with spaces instead of tab
		if grep -E '^\t' "${file}" >/dev/null 2>&1; then
			# Has tab-indented lines (correct)
			if grep -E '^[[:space:]]' "${file}" | grep -vE '^\t' >/dev/null 2>&1; then
				# Also has space-indented lines (incorrect)
				return 1
			fi
			return 0
		else
			# Check for space-indented recipe lines
			if grep -E '^    ' "${file}" >/dev/null 2>&1; then
				return 1
			fi
			return 0
		fi
		;;
	Make-04-01)
		# Rule: Use ${VAR} format instead of $(VAR)
		# Check for $(VAR) pattern (excluding $(shell ...), $(wildcard ...), etc.)
		if grep -E '\$\([A-Z_]+\)' "${file}" >/dev/null 2>&1; then
			return 1
		fi
		return 0
		;;
	Make-06-02)
		# Rule: Declare .PHONY targets
		if grep -E '^\.PHONY:' "${file}" >/dev/null 2>&1; then
			return 0
		fi
		return 1
		;;
	Make-08-03)
		# Rule: Add comment after endif
		# Check for endif without comment
		if grep -E '^endif[[:space:]]*$' "${file}" >/dev/null 2>&1; then
			return 1
		fi
		return 0
		;;
	*)
		# Unknown rule, use checkmake or make -n as fallback
		if command -v checkmake &>/dev/null; then
			if checkmake "${file}" >/dev/null 2>&1; then
				return 0
			fi
			return 1
		fi
		# Fallback to syntax check
		if make -n -f "${file}" >/dev/null 2>&1; then
			return 0
		fi
		return 1
		;;
	esac
}

# Test pass cases
echo "Testing PASS cases (should have no issues)..."
for file in "${TEST_DIR}"/pass/*.mk; do
	if [[ -f "${file}" ]]; then
		filename=$(basename "${file}")

		if check_makefile_rule "${file}"; then
			log_pass "${filename}"
		else
			log_error "${filename} - Expected to pass but found issues"
		fi
	fi
done

echo ""

# Test fail cases
echo "Testing FAIL cases (should detect issues)..."
for file in "${TEST_DIR}"/fail/*.mk; do
	if [[ -f "${file}" ]]; then
		filename=$(basename "${file}")

		if ! check_makefile_rule "${file}"; then
			log_pass "${filename} (detected issue)"
		else
			log_fail "${filename} - Expected to detect issue but passed"
		fi
	fi
done

echo ""
echo "========================================="
echo "Make Test Summary"
echo "========================================="
echo -e "Passed: ${GREEN}${PASS_COUNT}${NC}"
echo -e "Failed: ${RED}${FAIL_COUNT}${NC}"
echo "Total:  ${TOTAL_COUNT}"
echo ""

if [[ ${FAIL_COUNT} -gt 0 ]]; then
	exit 1
fi
