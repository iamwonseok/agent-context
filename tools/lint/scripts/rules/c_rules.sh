#!/bin/bash
# C/C++ Coding Convention Rules
# Shared module for lint-c and test_c_junit.sh
#
# Usage: source this file and call check_c_file() or check_c_rule()

# Project root for .clang-format
C_RULES_PROJECT_ROOT="${C_RULES_PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"

# Result variable (set by check functions)
CHECK_RESULT=""

# All supported rule IDs
C_RULE_IDS=(
	"C-01-01"  # Tab indentation
	"C-01-02"  # Switch-case indentation
	"C-01-11"  # Function brace on new line
	"C-01-12"  # Control statement brace on same line
	"C-01-13"  # else on same line as }
	"C-01-14"  # Always use braces
	"C-01-15"  # No assignment in if
	"C-01-18"  # Pointer on right side
	"C-02-05"  # Multi-statement macro do-while(0)
	"C-02-08"  # Macro parameter parentheses
	"C-03-04"  # snake_case identifiers
)

# Check a single rule on a file
# Args: $1 = file, $2 = rule_id (optional, auto-detect from filename if not provided)
# Returns: 0 = pass, 1 = fail
# Sets: CHECK_RESULT with details
check_c_rule() {
	local file="$1"
	local rule_id="${2:-}"
	local filename
	filename=$(basename "${file}")
	CHECK_RESULT=""

	# Auto-detect rule from filename if not provided
	if [[ -z "${rule_id}" ]]; then
		rule_id=$(echo "${filename}" | grep -oE '^C-[0-9]+-[0-9]+' || echo "")
	fi

	case "${rule_id}" in
	C-01-01)
		# Rule: Use tab indentation (not spaces)
		local match
		match=$(grep -nE '^    ' "${file}" 2>/dev/null | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] C-01-01: Space indentation found"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] C-01-01: Tab indentation"
		return 0
		;;
	C-01-02)
		# Rule: switch-case indentation (case at same level as switch)
		# Detect case indented more than switch (extra tab or spaces after switch)
		local match
		local TAB=$'\t'
		# Check for double-tab indented case (case should be at same level as switch)
		# Use actual tab character for portability (GNU/BSD grep compatibility)
		match=$(grep -n "^${TAB}${TAB}case[[:space:]]" "${file}" 2>/dev/null | head -3 || true)
		if [[ -z "${match}" ]]; then
			# Check for space-indented case (8 spaces = 2 indents)
			match=$(grep -n "^        case[[:space:]]" "${file}" 2>/dev/null | head -3 || true)
		fi
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] C-01-02: Case indented more than switch"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] C-01-02: Case indentation"
		return 0
		;;
	C-01-11)
		# Rule: Function opening brace on new line (not same line)
		local match
		match=$(grep -nE '^[a-zA-Z_][a-zA-Z0-9_ *]*\([^)]*\)[[:space:]]*\{' "${file}" 2>/dev/null | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] C-01-11: Function brace on same line"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] C-01-11: Function brace on new line"
		return 0
		;;
	C-01-12)
		# Rule: Opening brace on same line for control statements
		# Exclude: } while (0) pattern in macros (do-while(0) idiom)
		local match
		match=$(grep -nE '(if|while|for)[[:space:]]*\([^)]*\)[[:space:]]*$' "${file}" 2>/dev/null | grep -v '} while (0)' | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] C-01-12: Control statement brace on new line"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] C-01-12: Control statement brace on same line"
		return 0
		;;
	C-01-13)
		# Rule: else on same line as closing brace (} else {)
		if grep -qE '^[[:space:]]*\}[[:space:]]*$' "${file}" && grep -qE '^[[:space:]]*else' "${file}"; then
			CHECK_RESULT="[NG] C-01-13: else on separate line from }"
			return 1
		fi
		CHECK_RESULT="[OK] C-01-13: else on same line as }"
		return 0
		;;
	C-01-14)
		# Rule: Always use braces for control statements
		# Exclude: } while (0) pattern in macros (do-while(0) idiom)
		# Exclude: macro continuation lines (ending with \)
		local match
		match=$(grep -nE '(if|while|for)[[:space:]]*\([^)]*\)[[:space:]]*$' "${file}" 2>/dev/null | grep -v '} while (0)' | grep -v '\\$' | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] C-01-14: Missing braces for control statement"$'\n'"${match}"
			return 1
		fi
		match=$(grep -nE '^\s*(if|while|for)[[:space:]]*\([^)]*\)[[:space:]]+[^{]' "${file}" 2>/dev/null | grep -v '} while (0)' | grep -v '\\$' | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] C-01-14: Missing braces for control statement"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] C-01-14: Braces for control statements"
		return 0
		;;
	C-01-15)
		# Rule: No assignment in if condition
		local match
		match=$(grep -nE 'if[[:space:]]*\([^)]*[^!=<>]=[^=][^)]*\)' "${file}" 2>/dev/null | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] C-01-15: Assignment in if condition"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] C-01-15: No assignment in if condition"
		return 0
		;;
	C-01-18)
		# Rule: Pointer asterisk on right side (type *var, not type* var)
		local match
		match=$(grep -nE '[a-zA-Z_]\*[[:space:]]+[a-zA-Z_]' "${file}" 2>/dev/null | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] C-01-18: Pointer on left side"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] C-01-18: Pointer on right side"
		return 0
		;;
	C-02-05)
		# Rule: Multi-statement macros should use do-while(0)
		if grep -qE '#define.*\\$' "${file}"; then
			if ! grep -qE 'do[[:space:]]*\{' "${file}"; then
				CHECK_RESULT="[NG] C-02-05: Multi-statement macro without do-while(0)"
				return 1
			fi
		fi
		CHECK_RESULT="[OK] C-02-05: Macro uses do-while(0)"
		return 0
		;;
	C-02-08)
		# Rule: Macro parameters should be parenthesized
		if grep -qE '#define[[:space:]]+\w+\([^)]+\)' "${file}"; then
			local match
			match=$(grep -nE '#define[[:space:]]+\w+\((\w+)\)[^(]*\1[^)]' "${file}" 2>/dev/null | head -3 || true)
			if [[ -n "${match}" ]]; then
				CHECK_RESULT="[NG] C-02-08: Macro parameter not parenthesized"$'\n'"${match}"
				return 1
			fi
		fi
		CHECK_RESULT="[OK] C-02-08: Macro parameters parenthesized"
		return 0
		;;
	C-03-04)
		# Rule: Use snake_case for identifiers (not camelCase)
		local match
		match=$(grep -nE '\b[a-z]+[A-Z][a-z]+[[:space:]]*[=(;]' "${file}" 2>/dev/null | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] C-03-04: camelCase identifier found"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] C-03-04: snake_case identifiers"
		return 0
		;;
	"")
		# No specific rule - check all rules
		return check_c_file_all_rules "${file}"
		;;
	*)
		# Unknown rule, use clang-format as fallback
		if clang-format --style=file:"${C_RULES_PROJECT_ROOT}/.clang-format" --dry-run --Werror "${file}" >/dev/null 2>&1; then
			CHECK_RESULT="[OK] clang-format check passed"
			return 0
		fi
		CHECK_RESULT="[NG] clang-format check failed"
		return 1
		;;
	esac
}

# Check a file against all rules
# Args: $1 = file
# Returns: 0 = all pass, 1 = at least one fail
# Sets: CHECK_RESULT with all results
check_c_file_all_rules() {
	local file="$1"
	local all_results=""
	local has_failure=0

	for rule_id in "${C_RULE_IDS[@]}"; do
		if ! check_c_rule "${file}" "${rule_id}"; then
			has_failure=1
		fi
		all_results+="${CHECK_RESULT}"$'\n'
	done

	CHECK_RESULT="${all_results}"
	return ${has_failure}
}

# Check a file (convenience wrapper)
# Args: $1 = file
check_c_file() {
	check_c_file_all_rules "$1"
}
