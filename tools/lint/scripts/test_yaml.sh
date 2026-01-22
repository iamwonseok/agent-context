#!/bin/bash
# Test YAML and Dockerfile with custom rule checks
# Usage: ./test_yaml.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR="${SCRIPT_DIR}/../yaml"
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

# Check YAML file based on rule ID in filename
check_yaml_rule() {
	local file="$1"
	local filename
	filename=$(basename "${file}")

	local rule_id
	rule_id=$(echo "${filename}" | grep -oE '^YAML-[0-9]+-[0-9]+' || echo "")

	case "${rule_id}" in
	YAML-01-01)
		# Rule: Use 2-space indentation at first level
		# Check first indented line - should be 2 spaces, not 4
		local first_indent
		first_indent=$(grep -E '^[[:space:]]+[a-zA-Z]' "${file}" | head -1 | sed 's/[^ ].*//' | wc -c)
		if [[ "${first_indent}" -gt 3 ]]; then
			return 1
		fi
		return 0
		;;
	YAML-03-01)
		# Rule: No duplicate keys
		if command -v yamllint &>/dev/null; then
			if yamllint -d "{rules: {key-duplicates: enable}}" "${file}" >/dev/null 2>&1; then
				return 0
			fi
			return 1
		fi
		# Fallback: check for duplicate keys at any level
		# Extract all key lines with their indentation, check for duplicates at same indent
		local duplicates
		duplicates=$(grep -E '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*:' "${file}" | \
			sed 's/:.*/:/' | sort | uniq -d)
		if [[ -n "${duplicates}" ]]; then
			return 1
		fi
		return 0
		;;
	YAML-03-04)
		if grep -qE ':[[:space:]]*(yes|no|on|off)[[:space:]]*$' "${file}"; then
			return 1
		fi
		return 0
		;;
	YAML-04-01)
		if grep -qE '#[^ #]' "${file}"; then
			return 1
		fi
		return 0
		;;
	YAML-05-01)
		# Rule: Document start marker (---) should be present
		# Skip comment lines and check for ---
		if grep -qE '^---' "${file}"; then
			return 0
		fi
		return 1
		;;
	*)
		if yamllint -c "${PROJECT_ROOT}/.yamllint.yml" "${file}" >/dev/null 2>&1; then
			return 0
		fi
		return 1
		;;
	esac
}

# Check Dockerfile based on rule ID in filename
check_dockerfile_rule() {
	local file="$1"
	local filename
	filename=$(basename "${file}")

	local rule_id
	rule_id=$(echo "${filename}" | grep -oE '^Docker-[0-9]+-[0-9]+' || echo "")

	case "${rule_id}" in
	Docker-01-01)
		if grep -qE '^FROM[[:space:]]+\S+:latest' "${file}" || grep -qE '^FROM[[:space:]]+[^:]+[[:space:]]*$' "${file}"; then
			return 1
		fi
		return 0
		;;
	Docker-02-01)
		local run_count
		run_count=$(grep -cE '^RUN[[:space:]]+' "${file}" || echo "0")
		if [[ "${run_count}" -gt 2 ]]; then
			return 1
		fi
		return 0
		;;
	Docker-04-01)
		if grep -qE '^ADD[[:space:]]+' "${file}"; then
			return 1
		fi
		return 0
		;;
	*)
		if hadolint --config "${PROJECT_ROOT}/.hadolint.yaml" "${file}" >/dev/null 2>&1; then
			return 0
		fi
		return 1
		;;
	esac
}

# Test YAML pass cases
echo "Testing YAML PASS cases (should have no issues)..."
for file in "${TEST_DIR}"/pass/*.yaml; do
	if [[ -f "${file}" ]]; then
		filename=$(basename "${file}")
		if check_yaml_rule "${file}"; then
			log_pass "${filename}"
		else
			log_error "${filename} - Expected to pass but found issues"
		fi
	fi
done

echo ""

# Test YAML fail cases
echo "Testing YAML FAIL cases (should detect issues)..."
for file in "${TEST_DIR}"/fail/*.yaml; do
	if [[ -f "${file}" ]]; then
		filename=$(basename "${file}")
		if ! check_yaml_rule "${file}"; then
			log_pass "${filename} (detected issue)"
		else
			log_fail "${filename} - Expected to detect issue but passed"
		fi
	fi
done

echo ""

# Test Dockerfile pass cases
echo "Testing Dockerfile PASS cases (should have no issues)..."
for file in "${TEST_DIR}"/pass/*.Dockerfile; do
	if [[ -f "${file}" ]]; then
		filename=$(basename "${file}")
		if check_dockerfile_rule "${file}"; then
			log_pass "${filename}"
		else
			log_error "${filename} - Expected to pass but found issues"
		fi
	fi
done

echo ""

# Test Dockerfile fail cases
echo "Testing Dockerfile FAIL cases (should detect issues)..."
for file in "${TEST_DIR}"/fail/*.Dockerfile; do
	if [[ -f "${file}" ]]; then
		filename=$(basename "${file}")
		if ! check_dockerfile_rule "${file}"; then
			log_pass "${filename} (detected issue)"
		else
			log_fail "${filename} - Expected to detect issue but passed"
		fi
	fi
done

echo ""
echo "========================================="
echo "YAML/Dockerfile Test Summary"
echo "========================================="
echo -e "Passed: ${GREEN}${PASS_COUNT}${NC}"
echo -e "Failed: ${RED}${FAIL_COUNT}${NC}"
echo "Total:  ${TOTAL_COUNT}"
echo ""

if [[ ${FAIL_COUNT} -gt 0 ]]; then
	exit 1
fi
