---
name: review-code
category: validate
description: Review code quality
version: 1.0.0
role: developer
inputs:
  - Git diff (changes)
  - Test results
outputs:
  - Review report
  - Issue list
---

# Review

## When to Use

- After tests pass
- Before commit/PR
- Code complete

## Prerequisites

- [ ] Lint passed
- [ ] Tests passed

## Workflow

### 1. Get Changes

```bash
git diff --name-only HEAD~1
git diff HEAD~1
```

### 2. Auto Checks

```bash
radon cc src/ -a -nc    # Complexity
bandit -r src/          # Security
```

### 3. Manual Checklist

- [ ] Meets requirements?
- [ ] Edge cases handled?
- [ ] Readable code?
- [ ] No security issues?
- [ ] Tests meaningful?

### 4. Classify Issues

| Severity | Action |
|----------|--------|
| Critical | Must fix |
| Major | Should fix |
| Minor | Can fix later |

### 5. Result

```
Review: NEEDS WORK
Critical: 0
Major: 1
Minor: 2
```

## Outputs

| Output | Format |
|--------|--------|
| Report | Markdown |
| Issues | List |

## Quality Gate

- Critical: 0
- Major: resolved

## Examples

```markdown
## Major (1)
[M-001] SQL Injection at src/auth.py:45

## Minor (2)
[m-001] Magic number at src/token.py:12
```

## References

- [severity-levels.md](references/severity-levels.md)
- [review-checklist.md](references/review-checklist.md)

## Notes

- Self-review first
- Be constructive
