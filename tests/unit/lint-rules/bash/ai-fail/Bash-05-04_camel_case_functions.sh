#!/bin/bash
# Bash-05-04: Function names use snake_case (FAIL)

# Bad: Function names in camelCase
processFile() {
	local file="$1"
	echo "Processing: ${file}"
}

getConfigValue() {
	local key="$1"
	echo "value_for_${key}"
}

ValidateInputData() {
	local data="$1"
	[[ -n "${data}" ]]
}

main() {
	processFile "test.txt"
	getConfigValue "timeout"
	ValidateInputData "some data"
}

main "$@"
