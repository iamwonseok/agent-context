#!/bin/bash
# Test Bash scripts with custom rule checks
# Usage: ./test_bash.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR="${SCRIPT_DIR}/../bash"
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

# Check Bash script based on rule ID in filename
check_bash_rule() {
	local file="$1"
	local filename
	filename=$(basename "${file}")

	local rule_id
	rule_id=$(echo "${filename}" | grep -oE '^Bash-[0-9]+-[0-9]+' || echo "")

	case "${rule_id}" in
	Bash-01-01)
		if head -1 "${file}" | grep -qE '^#!/bin/bash'; then
			return 0
		fi
		return 1
		;;
	Bash-03-01)
		if grep -E '\$[a-zA-Z_][a-zA-Z0-9_]*[^}]' "${file}" | grep -vE '\$\{' >/dev/null 2>&1; then
			return 1
		fi
		return 0
		;;
	Bash-03-02)
		if grep -qE '^[[:space:]]*local[[:space:]]+' "${file}"; then
			return 0
		fi
		if grep -qE '^[[:space:]]*[a-zA-Z_]+[[:space:]]*\(\)[[:space:]]*\{' "${file}"; then
			return 1
		fi
		return 0
		;;
	Bash-04-01)
		if grep -E '\[\[.*\$[^"]*\]\]' "${file}" | grep -vE '"\$' >/dev/null 2>&1; then
			return 1
		fi
		return 0
		;;
	Bash-06-05)
		# Rule: Use [[ ]] instead of [ ]
		# Check for single bracket test (not double bracket)
		if grep -E '\[[[:space:]]+' "${file}" | grep -vE '\[\[' >/dev/null 2>&1; then
			return 1
		fi
		return 0
		;;
	Bash-07-01)
		if grep -qE '\`[^\`]+\`' "${file}"; then
			return 1
		fi
		return 0
		;;
	Bash-08-02)
		# Rule: Error messages should go to stderr
		# Check for echo with "Error" that doesn't use >&2
		if grep -qE 'echo.*[Ee]rror' "${file}"; then
			if ! grep -qE '>&2' "${file}"; then
				return 1
			fi
		fi
		return 0
		;;
	Bash-10-01)
		if grep -qE '^[[:space:]]*cd[[:space:]]+' "${file}"; then
			if grep -qE 'cd[[:space:]]+[^|]*\|\|' "${file}" || grep -qE 'cd[[:space:]]+[^&]*&&' "${file}"; then
				return 0
			fi
			return 1
		fi
		return 0
		;;
	Bash-10-02)
		# Rule: Use pipefail when using pipes
		if grep -qF '|' "${file}"; then
			# Check for actual set -o pipefail command (not in comments)
			if grep -vE '^[[:space:]]*#' "${file}" | grep -qE 'set[[:space:]]+.*pipefail|set[[:space:]]+-o[[:space:]]+pipefail'; then
				return 0
			fi
			return 1
		fi
		return 0
		;;
	*)
		if shellcheck --rcfile="${PROJECT_ROOT}/.shellcheckrc" "${file}" >/dev/null 2>&1; then
			return 0
		fi
		return 1
		;;
	esac
}

# Test pass cases
echo "Testing PASS cases (should have no issues)..."
for file in "${TEST_DIR}"/pass/*.sh; do
	if [[ -f "${file}" ]]; then
		filename=$(basename "${file}")
		if check_bash_rule "${file}"; then
			log_pass "${filename}"
		else
			log_error "${filename} - Expected to pass but found issues"
		fi
	fi
done

echo ""

# Test fail cases
echo "Testing FAIL cases (should detect issues)..."
for file in "${TEST_DIR}"/fail/*.sh; do
	if [[ -f "${file}" ]]; then
		filename=$(basename "${file}")
		if ! check_bash_rule "${file}"; then
			log_pass "${filename} (detected issue)"
		else
			log_fail "${filename} - Expected to detect issue but passed"
		fi
	fi
done

echo ""
echo "========================================="
echo "Bash Test Summary"
echo "========================================="
echo -e "Passed: ${GREEN}${PASS_COUNT}${NC}"
echo -e "Failed: ${RED}${FAIL_COUNT}${NC}"
echo "Total:  ${TOTAL_COUNT}"
echo ""

if [[ ${FAIL_COUNT} -gt 0 ]]; then
	exit 1
fi
