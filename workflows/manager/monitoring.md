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

## Status

Partial | CLI 30% | Manual: Jira filters/boards + `glab mr list`

## When to Use

- Daily standups
- Sprint reviews
- Stakeholder updates
- Risk identification

## Flow (PARTIAL)

1. `agent mgr status EPIC-50` - Progress, tasks by status, blockers
2. `agent mgr detect-delays EPIC-50` - Identify delayed tasks, assess impact
3. `agent mgr report daily|weekly` - Compile metrics, summarize progress
4. Take action: `agent mgr assign TASK-456 --to=@jane`

## Outputs

| Output | Description |
|--------|-------------|
| Status summary | Current state |
| Risk report | Issues and mitigations |
| Daily/Weekly report | Published updates |

## Retrospective Tips

- **Root Cause Analysis**: Investigate tasks with many `Causes` links
- **Dependency Map**: Identify complex `Blocks` relationships
- **Board Tip**: Board Settings -> Card Colours -> JQL `issueLinkType = "is blocked by"` -> red

## Example (Future)

```bash
# For now, use Jira UI + glab mr list
agent mgr status EPIC-50          # 70% complete, 2 blocked
agent mgr detect-delays EPIC-50   # TASK-456 delayed 2 days
agent mgr escalate TASK-456       # Waiting for API team
agent mgr report weekly --epic=EPIC-50 --publish
```
