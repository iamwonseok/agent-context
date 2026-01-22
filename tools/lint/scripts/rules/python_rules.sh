#!/bin/bash
# Python Coding Convention Rules
# Shared module for lint-python and test_python_junit.sh

PYTHON_RULES_PROJECT_ROOT="${PYTHON_RULES_PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
CHECK_RESULT=""

PYTHON_RULE_IDS=(
	"Py-02-01"  # Space indentation
	"Py-02-04"  # Two blank lines between definitions
	"Py-03-02"  # One import per line
	"Py-03-03"  # Import order
	"Py-03-04"  # No wildcard imports
	"Py-05-01"  # Double quotes
	"Py-06-02"  # No space inside parentheses
	"Py-08-05"  # No mutable default arguments
	"Py-10-01"  # No bare except
	"Py-11-01"  # Use with statement
)

check_python_rule() {
	local file="$1"
	local rule_id="${2:-}"
	local filename
	filename=$(basename "${file}")
	CHECK_RESULT=""

	if [[ -z "${rule_id}" ]]; then
		rule_id=$(echo "${filename}" | grep -oE '^Py-[0-9]+-[0-9]+' || echo "")
	fi

	case "${rule_id}" in
	Py-02-01)
		local match
		match=$(grep -nE '^	' "${file}" 2>/dev/null | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] Py-02-01: Tab indentation found"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] Py-02-01: Space indentation"
		return 0
		;;
	Py-02-04)
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
			CHECK_RESULT="[OK] Py-02-04: Proper blank lines"
			return 0
		fi
		CHECK_RESULT="[NG] Py-02-04: Missing blank lines between definitions"
		return 1
		;;
	Py-03-02)
		local match
		match=$(grep -nE '^import[[:space:]]+\w+,[[:space:]]*\w+' "${file}" 2>/dev/null | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] Py-03-02: Multiple imports on one line"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] Py-03-02: One import per line"
		return 0
		;;
	Py-03-03)
		# Rule: Import order - stdlib first, then third-party, then local
		# Violation: any non-stdlib import appears before any stdlib import
		local first_stdlib_line=0
		local first_other_line=0
		while IFS= read -r line; do
			linenum=$(echo "${line}" | cut -d: -f1)
			content=$(echo "${line}" | cut -d: -f2-)
			if echo "${content}" | grep -qE '^(import|from)[[:space:]]+(os|sys|re|json|pathlib|typing|collections|functools|itertools|datetime|time|math|random|string|io|subprocess|shutil|glob|logging|unittest|copy|hashlib|base64|urllib|http|socket|threading|multiprocessing|argparse|configparser|csv|pickle|struct|tempfile|contextlib|abc|dataclasses|enum|warnings)\b'; then
				if [[ ${first_stdlib_line} -eq 0 ]]; then
					first_stdlib_line=${linenum}
				fi
			elif echo "${content}" | grep -qE '^(import|from)[[:space:]]+'; then
				if [[ ${first_other_line} -eq 0 ]]; then
					first_other_line=${linenum}
				fi
			fi
		done < <(grep -nE '^(import|from)[[:space:]]+' "${file}")
		# Violation: other imports appear before stdlib imports
		if [[ ${first_stdlib_line} -gt 0 && ${first_other_line} -gt 0 && ${first_other_line} -lt ${first_stdlib_line} ]]; then
			CHECK_RESULT="[NG] Py-03-03: Import order incorrect (stdlib should come first)"
			return 1
		fi
		CHECK_RESULT="[OK] Py-03-03: Import order correct"
		return 0
		;;
	Py-03-04)
		local match
		match=$(grep -nE '^from[[:space:]]+\w+[[:space:]]+import[[:space:]]+\*' "${file}" 2>/dev/null | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] Py-03-04: Wildcard import found"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] Py-03-04: No wildcard imports"
		return 0
		;;
	Py-05-01)
		local match
		match=$(grep -vE '^#|^[[:space:]]*"""' "${file}" | grep -nE "'[^\"']+'" 2>/dev/null | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] Py-05-01: Single quotes found"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] Py-05-01: Using double quotes"
		return 0
		;;
	Py-06-02)
		local match
		match=$(grep -nE '\([[:space:]]+\S|\S[[:space:]]+\)' "${file}" 2>/dev/null | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] Py-06-02: Space inside parentheses"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] Py-06-02: No space inside parentheses"
		return 0
		;;
	Py-08-05)
		local match
		match=$(grep -nE 'def[[:space:]]+\w+\([^)]*=[[:space:]]*(\[\]|\{\})' "${file}" 2>/dev/null | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] Py-08-05: Mutable default argument"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] Py-08-05: No mutable defaults"
		return 0
		;;
	Py-10-01)
		local match
		match=$(grep -nE '^[[:space:]]*except[[:space:]]*:' "${file}" 2>/dev/null | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] Py-10-01: Bare except found"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] Py-10-01: No bare except"
		return 0
		;;
	Py-11-01)
		if grep -qE 'open[[:space:]]*\(' "${file}"; then
			if grep -qE '^[[:space:]]*with[[:space:]]+open' "${file}"; then
				CHECK_RESULT="[OK] Py-11-01: Using with statement"
				return 0
			fi
			local match
			match=$(grep -nE 'open[[:space:]]*\(' "${file}" 2>/dev/null | head -3 || true)
			CHECK_RESULT="[NG] Py-11-01: open() without with"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] Py-11-01: No file operations or using with"
		return 0
		;;
	"")
		return check_python_file_all_rules "${file}"
		;;
	*)
		if python3 -m py_compile "${file}" 2>/dev/null; then
			CHECK_RESULT="[OK] syntax check passed"
			return 0
		fi
		CHECK_RESULT="[NG] syntax check failed"
		return 1
		;;
	esac
}

check_python_file_all_rules() {
	local file="$1"
	local all_results=""
	local has_failure=0

	for rule_id in "${PYTHON_RULE_IDS[@]}"; do
		if ! check_python_rule "${file}" "${rule_id}"; then
			has_failure=1
		fi
		all_results+="${CHECK_RESULT}"$'\n'
	done

	CHECK_RESULT="${all_results}"
	return ${has_failure}
}

check_python_file() {
	check_python_file_all_rules "$1"
}
