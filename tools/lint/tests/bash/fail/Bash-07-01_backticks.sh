#!/bin/bash
# Bash-07-01: Use $() for command substitution - FAIL (uses backticks)
# Tool: ShellCheck (SC2006)

set -e

get_info() {
	local current_date
	local hostname
	local script_dir

	current_date=`date +%Y-%m-%d`
	hostname=`hostname`
	script_dir=`cd "\`dirname "$0"\`" && pwd`

	echo "Date: ${current_date}"
	echo "Host: ${hostname}"
	echo "Dir: ${script_dir}"

	# Nested backticks are hard to read
	local file_count
	file_count=`ls -1 \`pwd\` | wc -l`
	echo "Files: ${file_count}"
}

get_info
