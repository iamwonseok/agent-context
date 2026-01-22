#!/bin/bash
# Context installation script
# Installs tools and configs to ~/.context

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# SCRIPT_DIR is tools/lint/, so project root is ../..
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
INSTALL_DIR="${HOME}/.context"
BIN_DIR="${HOME}/.local/bin"

echo -e "${BLUE}Context Installer${NC}"
echo "=================="
echo ""

# Check if already installed
if [[ -d "${INSTALL_DIR}" ]]; then
    echo -e "${YELLOW}Warning: ${INSTALL_DIR} already exists${NC}"
    read -p "Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
    rm -rf "${INSTALL_DIR}"
fi

# Create installation directory
echo -e "${BLUE}Installing to ${INSTALL_DIR}...${NC}"
mkdir -p "${INSTALL_DIR}"

# Copy tools/lint directory
cp -r "${SCRIPT_DIR}" "${INSTALL_DIR}/lint"
chmod +x "${INSTALL_DIR}/lint/bin/"* 2>/dev/null || true
echo -e "  ${GREEN}[v]${NC} tools/lint/"

# Copy tools/pm directory
if [[ -d "${PROJECT_ROOT}/tools/pm" ]]; then
    cp -r "${PROJECT_ROOT}/tools/pm" "${INSTALL_DIR}/pm"
    chmod +x "${INSTALL_DIR}/pm/bin/"* 2>/dev/null || true
    echo -e "  ${GREEN}[v]${NC} tools/pm/"
fi

# Copy configs directory
if [[ -d "${PROJECT_ROOT}/configs" ]]; then
    cp -r "${PROJECT_ROOT}/configs" "${INSTALL_DIR}/configs"
    echo -e "  ${GREEN}[v]${NC} configs/"
fi

echo ""

# Install CLI to PATH
echo -e "${BLUE}Installing CLI...${NC}"
mkdir -p "${BIN_DIR}"

# Link lint tools
for tool in "${INSTALL_DIR}/lint/bin/"*; do
    if [[ -f "${tool}" ]]; then
        name=$(basename "${tool}")
        ln -sf "${tool}" "${BIN_DIR}/${name}"
        echo -e "  ${GREEN}[v]${NC} Linked: ${name}"
    fi
done

# Link pm tool
if [[ -f "${INSTALL_DIR}/pm/bin/pm" ]]; then
    ln -sf "${INSTALL_DIR}/pm/bin/pm" "${BIN_DIR}/pm"
    echo -e "  ${GREEN}[v]${NC} Linked: pm"
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""

# Check if BIN_DIR is in PATH
if [[ ":${PATH}:" != *":${BIN_DIR}:"* ]]; then
    echo -e "${YELLOW}Note: ${BIN_DIR} is not in your PATH${NC}"
    echo ""
    echo "Add this to your ~/.bashrc or ~/.zshrc:"
    echo ""
    echo -e "  ${BLUE}export PATH=\"\${HOME}/.local/bin:\${PATH}\"${NC}"
    echo ""
fi

echo "Usage:"
echo "  lint c .            # Check C files"
echo "  lint python src/    # Check Python files"
echo "  pm jira issue list  # List JIRA issues"
echo "  pm gitlab mr list   # List GitLab MRs"
echo ""
