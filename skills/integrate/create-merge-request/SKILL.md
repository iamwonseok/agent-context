---
name: create-merge-request
category: integrate
description: Create merge request for completed work
version: 1.0.0
role: developer
mode: implementation
cursor_mode: agent
inputs:
  - Completed branch
outputs:
  - Merge Request URL
---

# Create Merge Request

## State Assertion

**Mode**: implementation
**Cursor Mode**: agent
**Purpose**: Create merge request with proper description
**Boundaries**:
- Will: Push branch, create MR, link issues, add reviewers
- Will NOT: Merge MR, approve MR, or bypass CI checks

## When to Use

- All tasks done
- All commits done
- Ready to merge

## Prerequisites

- [ ] Tests pass
- [ ] Lint pass
- [ ] Review done

## Workflow

### 1. Final Check

```bash
git status
git log main..HEAD --oneline
```

### 2. Push

```bash
git push -u origin feat/PROJ-123
```

### 3. Create MR

**GitLab**:
```bash
glab mr create --title "feat: uart driver" --description "Closes #123"
```

**GitHub**:
```bash
gh pr create --title "feat: uart driver" --body "Closes #123"
```

### 4. Address Feedback

```bash
git commit -m "fix: address review"
git push
```

### 5. Merge

```bash
glab mr merge --squash
```

### 6. Cleanup

```bash
git checkout main
git pull
git branch -d feat/PROJ-123

# If worktree
git worktree remove ../project-feat
```

## Outputs

| Output | Format |
|--------|--------|
| MR | URL |
| Merged | SHA |

## Examples

```bash
# Push
git push -u origin feat/PROJ-123

# Create MR
glab mr create --title "feat: uart driver"

# After approval
glab mr merge --squash

# Cleanup
git checkout main && git pull
git branch -d feat/PROJ-123
```

## Notes

- Squash merge for features
- Always cleanup branches
