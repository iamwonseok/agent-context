#!/bin/bash
# Record all demo GIFs
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Recording AI Agent Evolution Demos ==="
echo "raw-intelligence -> role-and-persona -> skills-inheriting-role -> agentize -> squad"
echo ""

for step in 01-raw-intelligence 02-role-and-persona 03-skills-inheriting-role 04-agentize 05-squad; do
    echo "[Recording] $step..."
    cd "$SCRIPT_DIR/$step"
    vhs demo.tape
    echo "[Done] $step"
    echo ""
done

echo "=== All recordings complete ==="
echo ""
echo "Generated GIFs:"
ls -la "$SCRIPT_DIR"/*/*.gif 2>/dev/null || echo "No GIFs found"
