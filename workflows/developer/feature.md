---
name: feature
description: Full feature development workflow
role: developer
skills:
  - analyze/parse-requirement
  - plan/design-solution
  - execute/write-code
  - validate/check-style
  - validate/run-tests
  - validate/review-code
  - validate/verify-requirements
  - integrate/commit-changes
  - integrate/create-merge-request
---

# Feature Development

## Implementation Status

- **Status**: Implemented
- **CLI Coverage**: 95% (Jira auto-transition optional)
- **Manual Alternative**: [Manual Fallback Guide](../../docs/manual-fallback-guide.md#feature-development-manual)
- **Last Updated**: 2026-01-24

## When to Use

- New feature request
- Significant enhancement
- New module/component

## Prerequisites

- [ ] Feature branch created from main
- [ ] Requirements document available (if any)

## Flow

```
+---------------------+
| parse-requirement   | <- Clarify requirements
+---------+-----------+
          |
          v
+---------------------+
|  design-solution    | <- Plan tasks
+---------+-----------+
          |
          v
    +------------+
    |    Loop    |
    |  per task  |
    +-----+------+
          |
          v
    +-----------+
    | write-code| <- Write code (TDD)
    +-----+-----+
          |
          v
    +-----------+
    |check-style| <- Check style
    +-----+-----+
          |
          v
    +-----------+
    | run-tests | <- Run tests
    +-----+-----+
          |
          v
    +-----------+
    |review-code| <- Review code quality
    +-----+-----+
          |
          v
    +---------------+
    |commit-changes | <- Commit changes
    +-------+-------+
            |
    More tasks? --Yes--> Loop back to write-code
            |
            No
            |
            v
+------------------------+
|  verify-requirements   | <- Check against original intent
+-----------+------------+
            |
            v
+------------------------+
| create-merge-request   | <- Create MR, merge
+------------------------+
```

## Quality Gates (Recommended)

> These are **recommended targets**, not hard blocks.
> In exceptional cases, document the rationale in MR description and proceed.
> See: [ARCHITECTURE.md](../../ARCHITECTURE.md#3-feedback-over-enforcement)

| After | Gate | Target |
|-------|------|--------|
| check-style | Lint | 0 violations |
| run-tests | Test | All pass, >=80% coverage |
| review-code | Review | 0 critical issues |
| verify-requirements | Verify | All requirements met |

## Example

```
User: "Add SPI flash driver"

1. parse-requirement
   -> Questions about flash chip, interface, etc.
   -> Output: design/spi-flash.md

2. design-solution
   -> Break into tasks: SPI init, read, write, erase
   -> Output: plan/spi-flash-plan.md

3. For each task:
   write-code   -> Write tests, then code
   check-style  -> make lint
   run-tests    -> make test
   review-code  -> Check quality
   commit-changes -> git commit -m "feat(flash): ..."

4. verify-requirements
   -> Re-read design/spi-flash.md
   -> Check all requirements met
   -> Confirm no gaps

5. create-merge-request
   -> Push, create MR, merge
```

## Notes

- Skip parse-requirement if requirements are clear
- Skip design-solution for simple features
- Always run check-style -> run-tests -> review-code before commit
- verify-requirements ensures implementation matches original intent (design/*.md)
