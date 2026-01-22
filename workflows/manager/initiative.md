---
name: initiative
description: Initiative planning workflow
role: manager
skills:
  - analyze/parse-requirement
  - plan/design-solution
  - plan/breakdown-work
  - plan/schedule-timeline
  - plan/allocate-resources
---

# Initiative Planning

## When to Use

- Quarterly planning
- New strategic initiative
- Large cross-team effort

## Command Flow

### Step 1: Define Initiative

```bash
agent mgr initiative create "Q1 Performance Optimization"
```

- Interactive goal definition
- Scope clarification
- Success criteria

**Skills**: `analyze/parse-requirement`  
**Output**: `design/initiatives/<initiative-id>.md`

### Step 2: Create Epics

```bash
agent mgr epic create "Phase 1: Profiling" --initiative=INIT-1
agent mgr epic create "Phase 2: Database" --initiative=INIT-1
agent mgr epic create "Phase 3: Caching" --initiative=INIT-1
```

- Break into manageable phases
- Create JIRA Epics
- Create GitLab Milestones

**Skills**: `plan/design-solution`, `plan/breakdown-work`

### Step 3: Schedule Timeline

```bash
agent mgr schedule INIT-1
```

- Define milestones
- Set deadlines
- Identify dependencies

**Skills**: `plan/schedule-timeline`  
**Output**: Timeline document

### Step 4: Allocate Resources

```bash
agent mgr allocate INIT-1
```

- Assign teams
- Balance workload
- Identify gaps

**Skills**: `plan/allocate-resources`

### Step 5: Communicate

```bash
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
