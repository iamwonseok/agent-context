#!/bin/bash
# Bash-03-03: Global variables use UPPER_SNAKE_CASE (PASS)

# Good: Global/environment variables in uppercase
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="/etc/myapp/config"
MAX_RETRIES=3
DEFAULT_TIMEOUT=30

main() {
	# Good: Local variables in lowercase
	local config_path="${CONFIG_FILE}"
	local retry_count=0

	echo "Script directory: ${SCRIPT_DIR}"
}

main "$@"
