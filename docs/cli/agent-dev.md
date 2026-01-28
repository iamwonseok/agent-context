# agnt-c dev

## NAME

agnt-c dev - Developer commands for task management and code workflow

## SYNOPSIS

    agnt-c dev <COMMAND> [OPTIONS]
    agnt-c dev start <task-id> [--detached] [--try=<name>] [--from=<branch>]
    agnt-c dev list
    agnt-c dev switch <branch|worktree>
    agnt-c dev status
    agnt-c dev check
    agnt-c dev verify
    agnt-c dev retro
    agnt-c dev sync [--continue|--abort]
    agnt-c dev submit [--sync] [--draft] [--force]
    agnt-c dev cleanup <task-id>

## DESCRIPTION

The `agnt-c dev` commands help developers manage their daily workflow, from starting a new task to creating a merge request.

## COMMANDS

### agnt-c dev start

Start working on a task by creating a new branch and context.

    agnt-c dev start <task-id> [OPTIONS]

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
    agnt-c dev start TASK-123

    # Start in detached mode for background work
    agnt-c dev start TASK-123 --detached

    # Try multiple approaches
    agnt-c dev start TASK-123 --detached --try="approach-a"
    agnt-c dev start TASK-123 --detached --try="approach-b"

### agnt-c dev list

List active tasks (branches and worktrees).

    agnt-c dev list

Shows:
- Active task branches (feat/*, fix/*, hotfix/*)
- Active worktrees in .worktrees/
- Current branch marker

### agnt-c dev switch

Switch to another branch or worktree.

    agnt-c dev switch <target>

**Arguments:**

    <target>
        Branch name or worktree name to switch to.

### agnt-c dev status

Show current work status.

    agnt-c dev status

Displays:
- Current branch and mode (interactive/detached)
- Active contexts
- Git status summary

### agnt-c dev check

Run quality checks (lint, test, intent alignment).

    agnt-c dev check

Checks performed:
1. **Lint** - Code style validation
2. **Tests** - Run test suite
3. **Intent** - Check alignment with plan files

Note: This command produces warnings only and does not block commits.

### agnt-c dev verify

Generate a verification report for requirements tracking.

    agnt-c dev verify

Creates `.context/{task-id}/verification.md` with:
- Requirements checklist
- Quality gate status
- Test coverage summary

### agnt-c dev retro

Create or edit a retrospective document.

    agnt-c dev retro

Creates `.context/{task-id}/retrospective.md` with:
- Original intent
- What changed (commit history)
- Surprises and learnings
- Next steps

### agnt-c dev sync

Sync with base branch using rebase.

    agnt-c dev sync [OPTIONS]

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
    3. agnt-c dev sync --continue

    # To abort:
    agnt-c dev sync --abort

### agnt-c dev submit

Create merge request and cleanup context.

    agnt-c dev submit [OPTIONS]

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

### agnt-c dev cleanup

Clean up a completed task.

    agnt-c dev cleanup <task-id>

Removes:
- Task branch (if not current)
- Associated worktrees
- Context directory

## WORKFLOW

Typical development workflow:

    # 1. Start task
    agnt-c dev start TASK-123

    # 2. Make changes
    vim src/feature.c

    # 3. Check quality
    agnt-c dev check

    # 4. Commit changes
    git commit -m "feat: add feature"

    # 5. Generate verification
    agnt-c dev verify

    # 6. Write retrospective
    agnt-c dev retro

    # 7. Submit
    agnt-c dev submit

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
