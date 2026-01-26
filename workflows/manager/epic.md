---
name: epic
description: Epic management workflow
role: manager
skills:
  - analyze/parse-requirement
  - planning/breakdown-work
  - planning/estimate-effort
  - analyze/assess-status
references:
  - docs/guides/pm-hierarchy-sync.md
  - templates/planning/confluence-epic.md
---

# Epic Management

> Refer to [PM Hierarchy Sync Guide](../../docs/guides/pm-hierarchy-sync.md) for PM hierarchy rules.

## Status

Roadmap | CLI 0% | Manual: Create Epic in Jira UI + Link sub-Tasks/Stories

## When to Use

- Breaking down initiative into features
- Managing feature group delivery
- Tracking multi-sprint work

## Flow (NOT IMPLEMENTED)

1. `agent mgr epic create "Title" --initiative=INIT-1` - Define scope, criteria
2. `agent mgr breakdown EPIC-50` - Create stories/tasks, set dependencies
3. `agent mgr estimate EPIC-50` - Size tasks, calculate effort
4. `agent mgr status EPIC-50` - Monitor completion, identify blockers

## Outputs

| Output | Description |
|--------|-------------|
| Epic | JIRA/GitLab Epic |
| Tasks | Subtasks/Stories |
| Estimates | Effort sizing |
| Status | Progress tracking |

## Example (Future)

```bash
# For now, use Jira UI
agent mgr epic create "Auth System" --initiative=INIT-1
agent mgr breakdown EPIC-50    # Creates: TASK-51, 52, 53
agent mgr estimate EPIC-50     # Total 40 story points
agent mgr status EPIC-50       # 60% complete
```
