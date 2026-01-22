---
name: check-style
category: validate
description: Check code style and lint
version: 1.0.0
role: developer
inputs:
  - Changed code files
outputs:
  - Lint results (pass/fail)
---

# Check Style

## When to Use

- After code change
- Before commit
- In CI/CD

## Prerequisites

- [ ] Code files exist
- [ ] Lint tools installed

## Workflow

### 1. Run Lint

**Python**:
```bash
flake8 src/ tests/
black --check src/
mypy src/
```

**JavaScript**:
```bash
eslint src/
prettier --check src/
```

**Bash**:
```bash
shellcheck scripts/*.sh
```

### 2. Check Results

**Pass**:
```
Lint: PASS
Violations: 0
```

**Fail**:
```
Lint: FAIL
src/auth.py:42: E501 line too long
```

### 3. Fix (if fail)

**Auto-fix**:
```bash
black src/
eslint --fix src/
```

Re-run lint.

## Outputs

| Output | Format |
|--------|--------|
| Result | Pass/Fail |
| Violations | List |

## Examples

```bash
$ flake8 src/
src/auth.py:42: E501 line too long

$ black src/auth.py
reformatted

$ flake8 src/
# Pass
```

## Notes

- 0 violations = pass
- Auto-fix saves time
