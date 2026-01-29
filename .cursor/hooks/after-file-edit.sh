#!/bin/bash
# Hook: afterFileEdit
# Called after the Agent edits a file
# Log the edit for context tracking

set -e

# Read JSON input from stdin
INPUT=$(cat)

# Extract file path
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | cut -d'"' -f4)

# Use environment variable from sessionStart
LOG_FILE="${AGENT_LOG_FILE:-}"

if [[ -n "$LOG_FILE" && -f "$LOG_FILE" ]]; then
    # Determine skill based on file type/path
    SKILL="implement"
    if [[ "$FILE_PATH" == *"test"* ]]; then
        SKILL="test"
    elif [[ "$FILE_PATH" == *".md" ]]; then
        SKILL="design"
    fi

    # Get relative path
    REL_PATH="${FILE_PATH#$PWD/}"

    # Log the edit
    {
        echo "> edit $REL_PATH → [OK]"
    } >> "$LOG_FILE"
fi

# No output needed
echo '{}'
