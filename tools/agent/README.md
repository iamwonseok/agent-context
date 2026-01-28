# Agent Workflow CLI (agnt-c)

> **User manual**: [docs/cli/agent.md](../../docs/cli/agent.md)

Developer and Manager workflow automation for AI-assisted development.

## Installation

Add to PATH:

```bash
export PATH="/path/to/project/.agent/tools/agent/bin:$PATH"
```

Or use directly:

```bash
.agent/tools/agent/bin/agnt-c --help
```

## Quick Start

```bash
# Activate (for project-local installation)
source .agent/activate.sh

# Install templates to project
agnt-c setup

# Start a task (Interactive Mode - default)
agnt-c dev start TASK-123

# Check status
agnt-c status

# Submit work
agnt-c dev submit
```

## Modes

### Interactive Mode (Default)

Works in the current directory using Git branches.

```bash
agnt-c dev start TASK-123
# Creates: feat/TASK-123 branch
# Creates: .context/TASK-123/ directory
```

Best for:
- Single-task workflow
- Watching agent work
- Quick iterations

### Detached Mode

Works in a separate worktree directory.

```bash
agnt-c dev start TASK-123 --detached
# Creates: .worktrees/TASK-123/ directory
# Creates: .worktrees/TASK-123/.context/
```

Best for:
- Background work
- Parallel experiments (A/B testing)
- Not interrupting current work

## Commands

### Developer Commands

| Command | Description |
|---------|-------------|
| `agnt-c dev start <task>` | Start a task |
| `agnt-c dev list` | List active tasks |
| `agnt-c dev switch <target>` | Switch branch/worktree |
| `agnt-c dev status` | Show current status |
| `agnt-c dev sync` | Sync with base branch |
| `agnt-c dev submit` | Create MR |
| `agnt-c dev cleanup <task>` | Clean up completed task |

### Manager Commands

| Command | Description |
|---------|-------------|
| `agnt-c mgr pending` | List pending MRs |
| `agnt-c mgr review <mr>` | Review MR |
| `agnt-c mgr approve <mr>` | Approve MR |

### Common Commands

| Command | Description |
|---------|-------------|
| `agnt-c help` | Show help |
| `agnt-c status` | Show status |
| `agnt-c config show` | Show configuration |
| `agnt-c init` | Initialize project |
| `agnt-c setup` | Quick setup: templates + .agent symlink |
| `agnt-c setup --full` | Full setup: includes interactive JIRA/GitLab config |
| `agnt-c setup --project` | Configure JIRA/GitLab settings only |
| `agnt-c setup --force` | Force overwrite existing files |

## Context Management

The agent tracks work context in `.context/` directories:

```
.context/
└── TASK-123/
    ├── try.yaml        # Main context file
    ├── attempts/       # Individual attempt records
    │   ├── attempt-001.yaml
    │   └── attempt-002.yaml
    └── summary.yaml    # Generated summary
```

### try.yaml

Tracks the overall work session:
- Goal and expected outcome
- Status and timestamps
- Learnings

### attempt-NNN.yaml

Records each attempt:
- Approach taken
- Result
- Files changed
- Commit SHA

### summary.yaml

Generated when submitting:
- Summary of all attempts
- Key decisions
- MR description content

## Integration

### pm CLI

The agent CLI uses `pm` CLI internally for:
- JIRA integration
- GitLab MR creation
- Issue tracking

Configure pm CLI first:

```bash
pm config init
# Edit .project.yaml with your settings
```

### Git Strategy

Default: Fast-forward merge with rebase

```bash
# Sync before submit
agnt-c dev sync
agnt-c dev submit

# Or combined
agnt-c dev submit --sync
```

## Configuration

### Environment Variables

| Variable | Description |
|----------|-------------|
| `AGENT_ROLE` | Force role: `dev` or `mgr` |

### .gitignore

Add these to `.gitignore`:

```
.context/
.worktrees/
```

`agnt-c init` adds these automatically.

## Examples

### Feature Development

```bash
# Start feature
agnt-c dev start TASK-123

# ... make changes ...

# Sync and submit
agnt-c dev sync
agnt-c dev submit
```

### Bug Fix

```bash
agnt-c dev start BUG-456
# Creates: fix/BUG-456 branch
```

### Hotfix

```bash
agnt-c dev start HOTFIX-789 --from=main
# Creates: hotfix/HOTFIX-789 branch from main
```

### Parallel Experiments

```bash
# Try approach A
agnt-c dev start TASK-123 --detached --try="approach-a"

# Try approach B (in parallel)
agnt-c dev start TASK-123 --detached --try="approach-b"

# List all
agnt-c dev list

# Submit the successful one
cd .worktrees/TASK-123-approach-a
agnt-c dev submit
```

## File Structure

```
.agent/tools/agent/
├── bin/
│   └── agnt-c          # Main entry point
├── lib/
│   ├── parser.sh       # Command parsing
│   ├── roles.sh        # Role management
│   ├── git-strategy.sh # Git operations
│   ├── branch.sh       # Branch/worktree commands
│   ├── context.sh      # Context management
│   ├── checks.sh       # Quality checks
│   ├── markdown.sh     # Markdown generation
│   ├── upload.sh       # JIRA/GitLab upload
│   ├── permissions.sh  # Permission model
│   ├── executor.sh     # Execution model
│   ├── init.sh         # Project initialization
│   └── setup.sh        # Template installation
├── templates/
│   ├── try.yaml        # Context template
│   └── attempt.yaml    # Attempt template
└── README.md           # This file
```
