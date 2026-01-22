# Severity Levels

## Critical (Must Fix)

Security, data loss, system failure.

**Examples**:
```python
# SQL Injection
query = f"SELECT * FROM users WHERE id = {input}"

# Plain password
user.password = request.form['password']

# Infinite loop
while True:
    process()
```

---

## Major (Should Fix)

Bug potential, performance, design.

**Examples**:
```python
# Missing null check
def get_name(user):
    return user.name  # user could be None

# N+1 query
for post in posts:
    print(post.author.name)  # query each time

# High complexity (>15)
def process(data):
    if a:
        if b:
            if c:
                ...
```

---

## Minor (Can Fix Later)

Style, readability, small improvements.

**Examples**:
```python
# Vague name
d = calculate_discount()  # rename to discount

# Magic number
if age > 18:  # use ADULT_AGE constant

# Unnecessary comment
# Find user
user = find_user(id)  # code is clear
```

---

## Info (Reference)

Suggestions, learning, praise.

**Examples**:
```python
# New syntax available
match status:
    case 'active': ...

# Good job!
```

## Decision Guide

```
Security risk?         -> Critical
Data loss possible?    -> Critical
System crash?          -> Critical

Bug likely?            -> Major
Performance issue?     -> Major
Missing tests?         -> Major

Readability?           -> Minor
Consistency?           -> Minor
Small optimization?    -> Minor

Otherwise              -> Info
```

## Exceptions

Allow Major/Minor with:
1. Issue ticket created
2. Resolution plan
3. Reviewer approves

```markdown
**Reason**: Not in current release
**Ticket**: PROJ-456
**Plan**: Fix in next sprint
```
