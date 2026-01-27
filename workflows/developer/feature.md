---
name: feature
description: Full feature development workflow
role: developer
cursor_mode: agent
mode_transitions:
  - ask     # analyze/parse-requirement
  - plan    # planning/design-solution, design-test-plan
  - agent   # execute/write-code
  - debug   # validate/*
  - agent   # integrate/*
skills:
  - analyze/parse-requirement
  - planning/design-solution
  - planning/design-test-plan
  - execute/write-code
  - validate/check-style
  - validate/run-tests
  - validate/review-code
  - validate/verify-requirements
  - integrate/commit-changes
  - integrate/create-merge-request
---

# Feature Development

## Status

Implemented | CLI 95% | [Manual Guide](../../docs/guides/manual-fallback-guide.md#feature)

## When to Use

- New feature request
- Significant enhancement
- New module/component

## Prerequisites

- [ ] Feature branch created from main
- [ ] Requirements document available (if any)

## Flow

1. `parse-requirement` - Clarify requirements
2. `design-solution` - Plan tasks
3. Loop per task:
   - `write-code` (TDD) -> `check-style` -> `run-tests` -> `review-code` -> `commit-changes`
4. `verify-requirements` - Check against original intent
5. `create-merge-request` - Create MR, merge

## Quality Gates

| Gate | Target |
|------|--------|
| Lint | 0 violations |
| Test | All pass, >=80% coverage |
| Review | 0 critical issues |

## Example

```
User: "Add SPI flash driver"

1. parse-requirement -> design/spi-flash.md
2. design-solution -> planning/spi-flash-plan.md
3. For each task:
   write-code -> check-style -> run-tests -> review-code -> commit
4. verify-requirements -> Check all met
5. create-merge-request -> merge
```

## Notes

- Skip parse-requirement if requirements are clear
- Skip design-solution for simple features
- Always run check-style -> run-tests -> review-code before commit
