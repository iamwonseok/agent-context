# Multi-Agent Git Workflow Rules

Guidelines for managing git state when multiple agents work on the same repository.

## Core Principle

**All agent work MUST be done on a local branch, never directly on main.**

```
[Agent Work]
     |
     v
local branch (feat/*, fix/*, etc.)
     |
     v
[Review / Test]
     |
     v
Merge to main
```

### Why

- Protects main branch from incomplete work
- Enables parallel work by multiple agents
- Allows review before integration
- Easy rollback if something goes wrong

## Concurrent Work with Worktree

When multiple agents work simultaneously on different tasks, use **git worktree**.

```bash
# Main workspace (Agent 1)
/project/              <- main branch or feat/task-a

# Additional worktrees (Agent 2, 3, ...)
/project-feat-b/       <- feat/task-b (worktree)
/project-hotfix/       <- hotfix/urgent (worktree)
```

### Setup

```bash
# Agent 1: works in main directory
cd /project
git checkout -b feat/PROJ-100-task-a

# Agent 2: create worktree for separate task
git worktree add ../project-feat-b -b feat/PROJ-101-task-b main
cd ../project-feat-b

# Agent 3: another worktree
git worktree add ../project-hotfix -b hotfix/PROJ-102-fix main
cd ../project-hotfix
```

### Cleanup

```bash
cd /project
git worktree remove ../project-feat-b
git worktree remove ../project-hotfix
```

**See**: [worktree-guide.md](worktree-guide.md) for detailed usage.

## Session Lifecycle

### Session Start

1. **Check git status first**
   ```bash
   git status
   git branch        # What branch am I on?
   git stash list
   ```

2. **Ensure you're on a feature branch (not main)**
   ```bash
   # If on main, create or checkout a feature branch
   git checkout -b feat/PROJ-123-description
   # OR
   git checkout feat/PROJ-123-existing-branch
   ```

3. **Handle pending changes before starting new work**
   | Situation | Action |
   |-----------|--------|
   | Uncommitted changes from previous session | Commit, stash, or discard |
   | Untracked files | Add to .gitignore or commit |
   | Stashed changes | Pop and resolve, or drop |
   | On main branch | Checkout or create feature branch |

4. **Sync with remote**
   ```bash
   git pull --rebase origin <branch>
   ```

### During Session

1. **Atomic commits**: One logical change = One commit
2. **Commit early, commit often**: Don't accumulate large changesets
3. **Clear commit messages**: Write at the time of commit, not later

### Session End

1. **Always commit or explicitly defer**
   - Complete work -> Commit with proper message
   - Incomplete work -> WIP commit or stash with description

2. **Push to remote** (if working with others)
   ```bash
   git push origin <branch>
   ```

3. **Leave clean state for next agent**

## Commit Timing Policy

### When to Commit

| Trigger | Action |
|---------|--------|
| Single task completed | Commit immediately |
| Multiple related changes | Group into one logical commit |
| Before switching context | Commit or stash |
| Before ending session | Must commit or explicitly defer |
| After fixing review feedback | Separate commit per feedback item |

### When NOT to Commit

- In the middle of a refactoring
- With failing tests (unless WIP)
- With mixed unrelated changes

## Multi-Agent Collaboration Strategies

### Strategy A: Worktree per Agent (Recommended for Concurrent Work)

When multiple agents work **simultaneously** on **different tasks**:

```
/project/              <- Agent 1: feat/PROJ-100-task-a
/project-feat-b/       <- Agent 2: feat/PROJ-101-task-b (worktree)
/project-hotfix/       <- Agent 3: hotfix/PROJ-102 (worktree)
```

**Pros**: True parallel work, no interference
**Cons**: Requires worktree setup/cleanup

### Strategy B: Sequential Branch Work

When agents work **sequentially** on **same or different tasks**:

```
Agent 1: checkout feat/task-a -> work -> commit -> push -> done
Agent 2: checkout feat/task-b -> work -> commit -> push -> done
```

**Pros**: Simple, no worktree management
**Cons**: Cannot work simultaneously

### Strategy C: Same Branch Handoff

When agents work **sequentially** on the **same task**:

```
Agent 1: feat/task-a -> work -> commit -> push
Agent 2: pull feat/task-a -> continue -> commit -> push
```

**Pros**: Continuous work on same feature
**Cons**: Must sync before handoff

### Strategy D: WIP Commits

Use WIP (Work In Progress) commits for incomplete work.

```bash
# End of session (incomplete)
git commit -m "WIP: implement validation logic"

# Next session start
git commit --amend -m "feat: add input validation"
# OR
git reset --soft HEAD~1  # Continue working
```

**Pros**: Preserves work without polluting history
**Cons**: Requires cleanup

## Commit Message Generation

### When to Generate

| Timing | Recommendation |
|--------|----------------|
| Before commit | [BEST] Message reflects actual changes |
| After all changes | [OK] Review diff, then write message |
| End of session | [AVOID] Changes may be forgotten |

### Best Practice

1. Review `git diff --staged` before writing message
2. Write message immediately after staging
3. Don't batch unrelated changes

## Handling Conflicts

### Policy: Resolve When They Occur

Conflicts are **expected** when multiple agents work in parallel. Don't try to prevent all conflicts - just handle them when they happen.

### When Conflicts Occur

1. **During merge to main**
   ```bash
   git checkout main
   git pull origin main
   git merge feat/PROJ-123-task-a
   # CONFLICT! Resolve here
   ```

2. **During rebase**
   ```bash
   git checkout feat/PROJ-123-task-a
   git rebase main
   # CONFLICT! Resolve here
   ```

### Resolution Steps

```bash
# 1. See what's conflicting
git status

# 2. Open conflicting files, look for conflict markers
<<<<<<< HEAD
current code
=======
incoming code
>>>>>>> feat/branch

# 3. Resolve manually (choose one, combine, or rewrite)

# 4. Mark as resolved
git add <resolved-files>

# 5. Continue
git rebase --continue   # if rebasing
# OR
git commit              # if merging
```

### Best Practices

| Practice | Reason |
|----------|--------|
| Rebase feature branch on main before MR | Reduces conflicts at merge time |
| Keep branches short-lived | Less divergence = fewer conflicts |
| Small, focused commits | Easier to understand during conflict |
| Don't panic | Conflicts are normal |

## Checklist

### Session Start
- [ ] `git status` - check for pending changes
- [ ] `git branch` - verify on feature branch (NOT main)
- [ ] If on main, checkout/create feature branch
- [ ] Handle any uncommitted work
- [ ] `git pull --rebase` - sync with remote

### During Work
- [ ] Working on feature branch (not main)
- [ ] Atomic commits (one logical change per commit)
- [ ] Clear commit messages

### Session End
- [ ] All changes committed or explicitly stashed
- [ ] Commit messages are clear and accurate
- [ ] `git push -u origin <branch>` - sync to remote
- [ ] No untracked files left behind

### Before Merge to Main
- [ ] Rebase on latest main: `git rebase main`
- [ ] All tests pass
- [ ] Create MR/PR for review
- [ ] Resolve any conflicts

---

**See also**:
- [branch-naming.md](branch-naming.md) - Branch naming conventions
- [merge-strategies.md](merge-strategies.md) - Merge and rebase strategies
