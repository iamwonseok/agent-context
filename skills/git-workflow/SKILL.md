---
name: git-workflow
description: Manage branches and worktrees
version: 1.0.0
inputs:
  - Task or issue to work on
outputs:
  - Git branch or worktree
---

# Git Workflow

## When to Use

- Start new work
- Need isolated environment
- Concurrent tasks

## Prerequisites

- [ ] Git repo initialized
- [ ] Main branch up to date

## Workflow

### 1. Branch Naming

Format: `{type}/{issue}-{desc}`

| Type | Use |
|------|-----|
| feat | New feature |
| fix | Bug fix |
| hotfix | Emergency |

### 2. Choose Method

| Situation | Use |
|-----------|-----|
| Simple work | Branch |
| Emergency | Worktree |
| Concurrent | Worktree |

### 3. Create

**Branch**:
```bash
git checkout main
git pull
git checkout -b feat/PROJ-123-feature
```

**Worktree**:
```bash
git worktree add ../project-hotfix -b hotfix/1.2.3 main
cd ../project-hotfix
```

### 4. Cleanup (Worktree)

```bash
cd ../project
git worktree remove ../project-hotfix
```

## Outputs

| Output | Description |
|--------|-------------|
| Branch | Working branch |
| Worktree | Isolated environment |

## Examples

### New Feature

```bash
git checkout -b feat/PROJ-123-uart-driver
```

### Hotfix

```bash
git worktree add ../hotfix -b hotfix/1.2.3 main
cd ../hotfix
# fix...
git push -u origin hotfix/1.2.3
cd ../project
git worktree remove ../hotfix
```

## References

- [branch-naming.md](references/branch-naming.md)
- [worktree-guide.md](references/worktree-guide.md)
- [merge-strategies.md](references/merge-strategies.md)
- [multi-agent-rules.md](references/multi-agent-rules.md)

## Notes

- No direct push to main
- Cleanup worktrees after use
