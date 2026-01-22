# Git Worktree

## What

Multiple branches checked out at once. Each worktree = separate directory, shared `.git`.

## When to Use

| Situation | Worktree? |
|-----------|-----------|
| Emergency hotfix | Yes |
| Concurrent features | Yes |
| Review while working | Yes |
| Simple branch switch | No |
| Short task (<1h) | No |

## Commands

### Create

```bash
# Existing branch
git worktree add ../project-hotfix hotfix/1.2.3

# New branch
git worktree add ../project-feat -b feat/PROJ-123 main
```

### List

```bash
git worktree list
```

### Remove

```bash
git worktree remove ../project-hotfix

# Force (uncommitted changes)
git worktree remove --force ../project-hotfix
```

### Cleanup

```bash
git worktree prune
```

## Workflow: Hotfix

```bash
# 1. Create worktree
git worktree add ../hotfix -b hotfix/1.2.3 main

# 2. Fix
cd ../hotfix
vim src/bug.py
git commit -m "fix: critical bug"
git push -u origin hotfix/1.2.3

# 3. Cleanup
cd ../project
git worktree remove ../hotfix
```

## Workflow: Concurrent Work

```bash
# Feature A
git worktree add ../feat-a -b feat/PROJ-100 main

# Feature B
git worktree add ../feat-b -b feat/PROJ-200 main

# Work in separate terminals
# Terminal 1: cd ../feat-a
# Terminal 2: cd ../feat-b

# Cleanup when done
git worktree remove ../feat-a
git worktree remove ../feat-b
```

## Directory Structure

```
~/projects/
+-- my-project/        # main
+-- my-project-feat/   # feature worktree
+-- my-project-hotfix/ # hotfix worktree
```

## Rules

**Do**:
- Remove worktree after work
- Run `git worktree prune` regularly
- Use separate terminals

**Don't**:
- Checkout same branch twice
- Use `git checkout` in worktree
- Delete directory manually (use `git worktree remove`)

## Troubleshooting

### Already checked out

```bash
git worktree list
git worktree remove /path/to/worktree
```

### Dangling worktree

```bash
git worktree prune
```

### Uncommitted changes

```bash
git worktree remove --force /path
```
