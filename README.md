# agent-context

A comprehensive workflow and CI/CD template for agent-driven development.

**Design Philosophy**: See [ARCHITECTURE.md](ARCHITECTURE.md) for our approach to simplicity, user autonomy, and avoiding over-engineering.

## Why This Project?

**Problem**:
- New project -> Setup workflow, pipeline from scratch
- Repetitive work, inconsistent structure
- No standard for AI agent collaboration

**Solution**:
| Component | Purpose | Location |
|-----------|---------|----------|
| Workflow | Development process definition | `skills/`, `workflows/`, `.cursorrules` |
| Pipeline | CI/CD automation | `tools/lint/`, `templates/configs/` |
| Agent CLI | AI agent's interface to JIRA/GitLab | `tools/agent/`, `tools/pm/` |

**Goal**: AI agent performs all operations via CLI - no browser, no context switching.

## Quick Start

### Option 1: Global Installation (Recommended)

Install once, use in all projects:

```bash
# 1. Clone to ~/.agent
git clone https://github.com/your-org/agent-context.git ~/.agent

# 2. Run global setup
cd ~/.agent
./setup.sh --global

# 3. Add to shell profile (~/.bashrc or ~/.zshrc)
export AGENT_CONTEXT_PATH="$HOME/.agent"
export PATH="$HOME/.agent/tools/agent/bin:$HOME/.agent/tools/pm/bin:$HOME/.agent/tools/lint/bin:$PATH"

# 4. Reload shell
source ~/.bashrc  # or ~/.zshrc
```

Then in any project:
```bash
cd your-project
agnt-c setup              # Quick setup: templates + .agent symlink
agnt-c setup --full       # Full setup: includes interactive JIRA/GitLab config
agnt-c setup --project    # Configure JIRA/GitLab only
agnt-c setup --force      # Force overwrite existing files
```

### Option 2: Project-Local Installation

Install per-project for version pinning:

```bash
# 1. Clone to project
cd your-project
git clone https://github.com/your-org/agent-context.git .agent

# 2. Activate for this session
source .agent/activate.sh

# 3. Install templates
agnt-c setup
```

### What Gets Installed

`agnt-c setup` creates these files in your project:

| File | Description |
|------|-------------|
| `.agent/` | Symlink to agent-context (skills, workflows) |
| `.cursorrules` | Agent behavior rules |
| `configs/` | Tool configurations (clang-format, flake8, etc.) |
| `policies/` | Domain-specific knowledge templates |

For JIRA/GitLab configuration, use one of:
```bash
agnt-c setup --full     # Full interactive setup
agnt-c setup --project  # Configure JIRA/GitLab only
./setup.sh              # Alternative: direct script
```

This additionally creates:
- `.project.yaml` - JIRA/GitLab settings
- `.secrets/` - API tokens (gitignored, or use `~/.secrets/` global)

## Project Structure

### This Repository (agent-context)

```
agent-context/                  # Repository root = deployable unit
├── ARCHITECTURE.md             # Design philosophy
├── LICENSE                     # MIT License
├── docs/                       # Documentation hub
│   ├── installation.md        # Installation guide
│   ├── cli/                   # CLI usage docs
│   ├── style/                 # Coding conventions
│   ├── rfcs/                  # RFCs and proposals
│   └── guides/                # User guides
├── skills/                     # Atomic skills (building blocks)
│   ├── analyze/               # Input: Parse requirements, inspect code
│   ├── planning/              # Strategy: Design, breakdown, estimate
│   ├── execute/               # Action: Write code, refactor, fix
│   ├── validate/              # Check: Test, lint, review
│   └── integrate/             # Output: Commit, MR, notify
├── workflows/                  # Workflow definitions
│   ├── developer/             # feature, bug-fix, hotfix, refactor
│   └── manager/               # initiative, epic, approval
├── tools/                      # CLI tools
│   ├── agent/                 # Main CLI (agent dev start, etc.)
│   ├── pm/                    # JIRA/GitLab API wrapper
│   └── lint/                  # Code quality checks
├── templates/                  # User project templates
│   ├── configs/               # Tool configurations
│   ├── policies/              # Domain policy templates
│   ├── planning/              # Plan templates
│   └── secrets-examples/      # API token examples
├── tests/                      # All tests
│   ├── unit/                  # Unit tests
│   │   ├── skills/
│   │   ├── tools/
│   │   └── lint-rules/
│   ├── e2e/
│   ├── scenario/
│   └── smoke/
└── setup.sh                    # Installation script
```

### User Project (After Setup)

```
your-project/
├── .agent/                    # Local install (optional)
├── .cursorrules               # Agent behavior rules
├── .project.yaml              # JIRA/GitLab config (from setup.sh)
├── .secrets/                  # API tokens (gitignored, from setup.sh)
├── configs/                   # Tool configurations
├── policies/                  # Domain-specific knowledge
├── .context/                  # Work context (gitignored)
└── src/                       # Your source code
```

### Path Resolution

Agent context is resolved in this order:
1. `.agent/` (project local)
2. `.project.yaml` → `agent_context` setting
3. `$AGENT_CONTEXT_PATH` environment variable
4. `~/.agent` (global default)

## Core Concept

Agent-driven development = File-based development

```
AI Agent reads files -> Follows defined workflow -> Consistent output
```

| File | Agent Uses For |
|------|----------------|
| `.cursorrules` | Behavior rules |
| `skills/*.md` | Task execution |
| `workflows/*.md` | Process flow |
| `configs/*` | Code style |

## Skills & Workflows

### Skills (`skills/`)

Independent, reusable building blocks organized by purpose:

| Category | Skills | Purpose |
|----------|--------|---------|
| analyze | parse-requirement, inspect-codebase, inspect-logs | Input processing |
| planning | design-solution, breakdown-work, estimate-effort | Strategy |
| execute | write-code, refactor-code, fix-defect | Implementation |
| validate | run-tests, check-style, review-code | Quality checks |
| integrate | commit-changes, create-merge-request | Output |

See [skills/README.md](skills/README.md) for details.

### Workflows (`workflows/`)

Combine skills for specific scenarios:

| Workflow | Use Case |
|----------|----------|
| [feature](workflows/developer/feature.md) | New feature development |
| [bug-fix](workflows/developer/bug-fix.md) | Standard bug fix |
| [hotfix](workflows/developer/hotfix.md) | Emergency fix |
| [refactor](workflows/developer/refactor.md) | Code refactoring |

See [workflows/README.md](workflows/README.md) for details.

## CLI Tools

### agnt-c (Main CLI)

```bash
# Start a task
agnt-c dev start TASK-123

# Check quality
agnt-c dev check

# Commit changes
agnt-c dev commit "feat: add feature"

# Submit for review
agnt-c dev submit

# Manager commands
agnt-c mgr status EPIC-1
agnt-c mgr approve MR-456
```

### pm (Project Management)

```bash
# Create a new task
pm create "Add UART driver"

# List tasks
pm list

# Start a task
pm start PROJ-123
```

### lint (Code Quality)

```bash
# Check C files
lint c .

# Check Python files
lint python src/ -R

# Output JUnit XML
lint c . --junit -o results.xml
```

Supported: C/C++, Python, Bash, Make, YAML, Dockerfile

See [tools/lint/README.md](tools/lint/README.md) for details.

## Documentation

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Design philosophy and decisions |
| [docs/installation.md](docs/installation.md) | Installation guide |
| [docs/cli/](docs/cli/) | CLI command reference |
| [docs/style/](docs/style/) | Coding conventions |
| [docs/rfcs/](docs/rfcs/) | RFCs and proposals |

## Development

For contributing to agent-context itself:

```bash
# Clone the repository
git clone https://github.com/your-org/agent-context.git
cd agent-context

# Make changes to skills/, workflows/, tools/
# Test using Docker or global installation

# Option 1: Install globally for testing
./setup.sh --global

# Option 2: Use Docker (recommended for isolated testing)
# docker run -v $(pwd):/workspace ...
```

See [docs/rfcs/](docs/rfcs/) for implementation plans.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AGENT_CONTEXT_PATH` | `~/.agent` | Agent context location |
| `OLLAMA_HOST` | `http://localhost:11434` | Ollama API URL |
| `OLLAMA_MODEL` | `qwen2.5-coder:14b` | Model for AI tools |

## License

MIT License - See [LICENSE](LICENSE) for details.

Copyright (c) 2026 FADU Inc. and contributors
