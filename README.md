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
| CLI Tools | JIRA/Confluence interface | `tools/pm/` |

**Goal**: AI agent performs all operations via CLI (`git`, `gh`, `glab`, `pm`) - no browser, no context switching.

## Quick Start

```bash
# 1. Clone repository
git clone https://github.com/your-org/agent-context.git
cd agent-context

# 2. Install dependencies
pip install pre-commit
brew install gh glab jq yq

# 3. Configure tools
gh auth login      # GitHub authentication
glab auth login    # GitLab authentication

# 4. Setup pm CLI (JIRA/Confluence)
export PATH="$PATH:$(pwd)/tools/pm/bin"
pm config init     # Initialize project configuration

# 5. Setup pre-commit hooks
pre-commit install

# 6. Start working
git checkout -b feat/TASK-123
# ... make changes ...
pre-commit run --all-files
git commit -m "feat: add new feature"
git push origin feat/TASK-123
gh pr create --title "TASK-123: description"
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
│   └── pm/              # JIRA/Confluence API
└── tests/               # Tests
    ├── skills/          # Skill verification tests
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

### Git Operations

Use standard `git` commands for version control:

```bash
git checkout -b feat/TASK-123   # Create feature branch
git add .                       # Stage changes
git commit -m "feat: message"   # Commit changes
git push origin feat/TASK-123   # Push to remote
```

### GitHub CLI (gh)

```bash
gh auth login                   # Authenticate
gh pr create                    # Create pull request
gh pr list                      # List pull requests
gh pr view 123                  # View PR details
gh pr merge 123                 # Merge PR
```

### GitLab CLI (glab)

```bash
glab auth login                 # Authenticate
glab mr create                  # Create merge request
glab mr list                    # List merge requests
glab mr view 123                # View MR details
glab mr merge 123               # Merge MR
```

### pm (JIRA/Confluence)

```bash
pm config init                  # Initialize configuration
pm jira issue list              # List JIRA issues
pm jira issue view TASK-123     # View issue details
pm jira issue create "Title"    # Create new issue
pm jira issue transition        # Change issue status
pm confluence page list         # List Confluence pages
```

## Required Tools

| Tool | Purpose | Install |
|------|---------|---------|
| `git` | Version control | Pre-installed on most systems |
| `gh` | GitHub CLI | `brew install gh` |
| `glab` | GitLab CLI | `brew install glab` |
| `pre-commit` | Linting/formatting | `pip install pre-commit` |
| `jq` | JSON processor | `brew install jq` |
| `yq` | YAML processor | `brew install yq` |

## Documentation

| Document | Description |
|----------|-------------|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Design philosophy |
| [docs/convention/](docs/convention/) | Coding conventions |
| [skills/](skills/) | Generic skill templates |
| [workflows/](workflows/) | Context-aware workflows |

## License

MIT License - See [LICENSE](LICENSE) for details.
