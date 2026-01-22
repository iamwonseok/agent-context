---
name: evaluate-priority
category: analyze
description: Evaluate and prioritize tasks based on impact and urgency
version: 1.0.0
role: manager
inputs:
  - Task list or backlog
  - Business context
  - Resource constraints
outputs:
  - Prioritized task list
  - Priority rationale
---

# Evaluate Priority

## When to Use

- Sprint planning
- Backlog grooming
- Urgent request triage
- Resource allocation decisions

## Prerequisites

- [ ] List of tasks/issues
- [ ] Understanding of business goals
- [ ] Knowledge of team capacity

## Workflow

### 1. Gather Task Information

For each task, collect:
- Description and scope
- Requester and stakeholders
- Dependencies
- Estimated effort

### 2. Apply Priority Matrix

Use Eisenhower Matrix:

```
                URGENT              NOT URGENT
           ┌─────────────────┬─────────────────┐
IMPORTANT  │   DO FIRST      │   SCHEDULE      │
           │   (P1 - Critical)│   (P2 - High)   │
           ├─────────────────┼─────────────────┤
NOT        │   DELEGATE      │   ELIMINATE     │
IMPORTANT  │   (P3 - Medium) │   (P4 - Low)    │
           └─────────────────┴─────────────────┘
```

### 3. Evaluate Impact

| Factor | Questions |
|--------|-----------|
| Business Value | Revenue impact? User impact? |
| Risk | What if we don't do this? |
| Dependencies | Does it block other work? |
| Strategic Fit | Aligns with goals? |

Score: 1 (Low) to 5 (High)

### 4. Evaluate Urgency

| Factor | Questions |
|--------|-----------|
| Deadline | Hard deadline? Soft deadline? |
| Time Sensitivity | Gets harder over time? |
| External Pressure | Customer/stakeholder waiting? |
| Opportunity Cost | Miss window if delayed? |

Score: 1 (Low) to 5 (High)

### 5. Calculate Priority Score

```
Priority Score = (Impact × 2) + Urgency + Dependencies
```

Or use WSJF (Weighted Shortest Job First):

```
WSJF = (Business Value + Time Criticality + Risk Reduction) / Job Size
```

### 6. Consider Constraints

- Team availability
- Technical dependencies
- External blockers
- Budget limitations

### 7. Document Priority Decision

```markdown
## Priority Assessment: {task-id}

### Scores
| Factor | Score (1-5) |
|--------|-------------|
| Business Value | 4 |
| Urgency | 3 |
| Risk | 2 |
| Dependencies | 3 |
| **Total** | **12** |

### Priority: P2 (High)

### Rationale
- Direct customer impact (value: 4)
- No hard deadline but customer waiting (urgency: 3)
- Workaround exists (risk: 2)
- Blocks feature X (deps: 3)

### Recommendation
Schedule for next sprint, assign senior developer
```

## Outputs

| Output | Format | Description |
|--------|--------|-------------|
| Priority level | P1-P4 | Final priority assignment |
| Score breakdown | Table | Factor-by-factor scores |
| Rationale | Text | Explanation for priority |
| Recommendation | Text | Suggested action |

## Priority Levels

| Level | Response Time | Description |
|-------|---------------|-------------|
| P1 - Critical | Immediate | Production down, security breach |
| P2 - High | Same sprint | Important feature, customer blocker |
| P3 - Medium | Next sprint | Nice to have, improvements |
| P4 - Low | Backlog | Future consideration |

## Examples

### Example 1: Security Vulnerability

```
Task: "Fix SQL injection in login"

Impact: 5 (Security risk)
Urgency: 5 (Active vulnerability)
Priority: P1 - Critical
Action: Drop everything, fix immediately
```

### Example 2: Feature Request

```
Task: "Add dark mode support"

Impact: 2 (Nice to have)
Urgency: 1 (No deadline)
Priority: P4 - Low
Action: Add to backlog for future sprint
```

### Example 3: Customer Escalation

```
Task: "API timeout affecting 10% of users"

Impact: 4 (User experience)
Urgency: 4 (Customers complaining)
Priority: P2 - High
Action: Assign to current sprint
```

## Notes

- Re-evaluate priorities regularly
- Consider team morale (not always critical tasks)
- Balance quick wins with strategic work
- Document decisions for transparency
- Involve stakeholders in major decisions
