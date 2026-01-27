---
name: refactor-code
category: execute
description: Refactor existing code without changing behavior
version: 1.0.0
role: developer
mode: implementation
cursor_mode: agent
inputs:
  - Code to refactor
  - Refactoring goals
outputs:
  - Refactored code
  - Unchanged behavior (tests pass)
---

# Refactor Code

## State Assertion

**Mode**: implementation
**Cursor Mode**: agent
**Purpose**: Improve code structure while preserving behavior
**Boundaries**:
- Will: Restructure code, rename, extract functions, improve readability
- Will NOT: Change functionality, skip tests, or refactor without test coverage

## When to Use

- Code smells identified
- Technical debt reduction
- Before adding new features
- After code review feedback
- Improving readability

## Prerequisites

- [ ] Tests exist and pass
- [ ] Clear refactoring goal
- [ ] Understand current behavior

## Workflow

### 1. Identify Refactoring Target

Common code smells:

| Smell | Symptom | Solution |
|-------|---------|----------|
| Long Method | > 20 lines | Extract Method |
| Large Class | Too many responsibilities | Extract Class |
| Duplicate Code | Copy-paste | Extract Method/Class |
| Long Parameter List | > 3 parameters | Parameter Object |
| Feature Envy | Uses other class's data | Move Method |
| Magic Numbers | Hardcoded values | Extract Constant |

### 2. Ensure Test Coverage

```bash
# Check coverage before refactoring
pytest --cov=module_name tests/

# If coverage < 80%, add tests first
```

### 3. Apply Small Changes

One refactoring at a time:

```python
# Before: Long method
def process_order(order):
    # validate (10 lines)
    # calculate total (15 lines)
    # apply discount (10 lines)
    # save to database (5 lines)
    pass

# After: Extracted methods
def process_order(order):
    validate_order(order)
    total = calculate_total(order)
    total = apply_discount(total, order.customer)
    save_order(order, total)

def validate_order(order):
    # 10 lines
    pass

def calculate_total(order):
    # 15 lines
    pass
```

### 4. Run Tests After Each Change

```bash
# After each refactoring step
pytest tests/ -x  # Stop on first failure
```

### 5. Common Refactoring Patterns

| Pattern | Before | After |
|---------|--------|-------|
| Extract Method | Inline repeated code | Separate function |
| Rename | `calc(a,b,c)` | `calculate_price(price, qty, discount)` |
| Replace Magic Numbers | `if status == 1` | `if status == STATUS_ACTIVE` |
| Simplify Conditionals | Complex inline condition | `if can_read(user)` |

### 6. Document Changes

```markdown
## Refactoring: {file/module}

### Goal
Improve readability and reduce duplication

### Changes
1. Extracted `validate_order()` from `process_order()`
2. Extracted `calculate_total()` from `process_order()`
3. Renamed `calc()` to `calculate_discounted_price()`
4. Replaced magic numbers with constants

### Verification
- All tests pass (42 tests, 0 failures)
- Coverage maintained at 85%
- No behavior change
```

## Outputs

| Output | Format | Description |
|--------|--------|-------------|
| Refactored code | Source files | Changed code |
| Test results | Pass/Fail | Behavior unchanged |
| Change summary | Markdown | What was refactored |

## Refactoring Checklist

- [ ] Tests pass before starting
- [ ] Small, incremental changes
- [ ] Tests pass after each change
- [ ] No new features added
- [ ] Code is cleaner/simpler
- [ ] Tests pass at the end
- [ ] Commit with clear message

## Examples

| Refactoring | Summary |
|-------------|---------|
| Extract Class | User with address fields → User + Address classes |
| Remove Duplication | Repeated validation → Shared `validate_email()` |

## Notes

- Refactoring != Rewriting
- Never refactor without tests
- Commit frequently
- One type of change per commit
- "Make it work, make it right, make it fast"
