---
name: refactor
description: Code refactoring workflow
skills:
  - plan/design-solution
  - git-workflow
  - execute/write-code
  - validate/check-style
  - validate/run-tests
  - validate/review-code
  - validate/verify-requirements
  - integrate/commit-changes
  - integrate/create-merge-request
---

# Refactor

## When to Use

- Improve code structure
- Reduce complexity
- No new features

## Prerequisites

- [ ] Single agent? -> Use branch
- [ ] Multi-agent concurrent? -> Use worktree (see [multi-agent-rules](../skills/git-workflow/references/multi-agent-rules.md))

## Flow

```
+---------------------+
|  design-solution    | <- Plan refactoring scope
+---------+-----------+
          |
          v
+---------------------+
|    git-workflow     | <- Create refactor branch
+---------+-----------+
          |
          v
+---------------------+
|    write-code       | <- Ensure tests exist first
+---------+-----------+
          |
          v
    +------------+
    |    Loop    |
    | per change |
    +-----+------+
          |
          v
    +-----------+
    | refactor  | <- Make one change
    +-----+-----+
          |
          v
    +-----------+
    | run-tests | <- All tests still pass?
    +-----+-----+
          |
    Pass? --No--> Revert, try again
          |
         Yes
          |
          v
    +---------------+
    |commit-changes | <- Small commit
    +-------+-------+
            |
    More changes? --Yes--> Loop
            |
            No
            |
            v
+---------------------+
|    check-style      | <- Final check
+---------+-----------+
          |
          v
+---------------------+
|    review-code      | <- Review all changes
+---------+-----------+
          |
          v
+------------------------+
|  verify-requirements   | <- Check against refactoring goals
+-----------+------------+
            |
            v
+------------------------+
| create-merge-request   | <- MR and merge
+------------------------+
```

## Quality Gates

| After | Gate | Criteria |
|-------|------|----------|
| run-tests (each) | Test | All pass |
| check-style | Lint | 0 violations |
| review-code | Review | 0 critical |
| verify-requirements | Verify | Refactoring goals met |

## Example

```
Task: "Extract repository pattern from services"

1. design-solution
   -> List files to change
   -> Define refactoring steps

2. git-workflow
   -> git checkout -b refactor/PROJ-789-repository

3. write-code
   -> Verify existing tests cover behavior
   -> Add tests if missing

4. Loop (small steps):
   -> Extract BaseRepository
   -> run-tests -> Pass
   -> commit-changes: "refactor: add BaseRepository"
   
   -> Update UserService
   -> run-tests -> Pass
   -> commit-changes: "refactor: use repository in UserService"
   
   -> Update OrderService
   -> run-tests -> Pass
   -> commit-changes: "refactor: use repository in OrderService"

5. check-style
   -> Final lint check

6. review-code
   -> Verify no behavior change
   -> Check code quality improved

7. verify-requirements
   -> Check plan/refactor-repository.md
   -> All goals achieved?
   -> No missing items?

8. create-merge-request
   -> MR, merge
```

## Notes

- Tests must exist before refactoring
- Small, incremental changes
- Each commit = tests pass
- No feature changes
