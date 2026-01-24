#!/bin/bash
# Bash-03-03: Global variables use UPPER_SNAKE_CASE (FAIL)

# Bad: Global variables in lowercase
script_dir="$(cd "$(dirname "$0")" && pwd)"
config_file="/etc/myapp/config"
max_retries=3
defaultTimeout=30

main() {
	local config_path="${config_file}"
	echo "Script directory: ${script_dir}"
}

main "$@"
