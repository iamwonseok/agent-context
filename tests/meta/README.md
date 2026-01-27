# Meta-Validation Test Suite

Automated validation of agent-context framework policies and conventions.

## Overview

This test suite validates that the framework follows its own documented policies from ARCHITECTURE.md, policies/README.md, and various RFCs.

### Test Levels

| Level | Test | Focus | Status |
|-------|------|-------|--------|
| 1 | Skills Structure | YAML frontmatter, required sections | ✅ Active |
| 2 | Workflows Structure | Frontmatter, skill references | ✅ Active |
| 3 | .cursorrules | Required sections, valid references | ✅ Active |
| 4 | **Complexity Budget** | File size limits | ✅ **NEW** |
| 5 | **Naming Conventions** | File naming standards | ✅ **NEW** |
| 6 | **Anti-patterns** | Design anti-patterns | ✅ **NEW** |
| 7 | **Efficiency Patterns** | Batch operation guidance | ✅ **NEW** |

## Quick Start

### Run All Tests

```bash
cd tests/meta
bash run-all-meta-tests.sh
```

### Run Individual Tests

```bash
# Complexity budget (file size limits)
bash test_complexity_budget.sh

# Naming conventions (file naming standards)
bash test_naming_conventions.sh

# Anti-patterns (design smells)
bash test_antipatterns.sh

# Efficiency patterns (batch operations)
bash test_efficiency_patterns.sh
```

### Check Results

```bash
# View summary
cat TEST_RESULTS.md

# View detailed logs
ls logs/
cat logs/complexity_budget.log
```

---

## Test Descriptions

### Level 4: Complexity Budget

**Purpose**: Enforce file size limits per ARCHITECTURE.md

**Limits**:
- Skills: 200 lines max
- Workflows: 100 lines max
- CLI Commands: 100 lines max
- Helper Libraries: 300 lines max

**Rationale**: 
- Prevent over-engineering
- Encourage modularization
- Keep code maintainable

**Fixtures**:
```
fixtures/complexity/
├── pass/
│   ├── skill-simple.md       (59 lines - OK)
│   └── workflow-simple.md    (35 lines - OK)
└── fail/
    ├── skill-too-long.md     (211 lines - NG)
    └── workflow-too-long.md  (112 lines - NG)
```

---

### Level 5: Naming Conventions

**Purpose**: Enforce file naming standards per policies/README.md

**Standards**:
- Skills: `skills/{category}/{skill-name}/SKILL.md`
- Workflows: `workflows/{role}/{workflow-name}.md`
- RFCs: `docs/rfcs/NNN-descriptive-title.md`

**Rationale**:
- Consistent structure
- Easy navigation
- Clear hierarchy

**Fixtures**:
```
fixtures/naming/
├── pass/README.md     (valid examples)
└── fail/README.md     (invalid examples)
```

---

### Level 6: Anti-patterns

**Purpose**: Detect design anti-patterns per ARCHITECTURE.md

**Checks**:
1. Deep Nesting (max 2 levels)
2. Custom DSL (use YAML/Markdown)
3. Hard Blocking (need --force option)
4. Complex State Machines (use simple flags)
5. Implicit Dependencies (be explicit)
6. Forbidden Unicode (use ASCII)

**Rationale**:
- Simplicity over completeness
- User autonomy
- Feedback over enforcement

**Fixtures**:
```
fixtures/antipatterns/
├── pass/
│   └── simple-structure.md
└── fail/
    ├── deep-nesting/         (5 levels deep - NG)
    └── custom.dsl            (custom DSL - NG)
```

---

### Level 7: Efficiency Patterns

**Purpose**: Validate batch operation guidance per RFC-010

**Checks**:
1. No excessive grep repetition
2. No obvious sequential anti-patterns
3. No excessive test calls
4. Language policy automation
5. Efficiency documentation complete

**Rationale**:
- Reduce tool calls
- Enable batch operations
- Document best practices

**Fixtures**:
```
fixtures/efficiency/
└── README.md     (examples reference)
```

---

## Directory Structure

```
tests/meta/
├── README.md                      # This file
├── TEST_RESULTS.md                # Summary table
├── run-all-meta-tests.sh          # Run all tests
│
├── test_complexity_budget.sh      # Level 4
├── test_naming_conventions.sh     # Level 5
├── test_antipatterns.sh           # Level 6
├── test_efficiency_patterns.sh    # Level 7
│
├── test_skills_structure.sh       # Level 1 (existing)
├── test_workflows_structure.sh    # Level 2 (existing)
├── test_cursorrules.sh            # Level 3 (existing)
│
├── fixtures/                      # Test examples
│   ├── complexity/
│   ├── naming/
│   ├── antipatterns/
│   └── efficiency/
│
└── logs/                          # Test output logs
    ├── complexity_budget.log
    ├── naming_conventions.log
    ├── antipatterns.log
    ├── efficiency_patterns.log
    └── all-tests-summary.log
```

---

## CI Integration

### GitLab CI

```yaml
test:meta:
  script:
    - bash tests/meta/run-all-meta-tests.sh
  artifacts:
    reports:
      junit: tests/meta/logs/*.xml  # Future: JUnit format
    paths:
      - tests/meta/logs/
```

---

## Adding New Tests

### 1. Create Test Script

```bash
#!/bin/bash
# Test Description
# Purpose: What this test validates

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# ... test logic ...

if [ "$FAILED" -eq 0 ]; then
    echo "[PASS] Test passed"
    exit 0
else
    echo "[FAIL] Test failed"
    exit 1
fi
```

### 2. Add Test Fixtures

```bash
mkdir -p fixtures/my-test/{pass,fail}
# Create OK examples in pass/
# Create NG examples in fail/
```

### 3. Update run-all-meta-tests.sh

```bash
run_test "LEVEL X" "My Test Name" "${SCRIPT_DIR}/test_my_feature.sh" || true
```

### 4. Update TEST_RESULTS.md

Add row to summary table with results.

---

## Philosophy

These tests enforce the principles from ARCHITECTURE.md:

1. **Simplicity Over Completeness**
   - Complexity budget limits
   - Anti-pattern detection

2. **User Autonomy**
   - Warnings over hard blocks
   - --force escape hatches

3. **Feedback Over Enforcement**
   - Informative error messages
   - Actionable recommendations

4. **Composability**
   - Small, focused files
   - Clear dependencies

5. **State Through Artifacts**
   - File-based validation
   - Git-tracked policies

---

## Troubleshooting

### Test Fails Unexpectedly

```bash
# Check logs
cat logs/test_name.log

# Run individual test with verbose output
bash -x test_complexity_budget.sh
```

### Fixture Issues

```bash
# Verify fixture structure
find fixtures/ -type f

# Check fixture content
cat fixtures/complexity/pass/skill-simple.md
```

### Update Test Expectations

If policies change, update:
1. Test script limits/patterns
2. Fixtures (add new examples)
3. TEST_RESULTS.md
4. This README

---

## References

- **ARCHITECTURE.md**: Design philosophy and rationale
- **policies/README.md**: Framework policies summary
- **docs/rfcs/010-agent-efficiency-best-practices.md**: Efficiency patterns
- **docs/rfcs/011-language-policy.md**: Language enforcement
- **.cursorrules**: Agent-readable policy summary

---

**Maintainers**: Agent Context Team  
**Last Updated**: 2026-01-27  
**Status**: Active Development
