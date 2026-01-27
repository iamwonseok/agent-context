---
name: initiative
description: Initiative planning workflow
role: manager
cursor_mode: plan
mode_transitions:
  - ask     # analyze/parse-requirement
  - plan    # planning/*
skills:
  - analyze/parse-requirement
  - planning/design-solution
  - planning/breakdown-work
  - planning/schedule-timeline
  - planning/allocate-resources
references:
  - docs/guides/pm-hierarchy-sync.md
  - templates/planning/confluence-initiative.md
---

# Initiative Planning

> Refer to [PM Hierarchy Sync Guide](../../docs/guides/pm-hierarchy-sync.md) for PM hierarchy rules.

## Status

Roadmap | CLI 0% | Manual: Create Initiative in Jira UI + Link sub-Epics

## When to Use

- Quarterly planning
- New strategic initiative
- Large cross-team effort

## Flow (NOT IMPLEMENTED)

1. `agent mgr initiative create "Title"` - Define goals, scope, criteria
2. Create Epics: `agent mgr epic create "Phase N" --initiative=INIT-1`
3. `agent mgr schedule INIT-1` - Define milestones, deadlines
4. `agent mgr allocate INIT-1` - Assign teams, balance workload
5. `agent mgr announce INIT-1` - Notify stakeholders

## Outputs

| Output | Description |
|--------|-------------|
| Initiative doc | Goals, scope, criteria |
| Epics | JIRA/GitLab entries |
| Timeline | Schedule with milestones |
| Resource plan | Team assignments |

## Example (Future)

```bash
# For now, use Jira UI
agent mgr initiative create "Q1 Performance"
agent mgr epic create "Profiling" --initiative=INIT-1
agent mgr epic create "Database Opt" --initiative=INIT-1
agent mgr schedule INIT-1
agent mgr allocate INIT-1
agent mgr announce INIT-1
```
