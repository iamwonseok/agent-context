#!/bin/bash
# Hook: sessionStart
# Called when a new composer conversation is created
# Output: env variables for subsequent hooks

set -e

# Read JSON input from stdin
INPUT=$(cat)

# Extract fields from input
SESSION_ID=$(echo "$INPUT" | grep -o '"session_id":"[^"]*"' | cut -d'"' -f4)
COMPOSER_MODE=$(echo "$INPUT" | grep -o '"composer_mode":"[^"]*"' | cut -d'"' -f4)

# Create log directory
LOG_DIR=".context/logs"
mkdir -p "$LOG_DIR"

# Generate log file path
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
LOG_FILE="$LOG_DIR/agent_${TIMESTAMP}_${SESSION_ID:0:8}.log"

# Initialize log file
{
    echo "====================================="
    echo "Agent Session Log"
    echo "====================================="
    echo "Session ID: $SESSION_ID"
    echo "Mode: $COMPOSER_MODE"
    echo "Start: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "====================================="
    echo ""
} > "$LOG_FILE"

# Output JSON with environment variables for subsequent hooks
cat <<EOF
{
  "env": {
    "AGENT_LOG_FILE": "$LOG_FILE",
    "AGENT_SESSION_ID": "$SESSION_ID",
    "AGENT_START_TIME": "$(date +%s)"
  },
  "continue": true
}
EOF
