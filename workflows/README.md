# Workflows

Skill combinations for common development scenarios.

## Developer Workflows

| Workflow | Use Case |
|----------|----------|
| [developer/feature.md](developer/feature.md) | New feature development |
| [developer/bug-fix.md](developer/bug-fix.md) | Bug fix |
| [developer/hotfix.md](developer/hotfix.md) | Emergency production fix |
| [developer/refactor.md](developer/refactor.md) | Code refactoring |

## Manager Workflows

| Workflow | Use Case |
|----------|----------|
| [manager/initiative.md](manager/initiative.md) | Initiative planning |
| [manager/epic.md](manager/epic.md) | Epic management |
| [manager/task-assignment.md](manager/task-assignment.md) | Task assignment |
| [manager/monitoring.md](manager/monitoring.md) | Progress monitoring |
| [manager/approval.md](manager/approval.md) | MR review and approval |

## Workflow Format

Each workflow has YAML frontmatter:

```yaml
---
name: workflow-name
description: One line description
role: developer|manager
skills:
  - category/skill-name
  - category/skill-name
---

# Workflow Name

## When to Use
## Command Flow
## Quality Gates
## Example
## Notes
```

## Structure

```
workflows/
├── README.md
├── developer/
│   ├── feature.md
│   ├── bug-fix.md
│   ├── hotfix.md
│   └── refactor.md
└── manager/
    ├── initiative.md
    ├── epic.md
    ├── task-assignment.md
    ├── monitoring.md
    └── approval.md
```
