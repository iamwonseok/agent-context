#!/bin/bash
# Bash-04-01: Quote variables in strings - PASS
# Tool: ShellCheck (SC2086)

set -e

process_path() {
	local file_path="$1"
	local dir_name

	if [[ -f "${file_path}" ]]; then
		dir_name=$(dirname "${file_path}")
		echo "Directory: ${dir_name}"
		cat "${file_path}"
	fi
}

copy_files() {
	local source_dir="$1"
	local dest_dir="$2"

	for file in "${source_dir}"/*; do
		cp "${file}" "${dest_dir}/"
	done
}

# Handle paths with spaces correctly
process_path "/path/with spaces/file.txt"
