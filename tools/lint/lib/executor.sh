#!/bin/bash
# Executor for lint tools
# Handles external tool execution and configuration discovery

# Get script directory
EXECUTOR_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINT_ROOT="$(cd "$EXECUTOR_SCRIPT_DIR/.." && pwd)"
TEMPLATES_CONFIG="$LINT_ROOT/../../templates/configs"

# =============================================================================
# Tool Detection
# =============================================================================

# Check if a tool exists
# Usage: tool_exists <tool_name>
tool_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get tool version (for logging)
# Usage: tool_version <tool_name>
tool_version() {
    local tool="$1"
    case "$tool" in
        clang-format|clang-format-*)
            "$tool" --version 2>/dev/null | head -1 || echo "unknown"
            ;;
        clang-tidy|clang-tidy-*)
            "$tool" --version 2>/dev/null | head -1 || echo "unknown"
            ;;
        flake8)
            "$tool" --version 2>/dev/null | head -1 || echo "unknown"
            ;;
        black)
            "$tool" --version 2>/dev/null || echo "unknown"
            ;;
        shellcheck)
            "$tool" --version 2>/dev/null | head -1 || echo "unknown"
            ;;
        yamllint)
            "$tool" --version 2>/dev/null || echo "unknown"
            ;;
        hadolint)
            "$tool" --version 2>/dev/null || echo "unknown"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Find best available version of a tool
# Usage: find_tool <base_name> [version_suffix...]
# Example: find_tool clang-format 19 18 17
find_tool() {
    local base="$1"
    shift

    # Try base name first
    if tool_exists "$base"; then
        echo "$base"
        return 0
    fi

    # Try versioned names
    for version in "$@"; do
        local versioned="${base}-${version}"
        if tool_exists "$versioned"; then
            echo "$versioned"
            return 0
        fi
    done

    return 1
}

# =============================================================================
# Configuration Discovery
# =============================================================================

# Find configuration file
# Priority: project root > templates/configs
# Usage: find_config <config_name> [project_root]
find_config() {
    local config_name="$1"
    local project_root="${2:-.}"

    # Check project root first
    if [[ -f "$project_root/$config_name" ]]; then
        echo "$project_root/$config_name"
        return 0
    fi

    # Check templates/configs as fallback
    if [[ -f "$TEMPLATES_CONFIG/$config_name" ]]; then
        echo "$TEMPLATES_CONFIG/$config_name"
        return 0
    fi

    return 1
}

# Get all required configs for a language
# Usage: get_configs_for_lang <lang>
get_configs_for_lang() {
    local lang="$1"
    case "$lang" in
        c|cpp)
            echo ".clang-format .clang-tidy"
            ;;
        python)
            echo ".flake8 pyproject.toml"
            ;;
        bash|shell)
            echo ".shellcheckrc"
            ;;
        yaml)
            echo ".yamllint.yml"
            ;;
        dockerfile|docker)
            echo ".hadolint.yaml"
            ;;
        *)
            echo ""
            ;;
    esac
}

# =============================================================================
# External Tool Execution
# =============================================================================

# Run external tool and capture output
# Usage: run_tool <tool> [args...]
# Returns: exit code, stdout/stderr in TOOL_OUTPUT
run_tool() {
    local tool="$1"
    shift

    if ! tool_exists "$tool"; then
        TOOL_OUTPUT="[ERROR] Tool not found: $tool"
        return 127
    fi

    TOOL_OUTPUT=$("$tool" "$@" 2>&1)
    return $?
}

# Run clang-format check
# Usage: run_clang_format <file> [config_path]
run_clang_format() {
    local file="$1"
    local config="${2:-}"
    local tool

    tool=$(find_tool clang-format 19 18 17 16 15) || {
        echo "[SKIP] clang-format not found"
        return 127
    }

    local args=("--dry-run" "--Werror")
    if [[ -n "$config" ]]; then
        args+=("--style=file:$config")
    fi
    args+=("$file")

    run_tool "$tool" "${args[@]}"
}

# Run clang-tidy check
# Usage: run_clang_tidy <file> [config_path]
run_clang_tidy() {
    local file="$1"
    local config="${2:-}"
    local tool

    tool=$(find_tool clang-tidy 19 18 17 16 15) || {
        echo "[SKIP] clang-tidy not found"
        return 127
    }

    local args=()
    if [[ -n "$config" ]]; then
        args+=("--config-file=$config")
    fi
    args+=("$file" "--")

    run_tool "$tool" "${args[@]}"
}

# Run flake8 check
# Usage: run_flake8 <file> [config_path]
run_flake8() {
    local file="$1"
    local config="${2:-}"

    if ! tool_exists flake8; then
        echo "[SKIP] flake8 not found"
        return 127
    fi

    local args=()
    if [[ -n "$config" ]]; then
        args+=("--config=$config")
    fi
    args+=("$file")

    run_tool flake8 "${args[@]}"
}

# Run black check
# Usage: run_black <file> [config_path]
run_black() {
    local file="$1"
    local config="${2:-}"

    if ! tool_exists black; then
        echo "[SKIP] black not found"
        return 127
    fi

    local args=("--check" "--diff")
    if [[ -n "$config" ]]; then
        args+=("--config=$config")
    fi
    args+=("$file")

    run_tool black "${args[@]}"
}

# Run shellcheck
# Usage: run_shellcheck <file> [config_path]
run_shellcheck() {
    local file="$1"
    local config="${2:-}"

    if ! tool_exists shellcheck; then
        echo "[SKIP] shellcheck not found"
        return 127
    fi

    # shellcheck uses SHELLCHECK_OPTS env var or .shellcheckrc in project
    local args=("-f" "gcc")
    args+=("$file")

    run_tool shellcheck "${args[@]}"
}

# Run yamllint
# Usage: run_yamllint <file> [config_path]
run_yamllint() {
    local file="$1"
    local config="${2:-}"

    if ! tool_exists yamllint; then
        echo "[SKIP] yamllint not found"
        return 127
    fi

    local args=("-f" "parsable")
    if [[ -n "$config" ]]; then
        args+=("-c" "$config")
    fi
    args+=("$file")

    run_tool yamllint "${args[@]}"
}

# Run hadolint
# Usage: run_hadolint <file> [config_path]
run_hadolint() {
    local file="$1"
    local config="${2:-}"

    if ! tool_exists hadolint; then
        echo "[SKIP] hadolint not found"
        return 127
    fi

    local args=("-f" "tty")
    if [[ -n "$config" ]]; then
        args+=("-c" "$config")
    fi
    args+=("$file")

    run_tool hadolint "${args[@]}"
}

# =============================================================================
# Result Formatting
# =============================================================================

# Format tool output for console
# Usage: format_console <tool_name> <exit_code> <output>
format_console() {
    local tool="$1"
    local exit_code="$2"
    local output="$3"

    if [[ $exit_code -eq 0 ]]; then
        echo "[PASS] $tool"
    elif [[ $exit_code -eq 127 ]]; then
        echo "[SKIP] $tool (not installed)"
    else
        echo "[FAIL] $tool"
        if [[ -n "$output" ]]; then
            echo "$output" | sed 's/^/  /'
        fi
    fi
}

# Check tool availability and print status
# Usage: check_tools_status <lang>
check_tools_status() {
    local lang="$1"

    echo "=== Tool Availability ==="
    case "$lang" in
        c|cpp)
            local cf ct
            cf=$(find_tool clang-format 19 18 17 16 15) && echo "[OK] clang-format: $(tool_version "$cf")" || echo "[--] clang-format: not found"
            ct=$(find_tool clang-tidy 19 18 17 16 15) && echo "[OK] clang-tidy: $(tool_version "$ct")" || echo "[--] clang-tidy: not found"
            ;;
        python)
            tool_exists flake8 && echo "[OK] flake8: $(tool_version flake8)" || echo "[--] flake8: not found"
            tool_exists black && echo "[OK] black: $(tool_version black)" || echo "[--] black: not found"
            ;;
        bash|shell)
            tool_exists shellcheck && echo "[OK] shellcheck: $(tool_version shellcheck)" || echo "[--] shellcheck: not found"
            ;;
        yaml)
            tool_exists yamllint && echo "[OK] yamllint: $(tool_version yamllint)" || echo "[--] yamllint: not found"
            ;;
        dockerfile|docker)
            tool_exists hadolint && echo "[OK] hadolint: $(tool_version hadolint)" || echo "[--] hadolint: not found"
            ;;
    esac
    echo ""
}
