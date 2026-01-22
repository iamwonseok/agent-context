---
name: epic
description: Epic management workflow
role: manager
skills:
  - analyze/parse-requirement
  - plan/breakdown-work
  - plan/estimate-effort
  - analyze/assess-status
---

# Epic Management

## When to Use

- Breaking down initiative into features
- Managing feature group delivery
- Tracking multi-sprint work

## Command Flow

### Step 1: Create Epic

```bash
agent mgr epic create "User Authentication System" --initiative=INIT-1
```

- Define epic scope
- Set acceptance criteria
- Create in JIRA/GitLab

**Skills**: `analyze/parse-requirement`

### Step 2: Break Down to Tasks

```bash
agent mgr breakdown EPIC-50
```

- Create user stories
- Define tasks
- Set dependencies

**Skills**: `plan/breakdown-work`

### Step 3: Estimate

```bash
agent mgr estimate EPIC-50
```

- Size each task
- Calculate total effort
- Identify risks

**Skills**: `plan/estimate-effort`

### Step 4: Track Progress

```bash
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
