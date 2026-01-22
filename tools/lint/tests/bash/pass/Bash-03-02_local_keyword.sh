#!/bin/bash
# Bash-03-02: Use local keyword for local variables - PASS
# Tool: ShellCheck

set -e

process_file() {
	local input_file="$1"
	local output_file="$2"
	local line_count
	local temp_data

	line_count=$(wc -l < "${input_file}")
	temp_data=$(cat "${input_file}")

	echo "Processing ${line_count} lines"
	echo "${temp_data}" > "${output_file}"
}

calculate_sum() {
	local -i a="$1"
	local -i b="$2"
	local -i result

	result=$((a + b))
	echo "${result}"
}
