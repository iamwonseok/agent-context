---
name: hotfix
description: Emergency production fix
role: developer
skills:
  - git-workflow (worktree)
  - execute/write-code
  - validate/check-style
  - validate/run-tests
  - integrate/commit-changes
  - integrate/create-merge-request
---

# Hotfix

## When to Use

- Production bug
- Urgent fix needed
- Can't wait for normal process

## Flow

```
+---------------------+
|    git-workflow     | <- Worktree from main
|     (worktree)      |
+---------+-----------+
          |
          v
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
+-----------+------------+
            |
            v
+------------------------+
|       cleanup          | <- Remove worktree
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

1. git-workflow (worktree)
   -> Keep current work untouched
   -> git worktree add ../hotfix -b hotfix/1.2.3 main
   -> cd ../hotfix

2. write-code
   -> Quick test to reproduce
   -> Fix the issue
   -> Verify fix

3. check-style
   -> Quick check: flake8 src/auth.py

4. run-tests
   -> Run auth tests: pytest tests/test_auth.py

5. commit-changes
   -> git commit -m "fix: auth token validation"

6. create-merge-request
   -> git push -u origin hotfix/1.2.3
   -> Create MR with "urgent" label
   -> Fast-track merge

7. cleanup
   -> cd ../project
   -> git worktree remove ../hotfix
   -> Continue previous work
```

## Notes

- Use worktree to preserve current work
- Minimal fix only
- Review can happen after merge
- Document post-mortem later
