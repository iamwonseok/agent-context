#!/bin/bash
# Pre-merge Check Script
# Final checks before MR/PR creation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Check functions
check_pass() {
    echo -e "${GREEN}(v)${NC} $1"
    ((PASSED++))
}

check_fail() {
    echo -e "${RED}(x)${NC} $1"
    ((FAILED++))
}

check_warn() {
    echo -e "${YELLOW}(!)${NC} $1"
    ((WARNINGS++))
}

echo "=========================================="
echo "Pre-merge Check"
echo "=========================================="
echo ""

cd "${PROJECT_ROOT}"

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch: ${CURRENT_BRANCH}"
echo ""

# 1. Check uncommitted changes
echo "Checking for uncommitted changes..."
if [ -z "$(git status --porcelain)" ]; then
    check_pass "No uncommitted changes"
else
    check_fail "Uncommitted changes found"
    git status --short
fi

# 2. Check sync with main
echo ""
echo "Checking sync with main..."
git fetch origin main --quiet 2>/dev/null || true

LOCAL_MAIN=$(git rev-parse origin/main 2>/dev/null || echo "none")
if git merge-base --is-ancestor origin/main HEAD 2>/dev/null; then
    check_pass "Branch includes latest main"
else
    check_warn "Branch may need rebase on main"
fi

# 3. Check merge conflicts
echo ""
echo "Checking for merge conflicts..."
if git merge-tree $(git merge-base origin/main HEAD) origin/main HEAD 2>/dev/null | grep -q "^<<<<<<<"; then
    check_fail "Potential merge conflicts detected"
else
    check_pass "No merge conflicts"
fi

# 4. Run lint (if lint tool exists)
echo ""
echo "Running lint check..."
if command -v flake8 &> /dev/null && [ -d "src" ]; then
    if flake8 src/ --quiet 2>/dev/null; then
        check_pass "Python lint passed"
    else
        check_fail "Python lint failed"
    fi
elif command -v eslint &> /dev/null && [ -f "package.json" ]; then
    if eslint src/ --quiet 2>/dev/null; then
        check_pass "JavaScript lint passed"
    else
        check_fail "JavaScript lint failed"
    fi
else
    check_warn "No lint tool found, skipping"
fi

# 5. Run tests
echo ""
echo "Running tests..."
if [ -f "pytest.ini" ] || [ -f "pyproject.toml" ]; then
    if pytest tests/ --quiet 2>/dev/null; then
        check_pass "Python tests passed"
    else
        check_fail "Python tests failed"
    fi
elif [ -f "package.json" ] && grep -q '"test"' package.json; then
    if npm test --silent 2>/dev/null; then
        check_pass "Node.js tests passed"
    else
        check_fail "Node.js tests failed"
    fi
else
    check_warn "No test configuration found, skipping"
fi

# 6. Check branch naming
echo ""
echo "Checking branch naming..."
BRANCH_PATTERN="^(feat|fix|hotfix|refactor|perf|docs|test|chore|style)/[a-zA-Z]+-[0-9]+-[a-z0-9-]+$|^(main|master|develop)$"
if [[ $CURRENT_BRANCH =~ $BRANCH_PATTERN ]]; then
    check_pass "Branch name follows convention"
else
    check_warn "Branch name may not follow convention: ${CURRENT_BRANCH}"
fi

# 7. Check commit messages
echo ""
echo "Checking commit messages..."
BAD_COMMITS=$(git log origin/main..HEAD --oneline | grep -vE "^[a-f0-9]+ (feat|fix|refactor|test|docs|style|chore|perf|hotfix)(\(.+\))?: " | head -5)
if [ -z "$BAD_COMMITS" ]; then
    check_pass "All commit messages follow convention"
else
    check_warn "Some commits may not follow Conventional Commits:"
    echo "$BAD_COMMITS" | while read -r line; do
        echo "  - $line"
    done
fi

# 8. Check change size
echo ""
echo "Checking change size..."
CHANGES=$(git diff origin/main...HEAD --stat | tail -1)
INSERTIONS=$(echo "$CHANGES" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo "0")
DELETIONS=$(echo "$CHANGES" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || echo "0")
TOTAL=$((INSERTIONS + DELETIONS))

if [ "$TOTAL" -lt 500 ]; then
    check_pass "Change size is reasonable (${TOTAL} lines)"
elif [ "$TOTAL" -lt 1000 ]; then
    check_warn "Large change (${TOTAL} lines), consider splitting"
else
    check_fail "Very large change (${TOTAL} lines), should be split"
fi

# Summary
echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo -e "Passed:   ${GREEN}${PASSED}${NC}"
echo -e "Failed:   ${RED}${FAILED}${NC}"
echo -e "Warnings: ${YELLOW}${WARNINGS}${NC}"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}Ready to create MR${NC}"
    echo ""
    echo "Next steps:"
    echo "  git push -u origin ${CURRENT_BRANCH}"
    echo "  glab mr create  # or: gh pr create"
    exit 0
else
    echo -e "${RED}Please fix failed checks before creating MR${NC}"
    exit 1
fi
