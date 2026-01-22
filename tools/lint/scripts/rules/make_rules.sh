#!/bin/bash
# Makefile Coding Convention Rules
# Shared module for lint-make and test_make_junit.sh

MAKE_RULES_PROJECT_ROOT="${MAKE_RULES_PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
CHECK_RESULT=""

MAKE_RULE_IDS=(
	"Make-02-01"  # Tab indentation
	"Make-04-01"  # Use ${VAR} format
	"Make-06-02"  # .PHONY declaration
	"Make-08-03"  # endif comment
)

check_make_rule() {
	local file="$1"
	local rule_id="${2:-}"
	local filename
	filename=$(basename "${file}")
	CHECK_RESULT=""

	if [[ -z "${rule_id}" ]]; then
		rule_id=$(echo "${filename}" | grep -oE '^Make-[0-9]+-[0-9]+' || echo "")
	fi

	case "${rule_id}" in
	Make-02-01)
		local match
		match=$(grep -nE '^    ' "${file}" 2>/dev/null | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] Make-02-01: Space indentation in recipe"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] Make-02-01: Tab indentation"
		return 0
		;;
	Make-04-01)
		local match
		match=$(grep -nE '\$\([A-Z_]+\)' "${file}" 2>/dev/null | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] Make-04-01: Using \$(VAR) instead of \${VAR}"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] Make-04-01: Using \${VAR} format"
		return 0
		;;
	Make-06-02)
		if grep -qE '^\.PHONY:' "${file}"; then
			CHECK_RESULT="[OK] Make-06-02: .PHONY declared"
			return 0
		fi
		CHECK_RESULT="[NG] Make-06-02: Missing .PHONY declaration"
		return 1
		;;
	Make-08-03)
		local match
		match=$(grep -nE '^endif[[:space:]]*$' "${file}" 2>/dev/null | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] Make-08-03: endif without comment"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] Make-08-03: endif has comment"
		return 0
		;;
	"")
		return check_make_file_all_rules "${file}"
		;;
	*)
		if make -n -f "${file}" >/dev/null 2>&1; then
			CHECK_RESULT="[OK] make -n passed"
			return 0
		fi
		CHECK_RESULT="[NG] make -n failed"
		return 1
		;;
	esac
}

check_make_file_all_rules() {
	local file="$1"
	local all_results=""
	local has_failure=0

	for rule_id in "${MAKE_RULE_IDS[@]}"; do
		if ! check_make_rule "${file}" "${rule_id}"; then
			has_failure=1
		fi
		all_results+="${CHECK_RESULT}"$'\n'
	done

	CHECK_RESULT="${all_results}"
	return ${has_failure}
}

check_make_file() {
	check_make_file_all_rules "$1"
}
