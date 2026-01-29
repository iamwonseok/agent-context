#!/bin/bash
# Hook: beforeSubmitPrompt
# Called before user prompt is submitted
# Purpose: Sync .context via symlink in worktree + create session/log files

set -e

# Read JSON input from stdin
INPUT=$(cat)

# ============================================================
# Helper Functions
# ============================================================

get_main_worktree_path() {
    local git_common_dir
    git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)

    if [[ "$git_common_dir" == ".git" ]]; then
        # This is main worktree
        pwd
    else
        # This is a linked worktree - git_common_dir is like /path/to/main/.git
        dirname "$git_common_dir"
    fi
}

setup_context_symlink() {
    local main_path
    main_path=$(get_main_worktree_path)

    # Ensure .context exists in main worktree
    if [[ ! -d "$main_path/.context" ]]; then
        mkdir -p "$main_path/.context"
    fi

    # Create symlink in ALL linked worktrees
    while IFS= read -r worktree_line; do
        # Parse worktree path (first field)
        local worktree_path
        worktree_path=$(echo "$worktree_line" | awk '{print $1}')

        # Skip if empty
        [[ -z "$worktree_path" ]] && continue

        # Skip main worktree
        [[ "$worktree_path" == "$main_path" ]] && continue

        # Skip if already a symlink
        [[ -L "$worktree_path/.context" ]] && continue

        # Remove existing directory if not a symlink
        if [[ -d "$worktree_path/.context" ]]; then
            if [[ "$(ls -A "$worktree_path/.context" 2>/dev/null)" ]]; then
                mv "$worktree_path/.context" "$worktree_path/.context.backup.$(date +%Y%m%d%H%M%S)"
            else
                rmdir "$worktree_path/.context"
            fi
        fi

        # Create symlink
        ln -s "$main_path/.context" "$worktree_path/.context"
    done < <(git worktree list 2>/dev/null)
}

normalize_model_name() {
    local model_value="$1"
    local model_name="unknown"

    if [[ "$model_value" =~ opus ]]; then
        model_name="opus"
    elif [[ "$model_value" =~ sonnet ]]; then
        model_name="sonnet"
    elif [[ "$model_value" =~ gpt ]]; then
        model_name="gpt"
    elif [[ "$model_value" =~ gemini ]]; then
        model_name="gemini"
    fi

    echo "$model_name"
}

# ============================================================
# Main Logic
# ============================================================

# Step 1: Setup .context symlink for worktree
setup_context_symlink

# Step 2: Extract fields from input
MODEL=$(echo "$INPUT" | grep -o '"model":"[^"]*"' | cut -d'"' -f4)
CONVERSATION_ID=$(echo "$INPUT" | grep -o '"conversation_id":"[^"]*"' | cut -d'"' -f4)
GENERATION_ID=$(echo "$INPUT" | grep -o '"generation_id":"[^"]*"' | cut -d'"' -f4)

# Get current branch name
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

# Session state directory (per branch)
STATE_DIR=".context/${BRANCH}"
LOG_BASE_DIR="$STATE_DIR/logs"
SESSION_DIR="$STATE_DIR/sessions"

# Use first 8 characters of conversation_id for filename
CONV_SHORT="${CONVERSATION_ID:0:8}"
GEN_SHORT="${GENERATION_ID:0:8}"
SESSION_FILE="$SESSION_DIR/${CONV_SHORT}.json"
SESSION_INPUT_FILE="$SESSION_DIR/${CONV_SHORT}-input.json"

mkdir -p "$LOG_BASE_DIR" "$SESSION_DIR"

# DEBUG: Log raw input to see available fields (avoid overwriting across sessions)
DEBUG_DIR=".context/debug"
mkdir -p "$DEBUG_DIR"
if [[ -n "$GEN_SHORT" ]]; then
    echo "$INPUT" > "$DEBUG_DIR/${CONV_SHORT}-${GEN_SHORT}-hook-input.json"
else
    echo "$INPUT" > "$DEBUG_DIR/${CONV_SHORT}-hook-input.json"
fi

# Step 3: Create session/log files if new conversation
if [[ ! -f "$SESSION_FILE" ]]; then
    # New conversation - create session files
    TIMESTAMP=$(date +%H:%M:%S)
    DATE_DIR=$(date +%Y-%m-%d)
    LOG_DIR="$LOG_BASE_DIR/$DATE_DIR"
    mkdir -p "$LOG_DIR"

    # Save initial hook input (contains prompt, attachments, etc.)
    echo "$INPUT" > "$SESSION_INPUT_FILE"

    # Split multi-model list
    IFS=',' read -r -a MODEL_LIST <<< "$MODEL"
    if [[ ${#MODEL_LIST[@]} -eq 0 ]]; then
        MODEL_LIST=("unknown")
    fi

    # For multi-model, create ONLY ONE log file per conversation.
    # Keep the full model list in session metadata.
    MODEL_LABEL="unknown"
    FIRST_MODEL_TRIMMED="$(echo "${MODEL_LIST[0]}" | xargs)"
    if [[ -z "$FIRST_MODEL_TRIMMED" ]]; then
        FIRST_MODEL_TRIMMED="unknown"
    fi
    if [[ ${#MODEL_LIST[@]} -gt 1 ]]; then
        MODEL_LABEL="multimodel"
    else
        MODEL_LABEL="$(normalize_model_name "$FIRST_MODEL_TRIMMED")"
    fi

    if [[ -n "$GEN_SHORT" ]]; then
        CURRENT_LOG_FILE="$LOG_DIR/${TIMESTAMP}-${MODEL_LABEL}-${CONV_SHORT}-${GEN_SHORT}-1.log"
    else
        CURRENT_LOG_FILE="$LOG_DIR/${TIMESTAMP}-${MODEL_LABEL}-${CONV_SHORT}-1.log"
    fi

    # Initialize single log file (shared for all models)
    {
        echo "====================================="
        echo "Agent Session Log"
        echo "====================================="
        echo "Branch: $BRANCH"
        echo "Model: $MODEL_LABEL ($MODEL)"
        echo "Conversation ID: $CONVERSATION_ID"
        if [[ -n "$GENERATION_ID" ]]; then
            echo "Generation ID: $GENERATION_ID"
        fi
        echo "Start: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "====================================="
        echo ""
    } > "$CURRENT_LOG_FILE"

    # Build session metadata JSON
    # models: [{ model, model_full, log_file }]
    MODELS_JSON=""
    i=0
    for MODEL_ITEM in "${MODEL_LIST[@]}"; do
        i=$((i + 1))
        MODEL_ITEM_TRIMMED="$(echo "$MODEL_ITEM" | xargs)"
        if [[ -z "$MODEL_ITEM_TRIMMED" ]]; then
            MODEL_ITEM_TRIMMED="unknown"
        fi

        MODEL_NAME="$(normalize_model_name "$MODEL_ITEM_TRIMMED")"

        # Append models entry (simple JSON escaping for quotes/backslashes)
        MODEL_ITEM_ESCAPED=$(printf '%s' "$MODEL_ITEM_TRIMMED" | sed 's/\\/\\\\/g; s/"/\\"/g')
        LOG_FILE_ESCAPED=$(printf '%s' "$CURRENT_LOG_FILE" | sed 's/\\/\\\\/g; s/"/\\"/g')

        ENTRY=$(cat <<EOF
    {
      "model": "$MODEL_NAME",
      "model_full": "$MODEL_ITEM_ESCAPED",
      "log_file": "$LOG_FILE_ESCAPED"
    }
EOF
)
        if [[ -z "$MODELS_JSON" ]]; then
            MODELS_JSON="$ENTRY"
        else
            MODELS_JSON="$MODELS_JSON,
$ENTRY"
        fi
    done

    # Create session metadata file
    cat > "$SESSION_FILE" << EOF
{
  "conversation_id": "$CONVERSATION_ID",
  "generation_id": "$GENERATION_ID",
  "model_full": "$MODEL",
  "models": [
$MODELS_JSON
  ],
  "input_file": "$SESSION_INPUT_FILE",
  "start_time": "$(date +%s)",
  "branch": "$BRANCH"
}
EOF
fi

# Allow prompt to continue
cat << 'EOF'
{
  "continue": true
}
EOF
