# agnt-c

## NAME

agnt-c - Agent Context Workflow CLI for AI-assisted development

## SYNOPSIS

    agnt-c [COMMAND] [OPTIONS]
    agnt-c dev <ACTION> [OPTIONS]
    agnt-c mgr <ACTION> [OPTIONS]

## DESCRIPTION

`agnt-c` is a command-line tool for managing development workflows in AI-assisted projects. It provides commands for both developers and managers to streamline the software development lifecycle.

The tool integrates with Git for version control, JIRA for issue tracking, and GitLab for merge requests and code review.

## COMMANDS

### Developer Commands (agnt-c dev)

| Command | Description |
|---------|-------------|
| start   | Start working on a task (create branch) |
| list    | List active tasks |
| switch  | Switch to another branch/worktree |
| status  | Show current work status |
| check   | Run quality checks (lint, test, intent) |
| verify  | Generate verification report |
| retro   | Create/edit retrospective document |
| sync    | Sync with base branch (rebase) |
| submit  | Create MR and cleanup |
| cleanup | Clean up completed task |

See [agent-dev](agent-dev.md) for detailed documentation.

### Manager Commands (agnt-c mgr)

| Command | Description |
|---------|-------------|
| pending | List pending MRs for review |
| review  | Review MR details |
| approve | Approve MR |
| status  | Check initiative/epic/task status |

See [agent-mgr](agent-mgr.md) for detailed documentation.

### Common Commands

| Command | Description |
|---------|-------------|
| help    | Show help message |
| version | Show version |
| config  | Show/manage configuration |
| init    | Initialize project for agent workflow |
| setup   | Install templates to project (idempotent) |

See [agent-init](agent-init.md) for initialization details.

## OPTIONS

    -h, --help
        Show help message and exit.

    -v, --version
        Show version and exit.

## CONFIGURATION

The agent CLI uses the following configuration files:

| File | Purpose |
|------|---------|
| `.project.yaml` | Project settings (JIRA, GitLab) |
| `.secrets/` | API tokens (gitignored) |
| `.context/` | Work context (gitignored) |

## ENVIRONMENT VARIABLES

| Variable | Description |
|----------|-------------|
| `AGENT_ROLE` | Override role detection (dev/mgr) |
| `AGENT_MODE` | Set execution mode (agent/human) |
| `GITLAB_TOKEN` | GitLab API token |
| `JIRA_TOKEN` | JIRA API token |

## EXAMPLES

Start a new feature:

    $ agnt-c dev start TASK-123

Run quality checks:

    $ agnt-c dev check

Create merge request:

    $ agnt-c dev submit

Review pending MRs (manager):

    $ agnt-c mgr pending

## FILES

    ~/.agent/
        Global agent-context installation

    .agent/
        Project-local agent-context (overrides global)

    .context/{task-id}/
        Work context for each task

    .worktrees/{task-id}/
        Detached worktrees (when using --detached)

## SEE ALSO

[agent-dev](agent-dev.md), [agent-mgr](agent-mgr.md), [agent-init](agent-init.md)
