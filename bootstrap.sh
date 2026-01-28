#!/bin/bash
# bootstrap.sh
# Bootstrap script for agent-context installation
#
# Usage:
#   ./bootstrap.sh              # Check prerequisites and show install instructions
#   ./bootstrap.sh --install    # Auto-install agent-context to ~/.agent
#
# One-liner installation:
#   curl -sL https://example.com/bootstrap.sh | bash -s -- --install
#
# Supported environments:
#   - macOS 15+ (Sequoia)
#   - Ubuntu 22.04+
#   - Windows (WSL or Git Bash)

set -e

# Colors (if terminal supports)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Parse arguments
AUTO_INSTALL=false
for arg in "$@"; do
    case $arg in
        --install)
            AUTO_INSTALL=true
            ;;
        --help|-h)
            echo "Usage: bootstrap.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --install    Auto-install agent-context to ~/.agent"
            echo "  --help, -h   Show this help message"
            echo ""
            echo "Supported environments:"
            echo "  - macOS 15+ (Sequoia)"
            echo "  - Ubuntu 22.04+"
            echo "  - Windows (WSL or Git Bash)"
            exit 0
            ;;
    esac
done

echo "========================================="
echo "Agent Context Bootstrap"
echo "========================================="
echo ""

# Detect OS
detect_os() {
    local os_name=""
    local os_version=""

    case "$(uname -s)" in
        Darwin)
            os_name="macOS"
            os_version="$(sw_vers -productVersion 2>/dev/null || echo 'unknown')"
            ;;
        Linux)
            if [[ -f /etc/os-release ]]; then
                # shellcheck disable=SC1091
                . /etc/os-release
                os_name="${NAME:-Linux}"
                os_version="${VERSION_ID:-unknown}"
            elif grep -qi microsoft /proc/version 2>/dev/null; then
                os_name="WSL"
                os_version="unknown"
            else
                os_name="Linux"
                os_version="unknown"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            os_name="Windows (Git Bash)"
            os_version="unknown"
            ;;
        *)
            os_name="Unknown"
            os_version="unknown"
            ;;
    esac

    echo "${os_name}|${os_version}"
}

# Check if command exists
check_command() {
    local cmd="$1"
    local name="$2"

    if command -v "$cmd" >/dev/null 2>&1; then
        local version
        version=$("$cmd" --version 2>/dev/null | head -1 || echo "installed")
        printf "  ${GREEN}[OK]${NC} %s: %s\n" "$name" "$version"
        return 0
    else
        printf "  ${RED}[MISSING]${NC} %s\n" "$name"
        return 1
    fi
}

# Detect and display OS
OS_INFO=$(detect_os)
OS_NAME="${OS_INFO%%|*}"
OS_VERSION="${OS_INFO##*|}"

echo "System Information:"
echo "  OS: ${OS_NAME} ${OS_VERSION}"
echo "  Shell: ${SHELL:-unknown}"
echo "  Bash: ${BASH_VERSION:-unknown}"
echo ""

# Check prerequisites
echo "Checking prerequisites..."
MISSING=0

check_command git "Git" || MISSING=$((MISSING + 1))
check_command curl "curl" || MISSING=$((MISSING + 1))

echo ""

# Show warnings for unsupported environments
case "$OS_NAME" in
    macOS)
        # macOS version check (15+)
        MAJOR_VERSION="${OS_VERSION%%.*}"
        if [[ "$MAJOR_VERSION" =~ ^[0-9]+$ ]] && [[ "$MAJOR_VERSION" -lt 15 ]]; then
            printf "${YELLOW}[WARN]${NC} macOS %s detected. Recommended: macOS 15+\n" "$OS_VERSION"
        fi
        ;;
    Ubuntu)
        # Ubuntu version check (22.04+)
        if [[ "$OS_VERSION" =~ ^([0-9]+)\. ]]; then
            MAJOR_VERSION="${BASH_REMATCH[1]}"
            if [[ "$MAJOR_VERSION" -lt 22 ]]; then
                printf "${YELLOW}[WARN]${NC} Ubuntu %s detected. Recommended: Ubuntu 22.04+\n" "$OS_VERSION"
            fi
        fi
        ;;
esac

# Check result
if [[ "$MISSING" -gt 0 ]]; then
    echo ""
    printf "${RED}[ERROR]${NC} Missing %d prerequisite(s). Please install them first.\n" "$MISSING"
    echo ""
    echo "Installation guide:"
    case "$OS_NAME" in
        macOS)
            echo "  brew install git curl"
            ;;
        Ubuntu|Debian*)
            echo "  sudo apt update && sudo apt install -y git curl"
            ;;
        *)
            echo "  Please install git and curl using your package manager"
            ;;
    esac
    exit 1
fi

printf "${GREEN}[OK]${NC} All prerequisites satisfied!\n"
echo ""

# Auto-install or show instructions
if [[ "$AUTO_INSTALL" == "true" ]]; then
    echo "========================================="
    echo "Installing agent-context..."
    echo "========================================="
    echo ""

    # Determine installation source
    SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"

    if [[ -f "${SCRIPT_DIR}/setup.sh" ]]; then
        # Local installation (script is in agent-context repo)
        echo "[INFO] Installing from local source: ${SCRIPT_DIR}"
        "${SCRIPT_DIR}/setup.sh" --global --non-interactive
    else
        # Remote installation (one-liner)
        REPO_URL="https://github.com/example/agent-context.git"
        INSTALL_DIR="$HOME/.agent"

        echo "[INFO] Cloning agent-context repository..."

        if [[ -d "$INSTALL_DIR" ]]; then
            printf "${YELLOW}[WARN]${NC} ~/.agent already exists. Updating...\n"
            cd "$INSTALL_DIR"
            git pull --ff-only || {
                printf "${RED}[ERROR]${NC} Failed to update. Please remove ~/.agent and try again.\n"
                exit 1
            }
        else
            git clone "$REPO_URL" "$INSTALL_DIR" || {
                printf "${RED}[ERROR]${NC} Failed to clone repository.\n"
                exit 1
            }
        fi

        # Remove development files
        rm -rf "$INSTALL_DIR/_dev" 2>/dev/null || true

        printf "${GREEN}[OK]${NC} Installed to ~/.agent\n"
    fi

    echo ""
    echo "========================================="
    echo "Installation Complete!"
    echo "========================================="
    echo ""
    echo "Add to your shell profile (~/.bashrc or ~/.zshrc):"
    echo ""
    echo '  export AGENT_CONTEXT_PATH="$HOME/.agent"'
    echo '  export PATH="$HOME/.agent/tools/agent/bin:$HOME/.agent/tools/pm/bin:$PATH"'
    echo ""
    echo "Then restart your shell or run:"
    echo "  source ~/.bashrc  # or source ~/.zshrc"
    echo ""
    echo "Verify installation:"
    echo "  agnt-c --version"
    echo ""
else
    echo "========================================="
    echo "Ready to Install"
    echo "========================================="
    echo ""
    echo "Option 1: Global installation"
    echo "  ./bootstrap.sh --install"
    echo ""
    echo "Option 2: Project-level installation"
    echo "  cd your-project"
    echo "  /path/to/agent-context/setup.sh"
    echo ""
    echo "Option 3: One-liner (from GitHub)"
    echo "  curl -sL https://example.com/bootstrap.sh | bash -s -- --install"
    echo ""
fi
