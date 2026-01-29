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
MODEL=$(echo "$INPUT" | grep -o '"model":"[^"]*"' | cut -d'"' -f4)

# Extract model name and normalize
# Examples: claude-sonnet-4 -> sonnet, gpt-4 -> gpt, gemini-2.0 -> gemini
MODEL_NAME="unknown"
if [[ "$MODEL" =~ sonnet ]]; then
    MODEL_NAME="sonnet"
elif [[ "$MODEL" =~ opus ]]; then
    MODEL_NAME="opus"
elif [[ "$MODEL" =~ gpt ]]; then
    MODEL_NAME="gpt"
elif [[ "$MODEL" =~ gemini ]]; then
    MODEL_NAME="gemini"
fi

# Get current branch name
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

# Create log directory
LOG_DIR=".context/logs"
mkdir -p "$LOG_DIR"

# Generate log file path: <branch>-<model>-workflow-YYYY-MM-DD-HH-MM-SS.log
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOG_DIR/${BRANCH}-${MODEL_NAME}-workflow-${TIMESTAMP}.log"

# Initialize log file
{
    echo "====================================="
    echo "Agent Session Log"
    echo "====================================="
    echo "Branch: $BRANCH"
    echo "Model: $MODEL_NAME ($MODEL)"
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
