---
name: initiative
description: Initiative planning workflow
role: manager
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

> [!NOTE]
> Refer to [PM Hierarchy Sync Guide](../../docs/guides/pm-hierarchy-sync.md) for PM hierarchy operation rules.
> Use [Confluence Initiative Template](../../templates/planning/confluence-initiative.md) for Confluence pages.

## Implementation Status

- **Status**: Roadmap
- **CLI Coverage**: 0% (documentation only)
- **Manual Alternative**: Create Epic or Initiative type Issue in Jira UI + Link sub-Epics/Tasks
- **Last Updated**: 2026-01-24
- **Note**: `agent mgr initiative` command is currently not implemented.

## When to Use

- Quarterly planning
- New strategic initiative
- Large cross-team effort

## Command Flow

> **Note**: Commands below are **not yet implemented**. Use Manual Alternative in the meantime.

### Step 1: Define Initiative

```bash
# [NOT IMPLEMENTED] Future CLI example
agent mgr initiative create "Q1 Performance Optimization"
```

- Interactive goal definition
- Scope clarification
- Success criteria

**Skills**: `analyze/parse-requirement`  
**Output**: `design/initiatives/<initiative-id>.md`

### Step 2: Create Epics

```bash
# [NOT IMPLEMENTED] Future CLI example
agent mgr epic create "Phase 1: Profiling" --initiative=INIT-1
agent mgr epic create "Phase 2: Database" --initiative=INIT-1
agent mgr epic create "Phase 3: Caching" --initiative=INIT-1
```

- Break into manageable phases
- Create JIRA Epics
- Create GitLab Milestones

**Skills**: `planning/design-solution`, `planning/breakdown-work`

### Step 3: Schedule Timeline

```bash
# [NOT IMPLEMENTED] Future CLI example
agent mgr schedule INIT-1
```

- Define milestones
- Set deadlines
- Identify dependencies

**Skills**: `planning/schedule-timeline`  
**Output**: Timeline document

### Step 4: Allocate Resources

```bash
# [NOT IMPLEMENTED] Future CLI example
agent mgr allocate INIT-1
```

- Assign teams
- Balance workload
- Identify gaps

**Skills**: `planning/allocate-resources`

### Step 5: Communicate

```bash
# [NOT IMPLEMENTED] Future CLI example
agent mgr announce INIT-1
```

- Stakeholder notification
- Kickoff preparation

## Outputs

| Output | Description |
|--------|-------------|
| Initiative doc | Goals, scope, criteria |
| Epics | JIRA/GitLab entries |
| Timeline | Schedule with milestones |
| Resource plan | Team assignments |

## Example

```bash
# [NOT IMPLEMENTED] Future CLI workflow example
# For now, use Jira UI to create Epic/Initiative

# Create initiative
agent mgr initiative create "Q1 Performance"

# Break into epics
agent mgr epic create "Profiling" --initiative=INIT-1
agent mgr epic create "Database Optimization" --initiative=INIT-1
agent mgr epic create "Caching Layer" --initiative=INIT-1

# Plan and allocate
agent mgr schedule INIT-1
agent mgr allocate INIT-1

# Announce
agent mgr announce INIT-1
```
