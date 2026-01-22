#!/bin/bash
# Save current lint results as expected output
# Usage: ./save_results.sh [c|bash|make|python|yaml|all]
#
# This script runs lint tools on each test case and saves the raw output
# to expected files for future verification.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."
TEST_DIR="${PROJECT_ROOT}/tests"
EXPECTED_DIR="${TEST_DIR}/expected"
BIN_DIR="${PROJECT_ROOT}/bin"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Map language to lint command
get_lint_cmd() {
	local lang="$1"
	case "${lang}" in
		c) echo "${BIN_DIR}/lint-c" ;;
		bash) echo "${BIN_DIR}/lint-bash" ;;
		make) echo "${BIN_DIR}/lint-make" ;;
		python) echo "${BIN_DIR}/lint-python" ;;
		yaml) echo "${BIN_DIR}/lint-yaml" ;;
		*) echo "" ;;
	esac
}

# Get test file extension
get_extension() {
	local lang="$1"
	case "${lang}" in
		c) echo "c" ;;
		bash) echo "sh" ;;
		make) echo "mk" ;;
		python) echo "py" ;;
		yaml) echo "yaml" ;;
		*) echo "*" ;;
	esac
}

# Generate expected output for a language
save_language() {
	local lang="$1"
	local lint_cmd
	lint_cmd=$(get_lint_cmd "${lang}")
	local ext
	ext=$(get_extension "${lang}")
	local expected_file="${EXPECTED_DIR}/${lang}.expected"
	local test_base="${TEST_DIR}/${lang}"

	if [[ ! -x "${lint_cmd}" ]]; then
		echo -e "${RED}[ERROR]${NC} Lint command not found or not executable: ${lint_cmd}" >&2
		return 1
	fi

	if [[ ! -d "${test_base}" ]]; then
		echo -e "${YELLOW}[WARN]${NC} Test directory not found: ${test_base}" >&2
		return 0
	fi

	mkdir -p "${EXPECTED_DIR}"

	echo "Generating ${lang}.expected..." >&2

	{
		# Header
		local lang_upper
		lang_upper=$(echo "${lang}" | tr '[:lower:]' '[:upper:]')
		echo "# ${lang_upper} Lint Expected Output"
		echo "# Generated: $(date '+%Y-%m-%dT%H:%M:%S%z')"
		echo ""

		local count=0

		# Get relative path for display
		local lint_cmd_rel="./bin/lint-${lang}"
		local test_base_rel="tests/${lang}"

		# Process fail cases first
		if [[ -d "${test_base}/fail" ]]; then
			shopt -s nullglob
			for file in "${test_base}/fail"/*.${ext} "${test_base}/fail"/*.Dockerfile; do
				[[ -f "${file}" ]] || continue
				count=$((count + 1))

				local filename
				filename=$(basename "${file}")
				local rel_path="${test_base_rel}/fail/${filename}"

				echo "$ ${lint_cmd_rel} ${rel_path}"
				# Run lint and strip colors/paths from output (ignore exit code)
				"${lint_cmd}" "${file}" 2>&1 | sed "s|${PROJECT_ROOT}/||g; s/\x1b\[[0-9;]*m//g" || true
				echo ""
				echo "---"
				echo ""
			done
			shopt -u nullglob
		fi

		# Process pass cases
		if [[ -d "${test_base}/pass" ]]; then
			shopt -s nullglob
			for file in "${test_base}/pass"/*.${ext} "${test_base}/pass"/*.Dockerfile; do
				[[ -f "${file}" ]] || continue
				count=$((count + 1))

				local filename
				filename=$(basename "${file}")
				local rel_path="${test_base_rel}/pass/${filename}"

				echo "$ ${lint_cmd_rel} ${rel_path}"
				# Run lint and strip colors/paths from output (ignore exit code)
				"${lint_cmd}" "${file}" 2>&1 | sed "s|${PROJECT_ROOT}/||g; s/\x1b\[[0-9;]*m//g" || true
				echo ""
				echo "---"
				echo ""
			done
			shopt -u nullglob
		fi

	} > "${expected_file}"

	local lines
	lines=$(wc -l < "${expected_file}" | tr -d ' ')
	echo -e "${GREEN}[SAVED]${NC} ${lang}: ${lines} lines saved to ${expected_file}" >&2
}

# Main
LANGUAGES="${1:-all}"

if [[ "${LANGUAGES}" == "all" ]]; then
	LANGUAGES="c bash make python yaml"
fi

echo "=========================================" >&2
echo "Saving lint output as expected values" >&2
echo "=========================================" >&2

for lang in ${LANGUAGES}; do
	save_language "${lang}"
done

echo "" >&2
echo "=========================================" >&2
echo "Done! Expected files saved to:" >&2
echo "  ${EXPECTED_DIR}/" >&2
echo "=========================================" >&2

# Show what was saved
echo "" >&2
echo "Saved files:" >&2
ls -la "${EXPECTED_DIR}"/*.expected 2>/dev/null | while read -r line; do
	echo "  ${line}" >&2
done
