#!/bin/bash
# Scenario Markdown Parser
# Extracts executable commands and expected results from scenario documents

# Parse a scenario markdown file and extract commands
# Usage: parse_scenario_commands <file>
# Output: JSON-like format with step info
parse_scenario_commands() {
    local file="$1"
    local in_code_block=false
    local code_lang=""
    local step_num=0
    local current_command=""
    local line_num=0
    
    while IFS= read -r line || [ -n "$line" ]; do
        ((line_num++))
        
        # Detect code block start
        if [[ "$line" =~ ^\`\`\`([a-z]*) ]] && [ "$in_code_block" = false ]; then
            in_code_block=true
            code_lang="${BASH_REMATCH[1]}"
            current_command=""
            continue
        fi
        
        # Detect code block end
        if [[ "$line" == '```' ]] && [ "$in_code_block" = true ]; then
            in_code_block=false
            
            # Only output bash/shell commands
            if [[ "$code_lang" =~ ^(bash|sh|shell|zsh)$ ]] && [ -n "$current_command" ]; then
                ((step_num++))
                # Output command with metadata
                echo "STEP:${step_num}"
                echo "CMD:${current_command}"
                echo "---"
            fi
            
            code_lang=""
            current_command=""
            continue
        fi
        
        # Accumulate code block content
        if [ "$in_code_block" = true ]; then
            # Skip comments and empty lines in commands
            if [[ ! "$line" =~ ^[[:space:]]*# ]] && [ -n "$line" ]; then
                if [ -n "$current_command" ]; then
                    current_command="${current_command}
${line}"
                else
                    current_command="$line"
                fi
            fi
        fi
    done < "$file"
}

# Extract prerequisites section from scenario
# Usage: parse_prerequisites <file>
parse_prerequisites() {
    local file="$1"
    local in_prereq=false
    
    while IFS= read -r line; do
        # Start of prerequisites section
        if [[ "$line" =~ ^##.*[Pp]rerequisites|^##.*[Ss]etup|^##.*[Rr]equirements ]]; then
            in_prereq=true
            continue
        fi
        
        # End of section (next heading)
        if [[ "$line" =~ ^## ]] && [ "$in_prereq" = true ]; then
            break
        fi
        
        # Extract required items
        if [ "$in_prereq" = true ]; then
            # Look for required items (marked with - [ ] or - [x] or just -)
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*\[.\][[:space:]]*(.+) ]]; then
                echo "PREREQ:${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^[[:space:]]*-[[:space:]]*(.+) ]]; then
                echo "PREREQ:${BASH_REMATCH[1]}"
            fi
        fi
    done < "$file"
}

# Extract expected results after each step
# Usage: parse_expected_results <file>
parse_expected_results() {
    local file="$1"
    local step_num=0
    local in_code_block=false
    
    while IFS= read -r line; do
        # Track code blocks
        if [[ "$line" =~ ^\`\`\` ]]; then
            if [ "$in_code_block" = false ]; then
                in_code_block=true
                if [[ "$line" =~ ^\`\`\`(bash|sh|shell) ]]; then
                    ((step_num++))
                fi
            else
                in_code_block=false
            fi
            continue
        fi
        
        # Look for expected results (common patterns)
        if [ "$in_code_block" = false ] && [ $step_num -gt 0 ]; then
            if [[ "$line" =~ ^\*\*[Ee]xpected\*\*:?[[:space:]]*(.+) ]]; then
                echo "EXPECT:${step_num}:${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^[Ee]xpected:?[[:space:]]*(.+) ]]; then
                echo "EXPECT:${step_num}:${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^\*\*[Rr]esult\*\*:?[[:space:]]*(.+) ]]; then
                echo "EXPECT:${step_num}:${BASH_REMATCH[1]}"
            fi
        fi
    done < "$file"
}

# Get scenario metadata (title, purpose)
# Usage: parse_scenario_metadata <file>
parse_scenario_metadata() {
    local file="$1"
    local title=""
    local purpose=""
    
    while IFS= read -r line; do
        # Get title from first heading
        if [ -z "$title" ] && [[ "$line" =~ ^#[[:space:]]+(.+) ]]; then
            title="${BASH_REMATCH[1]}"
        fi
        
        # Get purpose
        if [[ "$line" =~ ^\*\*[Pp]urpose\*\*:?[[:space:]]*(.+) ]]; then
            purpose="${BASH_REMATCH[1]}"
            break
        elif [[ "$line" =~ ^[Pp]urpose:?[[:space:]]*(.+) ]]; then
            purpose="${BASH_REMATCH[1]}"
            break
        fi
    done < "$file"
    
    echo "TITLE:${title}"
    echo "PURPOSE:${purpose}"
}

# List all scenario files in order
# Usage: list_scenarios <directory>
list_scenarios() {
    local dir="$1"
    
    find "$dir" -maxdepth 1 -name "*.md" -type f | \
        grep -E '[0-9]{3}-' | \
        sort
}

# Get scenario number from filename
# Usage: get_scenario_number <filename>
get_scenario_number() {
    local file="$1"
    basename "$file" | grep -oE '^[0-9]{3}' || echo "000"
}
