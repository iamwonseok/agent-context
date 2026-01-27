#!/bin/bash
# AI-based C Code Review for Detectable=No rules
# Usage: ./test_c_ai_review.sh [file.c] > junit-c-ai.xml
#
# Prerequisites:
#   docker-compose -f docker-compose.ollama.yml up -d
#   docker-compose -f docker-compose.ollama.yml exec ollama ollama pull qwen2.5-coder:14b

# Note: Removed 'set -e' to allow graceful error handling for network failures

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/../../.."

source "${SCRIPT_DIR}/junit_helper.sh"

# Configuration
OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
OLLAMA_MODEL="${OLLAMA_MODEL:-qwen2.5-coder:14b}"
TIMEOUT_SECONDS=120

PASS_COUNT=0
FAIL_COUNT=0
TEST_CASES=""
REVIEW_RESULTS=""
DETAILED_RESULTS=""

# Load rules from external file (Detectable=No rules for AI review)
UNDETECTABLE_RULES=()
RULES_FILE="${SCRIPT_DIR}/rules/c_ai_rules.txt"
if [[ -f "${RULES_FILE}" ]]; then
	while IFS= read -r line; do
		[[ -z "$line" || "$line" == \#* ]] && continue
		UNDETECTABLE_RULES+=("$line")
	done < "${RULES_FILE}"
fi

# Check if Ollama is running
check_ollama() {
	echo "Checking Ollama at ${OLLAMA_HOST}..." >&2
	if ! curl -s --max-time 10 "${OLLAMA_HOST}/api/tags" >/dev/null 2>&1; then
		echo "Warning: Ollama is not running at ${OLLAMA_HOST} - skipping AI review" >&2
		echo "To enable AI review:" >&2
		echo "  Start Ollama: OLLAMA_HOST=0.0.0.0 ollama serve" >&2
		echo "  Pull model: ollama pull ${OLLAMA_MODEL}" >&2
		# Output valid JUnit XML with skipped status
		cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="CodingConvention.C.AI" tests="0" failures="0" errors="0" skipped="1">
    <testcase classname="c.ai" name="ollama_connection" time="0.01">
      <skipped message="Ollama not available">
Ollama is not accessible at ${OLLAMA_HOST} - AI review skipped

To enable AI review:
1. Start Ollama: OLLAMA_HOST=0.0.0.0 ollama serve
2. Pull model: ollama pull ${OLLAMA_MODEL}
3. Ensure firewall allows connection (port 11434)
      </skipped>
    </testcase>
  </testsuite>
</testsuites>
EOF
		exit 0
	fi
	echo "Ollama is running" >&2
}

# Check if model is available
check_model() {
	local models
	models=$(curl -s "${OLLAMA_HOST}/api/tags" | grep -o "\"name\":\"[^\"]*\"" | grep -o "${OLLAMA_MODEL}" || true)
	if [[ -z "${models}" ]]; then
		echo "Warning: Model ${OLLAMA_MODEL} not found. Pulling..." >&2
		curl -s "${OLLAMA_HOST}/api/pull" -d "{\"name\": \"${OLLAMA_MODEL}\"}" >/dev/null
	fi
}

# Build the AI prompt for code review
build_prompt() {
	local file="$1"
	local code
	code=$(cat "${file}")

	local rules_text=""
	for rule in "${UNDETECTABLE_RULES[@]}"; do
		local rule_id="${rule%%|*}"
		local rule_desc="${rule#*|}"
		rules_text+="- ${rule_id}: ${rule_desc}"$'\n'
	done

	cat <<EOF
You are a C code reviewer. Review the following code against these coding convention rules:

${rules_text}

For each rule, determine if the code PASSES or FAILS.
If a rule is not applicable to the code, mark it as PASS.

Output format (JSON array):
[
  {"rule": "C-XX-XX", "status": "PASS|FAIL", "line": <line_number_or_null>, "reason": "brief explanation"}
]

Code to review (${file}):
\`\`\`c
${code}
\`\`\`

Return ONLY the JSON array, no other text.
EOF
}

# Call Ollama API
call_ollama() {
	local prompt="$1"

	local response
	response=$(curl -s --max-time "${TIMEOUT_SECONDS}" "${OLLAMA_HOST}/api/generate" \
		-d "$(jq -n --arg model "${OLLAMA_MODEL}" --arg prompt "${prompt}" \
			'{model: $model, prompt: $prompt, stream: false, options: {temperature: 0.1}}')" 2>/dev/null)

	if [[ -z "${response}" ]]; then
		echo "[]"
		return 1
	fi

	# Extract the response text
	echo "${response}" | jq -r '.response // "[]"' 2>/dev/null || echo "[]"
}

# Parse AI response and extract results
parse_ai_response() {
	local response="$1"

	# Debug: show raw response
	if [[ "${DEBUG:-}" == "1" ]]; then
		echo "=== Raw AI Response ===" >&2
		echo "${response}" >&2
		echo "=== End Raw Response ===" >&2
	fi

	# Remove markdown code block markers (```json or ```)
	local cleaned
	cleaned=$(echo "${response}" | sed 's/^```json//g; s/^```//g; s/```$//g')

	# Try to extract JSON array from response
	# Method 1: Try direct jq parsing (if response is clean JSON)
	if echo "${cleaned}" | jq -e 'type == "array"' >/dev/null 2>&1; then
		echo "${cleaned}" | jq -c '.'
		return
	fi

	# Method 2: Extract JSON array from mixed text
	# Handle multiline JSON by collecting everything between [ and ]
	local json
	json=$(echo "${cleaned}" | \
		awk '/\[/{found=1} found{print} /\]/{if(found) exit}' | \
		jq -c '.' 2>/dev/null)

	# Validate JSON
	if [[ -n "${json}" ]] && echo "${json}" | jq -e 'type == "array"' >/dev/null 2>&1; then
		echo "${json}"
	else
		echo "[]"
	fi
}

# Generate markdown report
generate_markdown_report() {
	echo "# AI Code Review Report"
	echo ""
	echo "| Metric | Value |"
	echo "|--------|-------|"
	echo "| Model | ${OLLAMA_MODEL} |"
	echo "| Total | $((PASS_COUNT + FAIL_COUNT)) |"
	echo "| Passed | ${PASS_COUNT} |"
	echo "| Failed | ${FAIL_COUNT} |"
	echo ""
	echo "## Results"
	echo ""
	echo "${DETAILED_RESULTS}"
}

# Review a single file
review_file() {
	local file="$1"
	local filename
	filename=$(basename "${file}")

	echo "Reviewing: ${filename}" >&2

	local prompt
	prompt=$(build_prompt "${file}")

	local raw_response
	raw_response=$(call_ollama "${prompt}")

	local results
	results=$(parse_ai_response "${raw_response}")

	# Process each rule result
	local pass_rules=()
	local fail_rules=()

	while IFS= read -r item; do
		local rule status line reason
		rule=$(echo "${item}" | jq -r '.rule // "unknown"')
		status=$(echo "${item}" | jq -r '.status // "PASS"')
		line=$(echo "${item}" | jq -r '.line // "N/A"')
		reason=$(echo "${item}" | jq -r '.reason // ""')

		if [[ "${status}" == "FAIL" ]]; then
			fail_rules+=("${rule}: Line ${line} - ${reason}")
		else
			pass_rules+=("${rule}: ${reason}")
		fi
	done < <(echo "${results}" | jq -c '.[]' 2>/dev/null)

	# Generate test case output
	if [[ ${#fail_rules[@]} -eq 0 ]]; then
		local output="AI Review: PASS (${#pass_rules[@]} rules)"
		DETAILED_RESULTS+="- [OK] ${filename}: ${#pass_rules[@]} rules passed"$'\n'
		TEST_CASES+="$(junit_pass "c.ai" "${filename}" "1.00" "${output}")"$'\n'
		PASS_COUNT=$((PASS_COUNT + 1))
		REVIEW_RESULTS+="${filename}: PASS"$'\n'
	else
		local output="AI Review: FAIL"$'\n'
		DETAILED_RESULTS+="- [NG] ${filename}:"$'\n'
		for r in "${fail_rules[@]}"; do
			output+="  [NG] ${r}"$'\n'
			DETAILED_RESULTS+="  - ${r}"$'\n'
		done
		TEST_CASES+="$(junit_fail "c.ai" "${filename}" "Violations found" "1.00" "${output}")"$'\n'
		FAIL_COUNT=$((FAIL_COUNT + 1))
		REVIEW_RESULTS+="${filename}: FAIL (${#fail_rules[@]} issues)"$'\n'
	fi
}

# Main
main() {
	local files=("$@")

	# Check prerequisites
	check_ollama
	check_model

	# If no files specified, use AI test case directories
	if [[ ${#files[@]} -eq 0 ]]; then
		local ai_test_dir="${PROJECT_ROOT}/coding-convention/tests/c"

		# Check ai-pass and ai-fail directories
		if [[ -d "${ai_test_dir}/ai-pass" ]] || [[ -d "${ai_test_dir}/ai-fail" ]]; then
			echo "Using AI test case directories" >&2

			# Add ai-pass files
			for file in "${ai_test_dir}"/ai-pass/*.c; do
				[[ -f "${file}" ]] && files+=("${file}")
			done

			# Add ai-fail files
			for file in "${ai_test_dir}"/ai-fail/*.c; do
				[[ -f "${file}" ]] && files+=("${file}")
			done
		else
			# Fallback: find all .c files
			while IFS= read -r -d '' file; do
				files+=("${file}")
			done < <(find "${ai_test_dir}" -name "*.c" -print0 2>/dev/null)
		fi
	fi

	if [[ ${#files[@]} -eq 0 ]]; then
		echo "No C files found" >&2
		junit_testsuite "CodingConvention.C.AI" "0" "0" "" "0" && exit 0
	fi

	echo "AI Review: ${#files[@]} files, ${#UNDETECTABLE_RULES[@]} rules" >&2

	for file in "${files[@]}"; do
		if [[ -f "${file}" ]]; then
			review_file "${file}"
		fi
	done

	# Print summary to stderr
	echo "" >&2
	echo "AI Review: Total=$((PASS_COUNT + FAIL_COUNT)) Passed=${PASS_COUNT} Failed=${FAIL_COUNT}" >&2
	echo "${REVIEW_RESULTS}" >&2

	# Generate Markdown report if REPORT_FILE is set
	if [[ -n "${REPORT_FILE:-}" ]]; then
		generate_markdown_report > "${REPORT_FILE}"
		echo "Report saved to: ${REPORT_FILE}" >&2
	fi

	local total=$((PASS_COUNT + FAIL_COUNT))
	junit_testsuite "CodingConvention.C.AI" "${total}" "${FAIL_COUNT}" "${TEST_CASES}" "1"
}

main "$@"
