---
name: assess-status
category: analyze
description: Assess project or task status and health
version: 1.0.0
role: manager
inputs:
  - Project/Epic/Task ID
  - Status tracking system access
outputs:
  - Status report
  - Risk assessment
  - Recommendations
---

# Assess Status

## When to Use

- Daily standups
- Sprint reviews
- Stakeholder updates
- Risk identification
- Progress tracking

## Prerequisites

- [ ] Access to issue tracker (JIRA/GitLab)
- [ ] Knowledge of project goals
- [ ] Team member availability

## Workflow

### 1. Gather Status Data

```bash
# Using agent CLI (when available)
agent mgr status EPIC-123

# Or query directly
pm jira issue list --epic=EPIC-123
pm gitlab issue list --milestone="Sprint 5"
```

### 2. Calculate Progress Metrics

| Metric | Formula |
|--------|---------|
| Completion % | Done / Total × 100 |
| Velocity | Points completed / Sprint |
| Burndown | Remaining work over time |
| Lead Time | Request to Delivery |

### 3. Identify Status Categories

```
┌─────────────┬───────────────────────────────┐
│ On Track    │ Progress matches plan         │
├─────────────┼───────────────────────────────┤
│ At Risk     │ Minor delays, recoverable     │
├─────────────┼───────────────────────────────┤
│ Blocked     │ External dependency waiting   │
├─────────────┼───────────────────────────────┤
│ Off Track   │ Significant delays, re-plan   │
└─────────────┴───────────────────────────────┘
```

### 4. Identify Blockers

Check for:
- Tasks in "Blocked" status
- Tasks with no updates > 3 days
- Dependencies on external teams
- Technical blockers

### 5. Assess Risks

| Risk Category | Indicators |
|---------------|------------|
| Schedule | Velocity dropping, scope creep |
| Technical | Repeated failures, unknown tech |
| Resource | Team changes, overallocation |
| External | Vendor delays, API changes |

Risk Score: Probability × Impact (1-25)

### 6. Generate Status Report

```markdown
## Status Report: {project-name}

**Date**: 2026-01-23
**Period**: Sprint 5
**Status**: [WARN] At Risk

### Summary
- Planned: 25 points
- Completed: 18 points (72%)
- In Progress: 5 points
- Blocked: 2 points

### Progress
[████████░░] 80% complete

### Key Accomplishments
- [x] User authentication completed
- [x] API endpoints deployed

### In Progress
- User dashboard (3 points) - 70% done
- Report generation (2 points) - started

### Blockers
- [ ] TASK-456: Waiting for design approval
- [ ] TASK-789: External API not responding

### Risks
| Risk | Prob | Impact | Mitigation |
|------|------|--------|------------|
| Design delay | High | Medium | Escalate to PM |
| API dependency | Medium | High | Prepare fallback |

### Next Steps
1. Escalate design approval
2. Set up API fallback
3. Re-estimate remaining work

### Needs
- Design decision by EOD Friday
- API team sync meeting
```

## Outputs

| Output | Format | Description |
|--------|--------|-------------|
| Status summary | Text | Overall health indicator |
| Progress metrics | Numbers | Completion %, velocity |
| Blockers list | List | Items blocking progress |
| Risk assessment | Table | Risks with mitigation |
| Recommendations | List | Suggested actions |

## Status Indicators

| Indicator | Meaning | Action |
|-----------|---------|--------|
| [OK] On Track | No issues | Continue |
| [WARN] At Risk | Potential issues | Monitor closely |
| [FAIL] Off Track | Significant issues | Escalate, re-plan |
| [BLOCKED] Blocked | Waiting | Resolve blockers |

## Examples

### Example 1: Sprint Status

```
Sprint 5 Status: [WARN] At Risk

Progress: 18/25 points (72%)
Days remaining: 3
Required velocity: 2.3 points/day
Current velocity: 1.5 points/day

Risk: May not complete all planned items
Recommendation: Descope TASK-999 to next sprint
```

### Example 2: Epic Health Check

```
EPIC-100 Status: [OK] On Track

Features: 4/5 complete
Timeline: 2 weeks ahead
Quality: All tests passing

No blockers identified
Recommendation: Consider adding stretch goal
```

## Notes

- Update status regularly (daily/weekly)
- Be honest about problems
- Focus on actionable insights
- Celebrate wins, not just problems
- Keep reports concise for stakeholders
