#!/bin/bash
# Test Python code with custom rule checks
# Usage: ./test_python.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR="${SCRIPT_DIR}/../python"
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

# Check Python code based on rule ID in filename
check_python_rule() {
	local file="$1"
	local filename
	filename=$(basename "${file}")

	local rule_id
	rule_id=$(echo "${filename}" | grep -oE '^Py-[0-9]+-[0-9]+' || echo "")

	case "${rule_id}" in
	Py-02-01)
		if grep -qP '^\t' "${file}" 2>/dev/null || grep -qE '^	' "${file}"; then
			return 1
		fi
		return 0
		;;
	Py-02-04)
		# Rule: Two blank lines between top-level definitions
		# Check for def/class immediately following non-blank line (no 2 blank lines)
		if awk '
			/^(def |class )/ {
				if (prev_blank < 2 && prev_content == 1) { exit 1 }
				prev_blank = 0
				prev_content = 1
				next
			}
			/^$/ { prev_blank++; next }
			/^[^ #]/ { prev_blank = 0; prev_content = 1 }
		' "${file}"; then
			return 0
		fi
		return 1
		;;
	Py-03-02)
		if grep -qE '^import[[:space:]]+\w+,[[:space:]]*\w+' "${file}"; then
			return 1
		fi
		return 0
		;;
	Py-03-03)
		# Rule: Import order - stdlib first, then third-party, then local
		# Check if stdlib imports come after other imports
		local first_stdlib_line=0
		local last_other_line=0
		while IFS= read -r line; do
			linenum=$(echo "${line}" | cut -d: -f1)
			content=$(echo "${line}" | cut -d: -f2-)
			# Check for stdlib imports (os, sys, pathlib, etc.)
			if echo "${content}" | grep -qE '^(import|from)[[:space:]]+(os|sys|re|json|pathlib|typing|collections|functools|itertools)\b'; then
				if [[ ${first_stdlib_line} -eq 0 ]]; then
					first_stdlib_line=${linenum}
				fi
			# Check for third-party or local imports
			elif echo "${content}" | grep -qE '^(import|from)[[:space:]]+'; then
				last_other_line=${linenum}
			fi
		done < <(grep -nE '^(import|from)[[:space:]]+' "${file}")
		# If stdlib import comes after other imports, it's wrong order
		if [[ ${first_stdlib_line} -gt 0 && ${last_other_line} -gt 0 && ${first_stdlib_line} -gt ${last_other_line} ]]; then
			return 1
		fi
		# Also check if local imports come before stdlib
		if grep -nE '^from[[:space:]]+\w+[[:space:]]+import' "${file}" | head -1 | grep -qE '^[0-9]+:from[[:space:]]+(my|local)'; then
			local first_local
			first_local=$(grep -nE '^from[[:space:]]+(my|local)' "${file}" | head -1 | cut -d: -f1)
			local first_std
			first_std=$(grep -nE '^import[[:space:]]+(os|sys|re|json)' "${file}" | head -1 | cut -d: -f1)
			if [[ -n "${first_local}" && -n "${first_std}" && "${first_local}" -lt "${first_std}" ]]; then
				return 1
			fi
		fi
		return 0
		;;
	Py-03-04)
		if grep -qE '^from[[:space:]]+\w+[[:space:]]+import[[:space:]]+\*' "${file}"; then
			return 1
		fi
		return 0
		;;
	Py-05-01)
		# Rule: Use double quotes for strings
		# Allow single quotes only when string contains double quotes
		# Check for simple single-quoted strings without double quotes inside
		if grep -vE '^#|^[[:space:]]*"""' "${file}" | grep -qE "'[^\"']+'" 2>/dev/null; then
			return 1
		fi
		return 0
		;;
	Py-06-02)
		if grep -qE '\([[:space:]]+\S|\S[[:space:]]+\)' "${file}"; then
			return 1
		fi
		return 0
		;;
	Py-08-05)
		if grep -qE 'def[[:space:]]+\w+\([^)]*=[[:space:]]*\[\]' "${file}"; then
			return 1
		fi
		if grep -qE 'def[[:space:]]+\w+\([^)]*=[[:space:]]*\{\}' "${file}"; then
			return 1
		fi
		return 0
		;;
	Py-10-01)
		if grep -qE '^[[:space:]]*except[[:space:]]*:' "${file}"; then
			return 1
		fi
		return 0
		;;
	Py-11-01)
		if grep -qE 'open[[:space:]]*\(' "${file}"; then
			if grep -qE '^[[:space:]]*with[[:space:]]+open' "${file}"; then
				return 0
			fi
			return 1
		fi
		return 0
		;;
	*)
		if black --check --quiet "${file}" 2>/dev/null && \
		   flake8 --config="${PROJECT_ROOT}/.flake8" "${file}" 2>/dev/null; then
			return 0
		fi
		return 1
		;;
	esac
}

# Test pass cases
echo "Testing PASS cases (should have no issues)..."
for file in "${TEST_DIR}"/pass/*.py; do
	if [[ -f "${file}" ]]; then
		filename=$(basename "${file}")
		if check_python_rule "${file}"; then
			log_pass "${filename}"
		else
			log_error "${filename} - Expected to pass but found issues"
		fi
	fi
done

echo ""

# Test fail cases
echo "Testing FAIL cases (should detect issues)..."
for file in "${TEST_DIR}"/fail/*.py; do
	if [[ -f "${file}" ]]; then
		filename=$(basename "${file}")
		if ! check_python_rule "${file}"; then
			log_pass "${filename} (detected issue)"
		else
			log_fail "${filename} - Expected to detect issue but passed"
		fi
	fi
done

echo ""
echo "========================================="
echo "Python Test Summary"
echo "========================================="
echo -e "Passed: ${GREEN}${PASS_COUNT}${NC}"
echo -e "Failed: ${RED}${FAIL_COUNT}${NC}"
echo "Total:  ${TOTAL_COUNT}"
echo ""

if [[ ${FAIL_COUNT} -gt 0 ]]; then
	exit 1
fi
