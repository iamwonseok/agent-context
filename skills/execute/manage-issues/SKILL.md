---
name: manage-issues
category: execute
description: Create, update, and manage issues in tracking systems
version: 1.0.0
role: both
mode: implementation
cursor_mode: agent
inputs:
  - Issue details or updates
outputs:
  - Created/updated issues
---

# Manage Issues

## State Assertion

**Mode**: implementation
**Cursor Mode**: agent
**Purpose**: Create and manage issues in tracking systems
**Boundaries**:
- Will: Create issues, update status, link related issues, add comments
- Will NOT: Delete issues without confirmation, bulk operations without review

## When to Use

- Creating bug reports
- Creating feature requests
- Updating issue status
- Linking related issues

## Prerequisites

- [ ] Access to issue tracker
- [ ] Project permissions

## Workflow

### 1. Choose Issue Type

| Type | Use For |
|------|---------|
| Bug | Defects, errors |
| Task | Work items |
| Story | User features |
| Epic | Large features |

### 2. Write Good Title

Good: "Fix null pointer in user login"
Bad: "Bug"

### 3. Fill Details

- Description
- Steps to reproduce (bugs)
- Acceptance criteria (features)
- Environment info

### 4. Set Properties

- Priority: P1-P4
- Assignee
- Labels
- Sprint/Milestone

### 5. Update Status

TODO -> In Progress -> In Review -> Done

## Outputs

| Output | Format |
|--------|--------|
| Issue URL | Link |
| Issue key | TASK-123 |

## Notes

- Use clear titles
- Include details
- Update status promptly
