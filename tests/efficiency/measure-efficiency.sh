#!/bin/bash
# Efficiency Measurement Script
# Usage: bash tests/efficiency/measure-efficiency.sh [scenario-id]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_usage() {
    cat << EOF
Usage: $0 [scenario-id]

Scenarios:
  01  Path Update
  02  Language Cleanup
  03  Doc Creation
  04  Test Update
  05  Batch Files

Example:
  $0 01
  $0 all
EOF
}

measure_scenario() {
    local id="$1"
    local scenario_file="${SCRIPT_DIR}/scenario-${id}-*.md"
    
    if ! ls $scenario_file 1> /dev/null 2>&1; then
        echo -e "${RED}Scenario $id not found${NC}"
        return 1
    fi
    
    local scenario_name=$(basename $scenario_file .md)
    
    echo ""
    echo "=========================================="
    echo "Scenario: $scenario_name"
    echo "=========================================="
    echo ""
    
    # Extract success criteria from scenario file
    echo "Success Criteria:"
    grep -A 10 "Success Criteria" $scenario_file | head -15
    
    echo ""
    echo "Instructions:"
    echo "1. Execute the scenario manually"
    echo "2. Count tool calls used"
    echo "3. Compare against criteria above"
    echo ""
    
    echo -e "${YELLOW}[INFO] This is a manual measurement script.${NC}"
    echo -e "${YELLOW}[INFO] Automated measurement requires tool call logging.${NC}"
}

main() {
    local scenario="${1:-}"
    
    if [[ -z "$scenario" ]]; then
        show_usage
        exit 0
    fi
    
    if [[ "$scenario" == "all" ]]; then
        for id in 01 02 03 04 05; do
            measure_scenario "$id"
        done
    else
        measure_scenario "$scenario"
    fi
}

main "$@"
