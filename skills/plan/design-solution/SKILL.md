---
name: design-solution
category: plan
description: Design solution and plan implementation
version: 1.0.0
role: developer
inputs:
  - design/{feature}.md
outputs:
  - plan/{feature}-plan.md
---

# Design Solution

## When to Use

- Design approved
- Before coding
- Need task breakdown

## Prerequisites

- [ ] Approved design doc

## Workflow

### 1. Analyze Design

Extract:
- Files to change
- New files
- Dependencies

### 2. Break into Tasks

```markdown
### Task 1: Data Model
- [ ] Create model
- [ ] Write migration
- [ ] Write tests

### Task 2: API
- [ ] Implement endpoints
- [ ] Write tests
```

### 3. Define Dependencies

```
Task 1 -> Task 2 -> Task 3
```

### 4. Identify Risks

| Risk | Impact | Plan |
|------|--------|------|
| Risk 1 | High | Mitigation |

### 5. Save

```bash
plan/{feature}-plan.md
```

## Outputs

| Output | Format |
|--------|--------|
| `plan/{feature}-plan.md` | Markdown |

See `templates/implementation-plan.md`.

## Examples

### UART Driver Plan

```markdown
# Plan: UART Driver

## Tasks

### Task 1: Hardware Layer
- [ ] Register definitions
- [ ] Clock configuration

### Task 2: Buffer Layer
- [ ] Ring buffer implementation
- [ ] Overflow handling
- [ ] Tests
```

## Notes

- Large task? Break smaller
- Each task = testable unit
