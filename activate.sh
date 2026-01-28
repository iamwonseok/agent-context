# activate.sh - Load agent-context session environment
#
# This script should be sourced, not executed:
#   source .agent/activate.sh
#   source /path/to/agent-context/activate.sh
#
# Usage:
#   # Project-local installation
#   cd your-project
#   git clone https://github.com/iamwonseok/agent-context.git .agent
#   source .agent/activate.sh
#
#   # Or from any location
#   source /path/to/agent-context/activate.sh

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "[ERROR] This script must be sourced, not executed"
    echo "Usage: source ${0}"
    exit 1
fi

# Get the directory where activate.sh is located
_AGENT_ACTIVATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set AGENT_CONTEXT_PATH
export AGENT_CONTEXT_PATH="${_AGENT_ACTIVATE_DIR}"

# Add tools to PATH (only if not already present)
_add_to_path() {
    local dir="$1"
    if [[ -d "$dir" ]] && [[ ":$PATH:" != *":$dir:"* ]]; then
        export PATH="$dir:$PATH"  # Prepend to take precedence
    fi
}

_add_to_path "${_AGENT_ACTIVATE_DIR}/tools/agent/bin"
_add_to_path "${_AGENT_ACTIVATE_DIR}/tools/pm/bin"
_add_to_path "${_AGENT_ACTIVATE_DIR}/tools/lint/bin"

# Clean up
unset _AGENT_ACTIVATE_DIR
unset -f _add_to_path

echo "[OK] Agent context activated"
echo "     AGENT_CONTEXT_PATH=${AGENT_CONTEXT_PATH}"
echo ""
echo "Available commands: agnt-c, pm, lint"
echo "Run 'agnt-c setup' to install templates to your project"
