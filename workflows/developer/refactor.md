---
name: refactor
description: Code refactoring workflow
role: developer
skills:
  - planning/design-solution
  - execute/write-code
  - validate/check-style
  - validate/run-tests
  - validate/review-code
  - validate/verify-requirements
  - integrate/commit-changes
  - integrate/create-merge-request
---

# Refactor

## Implementation Status

- **Status**: Implemented
- **CLI Coverage**: 95% (Jira auto-transition optional)
- **Manual Alternative**: [Manual Fallback Guide](../../docs/manual-fallback-guide.md#refactor-manual)
- **Last Updated**: 2026-01-24

## When to Use

- Improve code structure
- Reduce complexity
- No new features

## Prerequisites

- [ ] Refactor branch created from main
- [ ] Tests exist for code being refactored

## Flow

```
+---------------------+
|  design-solution    | <- Plan refactoring scope
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

## Quality Gates (Recommended)

> These are **recommended targets**, not hard blocks.
> In exceptional cases, document the rationale in MR description and proceed.
> See: [ARCHITECTURE.md](../../ARCHITECTURE.md#3-feedback-over-enforcement)

| After | Gate | Target |
|-------|------|--------|
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

2. write-code
   -> Verify existing tests cover behavior
   -> Add tests if missing

3. Loop (small steps):
   -> Extract BaseRepository
   -> run-tests -> Pass
   -> commit-changes: "refactor: add BaseRepository"
   
   -> Update UserService
   -> run-tests -> Pass
   -> commit-changes: "refactor: use repository in UserService"
   
   -> Update OrderService
   -> run-tests -> Pass
   -> commit-changes: "refactor: use repository in OrderService"

4. check-style
   -> Final lint check

5. review-code
   -> Verify no behavior change
   -> Check code quality improved

6. verify-requirements
   -> Check planning/refactor-repository.md
   -> All goals achieved?
   -> No missing items?

7. create-merge-request
   -> MR, merge
```

## Notes

- Tests must exist before refactoring
- Small, incremental changes
- Each commit = tests pass
- No feature changes
