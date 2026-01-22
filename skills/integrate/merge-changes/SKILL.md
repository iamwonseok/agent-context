---
name: merge-changes
category: integrate
description: Merge approved changes into target branch
version: 1.0.0
role: developer
inputs:
  - Approved MR/PR
  - Target branch
outputs:
  - Merged code
  - Closed MR/PR
---

# Merge Changes

## When to Use

- MR/PR approved
- CI passed
- Ready to integrate

## Prerequisites

- [ ] Code review approved
- [ ] All checks pass
- [ ] No merge conflicts
- [ ] Up to date with target

## Workflow

### 1. Verify Readiness

- [ ] Approvals received
- [ ] CI pipeline green
- [ ] No unresolved discussions

### 2. Update Branch

```bash
git checkout feature-branch
git fetch origin main
git rebase origin/main
# Resolve conflicts if any
git push --force-with-lease
```

### 3. Merge

```bash
# Via CLI
git checkout main
git merge --ff-only feature-branch
git push origin main

# Or via GitLab/GitHub UI
# Click "Merge" button
```

### 4. Clean Up

```bash
# Delete local branch
git branch -d feature-branch

# Delete remote branch
git push origin --delete feature-branch
```

### 5. Verify Merge

- [ ] Target branch updated
- [ ] Feature branch deleted
- [ ] Issue updated to Done

## Merge Strategies

| Strategy | Use When |
|----------|----------|
| Fast-forward | Linear history, clean |
| Squash | Many small commits |
| Merge commit | Preserve history |

## Outputs

| Output | Description |
|--------|-------------|
| Merged code | Changes in target |
| Merge commit | SHA reference |
| Closed MR | MR marked merged |

## Notes

- Prefer fast-forward when possible
- Delete branches after merge
- Update related issues
