#!/bin/bash
# YAML/Dockerfile Coding Convention Rules
# Shared module for lint-yaml and test_yaml_junit.sh

YAML_RULES_PROJECT_ROOT="${YAML_RULES_PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
CHECK_RESULT=""

YAML_RULE_IDS=(
	"YAML-01-01"  # 2-space indentation
	"YAML-03-01"  # No duplicate keys
	"YAML-03-04"  # Use true/false
	"YAML-04-01"  # Space after comment
	"YAML-05-01"  # Document start marker
)

DOCKER_RULE_IDS=(
	"Docker-01-01"  # No :latest tag
	"Docker-02-01"  # Combine RUN commands
	"Docker-04-01"  # Use COPY not ADD
)

check_yaml_rule() {
	local file="$1"
	local rule_id="${2:-}"
	local filename
	filename=$(basename "${file}")
	CHECK_RESULT=""

	if [[ -z "${rule_id}" ]]; then
		rule_id=$(echo "${filename}" | grep -oE '^YAML-[0-9]+-[0-9]+' || echo "")
	fi

	case "${rule_id}" in
	YAML-01-01)
		local first_indent
		first_indent=$(grep -E '^[[:space:]]+[a-zA-Z]' "${file}" | head -1 | sed 's/[^ ].*//' | wc -c)
		if [[ "${first_indent}" -gt 3 ]]; then
			CHECK_RESULT="[NG] YAML-01-01: Indentation > 2 spaces (${first_indent} chars)"
			return 1
		fi
		CHECK_RESULT="[OK] YAML-01-01: 2-space indentation"
		return 0
		;;
	YAML-03-01)
		local duplicates
		duplicates=$(grep -E '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*:' "${file}" | \
			sed 's/:.*/:/' | sort | uniq -d || true)
		if [[ -n "${duplicates}" ]]; then
			CHECK_RESULT="[NG] YAML-03-01: Duplicate keys found"$'\n'"${duplicates}"
			return 1
		fi
		CHECK_RESULT="[OK] YAML-03-01: No duplicate keys"
		return 0
		;;
	YAML-03-04)
		local match
		match=$(grep -nE ':[[:space:]]*(yes|no|on|off)[[:space:]]*$' "${file}" 2>/dev/null | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] YAML-03-04: Non-standard boolean"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] YAML-03-04: Using true/false"
		return 0
		;;
	YAML-04-01)
		local match
		match=$(grep -nE '#[^ #]' "${file}" 2>/dev/null | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] YAML-04-01: No space after #"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] YAML-04-01: Space after comment"
		return 0
		;;
	YAML-05-01)
		if grep -qE '^---' "${file}"; then
			CHECK_RESULT="[OK] YAML-05-01: Document start marker present"
			return 0
		fi
		CHECK_RESULT="[NG] YAML-05-01: Missing document start (---)"
		return 1
		;;
	"")
		return check_yaml_file_all_rules "${file}"
		;;
	*)
		CHECK_RESULT="[OK] No specific rule"
		return 0
		;;
	esac
}

check_dockerfile_rule() {
	local file="$1"
	local rule_id="${2:-}"
	local filename
	filename=$(basename "${file}")
	CHECK_RESULT=""

	if [[ -z "${rule_id}" ]]; then
		rule_id=$(echo "${filename}" | grep -oE '^Docker-[0-9]+-[0-9]+' || echo "")
	fi

	case "${rule_id}" in
	Docker-01-01)
		local match
		match=$(grep -nE '^FROM[[:space:]]+(\S+:latest|\S+[^:0-9.][[:space:]]*$)' "${file}" 2>/dev/null | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] Docker-01-01: Using :latest or no tag"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] Docker-01-01: Specific image tag"
		return 0
		;;
	Docker-02-01)
		local run_count
		run_count=$(grep -cE '^RUN[[:space:]]+' "${file}" || echo "0")
		if [[ "${run_count}" -gt 2 ]]; then
			CHECK_RESULT="[NG] Docker-02-01: Too many RUN commands (${run_count})"
			return 1
		fi
		CHECK_RESULT="[OK] Docker-02-01: RUN commands combined"
		return 0
		;;
	Docker-04-01)
		local match
		match=$(grep -nE '^ADD[[:space:]]+' "${file}" 2>/dev/null | head -3 || true)
		if [[ -n "${match}" ]]; then
			CHECK_RESULT="[NG] Docker-04-01: Using ADD instead of COPY"$'\n'"${match}"
			return 1
		fi
		CHECK_RESULT="[OK] Docker-04-01: Using COPY"
		return 0
		;;
	"")
		return check_dockerfile_all_rules "${file}"
		;;
	*)
		CHECK_RESULT="[OK] No specific rule"
		return 0
		;;
	esac
}

check_yaml_file_all_rules() {
	local file="$1"
	local all_results=""
	local has_failure=0

	for rule_id in "${YAML_RULE_IDS[@]}"; do
		if ! check_yaml_rule "${file}" "${rule_id}"; then
			has_failure=1
		fi
		all_results+="${CHECK_RESULT}"$'\n'
	done

	CHECK_RESULT="${all_results}"
	return ${has_failure}
}

check_dockerfile_all_rules() {
	local file="$1"
	local all_results=""
	local has_failure=0

	for rule_id in "${DOCKER_RULE_IDS[@]}"; do
		if ! check_dockerfile_rule "${file}" "${rule_id}"; then
			has_failure=1
		fi
		all_results+="${CHECK_RESULT}"$'\n'
	done

	CHECK_RESULT="${all_results}"
	return ${has_failure}
}

check_yaml_file() {
	check_yaml_file_all_rules "$1"
}

check_dockerfile_file() {
	check_dockerfile_all_rules "$1"
}
