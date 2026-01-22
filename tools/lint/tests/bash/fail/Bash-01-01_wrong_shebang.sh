#!/bin/sh
# Bash-01-01: Shebang - FAIL (wrong shell)
# Tool: ShellCheck (SC2039, SC3010 when using bash features)

# Using bash-specific features with sh shebang
if [[ "${var}" == "value" ]]; then
	echo "Match"
fi
