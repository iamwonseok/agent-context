---
name: task-assignment
description: Task assignment workflow
role: manager
skills:
  - analyze/evaluate-priority
  - plan/allocate-resources
  - integrate/notify-stakeholders
---

# Task Assignment

## Implementation Status

- **Status**: Partial
- **CLI Coverage**: 40% (조회만 가능, 할당은 UI 필요)
- **Manual Alternative**: JQL로 유휴 인력 조회 + Jira UI에서 Assignee 할당
- **Last Updated**: 2026-01-24
- **Gaps**: `agent mgr inbox`, `agent mgr assign` 명령어 미구현

## When to Use

- New task needs assignee
- Rebalancing workload
- Sprint planning

## Command Flow

### Step 1: Review Inbox

```bash
agent mgr inbox
```

- List unassigned tasks
- Show priority indicators

### Step 2: Evaluate Priority

```bash
agent mgr evaluate TASK-123
```

- Assess urgency
- Assess impact
- Recommend priority level

**Skills**: `analyze/evaluate-priority`

### Step 3: Check Availability

```bash
agent mgr capacity
```

- Show team workload
- Identify available capacity

**Skills**: `plan/allocate-resources`

### Step 4: Assign & Validate Dependencies

```bash
agent mgr assign TASK-123 --to=@john --priority=P2
```

- Update JIRA/GitLab
- Set priority
- Set sprint/milestone
- **Validate Dependencies**: 
    - `Is blocked by` 링크가 걸린 경우, 선행 작업이 이미 완료되었거나 동일 스프린트에 포함되었는지 확인합니다.
    - 선행 작업이 다른 팀 소관일 경우, `Relates to`를 통해 미리 담당자 간 소통을 유도합니다.

### Step 5: Notify

```bash
agent mgr notify TASK-123
```

- Notify assignee
- Provide context

**Skills**: `integrate/notify-stakeholders`

## Outputs

| Output | Description |
|--------|-------------|
| Assignment | Task assigned to developer |
| Notification | Developer notified |
| Updated status | Task in sprint backlog |

## Example

```bash
# Review unassigned
agent mgr inbox
# Shows: TASK-123, TASK-124, TASK-125

# Evaluate
agent mgr evaluate TASK-123
# Output: P2 - High priority, customer impact

# Check capacity
agent mgr capacity
# Output: John at 60%, Jane at 80%

# Assign
agent mgr assign TASK-123 --to=@john --priority=P2
# Output: Assigned TASK-123 to John

# Notify
agent mgr notify TASK-123
# Output: John notified via Slack
```
