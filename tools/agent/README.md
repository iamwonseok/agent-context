# Agent Workflow CLI

Developer and Manager workflow automation for AI-assisted development.

## Installation

Add to PATH:

```bash
export PATH="$PATH:/path/to/project/.agent/tools/agent/bin"
```

Or use directly:

```bash
.agent/tools/agent/bin/agent --help
```

## Quick Start

```bash
# Activate (for project-local installation)
source .agent/activate.sh

# Install templates to project
agent setup

# Start a task (Interactive Mode - default)
agent dev start TASK-123

# Check status
agent status

# Submit work
agent dev submit
```

## Modes

### Interactive Mode (Default)

Works in the current directory using Git branches.

```bash
agent dev start TASK-123
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
agent dev start TASK-123 --detached
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
| `agent dev start <task>` | Start a task |
| `agent dev list` | List active tasks |
| `agent dev switch <target>` | Switch branch/worktree |
| `agent dev status` | Show current status |
| `agent dev sync` | Sync with base branch |
| `agent dev submit` | Create MR |
| `agent dev cleanup <task>` | Clean up completed task |

### Manager Commands

| Command | Description |
|---------|-------------|
| `agent mgr pending` | List pending MRs |
| `agent mgr review <mr>` | Review MR |
| `agent mgr approve <mr>` | Approve MR |

### Common Commands

| Command | Description |
|---------|-------------|
| `agent help` | Show help |
| `agent status` | Show status |
| `agent config show` | Show configuration |
| `agent init` | Initialize project |
| `agent setup` | Install templates (idempotent) |
| `agent setup --force` | Force overwrite templates |

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
agent dev sync
agent dev submit

# Or combined
agent dev submit --sync
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

`agent init` adds these automatically.

## Examples

### Feature Development

```bash
# Start feature
agent dev start TASK-123

# ... make changes ...

# Sync and submit
agent dev sync
agent dev submit
```

### Bug Fix

```bash
agent dev start BUG-456
# Creates: fix/BUG-456 branch
```

### Hotfix

```bash
agent dev start HOTFIX-789 --from=main
# Creates: hotfix/HOTFIX-789 branch from main
```

### Parallel Experiments

```bash
# Try approach A
agent dev start TASK-123 --detached --try="approach-a"

# Try approach B (in parallel)
agent dev start TASK-123 --detached --try="approach-b"

# List all
agent dev list

# Submit the successful one
cd .worktrees/TASK-123-approach-a
agent dev submit
```

## File Structure

```
.agent/tools/agent/
├── bin/
│   └── agent           # Main entry point
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
