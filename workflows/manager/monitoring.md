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

### Step 4: Take Action & Retrospective

Based on findings:

```bash
# Reassign blocked tasks
agent mgr assign TASK-456 --to=@jane

# Split oversized tasks for next sprint
# Create new task and link: pm jira link create TASK-123 TASK-124 "Split"
```

#### Monthly Retrospective Tips:
- **Root Cause Analysis**: `Causes` 링크가 많이 걸린 작업들을 전수 조사하여 프로세스 개선 (예: "기획 변경으로 인한 버그 발생 빈도 측정")
- **Dependency Map**: `Blocks` 관계가 복잡하게 얽힌 구간을 파악하여 다음 계획 시 자원 우선 배정

#### Visualization Tip:
> [!TIP]
> **Jira 보드에서 Blocked 강조하기**:
> 1. Board Settings -> Card Colours -> Choose 'Queries'
> 2. JQL에 `issueLinkType = "is blocked by"` 입력 후 색상을 **빨간색**으로 설정
> 3. 이제 차단된 업무가 보드에서 즉시 시각적으로 드러납니다!

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
