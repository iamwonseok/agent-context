#!/bin/bash
# Bash-10-02: Use set -o pipefail - PASS
# Tool: ShellCheck (SC2312)

set -e
set -o pipefail

process_log() {
	local log_file="$1"

	# Pipeline failures will be caught
	grep "ERROR" "${log_file}" | sort | uniq -c
}

count_errors() {
	local dir="$1"

	# All commands in pipeline must succeed
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
