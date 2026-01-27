---
name: commit-changes
category: integrate
description: Write commit message and commit changes
version: 1.0.0
role: developer
mode: implementation
cursor_mode: agent
inputs:
  - Staged changes (git diff)
outputs:
  - Git commit
---

# Commit Changes

## State Assertion

**Mode**: implementation
**Cursor Mode**: agent
**Purpose**: Create meaningful commits with proper messages
**Boundaries**:
- Will: Stage files, write commit message, create commit
- Will NOT: Push to remote, merge branches, or skip validation

## When to Use

- Task complete
- Tests pass
- Review done

## Prerequisites

- [ ] Changes staged
- [ ] Tests pass

## Workflow

### 1. Check Changes

```bash
git diff --staged --stat
```

### 2. Choose Type

| Type | Use |
|------|-----|
| feat | New feature |
| fix | Bug fix |
| refactor | Refactor |
| test | Tests |
| docs | Docs |

### 3. Write Message

Format:
```
type(scope): subject

body (optional)

footer (optional)
```

Rules:
- Imperative: "Add" not "Added"
- <=50 chars subject
- No period

### 4. Commit

```bash
git commit -m "feat(uart): add interrupt handler

- RX/TX ring buffer
- Baud rate configuration

Closes #123"
```

## Outputs

| Output | Format |
|--------|--------|
| Commit | Git SHA |

## Examples

### Feature

```bash
git commit -m "feat(user): add avatar upload"
```

### Bug Fix

```bash
git commit -m "fix(cart): prevent negative qty

Validate qty >= 1.

Fixes #567"
```

## Notes

- Atomic: one change
- Clear message
- Link issues
