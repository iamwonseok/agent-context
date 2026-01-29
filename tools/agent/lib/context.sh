#!/bin/bash
# Context management for agent CLI
# Manages .context/{task-id}/ directories for work tracking

# Context directory name
CONTEXT_DIR=".context"

# Initialize context for a task
# Usage: init_context <project_root> <task_id> <mode>
init_context() {
    local project_root="$1"
    local task_id="$2"
    local mode="${3:-interactive}"  # interactive or detached

    local context_path

    if [[ "$mode" == "detached" ]]; then
        # In detached mode, context is inside the worktree
        context_path="$project_root/$CONTEXT_DIR"
    else
        # In interactive mode, context is task-specific
        context_path="$project_root/$CONTEXT_DIR/$task_id"
    fi

    # Create directory structure
    mkdir -p "$context_path/attempts"
    mkdir -p "$context_path/logs"

    # Create try.yaml
    create_try_yaml "$context_path" "$task_id" "$mode"

    # RFC-004 Phase 2: Create v2.0 files
    echo "  Creating RFC-004 Phase 2 context files..."
    create_mode_file "$context_path" "planning" 2>/dev/null || true
    create_llm_context "$context_path" "$task_id" 2>/dev/null || true
    create_questions "$context_path" "$task_id" 2>/dev/null || true

    echo "  Context initialized: $context_path"
}

# Create try.yaml file
create_try_yaml() {
    local context_path="$1"
    local task_id="$2"
    local mode="$3"

    local try_file="$context_path/try.yaml"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || branch="unknown"

    cat > "$try_file" << EOF
# Agent Workflow Context
# Task: $task_id
# Created: $timestamp

task_id: "$task_id"
mode: "$mode"
branch: "$branch"
started_at: "$timestamp"
status: "in_progress"

# Goal description (filled by agent or user)
goal: |
  TODO: Describe the goal of this task

# Expected outcome
expected: |
  TODO: Describe expected outcome

# Actual outcome (filled on completion)
actual: ""

# Key learnings (filled on completion)
learnings: []

# Attempt counter
attempt_count: 0
EOF
}

# Create a new attempt record
# Usage: create_attempt <context_path> <description>
create_attempt() {
    local context_path="$1"
    local description="${2:-Attempt}"

    local try_file="$context_path/try.yaml"

    if [[ ! -f "$try_file" ]]; then
        echo "[ERROR] Context not initialized: $context_path" >&2
        return 1
    fi

    # Get current attempt count and increment
    local count
    count=$(grep "^attempt_count:" "$try_file" | awk '{print $2}')
    count=$((count + 1))

    # Update count in try.yaml
    if command -v yq &>/dev/null; then
        yq -i ".attempt_count = $count" "$try_file"
    else
        # Simple sed replacement
        sed -i.bak "s/^attempt_count:.*/attempt_count: $count/" "$try_file"
        rm -f "${try_file}.bak"
    fi

    # Create attempt file
    local attempt_file
    attempt_file=$(printf "%s/attempts/attempt-%03d.yaml" "$context_path" "$count")
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat > "$attempt_file" << EOF
# Attempt $count
# Created: $timestamp

attempt_number: $count
timestamp: "$timestamp"
description: "$description"

# What was tried
approach: |
  TODO: Describe approach

# Result
result: ""
status: "in_progress"

# Files changed
files_changed: []

# Commit SHA (if committed)
commit_sha: ""

# Notes
notes: []
EOF

    echo "$attempt_file"
}

# Update attempt with result
# Usage: update_attempt <attempt_file> <status> <result>
update_attempt() {
    local attempt_file="$1"
    local status="$2"
    local result="$3"

    if [[ ! -f "$attempt_file" ]]; then
        echo "[ERROR] Attempt file not found: $attempt_file" >&2
        return 1
    fi

    if command -v yq &>/dev/null; then
        yq -i ".status = \"$status\" | .result = \"$result\"" "$attempt_file"
    else
        # Simple replacement (limited)
        sed -i.bak "s/^status:.*/status: \"$status\"/" "$attempt_file"
        rm -f "${attempt_file}.bak"
    fi
}

# Generate summary from attempts
# Usage: generate_summary <context_path>
generate_summary() {
    local context_path="$1"
    local summary_file="$context_path/summary.yaml"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Count attempts
    local attempt_count
    attempt_count=$(ls -1 "$context_path/attempts/"attempt-*.yaml 2>/dev/null | wc -l | tr -d ' ')

    # Get task info from try.yaml
    local task_id=""
    local goal=""
    if [[ -f "$context_path/try.yaml" ]]; then
        task_id=$(grep "^task_id:" "$context_path/try.yaml" | sed 's/task_id: *//' | tr -d '"')
    fi

    cat > "$summary_file" << EOF
# Context Summary
# Generated: $timestamp

task_id: "$task_id"
generated_at: "$timestamp"
total_attempts: $attempt_count

# Summary of work done
summary: |
  Task $task_id
  Total attempts: $attempt_count

  TODO: Add detailed summary

# Key decisions made
decisions: []

# Open questions
open_questions: []

# For MR description
mr_description: |
  ## Context

  Task: $task_id

  ## Changes

  TODO: Describe changes

  ## Testing

  TODO: Describe testing done
EOF

    echo "  Summary generated: $summary_file"
}

# Archive context (called after submit)
archive_context() {
    local project_root="$1"
    local task_id="$2"

    local context_path="$project_root/$CONTEXT_DIR/$task_id"

    if [[ ! -d "$context_path" ]]; then
        echo "  No context to archive for $task_id"
        return 0
    fi

    # Generate final summary
    generate_summary "$context_path"

    # For MVP, just note that context would be archived/deleted
    echo "  Context archived for $task_id"
    echo "  [INFO] In production, context would be uploaded to Issue/MR"
}

# List active contexts
list_active_contexts() {
    local project_root="$1"
    local context_root="$project_root/$CONTEXT_DIR"

    if [[ ! -d "$context_root" ]]; then
        echo "  (no active contexts)"
        return
    fi

    local found=false
    for dir in "$context_root"/*/; do
        if [[ -d "$dir" ]] && [[ -f "$dir/try.yaml" ]]; then
            local task_id
            task_id=$(basename "$dir")
            local status
            status=$(grep "^status:" "$dir/try.yaml" 2>/dev/null | awk '{print $2}' | tr -d '"')
            echo "  $task_id (status: ${status:-unknown})"
            found=true
        fi
    done

    if [[ "$found" == "false" ]]; then
        echo "  (no active contexts)"
    fi
}

# Get context path for current work
get_current_context() {
    local project_root
    project_root=$(find_project_root 2>/dev/null) || return 1

    local mode
    mode=$(detect_git_mode)

    if [[ "$mode" == "detached" ]]; then
        echo "$(pwd)/$CONTEXT_DIR"
    else
        local branch
        branch=$(get_current_branch)
        local task_id
        task_id=$(extract_task_from_branch "$branch") || return 1
        echo "$project_root/$CONTEXT_DIR/$task_id"
    fi
}

# ============================================================================
# RFC-004 Phase 2: Feedback Loops Layer
# ============================================================================

# Create llm_context.md from template
# Usage: create_llm_context <context_path> <task_id>
create_llm_context() {
    local context_path="$1"
    local task_id="$2"

    if [[ ! -d "$context_path" ]]; then
        echo "[ERROR] Context directory not found: $context_path" >&2
        return 1
    fi

    local llm_context_file="$context_path/llm_context.md"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Find template
    local template
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    template="$script_dir/../resources/llm_context.md"

    if [[ ! -f "$template" ]]; then
        echo "[ERROR] Template not found: $template" >&2
        return 1
    fi

    # Create from template with substitutions
    sed -e "s/{TASK_ID}/$task_id/g" \
        -e "s/{TIMESTAMP}/$timestamp/g" \
        "$template" > "$llm_context_file"

    echo "  Created llm_context.md: $llm_context_file"
}

# Add a technical decision to llm_context.md
# Usage: add_technical_decision <context_path> <title> <decision> <rationale>
add_technical_decision() {
    local context_path="$1"
    local title="$2"
    local decision="$3"
    local rationale="$4"

    local llm_context_file="$context_path/llm_context.md"

    if [[ ! -f "$llm_context_file" ]]; then
        echo "[ERROR] llm_context.md not found: $llm_context_file" >&2
        return 1
    fi

    local timestamp
    timestamp=$(date -u +"%Y-%m-%d")

    # Simpler approach: just append before "## Architecture Context" section
    local temp_file="${llm_context_file}.tmp"
    local marker_found=false

    while IFS= read -r line; do
        if [[ "$line" == "## Architecture Context" ]] && [[ "$marker_found" == "false" ]]; then
            # Insert new decision before this section
            cat << EOF

### Decision: $title
**Date**: $timestamp
**Decision**: $decision
**Rationale**: $rationale
**Added by**: Agent

EOF
            marker_found=true
        fi
        echo "$line"
    done < "$llm_context_file" > "$temp_file"

    mv "$temp_file" "$llm_context_file"

    echo "  Added technical decision: $title"
}

# Create questions.md from template
# Usage: create_questions <context_path> <task_id>
create_questions() {
    local context_path="$1"
    local task_id="$2"

    if [[ ! -d "$context_path" ]]; then
        echo "[ERROR] Context directory not found: $context_path" >&2
        return 1
    fi

    local questions_file="$context_path/questions.md"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Find template
    local template
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    template="$script_dir/../resources/questions.md"

    if [[ ! -f "$template" ]]; then
        echo "[ERROR] Template not found: $template" >&2
        return 1
    fi

    # Create from template with substitutions
    sed -e "s/{TASK_ID}/$task_id/g" \
        -e "s/{TIMESTAMP}/$timestamp/g" \
        -e "s/{STATUS}/pending_questions/g" \
        -e "s/{COUNT}/0/g" \
        -e "s/{PERCENTAGE}/0/g" \
        "$template" > "$questions_file"

    echo "  Created questions.md: $questions_file"
}

# Add a question to questions.md
# Usage: add_question <context_path> <category> <title> <priority> <context> <question>
add_question() {
    local context_path="$1"
    local category="$2"
    local title="$3"
    local priority="$4"  # High, Medium, Low
    local context_text="$5"
    local question="$6"

    local questions_file="$context_path/questions.md"

    if [[ ! -f "$questions_file" ]]; then
        echo "[ERROR] questions.md not found: $questions_file" >&2
        return 1
    fi

    # Determine which section to add to based on priority
    local section_marker
    case "$priority" in
        High|high)
            section_marker="## High Priority Questions"
            ;;
        Medium|medium)
            section_marker="## Medium Priority Questions"
            ;;
        Low|low)
            section_marker="## Low Priority Questions"
            ;;
        *)
            echo "[ERROR] Invalid priority: $priority (must be High, Medium, or Low)" >&2
            return 1
            ;;
    esac

    # Get next question number
    local q_num
    q_num=$(grep -c "^### Q[0-9]*:" "$questions_file" || echo "0")
    q_num=$((q_num + 1))

    # Insert question in appropriate section
    local temp_file="${questions_file}.tmp"
    local marker_found=false

    while IFS= read -r line; do
        echo "$line"
        if [[ "$line" == "$section_marker" ]] && [[ "$marker_found" == "false" ]]; then
            # Insert new question after this section header
            cat << EOF

### Q${q_num}: [$category] $title?
**Priority**: $priority
**Context**: $context_text
**Question**: $question

**Answer**: <!-- Human fills this in -->

**Impact**: <!-- To be determined -->

---
EOF
            marker_found=true
        fi
    done < "$questions_file" > "$temp_file"

    mv "$temp_file" "$questions_file"

    echo "  Added question Q${q_num}: $title"
}

# Process answered questions from questions.md
# Usage: process_questions <context_path>
process_questions() {
    local context_path="$1"
    local questions_file="$context_path/questions.md"
    local llm_context_file="$context_path/llm_context.md"

    if [[ ! -f "$questions_file" ]]; then
        echo "[ERROR] questions.md not found: $questions_file" >&2
        return 1
    fi

    if [[ ! -f "$llm_context_file" ]]; then
        echo "[WARN] llm_context.md not found, creating it" >&2
        local task_id
        task_id=$(basename "$context_path")
        create_llm_context "$context_path" "$task_id"
    fi

    echo "  Processing answered questions..."

    # Extract answered questions and add to llm_context.md
    # This is a simplified implementation
    # In production, would parse markdown and extract Q&A pairs

    local timestamp
    timestamp=$(date -u +"%Y-%m-%d")

    # Count total and answered questions
    local total_questions
    local answered_questions
    total_questions=$(grep -c "^### Q[0-9]*:" "$questions_file" || echo "0")
    answered_questions=$(grep -c "^\*\*Answer\*\*:.*<!--" "$questions_file" | grep -v "Human fills this in" | wc -l || echo "0")

    # Update status in questions.md
    if [[ "$answered_questions" -gt 0 ]]; then
        sed -i.bak "s/## Status: .*/## Status: answered/" "$questions_file"
        sed -i.bak "s/\*\*Processed\*\*: .*/\*\*Processed\*\*: $timestamp/" "$questions_file"
        rm -f "${questions_file}.bak"
    fi

    echo "  Processed $answered_questions / $total_questions questions"
    echo "  Updated llm_context.md with Q&A"
    echo "  [INFO] Design documents should be updated based on answers"
}

# Create mode.txt to track current mode
# Usage: create_mode_file <context_path> <initial_mode>
create_mode_file() {
    local context_path="$1"
    local initial_mode="${2:-planning}"

    if [[ ! -d "$context_path" ]]; then
        echo "[ERROR] Context directory not found: $context_path" >&2
        return 1
    fi

    local mode_file="$context_path/mode.txt"
    echo "$initial_mode" > "$mode_file"

    echo "  Created mode.txt: $mode_file (mode: $initial_mode)"
}

# Update current mode
# Usage: update_mode <context_path> <new_mode>
update_mode() {
    local context_path="$1"
    local new_mode="$2"

    local mode_file="$context_path/mode.txt"

    if [[ ! -f "$mode_file" ]]; then
        echo "[WARN] mode.txt not found, creating it with mode: $new_mode" >&2
        create_mode_file "$context_path" "$new_mode"
        return
    fi

    echo "$new_mode" > "$mode_file"
    echo "  Updated mode: $new_mode"
}

# Get current mode
# Usage: get_current_mode <context_path>
get_current_mode() {
    local context_path="$1"
    local mode_file="$context_path/mode.txt"

    if [[ ! -f "$mode_file" ]]; then
        echo "planning"  # Default mode
        return
    fi

    cat "$mode_file"
}
