#!/bin/bash
# Bash-03-01: Use ${var} format - FAIL (unbraced variables)
# Tool: ShellCheck (require-variable-braces)

set -e

main() {
	local name="test"
	local path="/tmp/$name"
	local count=10

	echo "Name: $name"
	echo "Path: $path"
	echo "Count: $count"

	for file in $path/*; do
		echo "File: $file"
	done
}

main "$@"
