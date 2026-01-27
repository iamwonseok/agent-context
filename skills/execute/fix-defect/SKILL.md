---
name: fix-defect
category: execute
description: Fix bugs and defects in code
version: 1.0.0
role: developer
mode: implementation
cursor_mode: agent
inputs:
  - Bug report or error description
  - Steps to reproduce
outputs:
  - Fixed code
  - Regression test
---

# Fix Defect

## State Assertion

**Mode**: implementation
**Cursor Mode**: agent
**Purpose**: Identify and fix bugs in code
**Boundaries**:
- Will: Investigate root cause, modify code, add regression tests
- Will NOT: Introduce new features, refactor unrelated code, or skip testing

## When to Use

- Bug reported by users/QA
- Test failure
- Error in logs
- Unexpected behavior

## Prerequisites

- [ ] Bug report with reproduction steps
- [ ] Access to codebase
- [ ] Test environment available

## Workflow

### 1. Understand the Bug

Gather information:
- What is expected behavior?
- What is actual behavior?
- Steps to reproduce
- Environment details
- Error messages/logs

### 2. Reproduce the Bug

```bash
# Set up same conditions
# Follow exact steps
# Confirm bug exists
```

If can't reproduce:
- Check environment differences
- Check data differences
- Ask for more details

### 3. Write a Failing Test

```python
def test_bug_123_division_by_zero():
    """Regression test for BUG-123: Division by zero when quantity is 0"""
    # This test should FAIL before the fix
    result = calculate_unit_price(total=100, quantity=0)
    assert result == 0  # or appropriate handling
```

### 4. Locate the Root Cause

Strategies:
- **Binary search**: Comment out code until bug disappears
- **Print debugging**: Add logging at key points
- **Debugger**: Step through code execution
- **Git bisect**: Find which commit introduced bug

```bash
# Find which commit introduced the bug
git bisect start
git bisect bad HEAD
git bisect good v1.0.0
# Git will help find the commit
```

### 5. Implement the Fix

```python
# Before (buggy)
def calculate_unit_price(total, quantity):
    return total / quantity  # ZeroDivisionError when quantity=0

# After (fixed)
def calculate_unit_price(total, quantity):
    if quantity == 0:
        return 0  # or raise ValueError("Quantity cannot be zero")
    return total / quantity
```

### 6. Verify the Fix

```bash
# Run the specific test
pytest tests/test_calculate.py::test_bug_123_division_by_zero

# Run related tests
pytest tests/test_calculate.py

# Run all tests to check for regressions
pytest tests/
```

### 7. Document the Fix

```markdown
## Bug Fix: BUG-123

### Problem
Division by zero error when calculating unit price with quantity=0

### Root Cause
`calculate_unit_price()` didn't handle zero quantity case

### Solution
Added zero-quantity check, return 0 when quantity is 0

### Files Changed
- `src/pricing.py`: Added guard clause
- `tests/test_pricing.py`: Added regression test

### Testing
- [x] Regression test added
- [x] All existing tests pass
- [x] Manual verification done
```

## Outputs

| Output | Format | Description |
|--------|--------|-------------|
| Fixed code | Source files | Bug fix |
| Regression test | Test file | Prevents recurrence |
| Root cause | Documentation | Why it happened |

## Bug Fix Checklist

- [ ] Bug reproduced
- [ ] Failing test written
- [ ] Root cause identified
- [ ] Fix implemented
- [ ] Test passes
- [ ] No regressions
- [ ] Code reviewed
- [ ] Documentation updated

## Common Bug Categories

| Category | Typical Cause | Example Fix |
|----------|---------------|-------------|
| Null/None | Missing null check | Add guard clause |
| Off-by-one | Loop boundary wrong | Fix index/range |
| Race condition | Concurrent access | Add locking |
| Type error | Wrong type passed | Add validation |
| Logic error | Wrong condition | Fix boolean logic |
| Edge case | Unhandled scenario | Add special case |

## Examples

| Bug Type | Fix Strategy |
|----------|-------------|
| Null Pointer | Add null check, return default |
| Off-by-One | Fix range boundary |
| Race Condition | Use database constraints |

## Notes

- Always write a test first
- Fix the root cause, not symptoms
- One bug = one commit
- Reference bug ID in commit message
- Consider similar bugs elsewhere
