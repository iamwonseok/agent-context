---
name: monitoring
description: Progress monitoring workflow
role: manager
skills:
  - analyze/assess-status
  - validate/analyze-impact
  - integrate/publish-report
---

# Progress Monitoring

## Implementation Status

- **Status**: Partial
- **CLI Coverage**: 30% (MR 조회만 가능, Epic/Initiative 상태는 Jira UI)
- **Manual Alternative**: Jira UI에서 필터/보드/리포트 사용 + `glab mr list`로 MR 현황 조회
- **Last Updated**: 2026-01-24
- **Gaps**: `agent mgr status`, `agent mgr detect-delays` 명령어 미구현

## When to Use

- Daily standups
- Sprint reviews
- Stakeholder updates
- Risk identification

## Command Flow

### Step 1: Check Status

```bash
agent mgr status EPIC-50
```

- Progress percentage
- Tasks by status
- Blockers

**Skills**: `analyze/assess-status`

### Step 2: Detect Issues

```bash
agent mgr detect-delays EPIC-50
```

- Identify delayed tasks
- Assess impact
- Suggest actions

**Skills**: `validate/analyze-impact`

### Step 3: Generate Report

```bash
agent mgr report daily
agent mgr report weekly --epic=EPIC-50
```

- Compile metrics
- Summarize progress
- List action items

**Skills**: `integrate/publish-report`

### Step 4: Take Action

Based on findings:

```bash
# Reassign blocked tasks
agent mgr assign TASK-456 --to=@jane

# Adjust timeline
agent mgr adjust EPIC-50 --deadline="2026-02-15"

# Escalate issues
agent mgr escalate TASK-789 --reason="External dependency"
```

## Outputs

| Output | Description |
|--------|-------------|
| Status summary | Current state |
| Risk report | Issues and mitigations |
| Daily/Weekly report | Published updates |

## Example

```bash
# Morning check
agent mgr status EPIC-50
# Output: 70% complete, 2 blocked

# Investigate
agent mgr detect-delays EPIC-50
# Output: TASK-456 delayed 2 days, API dependency

# Take action
agent mgr escalate TASK-456 --reason="Waiting for API team"

# End of week report
agent mgr report weekly --epic=EPIC-50 --publish
# Output: Report published to Confluence
```
