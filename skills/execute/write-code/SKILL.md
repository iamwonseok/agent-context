---
name: write-code
category: execute
description: Write code using test-driven development
version: 1.0.0
role: developer
inputs:
  - Task to implement
outputs:
  - Code in src/
  - Tests in tests/
---

# Write Code

## When to Use

- New feature
- Bug fix
- Refactoring

## Prerequisites

- [ ] Task defined
- [ ] Test environment ready

## Workflow

### Cycle: RED -> GREEN -> REFACTOR

### 1. RED: Failing Test

```python
def test_add():
    calc = Calculator()
    assert calc.add(2, 3) == 5
# FAIL: Calculator not defined
```

### 2. GREEN: Minimal Code

```python
class Calculator:
    def add(self, a, b):
        return a + b
# PASS
```

### 3. REFACTOR: Improve

```python
class Calculator:
    def add(self, a: int, b: int) -> int:
        return a + b
# Still PASS
```

### 4. Commit

```bash
git commit -m "feat: add Calculator.add"
```

### 5. Repeat

Next feature -> RED -> GREEN -> REFACTOR

## Outputs

| Output | Format |
|--------|--------|
| `src/**` | Code |
| `tests/**` | Tests |

## Examples

### Bug Fix

```python
# 1. RED: Reproduce
def test_null_case():
    assert func(None) is None
# FAIL: Exception

# 2. GREEN: Fix
def func(x):
    if x is None:
        return None
    ...
# PASS

# 3. REFACTOR: Clean
```

## References

- [testing-guide.md](references/testing-guide.md)

## Notes

- Don't skip RED
- Minimal code in GREEN
- Always REFACTOR
