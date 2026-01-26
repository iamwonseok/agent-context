# Skills

Independent, reusable building blocks for AI agent tasks.

**[-> How to Use (USAGE.md)](USAGE.md)** - Start here for usage guide.

## Skill Categories

Skills are organized into 5 categories based on workflow phase:

| Category | Purpose | Skills |
|----------|---------|--------|
| [analyze/](analyze/) | Understand the situation | parse-requirement, inspect-codebase, inspect-logs, ... |
| [planning/](planning/) | Design the approach | design-solution, breakdown-work, estimate-effort, ... |
| [execute/](execute/) | Perform the work | write-code, refactor-code, fix-defect, ... |
| [validate/](validate/) | Verify quality | run-tests, check-style, review-code, verify-requirements, ... |
| [integrate/](integrate/) | Deliver results | commit-changes, create-merge-request, merge-changes, ... |

## Quick Reference

### Developer Skills

| Path | Purpose |
|------|---------|
| `analyze/parse-requirement` | Clarify requirements |
| `planning/design-solution` | Plan implementation |
| `execute/write-code` | Test-driven development |
| `validate/check-style` | Check code style |
| `validate/run-tests` | Run tests |
| `validate/review-code` | Review code quality |
| `validate/verify-requirements` | Verify implementation |
| `integrate/commit-changes` | Write commit message |
| `integrate/create-merge-request` | Create merge request |

## Skill Format

Each skill has `SKILL.md` with:

```yaml
---
name: skill-name
category: analyze|plan|execute|validate|integrate
description: One line
version: 1.0.0
role: developer|manager|both
inputs:
  - Input 1
outputs:
  - Output 1
---

# Skill Name

## When to Use
## Prerequisites
## Workflow
## Outputs
## Examples
```

## Add New Skill

1. Choose appropriate category (`analyze/`, `planning/`, `execute/`, `validate/`, `integrate/`)
2. Create directory: `category/skill-name/`
3. Copy `_template/SKILL.md`
4. Fill in details with proper frontmatter
5. Update category README

## Combine Skills

See `../workflows/` for skill combinations:
- Feature development
- Bug fix
- Hotfix
- Refactoring

## Structure

```
skills/
├── README.md
├── USAGE.md
├── _template/
├── analyze/
│   ├── README.md
│   ├── parse-requirement/
│   ├── inspect-codebase/
│   └── ...
├── planning/
│   ├── README.md
│   ├── design-solution/
│   └── ...
├── execute/
│   ├── README.md
│   ├── write-code/
│   └── ...
├── validate/
│   ├── README.md
│   ├── run-tests/
│   ├── check-style/
│   └── ...
└── integrate/
    ├── README.md
    ├── commit-changes/
    └── ...

# Tests are located at tests/unit/skills/
```
