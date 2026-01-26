---
name: task-assignment
description: Task assignment workflow
role: manager
skills:
  - analyze/evaluate-priority
  - planning/allocate-resources
  - integrate/notify-stakeholders
---

# Task Assignment

## Status

Partial | CLI 40% | Manual: JQL query + Assign in Jira UI

## When to Use

- New task needs assignee
- Rebalancing workload
- Sprint planning

## Flow

1. `agent mgr inbox` - List unassigned tasks with priority
2. `agent mgr evaluate TASK-123` - Assess urgency/impact
3. `agent mgr capacity` - Show team workload
4. `agent mgr assign TASK-123 --to=@john --priority=P2` - Assign with validation
   - Check `Is blocked by` links - ensure prerequisites complete
   - Use `Relates to` for cross-team coordination
5. `agent mgr notify TASK-123` - Notify assignee with context

## Outputs

| Output | Description |
|--------|-------------|
| Assignment | Task assigned |
| Notification | Developer notified |
| Updated status | Task in sprint backlog |

## Example

```bash
agent mgr inbox               # TASK-123, 124, 125
agent mgr evaluate TASK-123   # P2 - High priority
agent mgr capacity            # John 60%, Jane 80%
agent mgr assign TASK-123 --to=@john --priority=P2
agent mgr notify TASK-123     # John notified
```
