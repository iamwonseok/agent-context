---
name: run-tests
category: validate
description: Run tests and check coverage
version: 1.0.0
role: developer
mode: verification
cursor_mode: debug
inputs:
  - Code with tests
outputs:
  - Test results (JUnit XML)
  - Coverage report
---

# Run Tests

## State Assertion

**Mode**: verification
**Cursor Mode**: debug
**Purpose**: Execute tests and validate code behavior
**Boundaries**:
- Will: Run test suites, collect results, report coverage
- Will NOT: Modify tests, skip failing tests, or change code

## When to Use

- After code change
- Before commit
- In CI/CD

## Prerequisites

- [ ] Test files exist
- [ ] Lint passed (recommended)

## Workflow

### 1. Run Tests

**Python**:
```bash
pytest --junit-xml=results.xml --cov=src tests/
```

**Node.js**:
```bash
npm test -- --coverage
```

### 2. Check Results

```
Tests: 127 total
Passed: 125
Failed: 2
Coverage: 87%

Status: FAIL
```

### 3. Fix (if fail)

Debug failed test:
```bash
pytest tests/test_auth.py::test_invalid -v --pdb
```

## Outputs

| Output | Format |
|--------|--------|
| Results | JUnit XML |
| Coverage | HTML/XML |

## Quality Gate

- All tests pass
- Coverage >=80%

## Examples

```bash
$ make test

test_uart.c::test_uart_init PASSED
test_uart.c::test_uart_write FAILED

Coverage: 87%
125 passed, 2 failed
```

## Notes

- Failed test = must fix
- Coverage < 80% = add tests
