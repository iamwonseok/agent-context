# agent dev

## NAME

agent dev - Developer commands for task management and code workflow

## SYNOPSIS

    agent dev <COMMAND> [OPTIONS]
    agent dev start <task-id> [--detached] [--try=<name>] [--from=<branch>]
    agent dev list
    agent dev switch <branch|worktree>
    agent dev status
    agent dev check
    agent dev verify
    agent dev retro
    agent dev sync [--continue|--abort]
    agent dev submit [--sync] [--draft] [--force]
    agent dev cleanup <task-id>

## DESCRIPTION

The `agent dev` commands help developers manage their daily workflow, from starting a new task to creating a merge request.

## COMMANDS

### agent dev start

Start working on a task by creating a new branch and context.

    agent dev start <task-id> [OPTIONS]

**Options:**

    --detached
        Use worktree mode for background work.
        Creates .worktrees/{task-id}/ instead of branch.

    --try=<name>
        Name the try (for A/B testing in detached mode).
        Creates .worktrees/{task-id}-{name}/

    --from=<branch>
        Branch to start from (default: main).

**Examples:**

    # Start feature task (interactive mode)
    agent dev start TASK-123

    # Start in detached mode for background work
    agent dev start TASK-123 --detached

    # Try multiple approaches
    agent dev start TASK-123 --detached --try="approach-a"
    agent dev start TASK-123 --detached --try="approach-b"

### agent dev list

List active tasks (branches and worktrees).

    agent dev list

Shows:
- Active task branches (feat/*, fix/*, hotfix/*)
- Active worktrees in .worktrees/
- Current branch marker

### agent dev switch

Switch to another branch or worktree.

    agent dev switch <target>

**Arguments:**

    <target>
        Branch name or worktree name to switch to.

### agent dev status

Show current work status.

    agent dev status

Displays:
- Current branch and mode (interactive/detached)
- Active contexts
- Git status summary

### agent dev check

Run quality checks (lint, test, intent alignment).

    agent dev check

Checks performed:
1. **Lint** - Code style validation
2. **Tests** - Run test suite
3. **Intent** - Check alignment with plan files

Note: This command produces warnings only and does not block commits.

### agent dev verify

Generate a verification report for requirements tracking.

    agent dev verify

Creates `.context/{task-id}/verification.md` with:
- Requirements checklist
- Quality gate status
- Test coverage summary

### agent dev retro

Create or edit a retrospective document.

    agent dev retro

Creates `.context/{task-id}/retrospective.md` with:
- Original intent
- What changed (commit history)
- Surprises and learnings
- Next steps

### agent dev sync

Sync with base branch using rebase.

    agent dev sync [OPTIONS]

**Options:**

    --continue
        Continue after resolving conflicts.

    --abort
        Abort rebase and restore previous state.

    --base=<branch>
        Base branch to sync with (default: main).

**Conflict Resolution:**

    # If conflicts occur:
    1. Fix conflicts in the files
    2. git add <resolved-files>
    3. agent dev sync --continue

    # To abort:
    agent dev sync --abort

### agent dev submit

Create merge request and cleanup context.

    agent dev submit [OPTIONS]

**Options:**

    --sync
        Sync with base branch before submit.

    --draft
        Create as draft MR.

    --force
        Skip pre-submit checks (not recommended).

**Process:**

1. Run pre-submit checks (verification, retrospective)
2. Push branch to remote
3. Create merge request via pm CLI
4. Archive context

### agent dev cleanup

Clean up a completed task.

    agent dev cleanup <task-id>

Removes:
- Task branch (if not current)
- Associated worktrees
- Context directory

## WORKFLOW

Typical development workflow:

    # 1. Start task
    agent dev start TASK-123

    # 2. Make changes
    vim src/feature.c

    # 3. Check quality
    agent dev check

    # 4. Commit changes
    git commit -m "feat: add feature"

    # 5. Generate verification
    agent dev verify

    # 6. Write retrospective
    agent dev retro

    # 7. Submit
    agent dev submit

## GIT MODES

### Interactive Mode (Default)

- Works in current directory
- Creates feature branch
- Context in `.context/{task-id}/`

### Detached Mode (--detached)

- Creates separate worktree
- For background/parallel work
- Context in `.worktrees/{task-id}/.context/`

## SEE ALSO

[agent](agent.md), [agent-mgr](agent-mgr.md), [agent-init](agent-init.md)
