---
name: refactor
description: Code refactoring workflow
role: developer
cursor_mode: agent
mode_transitions:
  - plan    # planning/design-solution
  - agent   # execute/write-code
  - debug   # validate/* (regression tests)
  - agent   # integrate/*
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

## Status

Implemented | CLI 95% | [Manual Guide](../../docs/guides/manual-fallback-guide.md#refactor)

## When to Use

- Improve code structure
- Reduce complexity
- No new features

## Prerequisites

- [ ] Refactor branch created from main
- [ ] Tests exist for code being refactored

## Flow

1. `design-solution` - Plan refactoring scope
2. `write-code` - Ensure tests exist first
3. Loop per change: `refactor` -> `run-tests` -> `commit-changes`
4. `check-style` -> `review-code` -> `verify-requirements`
5. `create-merge-request` - MR and merge

## Quality Gates

| Gate | Target |
|------|--------|
| Test (each loop) | All pass |
| Lint | 0 violations |
| Review | 0 critical |

## Example

```
Task: "Extract repository pattern from services"

1. design-solution
   -> List files, define steps

2. write-code
   -> Verify tests exist, add if missing

3. Loop (small steps):
   -> Extract BaseRepository -> test -> commit
   -> Update UserService -> test -> commit
   -> Update OrderService -> test -> commit

4. check-style -> review-code -> verify-requirements

5. create-merge-request -> merge
```

## Notes

- Tests must exist before refactoring
- Small, incremental changes
- Each commit = tests pass
- No feature changes
