#!/bin/bash
# Hook: sessionEnd
# Called when a composer conversation ends
# Fire-and-forget - no output needed

set -e

# Read JSON input from stdin
INPUT=$(cat)

# Extract fields
REASON=$(echo "$INPUT" | grep -o '"reason":"[^"]*"' | cut -d'"' -f4)
DURATION_MS=$(echo "$INPUT" | grep -o '"duration_ms":[0-9]*' | cut -d':' -f2)

# Session state file
STATE_FILE=".context/current-session.json"

# Get log file from state file
LOG_FILE=""
if [[ -f "$STATE_FILE" ]]; then
    LOG_FILE=$(grep -o '"log_file":"[^"]*"' "$STATE_FILE" 2>/dev/null | cut -d'"' -f4 || echo "")
fi

if [[ -n "$LOG_FILE" && -f "$LOG_FILE" ]]; then
    # Calculate duration in seconds
    DURATION_S=$((DURATION_MS / 1000))

    # Append session end to log
    {
        echo ""
        echo "====================================="
        echo "End: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Duration: ${DURATION_S}s"
        echo "Reason: $REASON"
        echo "Result: OK"
        echo "====================================="
    } >> "$LOG_FILE"
fi

# No output needed for sessionEnd
echo '{}'
