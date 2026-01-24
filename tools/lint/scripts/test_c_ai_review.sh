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

# Detectable=No rules that AI will check
# Format: "RULE_ID|RULE_DESCRIPTION"
UNDETECTABLE_RULES=(
	"C-01-04|포인터가 아닌 기본 자료형의 연관된 변수는 한 줄에 선언 가능하나, 포인터는 한 줄 선언 금지"
	"C-01-25|주석을 포함한 모든 코드 내 텍스트는 영어를 사용"
	"C-01-26|코드는 그 자체로 설명되도록 작성하며, 불필요한 동작 설명 주석은 지양"
	"C-02-01|구조체와 포인터 정의에 typedef를 사용하여 타입을 숨기지 않음"
	"C-02-02|함수 종료 시 공통된 자원 해제가 필요한 경우에만 goto문 사용"
	"C-02-03|goto 레이블 이름은 해당 위치의 역할이나 이유를 명확히 기술"
	"C-02-04|자원 해제가 필요 없는 단순 종료 시에는 goto 대신 직접 return"
	"C-02-06|호출부의 제어 흐름에 영향을 주는 매크로 사용 금지"
	"C-02-07|매크로 내부에서 인자로 전달되지 않은 외부 변수 참조 금지"
	"C-02-09|매크로를 좌변 값(L-value)으로 사용하여 대입 금지"
	"C-03-01|전역 변수와 함수 이름은 용도를 명확히 알 수 있도록 설명적으로 작성"
	"C-03-02|지역 변수는 간결하게 짓되, 용도에 따라 관습적인 이름 사용"
	"C-03-03|개발자 개인만 아는 모호한 약어 사용 금지"
	"C-03-06|헝가리안 표기법 사용 금지"
	"C-04-01|함수는 한 가지 기능만 명확하게 수행하도록 작게 작성"
	"C-04-06|Public 함수는 명확한 반환 값 규칙을 따름"
	"C-04-07|동작/명령 수행 함수는 int형 에러 코드 반환 (0: 성공, <0: 실패)"
	"C-04-08|상태 확인 함수는 bool형 반환"
	"C-04-09|표준 매크로나 라이브러리 함수를 재구현하지 않음"
)

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

	# Generate test case output and detailed results for report
	if [[ ${#fail_rules[@]} -eq 0 ]]; then
		local output="AI Review Passed"$'\n'
		DETAILED_RESULTS+="### [OK] ${filename}"$'\n\n'
		DETAILED_RESULTS+="**Result:** PASS (${#pass_rules[@]} rules checked)"$'\n\n'
		DETAILED_RESULTS+="<details>"$'\n'
		DETAILED_RESULTS+="<summary>Show details</summary>"$'\n\n'
		for r in "${pass_rules[@]}"; do
			output+="[OK] ${r}"$'\n'
			DETAILED_RESULTS+="- [OK] ${r}"$'\n'
		done
		DETAILED_RESULTS+=$'\n'"</details>"$'\n\n'
		TEST_CASES+="$(junit_pass "c.ai" "${filename}" "1.00" "${output}")"$'\n'
		PASS_COUNT=$((PASS_COUNT + 1))
		REVIEW_RESULTS+="${filename}: PASS (${#pass_rules[@]} rules checked)"$'\n'
	else
		local output="AI Review Found Issues"$'\n'
		DETAILED_RESULTS+="### [NG] ${filename}"$'\n\n'
		DETAILED_RESULTS+="**Result:** FAIL"$'\n\n'
		DETAILED_RESULTS+="| Rule | Line | Issue |"$'\n'
		DETAILED_RESULTS+="|------|------|-------|"$'\n'
		for r in "${fail_rules[@]}"; do
			output+="[NG] ${r}"$'\n'
			# Parse rule info: "C-XX-XX: Line N - reason"
			local rule_id line_info reason_text
			rule_id=$(echo "${r}" | cut -d: -f1)
			line_info=$(echo "${r}" | sed 's/.*Line \([^ ]*\).*/\1/')
			reason_text=$(echo "${r}" | sed 's/.*Line [^ ]* - //')
			DETAILED_RESULTS+="| ${rule_id} | ${line_info} | ${reason_text} |"$'\n'
		done
		DETAILED_RESULTS+=$'\n'
		TEST_CASES+="$(junit_fail "c.ai" "${filename}" "Coding convention violations found" "1.00" "${output}")"$'\n'
		FAIL_COUNT=$((FAIL_COUNT + 1))
		REVIEW_RESULTS+="${filename}: FAIL"$'\n'
		for r in "${fail_rules[@]}"; do
			REVIEW_RESULTS+="  - ${r}"$'\n'
		done
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
		echo "No C files found to review" >&2
		echo "Create test cases in: coding-convention/tests/c/ai-pass/ and ai-fail/" >&2
		junit_testsuite "CodingConvention.C.AI" "0" "0" "" "0"
		exit 0
	fi

	echo "" >&2
	echo "========================================" >&2
	echo "AI Code Review (${OLLAMA_MODEL})" >&2
	echo "Files to review: ${#files[@]}" >&2
	echo "Checking ${#UNDETECTABLE_RULES[@]} Detectable=No rules" >&2
	echo "========================================" >&2

	for file in "${files[@]}"; do
		if [[ -f "${file}" ]]; then
			review_file "${file}"
		fi
	done

	# Print summary to stderr
	{
		echo ""
		echo "=========================================="
		echo "AI Review Summary"
		echo "=========================================="
		echo "Model: ${OLLAMA_MODEL}"
		echo "Total: $((PASS_COUNT + FAIL_COUNT)) | Passed: ${PASS_COUNT} | Failed: ${FAIL_COUNT}"
		echo ""
		echo "[REVIEW RESULTS]"
		echo "${REVIEW_RESULTS}"
		if [[ ${FAIL_COUNT} -eq 0 ]]; then
			echo "All AI reviews passed!"
		else
			echo "Some files have coding convention issues."
		fi
		echo "=========================================="
	} >&2

	# Generate Markdown report if REPORT_FILE is set
	if [[ -n "${REPORT_FILE:-}" ]]; then
		{
			echo "# AI Code Review Report"
			echo ""
			echo "## Summary"
			echo ""
			echo "| Metric | Value |"
			echo "|--------|-------|"
			echo "| Model | ${OLLAMA_MODEL} |"
			echo "| Total Files | $((PASS_COUNT + FAIL_COUNT)) |"
			echo "| Passed | ${PASS_COUNT} |"
			echo "| Failed | ${FAIL_COUNT} |"
			echo "| Timestamp | $(date -Iseconds) |"
			echo ""
			if [[ ${FAIL_COUNT} -eq 0 ]]; then
				echo "> **[OK] All AI reviews passed!**"
			else
				echo "> **[NG] ${FAIL_COUNT} file(s) have coding convention issues.**"
			fi
			echo ""
			echo "## Detailed Results"
			echo ""
			echo "${DETAILED_RESULTS}"
			echo ""
			echo "---"
			echo ""
			echo "## Rules Checked (Detectable=No)"
			echo ""
			echo "These rules cannot be detected by static analysis and require AI review:"
			echo ""
			for rule in "${UNDETECTABLE_RULES[@]}"; do
				local rule_id="${rule%%|*}"
				local rule_desc="${rule#*|}"
				echo "- **${rule_id}**: ${rule_desc}"
			done
		} > "${REPORT_FILE}"
		echo "Report saved to: ${REPORT_FILE}" >&2
	fi

	local total=$((PASS_COUNT + FAIL_COUNT))
	junit_testsuite "CodingConvention.C.AI" "${total}" "${FAIL_COUNT}" "${TEST_CASES}" "1"
}

main "$@"
