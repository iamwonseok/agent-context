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
- **CLI Coverage**: 30% (MR query only, Epic/Initiative status via Jira UI)
- **Manual Alternative**: Use Jira filters/boards/reports + `glab mr list` for MR status
- **Last Updated**: 2026-01-24
- **Gaps**: `agent mgr status`, `agent mgr detect-delays` commands not implemented

## When to Use

- Daily standups
- Sprint reviews
- Stakeholder updates
- Risk identification

## Command Flow

> **Note**: Most commands below are **not yet implemented**. See "Gaps" in Implementation Status.

### Step 1: Check Status

```bash
# [NOT IMPLEMENTED] Future CLI example
agent mgr status EPIC-50
```

- Progress percentage
- Tasks by status
- Blockers

**Skills**: `analyze/assess-status`

### Step 2: Detect Issues

```bash
# [NOT IMPLEMENTED] Future CLI example
agent mgr detect-delays EPIC-50
```

- Identify delayed tasks
- Assess impact
- Suggest actions

**Skills**: `validate/analyze-impact`

### Step 3: Generate Report

```bash
# [NOT IMPLEMENTED] Future CLI example
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
- **Root Cause Analysis**: Investigate tasks with many `Causes` links to improve processes (e.g., "Measure bug frequency due to requirement changes")
- **Dependency Map**: Identify areas with complex `Blocks` relationships to prioritize resource allocation in next planning

#### Visualization Tip:
> [!TIP]
> **Highlight Blocked Items in Jira Board**:
> 1. Board Settings -> Card Colours -> Choose 'Queries'
> 2. Enter `issueLinkType = "is blocked by"` in JQL and set color to **red**
> 3. Blocked tasks are now immediately visible on the board!

## Outputs

| Output | Description |
|--------|-------------|
| Status summary | Current state |
| Risk report | Issues and mitigations |
| Daily/Weekly report | Published updates |

## Example

```bash
# [NOT IMPLEMENTED] Future CLI workflow example
# For now, use Jira UI filters/boards/reports + `glab mr list`

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
