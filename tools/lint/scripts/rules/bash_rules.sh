#!/bin/bash
# Bash Coding Convention Rules
# Shared module for lint-bash and test_bash_junit.sh

BASH_RULES_PROJECT_ROOT="${BASH_RULES_PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
CHECK_RESULT=""

BASH_RULE_IDS=(
	"Bash-01-01"  # Shebang
	"Bash-03-01"  # Braced variables
	"Bash-03-02"  # Local keyword
	"Bash-04-01"  # Quote variables
	"Bash-06-05"  # Use [[ ]]
	"Bash-07-01"  # Use $() not backticks
	"Bash-08-02"  # Error to stderr
	"Bash-10-01"  # Check cd return
	"Bash-10-02"  # Use pipefail
)

check_bash_rule() {
	local file="$1"
	local rule_id="${2:-}"
	local filename
	filename=$(basename "${file}")
	CHECK_RESULT=""

	if [[ -z "${rule_id}" ]]; then
		rule_id=$(echo "${filename}" | grep -oE '^Bash-[0-9]+-[0-9]+' || echo "")
	fi

	case "${rule_id}" in
	Bash-01-01)
		local first_line
		first_line=$(head -1 "${file}")
		if echo "${first_line}" | grep -qE '^#!/bin/bash'; then
			CHECK_RESULT="[OK] Bash-01-01: Correct shebang"
			return 0
		fi
		CHECK_RESULT="[NG] Bash-01-01: Invalid shebang"$'\n'"1:${first_line}"
		return 1
		;;
	Bash-03-01)
		local match
		match=$(grep -nE '\$[a-zA-Z_][a-zA-Z0-9_]*[^}]' "${file}" 2>/dev/null | grep -vE '\$\{' | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] Bash-03-01: Unbraced variable found"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] Bash-03-01: Variables are braced"
		return 0
		;;
	Bash-03-02)
		if grep -qE '^[[:space:]]*local[[:space:]]+' "${file}"; then
			CHECK_RESULT="[OK] Bash-03-02: local keyword used"
			return 0
		fi
		if grep -qE '^[[:space:]]*[a-zA-Z_]+[[:space:]]*\(\)[[:space:]]*\{' "${file}"; then
			CHECK_RESULT="[NG] Bash-03-02: Function without local variables"
			return 1
		fi
		CHECK_RESULT="[OK] Bash-03-02: No functions or local used"
		return 0
		;;
	Bash-04-01)
		local match
		match=$(grep -nE '\[\[.*\$[^"]*\]\]' "${file}" 2>/dev/null | grep -vE '"\$' | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] Bash-04-01: Unquoted variable found"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] Bash-04-01: Variables are quoted"
		return 0
		;;
	Bash-06-05)
		local match
		match=$(grep -nE '\[[[:space:]]+' "${file}" 2>/dev/null | grep -vE '\[\[' | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] Bash-06-05: Single bracket [ ] found"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] Bash-06-05: Using [[ ]]"
		return 0
		;;
	Bash-07-01)
		local match
		match=$(grep -nE '`[^`]+`' "${file}" 2>/dev/null | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] Bash-07-01: Backticks found"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] Bash-07-01: Using \$()"
		return 0
		;;
	Bash-08-02)
		if grep -qE 'echo.*[Ee]rror' "${file}"; then
			if ! grep -qE '>&2' "${file}"; then
				local match
				match=$(grep -nE 'echo.*[Ee]rror' "${file}" 2>/dev/null | head -3 || true)
				CHECK_RESULT="[NG] Bash-08-02: Error not to stderr"$'\n'"${match}"
				return 1
			fi
		fi
		CHECK_RESULT="[OK] Bash-08-02: Errors go to stderr"
		return 0
		;;
	Bash-10-01)
		if grep -qE '^[[:space:]]*cd[[:space:]]+' "${file}"; then
			if grep -qE 'cd[[:space:]]+[^|]*\|\|' "${file}" || grep -qE 'cd[[:space:]]+[^&]*&&' "${file}"; then
				CHECK_RESULT="[OK] Bash-10-01: cd return checked"
				return 0
			fi
			local match
			match=$(grep -nE '^[[:space:]]*cd[[:space:]]+' "${file}" 2>/dev/null | head -3 || true)
			CHECK_RESULT="[NG] Bash-10-01: cd return not checked"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] Bash-10-01: No cd or return checked"
		return 0
		;;
	Bash-10-02)
		if grep -qF '|' "${file}"; then
			if grep -vE '^[[:space:]]*#' "${file}" | grep -qE 'set[[:space:]]+.*pipefail|set[[:space:]]+-o[[:space:]]+pipefail'; then
				CHECK_RESULT="[OK] Bash-10-02: pipefail is set"
				return 0
			fi
			CHECK_RESULT="[NG] Bash-10-02: Pipe without pipefail"
			return 1
		fi
		CHECK_RESULT="[OK] Bash-10-02: No pipes or pipefail set"
		return 0
		;;
	"")
		return check_bash_file_all_rules "${file}"
		;;
	*)
		if shellcheck "${file}" >/dev/null 2>&1; then
			CHECK_RESULT="[OK] shellcheck passed"
			return 0
		fi
		CHECK_RESULT="[NG] shellcheck failed"
		return 1
		;;
	esac
}

check_bash_file_all_rules() {
	local file="$1"
	local all_results=""
	local has_failure=0

	for rule_id in "${BASH_RULE_IDS[@]}"; do
		if ! check_bash_rule "${file}" "${rule_id}"; then
			has_failure=1
		fi
		all_results+="${CHECK_RESULT}"$'\n'
	done

	CHECK_RESULT="${all_results}"
	return ${has_failure}
}

check_bash_file() {
	check_bash_file_all_rules "$1"
}
