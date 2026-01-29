#!/bin/bash
# Hook: beforeSubmitPrompt
# Called before user prompt is submitted
# Creates/updates log file based on model

set -e

# Read JSON input from stdin
INPUT=$(cat)

# Extract fields from input
MODEL=$(echo "$INPUT" | grep -o '"model":"[^"]*"' | cut -d'"' -f4)
CONVERSATION_ID=$(echo "$INPUT" | grep -o '"conversation_id":"[^"]*"' | cut -d'"' -f4)

# Normalize model name
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

# Session state directory (per branch)
STATE_DIR=".context/${BRANCH}"
STATE_FILE="$STATE_DIR/current-session.json"
LOG_DIR="$STATE_DIR/logs"

mkdir -p "$LOG_DIR"

# Check if we need to create a new log file
CREATE_NEW_LOG=false
CURRENT_LOG_FILE=""

if [[ -f "$STATE_FILE" ]]; then
    # Read current state
    PREV_MODEL=$(grep -o '"model":"[^"]*"' "$STATE_FILE" 2>/dev/null | cut -d'"' -f4 || echo "")
    PREV_CONVERSATION=$(grep -o '"conversation_id":"[^"]*"' "$STATE_FILE" 2>/dev/null | cut -d'"' -f4 || echo "")
    CURRENT_LOG_FILE=$(grep -o '"log_file":"[^"]*"' "$STATE_FILE" 2>/dev/null | cut -d'"' -f4 || echo "")

    # New conversation or model changed
    if [[ "$CONVERSATION_ID" != "$PREV_CONVERSATION" ]] || [[ "$MODEL_NAME" != "$PREV_MODEL" ]]; then
        CREATE_NEW_LOG=true
    fi
else
    CREATE_NEW_LOG=true
fi

if [[ "$CREATE_NEW_LOG" == "true" ]]; then
    # Generate new log file path
    TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
    CURRENT_LOG_FILE="$LOG_DIR/${MODEL_NAME}-${TIMESTAMP}.log"

    # Initialize log file
    {
        echo "====================================="
        echo "Agent Session Log"
        echo "====================================="
        echo "Branch: $BRANCH"
        echo "Model: $MODEL_NAME ($MODEL)"
        echo "Conversation ID: $CONVERSATION_ID"
        echo "Start: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "====================================="
        echo ""
    } > "$CURRENT_LOG_FILE"

    # Update state file
    cat > "$STATE_FILE" << EOF
{
  "conversation_id": "$CONVERSATION_ID",
  "model": "$MODEL_NAME",
  "model_full": "$MODEL",
  "log_file": "$CURRENT_LOG_FILE",
  "start_time": "$(date +%s)"
}
EOF
fi

# Allow prompt to continue
cat << 'EOF'
{
  "continue": true
}
EOF
