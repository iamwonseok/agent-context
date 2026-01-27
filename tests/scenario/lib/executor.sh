#!/bin/bash
# Scenario Command Executor
# Executes commands from parsed scenarios with safety checks

# Execute a single command with timeout and capture
# Usage: execute_command <command> [timeout_seconds]
# Returns: exit code, sets EXEC_OUTPUT and EXEC_DURATION
execute_command() {
    local cmd="$1"
    local timeout="${2:-60}"
    
    EXEC_OUTPUT=""
    EXEC_DURATION=0
    EXEC_EXIT_CODE=0
    
    local start_time
    start_time=$(date +%s)
    
    # Execute with timeout
    if command -v timeout > /dev/null 2>&1; then
        EXEC_OUTPUT=$(timeout "$timeout" bash -c "$cmd" 2>&1) || EXEC_EXIT_CODE=$?
    else
        # macOS fallback (no timeout command by default)
        EXEC_OUTPUT=$(bash -c "$cmd" 2>&1) || EXEC_EXIT_CODE=$?
    fi
    
    local end_time
    end_time=$(date +%s)
    EXEC_DURATION=$((end_time - start_time))
    
    return $EXEC_EXIT_CODE
}

# Check if command is safe to execute
# Usage: is_safe_command <command>
# Returns: 0 if safe, 1 if dangerous
is_safe_command() {
    local cmd="$1"
    
    # Dangerous patterns
    local dangerous_patterns=(
        "rm -rf /"
        "rm -rf /*"
        "rm -rf ~"
        "> /dev/sd"
        "dd if="
        "mkfs"
        ":(){:|:&};:"
        "chmod -R 777 /"
        "chown -R"
        "sudo rm"
    )
    
    for pattern in "${dangerous_patterns[@]}"; do
        if [[ "$cmd" == *"$pattern"* ]]; then
            return 1
        fi
    done
    
    return 0
}

# Check if command requires external services
# Usage: requires_external_service <command>
# Returns: service name or empty
requires_external_service() {
    local cmd="$1"
    
    # GitLab commands
    if [[ "$cmd" =~ (pm[[:space:]]+gitlab|GITLAB|gitlab) ]]; then
        echo "gitlab"
        return 0
    fi
    
    # GitHub commands
    if [[ "$cmd" =~ (pm[[:space:]]+github|GITHUB|gh[[:space:]]) ]]; then
        echo "github"
        return 0
    fi
    
    # JIRA commands
    if [[ "$cmd" =~ (pm[[:space:]]+jira|JIRA|jira) ]]; then
        echo "jira"
        return 0
    fi
    
    # Confluence commands
    if [[ "$cmd" =~ (pm[[:space:]]+confluence|CONFLUENCE|confluence) ]]; then
        echo "confluence"
        return 0
    fi
    
    echo ""
    return 1
}

# Check if required service is available
# Usage: check_service_available <service>
check_service_available() {
    local service="$1"
    
    case "$service" in
        gitlab)
            [ -n "$GITLAB_API_TOKEN" ] || [ -n "$GITLAB_TOKEN" ]
            ;;
        github)
            [ -n "$GITHUB_TOKEN" ] || [ -n "$GH_TOKEN" ]
            ;;
        jira)
            [ -n "$JIRA_API_TOKEN" ] || [ -n "$JIRA_TOKEN" ]
            ;;
        confluence)
            [ -n "$CONFLUENCE_API_TOKEN" ] || [ -n "$CONFLUENCE_TOKEN" ]
            ;;
        *)
            return 0
            ;;
    esac
}

# Execute command with dry-run option
# Usage: execute_with_dry_run <command> [dry_run]
execute_with_dry_run() {
    local cmd="$1"
    local dry_run="${2:-false}"
    
    if [ "$dry_run" = true ]; then
        echo "[DRY-RUN] Would execute: $cmd"
        EXEC_OUTPUT="[DRY-RUN]"
        EXEC_EXIT_CODE=0
        EXEC_DURATION=0
        return 0
    fi
    
    # Safety check
    if ! is_safe_command "$cmd"; then
        echo "[BLOCKED] Dangerous command detected: $cmd"
        EXEC_OUTPUT="[BLOCKED]"
        EXEC_EXIT_CODE=1
        return 1
    fi
    
    # Service availability check
    local service
    service=$(requires_external_service "$cmd")
    if [ -n "$service" ] && ! check_service_available "$service"; then
        echo "[SKIP] Service not available: $service"
        EXEC_OUTPUT="[SKIP:$service]"
        EXEC_EXIT_CODE=0
        return 0
    fi
    
    execute_command "$cmd"
}

# Setup test environment
# Usage: setup_test_env <work_dir>
setup_test_env() {
    local work_dir="$1"
    
    # Create work directory if needed
    mkdir -p "$work_dir"
    
    # Set up PATH
    export PATH="${AGENT_CONTEXT_PATH:-$PWD}/tools/agent/bin:${AGENT_CONTEXT_PATH:-$PWD}/tools/pm/bin:$PATH"
    
    # Initialize git if needed
    if [ ! -d "$work_dir/.git" ]; then
        cd "$work_dir" || return 1
        git init -q
        git config user.email "test@example.com"
        git config user.name "E2E Test"
    fi
}

# Cleanup test environment
# Usage: cleanup_test_env <work_dir>
cleanup_test_env() {
    local work_dir="$1"
    
    if [ -d "$work_dir" ] && [[ "$work_dir" == /tmp/* ]]; then
        rm -rf "$work_dir"
    fi
}
