#!/bin/bash
# Bash-05-04: Function names use snake_case (PASS)

# Good: Function names in snake_case
process_file() {
	local file="$1"
	echo "Processing: ${file}"
}

get_config_value() {
	local key="$1"
	echo "value_for_${key}"
}

validate_input_data() {
	local data="$1"
	[[ -n "${data}" ]]
}

main() {
	process_file "test.txt"
	get_config_value "timeout"
	validate_input_data "some data"
}

main "$@"
