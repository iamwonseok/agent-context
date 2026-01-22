---
name: refactor-code
category: execute
description: Refactor existing code without changing behavior
version: 1.0.0
role: developer
inputs:
  - Code to refactor
  - Refactoring goals
outputs:
  - Refactored code
  - Unchanged behavior (tests pass)
---

# Refactor Code

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

#### Extract Method
```python
# Before
def report():
    # ... header ...
    print("=" * 50)
    print("Report Title")
    print("=" * 50)
    # ... content ...

# After
def report():
    print_header("Report Title")
    # ... content ...

def print_header(title):
    print("=" * 50)
    print(title)
    print("=" * 50)
```

#### Rename for Clarity
```python
# Before
def calc(a, b, c):
    return a * b * (1 - c)

# After
def calculate_discounted_price(price, quantity, discount_rate):
    return price * quantity * (1 - discount_rate)
```

#### Replace Magic Numbers
```python
# Before
if status == 1:
    # active
elif status == 2:
    # inactive

# After
STATUS_ACTIVE = 1
STATUS_INACTIVE = 2

if status == STATUS_ACTIVE:
    # active
elif status == STATUS_INACTIVE:
    # inactive
```

#### Simplify Conditionals
```python
# Before
if user and user.is_active and user.has_permission('read'):
    return data

# After
def can_read(user):
    return user and user.is_active and user.has_permission('read')

if can_read(user):
    return data
```

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

### Example 1: Extract Class

```python
# Before: User class doing too much
class User:
    def __init__(self, name, email, street, city, zip):
        self.name = name
        self.email = email
        self.street = street
        self.city = city
        self.zip = zip
    
    def full_address(self):
        return f"{self.street}, {self.city} {self.zip}"

# After: Separate Address class
class Address:
    def __init__(self, street, city, zip):
        self.street = street
        self.city = city
        self.zip = zip
    
    def full(self):
        return f"{self.street}, {self.city} {self.zip}"

class User:
    def __init__(self, name, email, address):
        self.name = name
        self.email = email
        self.address = address
```

### Example 2: Remove Duplication

```python
# Before: Duplicated validation
def create_user(data):
    if not data.get('email'):
        raise ValueError("Email required")
    if not '@' in data['email']:
        raise ValueError("Invalid email")
    # create user...

def update_user(user_id, data):
    if not data.get('email'):
        raise ValueError("Email required")
    if not '@' in data['email']:
        raise ValueError("Invalid email")
    # update user...

# After: Shared validation
def validate_email(email):
    if not email:
        raise ValueError("Email required")
    if '@' not in email:
        raise ValueError("Invalid email")

def create_user(data):
    validate_email(data.get('email'))
    # create user...

def update_user(user_id, data):
    validate_email(data.get('email'))
    # update user...
```

## Notes

- Refactoring != Rewriting
- Never refactor without tests
- Commit frequently
- One type of change per commit
- "Make it work, make it right, make it fast"
