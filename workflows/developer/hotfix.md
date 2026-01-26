---
name: hotfix
description: Emergency production fix
role: developer
skills:
  - execute/write-code
  - validate/check-style
  - validate/run-tests
  - integrate/commit-changes
  - integrate/create-merge-request
---

# Hotfix

## Implementation Status

- **Status**: Implemented
- **CLI Coverage**: 90% (verification/retro skippable)
- **Manual Alternative**: [Manual Fallback Guide](../../docs/manual-fallback-guide.md#hotfix-manual---fastest) - **Manual is faster**
- **Last Updated**: 2026-01-24
- **Note**: In emergency situations, manual approach is faster and more direct than using agent.

## When to Use

- Production bug
- Urgent fix needed
- Can't wait for normal process

## Flow

```
+---------------------+
|    write-code       | <- Quick test + fix
+---------+-----------+
          |
          v
+---------------------+
|    check-style      | <- Quick check
+---------+-----------+
          |
          v
+---------------------+
|     run-tests       | <- Run critical tests
+---------+-----------+
          |
          v
+---------------------+
|  commit-changes     | <- fix: urgent message
+---------+-----------+
          |
          v
+------------------------+
| create-merge-request   | <- Fast merge
+------------------------+
```

## Quality Gates

| After | Gate | Criteria |
|-------|------|----------|
| run-tests | Test | Critical tests pass |

Review can be async (post-merge).

## Example

```
Alert: "Production down! Auth failing"

1. write-code
   -> Quick test to reproduce
   -> Fix the issue
   -> Verify fix

2. check-style
   -> Quick check: flake8 src/auth.py

3. run-tests
   -> Run auth tests: pytest tests/test_auth.py

4. commit-changes
   -> git commit -m "fix: auth token validation"

5. create-merge-request
   -> git push -u origin hotfix/1.2.3
   -> Create MR with "urgent" label
   -> Fast-track merge
```

## Notes

- Create hotfix branch from main
- Minimal fix only
- Review can happen after merge
- Document post-mortem later
