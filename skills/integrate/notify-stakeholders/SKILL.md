---
name: notify-stakeholders
category: integrate
description: Notify relevant stakeholders about changes
version: 1.0.0
role: both
mode: implementation
cursor_mode: agent
inputs:
  - Change details
  - Stakeholder list
outputs:
  - Notifications sent
---

# Notify Stakeholders

## State Assertion

**Mode**: implementation
**Cursor Mode**: agent
**Purpose**: Send notifications about changes to stakeholders
**Boundaries**:
- Will: Draft messages, send notifications, update channels
- Will NOT: Make decisions on behalf of stakeholders, or escalate without permission

## When to Use

- Feature released
- Breaking changes
- Incidents
- Important updates

## Prerequisites

- [ ] Change information
- [ ] Stakeholder list
- [ ] Communication channels

## Workflow

### 1. Identify Audience

| Audience | Notify When |
|----------|-------------|
| Users | User-facing changes |
| Dev team | Technical changes |
| Support | Customer impact |
| Management | Major releases |

### 2. Choose Channel

| Channel | Use For |
|---------|---------|
| Slack | Quick updates |
| Email | Formal announcements |
| JIRA | Issue updates |
| Docs | Permanent reference |

### 3. Write Message

Include:
- What changed
- Why it matters
- Action needed
- Timeline

### 4. Send & Track

- Send notification
- Track acknowledgments
- Follow up if needed

## Template

```
Subject: [Release] Feature X now available

Hi team,

Feature X has been released to production.

What changed:
- New login flow
- Improved performance

Action needed:
- Update client SDK to v2.0

Timeline:
- Available now
- Old API deprecated in 30 days

Questions? Reply to this thread.
```

## Outputs

| Output | Description |
|--------|-------------|
| Notifications | Messages sent |
| Acknowledgments | Confirmations |

## Notes

- Be concise
- Include action items
- Provide timeline
