#!/bin/bash
# Bash-03-02: Use local keyword for local variables - FAIL (missing local)
# Tool: ShellCheck (SC2034 may flag unused, but no direct check for missing local)

set -e

process_file() {
	input_file="$1"
	output_file="$2"
	line_count=$(wc -l < "${input_file}")
	temp_data=$(cat "${input_file}")

	echo "Processing ${line_count} lines"
	echo "${temp_data}" > "${output_file}"
}

calculate_sum() {
	a="$1"
	b="$2"
	result=$((a + b))
	echo "${result}"
}
