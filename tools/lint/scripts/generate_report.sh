#!/bin/bash
# Generate coding convention test report
# Usage: ./generate_report.sh > out/report.md

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_BASE="${SCRIPT_DIR}/.."
PROJECT_ROOT="${SCRIPT_DIR}/../../.."

# Initialize counters
declare -A LANG_PASS
declare -A LANG_FAIL
declare -A LANG_TOTAL

LANGUAGES=("c" "bash" "python" "make" "yaml")

# Count test files
for lang in "${LANGUAGES[@]}"; do
	pass_count=$(find "${TEST_BASE}/${lang}/pass" -type f 2>/dev/null | wc -l)
	fail_count=$(find "${TEST_BASE}/${lang}/fail" -type f 2>/dev/null | wc -l)
	LANG_PASS[${lang}]=${pass_count}
	LANG_FAIL[${lang}]=${fail_count}
	LANG_TOTAL[${lang}]=$((pass_count + fail_count))
done

# Calculate totals
TOTAL_PASS=0
TOTAL_FAIL=0
for lang in "${LANGUAGES[@]}"; do
	TOTAL_PASS=$((TOTAL_PASS + LANG_PASS[${lang}]))
	TOTAL_FAIL=$((TOTAL_FAIL + LANG_FAIL[${lang}]))
done
TOTAL_CASES=$((TOTAL_PASS + TOTAL_FAIL))

# Generate report header
cat << 'EOF'
# Coding Convention Test Report

EOF

echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Summary table
cat << 'EOF'
## Summary

| Language | Pass Cases | Fail Cases | Total |
|----------|------------|------------|-------|
EOF

for lang in "${LANGUAGES[@]}"; do
	printf "| %-8s | %-10s | %-10s | %-5s |\n" \
		"${lang^}" "${LANG_PASS[${lang}]}" "${LANG_FAIL[${lang}]}" "${LANG_TOTAL[${lang}]}"
done

printf "| **Total** | **%s** | **%s** | **%s** |\n" "${TOTAL_PASS}" "${TOTAL_FAIL}" "${TOTAL_CASES}"
echo ""

# Tools section
cat << 'EOF'
## Tools Used

| Language | Tools |
|----------|-------|
| C | clang-format, clang-tidy |
| Bash | ShellCheck, shfmt |
| Python | Black, Flake8, isort, mypy |
| Make | checkmake |
| YAML | yamllint |
| Dockerfile | hadolint |

EOF

# Details by language
cat << 'EOF'
## Test Cases by Language

EOF

for lang in "${LANGUAGES[@]}"; do
	echo "### ${lang^}"
	echo ""
	echo "#### Pass Cases"
	echo ""
	echo "| File | Rule ID |"
	echo "|------|---------|"

	for file in "${TEST_BASE}/${lang}"/pass/*; do
		if [[ -f "${file}" ]]; then
			filename=$(basename "${file}")
			# Extract rule ID from filename (e.g., C-01-01_xxx.c -> C-01-01)
			rule_id=$(echo "${filename}" | grep -oE '^[A-Za-z]+-[0-9]+-[0-9]+' || echo "-")
			echo "| ${filename} | ${rule_id} |"
		fi
	done
	echo ""

	echo "#### Fail Cases"
	echo ""
	echo "| File | Rule ID |"
	echo "|------|---------|"

	for file in "${TEST_BASE}/${lang}"/fail/*; do
		if [[ -f "${file}" ]]; then
			filename=$(basename "${file}")
			rule_id=$(echo "${filename}" | grep -oE '^[A-Za-z]+-[0-9]+-[0-9]+' || echo "-")
			echo "| ${filename} | ${rule_id} |"
		fi
	done
	echo ""
done

# Configuration files
cat << 'EOF'
## Configuration Files

| File | Purpose |
|------|---------|
| `.editorconfig` | IDE/Editor 공통 설정 |
| `.clang-format` | C/C++ 포맷팅 |
| `.clang-tidy` | C/C++ 정적 분석 |
| `.shellcheckrc` | Bash 린팅 |
| `.flake8` | Python 린팅 |
| `.yamllint.yml` | YAML 린팅 |
| `.hadolint.yaml` | Dockerfile 린팅 |
| `.pre-commit-config.yaml` | Pre-commit hooks |

EOF

# How to run
cat << 'EOF'
## How to Run

```bash
# Build Docker image and run all tests
make test

# Run specific language tests
make test-c
make test-bash
make test-python
make test-make
make test-yaml

# Generate this report
make report
```
EOF
