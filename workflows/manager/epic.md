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

> [!NOTE]
> Refer to [PM Hierarchy Sync Guide](../../docs/guides/pm-hierarchy-sync.md) for PM hierarchy operation rules.
> Use [Confluence Epic Template](../../templates/planning/confluence-epic.md) for Confluence pages.

## Implementation Status

- **Status**: Roadmap
- **CLI Coverage**: 0% (documentation only)
- **Manual Alternative**: Create Epic in Jira UI + Link sub-Tasks/Stories
- **Last Updated**: 2026-01-24
- **Note**: `agent mgr epic` command is currently not implemented.

## When to Use

- Breaking down initiative into features
- Managing feature group delivery
- Tracking multi-sprint work

## Command Flow

> **Note**: Commands below are **not yet implemented**. Use Manual Alternative in the meantime.

### Step 1: Create Epic

```bash
# [NOT IMPLEMENTED] Future CLI example
agent mgr epic create "User Authentication System" --initiative=INIT-1
```

- Define epic scope
- Set acceptance criteria
- Create in JIRA/GitLab

**Skills**: `analyze/parse-requirement`

### Step 2: Break Down to Tasks

```bash
# [NOT IMPLEMENTED] Future CLI example
agent mgr breakdown EPIC-50
```

- Create user stories
- Define tasks
- Set dependencies

**Skills**: `planning/breakdown-work`

### Step 3: Estimate

```bash
# [NOT IMPLEMENTED] Future CLI example
agent mgr estimate EPIC-50
```

- Size each task
- Calculate total effort
- Identify risks

**Skills**: `planning/estimate-effort`

### Step 4: Track Progress

```bash
# [NOT IMPLEMENTED] Future CLI example
agent mgr status EPIC-50
```

- Monitor completion
- Identify blockers
- Update stakeholders

**Skills**: `analyze/assess-status`

## Outputs

| Output | Description |
|--------|-------------|
| Epic | JIRA/GitLab Epic |
| Tasks | Subtasks/Stories |
| Estimates | Effort sizing |
| Status | Progress tracking |

## Example

```bash
# [NOT IMPLEMENTED] Future CLI workflow example
# For now, use Jira UI to create Epic and link Tasks

# Create epic
agent mgr epic create "Auth System" --initiative=INIT-1

# Break down
agent mgr breakdown EPIC-50
# Creates: TASK-51, TASK-52, TASK-53, ...

# Estimate
agent mgr estimate EPIC-50
# Output: Total 40 story points

# Track
agent mgr status EPIC-50
# Output: 60% complete, on track
```
