---
name: bug-fix
description: Standard bug fix workflow
role: developer
skills:
  - execute/write-code
  - validate/check-style
  - validate/run-tests
  - validate/review-code
  - integrate/commit-changes
  - integrate/create-merge-request
---

# Bug Fix

## Implementation Status

- **Status**: Implemented
- **CLI Coverage**: 95% (Jira auto-transition optional)
- **Manual Alternative**: [Manual Fallback Guide](../../docs/manual-fallback-guide.md#bug-fix-manual)
- **Last Updated**: 2026-01-24

## When to Use

- Bug reported
- Non-urgent fix
- Scheduled fix

## Prerequisites

- [ ] Fix branch created from main
- [ ] Bug can be reproduced

## Flow

```
+---------------------+
|    write-code       | <- Write failing test, then fix
+---------+-----------+
          |
          v
+---------------------+
|    check-style      | <- Check style
+---------+-----------+
          |
          v
+---------------------+
|     run-tests       | <- Run all tests
+---------+-----------+
          |
          v
+---------------------+
|    review-code      | <- Quick review
+---------+-----------+
          |
          v
+---------------------+
|  commit-changes     | <- fix(scope): message
+---------+-----------+
          |
          v
+------------------------+
| create-merge-request   | <- MR and merge
+------------------------+
```

## Quality Gates (Recommended)

> These are **recommended targets**, not hard blocks.
> In exceptional cases, document the rationale in MR description and proceed.
> See: [ARCHITECTURE.md](../../ARCHITECTURE.md#3-feedback-over-enforcement)

| After | Gate | Target |
|-------|------|--------|
| check-style | Lint | 0 violations |
| run-tests | Test | All pass (including new test) |
| review-code | Review | 0 critical |

## Example

```
Issue: "I2C read fails on repeated start"

1. write-code
   -> Write test: test_i2c_repeated_start()
   -> Run: FAIL (reproduces bug)
   -> Fix code
   -> Run: PASS

2. check-style
   -> make lint
   -> Pass

3. run-tests
   -> make test
   -> All pass

4. review-code
   -> Check fix is correct
   -> No side effects

5. commit-changes
   -> git commit -m "fix(i2c): handle repeated start condition"

6. create-merge-request
   -> Push, MR, merge
```

## Notes

- Always write test first (reproduces bug)
- Keep fix minimal
- No new features in bug fix
