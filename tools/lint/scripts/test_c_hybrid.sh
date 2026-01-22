#!/bin/bash
# Hybrid C Code Convention Test (Static + AI)
# Usage: ./test_c_hybrid.sh [--ai] [--static-only] > junit-c-hybrid.xml
#
# Options:
#   --ai          Enable AI review for Detectable=No rules (requires Ollama)
#   --static-only Run only static analysis (default if Ollama not available)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Parse arguments
ENABLE_AI=false
STATIC_ONLY=false

for arg in "$@"; do
	case "${arg}" in
	--ai)
		ENABLE_AI=true
		;;
	--static-only)
		STATIC_ONLY=true
		;;
	esac
done

# Check if Ollama is available
OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
ollama_available() {
	curl -s --max-time 2 "${OLLAMA_HOST}/api/tags" >/dev/null 2>&1
}

echo "" >&2
echo "╔══════════════════════════════════════════════════════════════╗" >&2
echo "║          C Coding Convention Hybrid Test Suite               ║" >&2
echo "╠══════════════════════════════════════════════════════════════╣" >&2

# Run static analysis (always)
echo "║ [1/2] Running Static Analysis (grep + regex patterns)...     ║" >&2
echo "╚══════════════════════════════════════════════════════════════╝" >&2

STATIC_XML=$("${SCRIPT_DIR}/test_c_junit.sh" 2>&1)
STATIC_EXIT=$?

# Determine if AI review should run
RUN_AI=false
if [[ "${STATIC_ONLY}" == "true" ]]; then
	echo "" >&2
	echo "Skipping AI review (--static-only specified)" >&2
elif [[ "${ENABLE_AI}" == "true" ]]; then
	if ollama_available; then
		RUN_AI=true
	else
		echo "" >&2
		echo "Warning: --ai specified but Ollama not available at ${OLLAMA_HOST}" >&2
		echo "Start Ollama: docker-compose -f docker-compose.ollama.yml up -d" >&2
	fi
elif ollama_available; then
	# Auto-detect: if Ollama is running, use it
	RUN_AI=true
	echo "" >&2
	echo "Ollama detected, enabling AI review automatically" >&2
fi

AI_XML=""
if [[ "${RUN_AI}" == "true" ]]; then
	echo "" >&2
	echo "╔══════════════════════════════════════════════════════════════╗" >&2
	echo "║ [2/2] Running AI Review (Detectable=No rules)...             ║" >&2
	echo "╚══════════════════════════════════════════════════════════════╝" >&2

	AI_XML=$("${SCRIPT_DIR}/test_c_ai_review.sh" 2>&1) || true
else
	echo "" >&2
	echo "╔══════════════════════════════════════════════════════════════╗" >&2
	echo "║ [2/2] AI Review: SKIPPED (Ollama not available)              ║" >&2
	echo "╚══════════════════════════════════════════════════════════════╝" >&2
fi

# Output combined results
echo "" >&2
echo "═══════════════════════════════════════════════════════════════" >&2
echo "                    FINAL SUMMARY                               " >&2
echo "═══════════════════════════════════════════════════════════════" >&2

# For now, output static analysis results
# In future, merge XML from both sources
echo "${STATIC_XML}" | grep -v "^<" | grep -v "^$" >&2

if [[ -n "${AI_XML}" ]]; then
	echo "" >&2
	echo "--- AI Review Results ---" >&2
	echo "${AI_XML}" | grep -v "^<" | grep -v "^$" >&2
fi

# Output static XML (primary result)
echo "${STATIC_XML}" | grep "^<"
