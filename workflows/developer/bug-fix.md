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

## Status

Implemented | CLI 95% | [Manual Guide](../../docs/guides/manual-fallback-guide.md#bug-fix)

## When to Use

- Bug reported
- Non-urgent fix
- Scheduled fix

## Prerequisites

- [ ] Fix branch created from main
- [ ] Bug can be reproduced

## Flow

1. `write-code` - Write failing test, then fix
2. `check-style` - Check style
3. `run-tests` - Run all tests
4. `review-code` - Quick review
5. `commit-changes` - fix(scope): message
6. `create-merge-request` - MR and merge

## Quality Gates

| Gate | Target |
|------|--------|
| Lint | 0 violations |
| Test | All pass (including new test) |
| Review | 0 critical |

## Example

```
Issue: "I2C read fails on repeated start"

1. write-code -> test_i2c_repeated_start() -> FAIL -> Fix -> PASS
2. check-style -> make lint -> Pass
3. run-tests -> make test -> All pass
4. review-code -> Check fix is correct
5. commit-changes -> "fix(i2c): handle repeated start condition"
6. create-merge-request -> Push, MR, merge
```

## Notes

- Always write test first (reproduces bug)
- Keep fix minimal
- No new features in bug fix
