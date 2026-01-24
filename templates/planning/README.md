# Project Plans

This directory contains implementation plans and templates for this project.

## Directory Structure

```
project/
├── .agent/           # Agent-context framework
│   └── plan/         # Framework development plans (do not modify)
│
└── plan/             # YOUR project plans (this directory)
    ├── README.md
    └── *.md          # Your implementation plans
```

## Difference

| Directory | Purpose | Owner |
|-----------|---------|-------|
| `.agent/plan/` | Agent-context framework plans | Framework maintainers |
| `plan/` | This project's plans | You |

## Available Templates

| Template | Description |
|----------|-------------|
| [confluence-initiative.md](confluence-initiative.md) | Confluence Initiative page template |
| [confluence-epic.md](confluence-epic.md) | Confluence Epic page template |

## Usage

1. Create a new plan using the skill:
   - Read `.agent/skills/planning/design-solution/SKILL.md`

2. Save your plans here with descriptive names:
   - `feature-user-auth.md`
   - `refactor-database-layer.md`
   - `bugfix-login-issue.md`

3. Reference plans in commits and MRs for traceability.

4. For Confluence documentation, use the provided templates:
   - See [PM Hierarchy Sync Guide](../../docs/guides/pm-hierarchy-sync.md) for operational rules

## Template

See `.agent/skills/planning/design-solution/templates/implementation-plan.md` for the plan template.
