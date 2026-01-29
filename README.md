# agent-context

A workflow template for agent-driven development.

**Design Philosophy**: See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for Thin Skill / Thick Workflow pattern.

## Why This Project?

**Problem**:
- New project -> Setup workflow from scratch
- Repetitive work, inconsistent structure
- No standard for AI agent collaboration

**Solution**:
| Component | Purpose | Location |
|-----------|---------|----------|
| Skills | Generic templates | `skills/` |
| Workflows | Context-aware orchestration | `workflows/` |
| CLI Tools | AI agent's interface | `tools/agent/`, `tools/pm/` |

**Goal**: AI agent performs all operations via CLI (`agnt-c`, `pm`, `gh`, `glab`) - no browser, no context switching.

## Quick Start

```bash
# Clone repository
git clone https://github.com/your-org/agent-context.git
cd agent-context

# Add to PATH (or create alias)
export PATH="$PATH:$(pwd)/tools/agent/bin:$(pwd)/tools/pm/bin"

# Check dependencies
agnt-c bootstrap --check

# Start working
agnt-c dev start TASK-123
```

## Project Structure

```
agent-context/
├── docs/                # Documentation
│   ├── ARCHITECTURE.md  # Design philosophy
│   └── convention/      # Coding conventions
├── skills/              # Generic skill templates (Thin)
│   ├── analyze.md       # Understand situation
│   ├── design.md        # Design approach
│   ├── implement.md     # Perform work
│   ├── test.md          # Verify quality
│   └── review.md        # Check results
├── workflows/           # Context-aware workflows (Thick)
│   ├── solo/            # Individual developer
│   │   ├── feature.md
│   │   ├── bugfix.md
│   │   └── hotfix.md
│   ├── team/            # Squad coordination
│   │   ├── sprint.md
│   │   └── release.md
│   └── project/         # Organization level
│       ├── quarter.md
│       └── roadmap.md
├── tools/               # CLI tools
│   ├── agent/           # Main CLI (agnt-c)
│   ├── pm/              # JIRA/Confluence API
│   └── worktree/        # Git worktree helpers
└── tests/               # Tests
    └── workflows/       # Workflow integration tests
```

## Core Concept

### Engineering Coordinate System

```
Y-Axis (Layer)              X-Axis (Timeline)
---------------------------------------------------------
PROJECT (Org)               Plan --> Execute --> Review
    |
TEAM (Squad)                Plan --> Execute --> Review
    |
SOLO (Dev)                  Plan --> Execute --> Review
```

### Thin Skill / Thick Workflow

| Concept | Role | Analogy |
|---------|------|---------|
| **Skill** | Generic template | Interface, Abstract class |
| **Workflow** | Context injection | DI Container, Implementation |

**Skills (Thin)**: 5 generic templates
- Parameter-driven ("fill in the blanks")
- Focus on HOW: methods, checklists
- No context: no ticket IDs, project names

**Workflows (Thick)**: Context-aware orchestration
- Map current context to skill inputs
- Focus on WHAT: what information goes where
- Context-aware: tickets, tools, deadlines

## CLI Tools

### agnt-c (Workflow CLI)

```bash
agnt-c dev start TASK-123    # Start a task (create branch)
agnt-c dev status            # Show current work status
agnt-c dev check             # Run quality checks
agnt-c dev submit            # Create MR and cleanup
agnt-c bootstrap --check     # Check tool dependencies
```

### pm (JIRA/Confluence)

```bash
pm jira issue list           # List JIRA issues
pm jira issue view TASK-123  # View issue details
pm jira issue create "Title" # Create new issue
pm confluence page list      # List Confluence pages
```

### External CLIs

For GitLab/GitHub operations, use official CLIs:

```bash
# GitLab (glab)
glab mr list                 # List merge requests
glab mr create               # Create MR

# GitHub (gh)
gh pr list                   # List pull requests
gh pr create                 # Create PR
```

## Required Tools

| Tool | Purpose | Install |
|------|---------|---------|
| `pre-commit` | Linting/formatting | `pip install pre-commit` |
| `gh` | GitHub CLI | `brew install gh` |
| `glab` | GitLab CLI | `brew install glab` |

## Documentation

| Document | Description |
|----------|-------------|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Design philosophy |
| [docs/convention/](docs/convention/) | Coding conventions |
| [tools/pm/README.md](tools/pm/README.md) | PM CLI usage |

## License

MIT License - See [LICENSE](LICENSE) for details.
