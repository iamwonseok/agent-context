---
name: publish-report
category: integrate
description: Publish project reports and metrics
version: 1.0.0
role: manager
mode: implementation
cursor_mode: agent
inputs:
  - Report data
  - Report type
outputs:
  - Published report
---

# Publish Report

## State Assertion

**Mode**: implementation
**Cursor Mode**: agent
**Purpose**: Generate and publish project reports
**Boundaries**:
- Will: Generate reports, format data, publish to channels
- Will NOT: Fabricate data, change metrics, or bypass approvals

## When to Use

- Sprint completion
- Release milestones
- Status updates
- Metrics review

## Prerequisites

- [ ] Data collected
- [ ] Report template
- [ ] Publishing access

## Workflow

### 1. Gather Data

- Sprint metrics
- Completion rates
- Quality metrics
- Team velocity

### 2. Generate Report

```markdown
## Sprint 5 Report

### Summary
- Planned: 30 points
- Completed: 28 points
- Velocity: 28 pts/sprint

### Highlights
- Feature X released
- Bug count reduced 20%

### Challenges
- External API delays

### Next Sprint
- Focus on performance
```

### 3. Review

- Check accuracy
- Get feedback
- Update if needed

### 4. Publish

- Upload to wiki/docs
- Share via email/Slack
- Archive for reference

## Report Types

| Type | Frequency | Audience |
|------|-----------|----------|
| Sprint | Bi-weekly | Team |
| Monthly | Monthly | Management |
| Release | Per release | All |
| Quarterly | Quarterly | Executives |

## Outputs

| Output | Description |
|--------|-------------|
| Report | Published document |
| Metrics | Key numbers |
| Archive | Historical record |

## Notes

- Be honest about challenges
- Include actionable insights
- Keep concise for executives
