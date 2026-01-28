# Skills

Independent, reusable building blocks for AI agent tasks.

**[-> How to Use (USAGE.md)](USAGE.md)** - Start here for usage guide.

## Core Workflow

Skills support this development workflow:

```
RFC/Requirement → Design → Implement → Test → Review → Commit → MR → JIRA/Confluence
```

## Essential Skills (Developer Workflow)

These are the core skills for the main development workflow:

| Stage | Skill | Purpose |
|-------|-------|---------|
| **Analyze** | `analyze/parse-requirement` | Clarify requirements, create design doc |
| **Plan** | `planning/design-solution` | Design solution, create implementation plan |
| **Execute** | `execute/write-code` | Test-driven development |
| **Validate** | `validate/run-tests` | Run tests, check coverage |
| **Validate** | `validate/check-style` | Lint, code style |
| **Validate** | `validate/review-code` | Code review checklist |
| **Integrate** | `integrate/commit-changes` | Write commit message |
| **Integrate** | `integrate/create-merge-request` | Create MR/PR |

## Optional Skills

These skills are useful but not required for every task:

| Category | Skill | When to Use |
|----------|-------|-------------|
| Execute | `execute/fix-defect` | Bug fixes |
| Execute | `execute/manage-issues` | JIRA card management |
| Execute | `execute/update-documentation` | Update docs after changes |
| Validate | `validate/verify-requirements` | Check implementation matches spec |
| Validate | `validate/check-intent` | Verify alignment with plan |
| Planning | `planning/breakdown-work` | Large feature decomposition |
| Planning | `planning/design-test-plan` | Comprehensive test planning |
| Analyze | `analyze/inspect-codebase` | Understand unfamiliar code |
| Analyze | `analyze/inspect-logs` | Debug production issues |
| Integrate | `integrate/merge-changes` | Merge approved MR |

## Manager Skills (Future)

These skills are for project management, not currently prioritized:

| Skill | Purpose |
|-------|---------|
| `analyze/assess-status` | Sprint/project status |
| `analyze/evaluate-priority` | Task prioritization |
| `planning/allocate-resources` | Resource allocation |
| `planning/schedule-timeline` | Project timeline |
| `planning/estimate-effort` | Effort estimation |
| `validate/analyze-impact` | Change impact analysis |
| `integrate/notify-stakeholders` | Notifications |
| `integrate/publish-report` | Status reports |

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

## Finding Skills

Use `skills_index.json` for quick lookup:

```bash
# Find all execute skills
jq '.skills[] | select(.category == "execute")' skills_index.json

# Find skills by keyword
jq '.skills[] | select(.when_to_use | contains("test"))' skills_index.json
```

Regenerate index after adding/modifying skills:

```bash
./scripts/generate-index.sh
```

## Add New Skill

1. Choose appropriate category (`analyze/`, `planning/`, `execute/`, `validate/`, `integrate/`)
2. Create directory: `category/skill-name/`
3. Copy `_template/SKILL.md`
4. Fill in details with proper frontmatter
5. Run `./scripts/generate-index.sh` to update index

## Structure

```
skills/
├── README.md           # This file
├── USAGE.md            # Usage guide
├── PIPELINE.md         # Pipeline flow
├── _template/          # Skill template
├── analyze/            # Understand situation
├── planning/           # Design approach
├── execute/            # Perform work
├── validate/           # Verify quality
└── integrate/          # Deliver results
```

## Philosophy

From [ARCHITECTURE.md](../ARCHITECTURE.md):

- **Skill**: What the agent CAN do (Capability)
- **Workflow**: What the agent SHOULD do in order (Process)
- **.cursorrules**: What the agent MUST follow (Behavior)

Keep these boundaries clear. Don't mix workflow logic into skills.
