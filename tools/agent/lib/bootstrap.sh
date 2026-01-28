# bootstrap.sh - Tool dependency management
# Check and install required tools for agent-context

# Tool definitions by language/category
# Format: "tool_name:check_command:install_command:description"

# C/C++ tools
TOOLS_C=(
    "clang-format:clang-format --version:brew install clang-format:Code formatter for C/C++"
    "clang-tidy:clang-tidy --version:brew install llvm:Static analyzer for C/C++"
)

TOOLS_CPP=(
    "clang-format:clang-format --version:brew install clang-format:Code formatter for C/C++"
    "clang-tidy:clang-tidy --version:brew install llvm:Static analyzer for C/C++"
)

# Python tools
TOOLS_PYTHON=(
    "flake8:flake8 --version:pip install flake8:Python linter"
    "black:black --version:pip install black:Python code formatter"
    "ruff:ruff --version:pip install ruff:Fast Python linter"
    "mypy:mypy --version:pip install mypy:Static type checker"
    "pre-commit:pre-commit --version:pip install pre-commit:Git hook manager"
)

# Shell tools
TOOLS_SHELL=(
    "shellcheck:shellcheck --version:brew install shellcheck:Shell script analyzer"
)

# YAML tools
TOOLS_YAML=(
    "yamllint:yamllint --version:pip install yamllint:YAML linter"
)

# Docker tools
TOOLS_DOCKER=(
    "hadolint:hadolint --version:brew install hadolint:Dockerfile linter"
)

# Common tools (always recommended)
TOOLS_COMMON=(
    "pre-commit:pre-commit --version:pip install pre-commit:Git hook manager"
    "yq:yq --version:brew install yq:YAML processor"
)

# Detect package manager
detect_package_manager() {
    if command -v brew >/dev/null 2>&1; then
        echo "brew"
    elif command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

# Get install command for package manager
get_install_cmd() {
    local tool="$1"
    local default_cmd="$2"
    local pkg_manager
    pkg_manager=$(detect_package_manager)

    case "$pkg_manager" in
        brew)
            # Use default (usually brew)
            echo "$default_cmd"
            ;;
        apt)
            # Map to apt packages
            case "$tool" in
                clang-format) echo "sudo apt-get install -y clang-format" ;;
                clang-tidy) echo "sudo apt-get install -y clang-tidy" ;;
                shellcheck) echo "sudo apt-get install -y shellcheck" ;;
                hadolint) echo "wget -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 && chmod +x /usr/local/bin/hadolint" ;;
                yq) echo "sudo snap install yq" ;;
                *) echo "$default_cmd" ;;
            esac
            ;;
        *)
            echo "$default_cmd"
            ;;
    esac
}

# Check if a tool is installed
check_tool() {
    local check_cmd="$1"
    if eval "$check_cmd" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Parse tool definition string
# Returns: tool_name check_cmd install_cmd description
parse_tool_def() {
    local def="$1"
    echo "$def" | tr ':' '\n'
}

# Get tools for a language
get_tools_for_lang() {
    local lang="$1"
    case "$lang" in
        c) echo "${TOOLS_C[@]}" ;;
        cpp|c++) echo "${TOOLS_CPP[@]}" ;;
        python|py) echo "${TOOLS_PYTHON[@]}" ;;
        shell|bash|sh) echo "${TOOLS_SHELL[@]}" ;;
        yaml|yml) echo "${TOOLS_YAML[@]}" ;;
        docker|dockerfile) echo "${TOOLS_DOCKER[@]}" ;;
        common|all) echo "${TOOLS_COMMON[@]}" ;;
        *) echo "" ;;
    esac
}

# Check tools for specified languages
# Returns: list of missing tools
check_tools() {
    local langs="$1"
    local missing=()
    local checked=()

    # Parse comma-separated languages
    IFS=',' read -ra LANG_ARRAY <<< "$langs"

    for lang in "${LANG_ARRAY[@]}"; do
        lang=$(echo "$lang" | tr '[:upper:]' '[:lower:]' | xargs)  # lowercase and trim

        local tools
        case "$lang" in
            c) tools=("${TOOLS_C[@]}") ;;
            cpp|c++) tools=("${TOOLS_CPP[@]}") ;;
            python|py) tools=("${TOOLS_PYTHON[@]}") ;;
            shell|bash|sh) tools=("${TOOLS_SHELL[@]}") ;;
            yaml|yml) tools=("${TOOLS_YAML[@]}") ;;
            docker|dockerfile) tools=("${TOOLS_DOCKER[@]}") ;;
            common) tools=("${TOOLS_COMMON[@]}") ;;
            all)
                tools=("${TOOLS_C[@]}" "${TOOLS_PYTHON[@]}" "${TOOLS_SHELL[@]}" "${TOOLS_YAML[@]}" "${TOOLS_DOCKER[@]}" "${TOOLS_COMMON[@]}")
                ;;
            *)
                echo "[WARN] Unknown language: $lang" >&2
                continue
                ;;
        esac

        for tool_def in "${tools[@]}"; do
            local tool_name check_cmd install_cmd desc
            IFS=':' read -r tool_name check_cmd install_cmd desc <<< "$tool_def"

            # Skip if already checked
            if [[ " ${checked[*]} " =~ " ${tool_name} " ]]; then
                continue
            fi
            checked+=("$tool_name")

            if ! check_tool "$check_cmd"; then
                missing+=("$tool_def")
            fi
        done
    done

    printf '%s\n' "${missing[@]}"
}

# Display tool status
display_status() {
    local langs="$1"
    local show_all="${2:-false}"

    echo "=================================================="
    echo "Tool Dependency Status"
    echo "=================================================="
    echo ""

    local pkg_manager
    pkg_manager=$(detect_package_manager)
    echo "Package Manager: $pkg_manager"
    echo ""

    # Parse comma-separated languages
    IFS=',' read -ra LANG_ARRAY <<< "$langs"

    local total=0
    local installed=0
    local missing_count=0
    local checked=()

    for lang in "${LANG_ARRAY[@]}"; do
        lang=$(echo "$lang" | tr '[:upper:]' '[:lower:]' | xargs)

        local tools
        local lang_display
        case "$lang" in
            c) tools=("${TOOLS_C[@]}"); lang_display="C" ;;
            cpp|c++) tools=("${TOOLS_CPP[@]}"); lang_display="C++" ;;
            python|py) tools=("${TOOLS_PYTHON[@]}"); lang_display="Python" ;;
            shell|bash|sh) tools=("${TOOLS_SHELL[@]}"); lang_display="Shell" ;;
            yaml|yml) tools=("${TOOLS_YAML[@]}"); lang_display="YAML" ;;
            docker|dockerfile) tools=("${TOOLS_DOCKER[@]}"); lang_display="Docker" ;;
            common) tools=("${TOOLS_COMMON[@]}"); lang_display="Common" ;;
            all)
                tools=("${TOOLS_C[@]}" "${TOOLS_PYTHON[@]}" "${TOOLS_SHELL[@]}" "${TOOLS_YAML[@]}" "${TOOLS_DOCKER[@]}" "${TOOLS_COMMON[@]}")
                lang_display="All"
                ;;
            *)
                continue
                ;;
        esac

        echo "[$lang_display]"

        for tool_def in "${tools[@]}"; do
            local tool_name check_cmd install_cmd desc
            IFS=':' read -r tool_name check_cmd install_cmd desc <<< "$tool_def"

            # Skip if already checked
            if [[ " ${checked[*]} " =~ " ${tool_name} " ]]; then
                continue
            fi
            checked+=("$tool_name")

            total=$((total + 1))

            if check_tool "$check_cmd"; then
                echo "  [OK] $tool_name - $desc"
                installed=$((installed + 1))
            else
                echo "  [MISSING] $tool_name - $desc"
                echo "           Install: $install_cmd"
                missing_count=$((missing_count + 1))
            fi
        done
        echo ""
    done

    echo "=================================================="
    echo "Summary: $installed/$total installed, $missing_count missing"
    echo "=================================================="

    return $missing_count
}

# Install missing tools
install_tools() {
    local langs="$1"
    local dry_run="${2:-false}"

    echo "=================================================="
    echo "Installing Missing Tools"
    echo "=================================================="
    echo ""

    local missing
    missing=$(check_tools "$langs")

    if [[ -z "$missing" ]]; then
        echo "[OK] All required tools are already installed"
        return 0
    fi

    local installed=0
    local failed=0

    while IFS= read -r tool_def; do
        [[ -z "$tool_def" ]] && continue

        local tool_name check_cmd install_cmd desc
        IFS=':' read -r tool_name check_cmd install_cmd desc <<< "$tool_def"

        # Adjust install command for package manager
        install_cmd=$(get_install_cmd "$tool_name" "$install_cmd")

        echo "[INFO] Installing $tool_name..."
        echo "       Command: $install_cmd"

        if [[ "$dry_run" == "true" ]]; then
            echo "       (dry-run, skipping)"
            continue
        fi

        if eval "$install_cmd"; then
            echo "[OK] $tool_name installed successfully"
            installed=$((installed + 1))
        else
            echo "[FAIL] Failed to install $tool_name"
            failed=$((failed + 1))
        fi
        echo ""
    done <<< "$missing"

    echo "=================================================="
    echo "Installation Complete: $installed installed, $failed failed"
    echo "=================================================="

    return $failed
}

# Main bootstrap command
agent_bootstrap() {
    local action="check"
    local langs="all"
    local dry_run=false

    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            --check)
                action="check"
                ;;
            --install)
                action="install"
                ;;
            --dry-run)
                dry_run=true
                ;;
            --lang=*)
                langs="${arg#*=}"
                ;;
            --help|-h)
                cat << 'EOF'
Usage: agnt-c bootstrap [OPTIONS]

Check and install tool dependencies for agent-context.

OPTIONS:
    --check             Check if tools are installed (default)
    --install           Install missing tools
    --dry-run           Show what would be installed without installing
    --lang=<languages>  Specify languages (comma-separated)
    --help, -h          Show this help

LANGUAGES:
    c, cpp, python, shell, yaml, docker, common, all

EXAMPLES:
    agnt-c bootstrap                      # Check all tools
    agnt-c bootstrap --check              # Same as above
    agnt-c bootstrap --lang=python        # Check Python tools only
    agnt-c bootstrap --lang=c,python      # Check C and Python tools
    agnt-c bootstrap --install            # Install all missing tools
    agnt-c bootstrap --install --lang=c   # Install C tools only
    agnt-c bootstrap --install --dry-run  # Show what would be installed

TOOL CATEGORIES:
    c/cpp:    clang-format, clang-tidy
    python:   flake8, black, ruff, mypy, pre-commit
    shell:    shellcheck
    yaml:     yamllint
    docker:   hadolint
    common:   pre-commit, yq
EOF
                return 0
                ;;
            *)
                echo "[ERROR] Unknown option: $arg" >&2
                echo "Run 'agnt-c bootstrap --help' for usage." >&2
                return 1
                ;;
        esac
    done

    case "$action" in
        check)
            display_status "$langs"
            ;;
        install)
            install_tools "$langs" "$dry_run"
            ;;
    esac
}
