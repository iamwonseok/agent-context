#!/bin/bash
# Generate skills_index.json from SKILL.md files
# Usage: ./scripts/generate-index.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_DIR="$PROJECT_ROOT/skills"
OUTPUT_FILE="$PROJECT_ROOT/skills_index.json"

# Parse YAML frontmatter from SKILL.md
parse_frontmatter() {
    local file="$1"
    local key="$2"
    
    # Extract value between --- markers
    sed -n '/^---$/,/^---$/p' "$file" | \
        grep "^${key}:" | \
        sed "s/^${key}:[[:space:]]*//" | \
        sed 's/^"\(.*\)"$/\1/'
}

# Parse array from frontmatter (inputs/outputs)
parse_array() {
    local file="$1"
    local key="$2"
    
    sed -n '/^---$/,/^---$/p' "$file" | \
        sed -n "/^${key}:/,/^[a-z]/p" | \
        grep "^  - " | \
        sed 's/^  - //' | \
        tr '\n' '|' | \
        sed 's/|$//'
}

# Extract "When to Use" section
parse_when_to_use() {
    local file="$1"
    
    # Get first 3 bullet points after "## When to Use"
    sed -n '/^## When to Use/,/^##/p' "$file" | \
        grep "^- " | \
        head -3 | \
        sed 's/^- //' | \
        tr '\n' '; ' | \
        sed 's/; $//'
}

# Build JSON
echo "Generating skills index..."

# Start JSON
echo '{' > "$OUTPUT_FILE"
echo '  "version": "1.0",' >> "$OUTPUT_FILE"
echo '  "generated": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",' >> "$OUTPUT_FILE"
echo '  "skills": [' >> "$OUTPUT_FILE"

first=true

# Find all SKILL.md files (excluding _template)
while IFS= read -r -d '' skill_file; do
    # Skip template
    if [[ "$skill_file" == *"_template"* ]]; then
        continue
    fi
    
    # Get relative path
    rel_path="${skill_file#$PROJECT_ROOT/}"
    skill_dir="$(dirname "$rel_path")"
    
    # Parse frontmatter
    name=$(parse_frontmatter "$skill_file" "name")
    category=$(parse_frontmatter "$skill_file" "category")
    description=$(parse_frontmatter "$skill_file" "description")
    version=$(parse_frontmatter "$skill_file" "version")
    role=$(parse_frontmatter "$skill_file" "role")
    mode=$(parse_frontmatter "$skill_file" "mode")
    cursor_mode=$(parse_frontmatter "$skill_file" "cursor_mode")
    inputs=$(parse_array "$skill_file" "inputs")
    outputs=$(parse_array "$skill_file" "outputs")
    when_to_use=$(parse_when_to_use "$skill_file")
    
    # Skip if no name
    if [[ -z "$name" ]]; then
        echo "[WARN] Skipping $skill_file - no name found"
        continue
    fi
    
    # Add comma for previous entry
    if [[ "$first" != "true" ]]; then
        echo ',' >> "$OUTPUT_FILE"
    fi
    first=false
    
    # Write JSON entry
    cat >> "$OUTPUT_FILE" << EOF
    {
      "name": "$name",
      "path": "$skill_dir",
      "category": "$category",
      "description": "$description",
      "version": "$version",
      "role": "$role",
      "mode": "$mode",
      "cursor_mode": "$cursor_mode",
      "when_to_use": "$when_to_use",
      "inputs": "$(echo "$inputs" | sed 's/"/\\"/g')",
      "outputs": "$(echo "$outputs" | sed 's/"/\\"/g')"
    }
EOF

done < <(find "$SKILLS_DIR" -name "SKILL.md" -print0 | sort -z)

# Close JSON
echo '' >> "$OUTPUT_FILE"
echo '  ]' >> "$OUTPUT_FILE"
echo '}' >> "$OUTPUT_FILE"

# Count skills
skill_count=$(grep -c '"name":' "$OUTPUT_FILE" || echo 0)
echo "[OK] Generated $OUTPUT_FILE with $skill_count skills"
