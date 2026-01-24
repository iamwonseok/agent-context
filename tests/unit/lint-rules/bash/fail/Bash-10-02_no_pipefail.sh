#!/bin/bash
# Bash-10-02: Use set -o pipefail - FAIL (missing pipefail)
# Tool: ShellCheck (SC2312)

set -e

process_log() {
	local log_file="$1"

	# First command failure will be hidden
	grep "ERROR" "${log_file}" | sort | uniq -c
}

count_errors() {
	local dir="$1"

	# grep failure may be hidden by wc success
	find "${dir}" -name "*.log" -print0 | \
		xargs -0 grep -l "ERROR" | \
		wc -l
}

main() {
	local log_dir="${1:-.}"

	echo "Processing logs in: ${log_dir}"
	count_errors "${log_dir}"
}

main "$@"
