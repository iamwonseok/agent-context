---
name: bug-fix
description: Standard bug fix workflow
skills:
  - git-workflow
  - execute/write-code
  - validate/check-style
  - validate/run-tests
  - validate/review-code
  - integrate/commit-changes
  - integrate/create-merge-request
---

# Bug Fix

## When to Use

- Bug reported
- Non-urgent fix
- Scheduled fix

## Prerequisites

- [ ] Single agent? -> Use branch
- [ ] Multi-agent concurrent? -> Use worktree (see [multi-agent-rules](../skills/git-workflow/references/multi-agent-rules.md))

## Flow

```
+---------------------+
|    git-workflow     | <- Create fix branch
+---------+-----------+
          |
          v
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

## Quality Gates

| After | Gate | Criteria |
|-------|------|----------|
| check-style | Lint | 0 violations |
| run-tests | Test | All pass (including new test) |
| review-code | Review | 0 critical |

## Example

```
Issue: "I2C read fails on repeated start"

1. git-workflow
   -> git checkout -b fix/PROJ-456-i2c-repeated-start

2. write-code
   -> Write test: test_i2c_repeated_start()
   -> Run: FAIL (reproduces bug)
   -> Fix code
   -> Run: PASS

3. check-style
   -> make lint
   -> Pass

4. run-tests
   -> make test
   -> All pass

5. review-code
   -> Check fix is correct
   -> No side effects

6. commit-changes
   -> git commit -m "fix(i2c): handle repeated start condition"

7. create-merge-request
   -> Push, MR, merge
```

## Notes

- Always write test first (reproduces bug)
- Keep fix minimal
- No new features in bug fix
