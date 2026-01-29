#!/bin/bash
# Hook: stop
# Called when the agent loop ends
# Finalize the log

set -e

# Read JSON input from stdin
INPUT=$(cat)

# Extract status
STATUS=$(echo "$INPUT" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
LOOP_COUNT=$(echo "$INPUT" | grep -o '"loop_count":[0-9]*' | cut -d':' -f2)

# Use environment variable from sessionStart
LOG_FILE="${AGENT_LOG_FILE:-}"

if [[ -n "$LOG_FILE" && -f "$LOG_FILE" ]]; then
    # Map status to result
    RESULT="OK"
    if [[ "$STATUS" == "error" ]]; then
        RESULT="NG"
    elif [[ "$STATUS" == "aborted" ]]; then
        RESULT="!!"
    fi

    # Log the stop
    {
        echo ""
        echo "---"
        echo "Agent loop ended: [$RESULT] (status: $STATUS, loops: $LOOP_COUNT)"
    } >> "$LOG_FILE"
fi

# No followup message - just complete
echo '{}'
