# Installation Guide

## Supported Environments

| OS | Version | Notes |
|----|---------|-------|
| macOS | 15+ (Sequoia) | Bash 3.2 (default) supported |
| Ubuntu | 22.04+ | |
| Windows | 10/11 | WSL or Git Bash |

## Prerequisites

- **git** - Version control
- **curl** - HTTP client (for one-liner installation)

Most systems have these pre-installed. If not:

```bash
# macOS (with Homebrew)
brew install git curl

# Ubuntu/Debian
sudo apt update && sudo apt install -y git curl

# Windows (Git Bash includes both)
# Download from: https://git-scm.com/download/win
```

## Lint Tools (Optional)

For enhanced code quality checking, install external lint tools.
Without these, basic regex-based checking still works.

### C/C++

```bash
# macOS
brew install llvm
# Add to PATH: export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

# Ubuntu/Debian
sudo apt install clang-format clang-tidy
```

### Python

```bash
pip install flake8 black isort mypy
```

### Bash

```bash
# macOS
brew install shellcheck

# Ubuntu/Debian
sudo apt install shellcheck
```

### YAML / Dockerfile

```bash
# yamllint
pip install yamllint

# hadolint (Dockerfile)
# macOS
brew install hadolint

# Ubuntu/Debian (via Docker)
docker pull hadolint/hadolint
# Or download binary from: https://github.com/hadolint/hadolint/releases
```

### Verify Installation

```bash
lint c --check-tools
lint python --check-tools
lint bash --check-tools
lint yaml --check-tools
```

## Quick Start

### 1. Check Prerequisites

```bash
./bootstrap.sh
```

This will:
- Detect your OS
- Check for required tools (git, curl)
- Show installation options

### 2. Install

**Option A: Global installation (recommended)**

```bash
./bootstrap.sh --install
# or
./setup.sh --global
```

Installs to `~/.agent`. Add to your shell profile:

```bash
# Add to ~/.bashrc or ~/.zshrc
export AGENT_CONTEXT_PATH="$HOME/.agent"
export PATH="$PATH:$HOME/.agent/tools/agent/bin:$HOME/.agent/tools/pm/bin"
```

**Option B: Project-level installation**

```bash
cd your-project
git clone https://github.com/example/agent-context.git .agent

# Activate for this session
source .agent/activate.sh

# Install templates
agent setup
```

Creates `.agent/` directory and installs templates to your project.

**Option C: One-liner (from GitHub)**

```bash
curl -sL https://raw.githubusercontent.com/example/agent-context/main/bootstrap.sh | bash -s -- --install
```

## Verify Installation

```bash
agent --version
agent status
```

## Configuration

After installation, install templates and configure your project:

```bash
cd your-project

# Install templates (idempotent)
agent setup

# Or force overwrite existing files
agent setup --force
```

This creates:
- `.cursorrules` - AI agent rules
- `configs/` - Project configuration templates
- `policies/` - Domain-specific knowledge templates

For JIRA/GitLab configuration, run the interactive setup:

```bash
./setup.sh  # or .agent/setup.sh for project-local
```

This creates:
- `.secrets/` - API tokens (gitignored)
- `.project.yaml` - Project settings

### Secrets Setup

```bash
# GitLab
echo "glpat-xxx" > .secrets/gitlab-api-token

# GitHub
echo "ghp_xxx" > .secrets/github-api-token

# Atlassian (JIRA + Confluence - same token)
echo "ATATT3xFfGF0xxx" > .secrets/atlassian-api-token
```

Or use environment variables:

```bash
export GITLAB_TOKEN="your-gitlab-token"
export GITHUB_TOKEN="your-github-token"
export JIRA_TOKEN="your-atlassian-token"
export JIRA_EMAIL="your-email"
```

> **Detailed setup:** See `templates/secrets-examples/README.md` for token generation steps.

## Uninstallation

**Global installation:**

```bash
rm -rf ~/.agent
# Remove PATH entries from ~/.bashrc or ~/.zshrc
```

**Project-level:**

```bash
rm -rf .agent .cursorrules configs .secrets plan .project.yaml
# Remove entries from .gitignore if needed
```

## Troubleshooting

### "command not found: agent"

PATH not configured. Add to shell profile:

```bash
export PATH="$PATH:$HOME/.agent/tools/agent/bin"
```

Then restart shell or `source ~/.bashrc`.

### "Permission denied"

Make scripts executable:

```bash
chmod +x bootstrap.sh setup.sh
chmod +x tools/agent/bin/agent
chmod +x tools/pm/bin/pm
```

### macOS: Bash version warning

macOS ships with Bash 3.2 (GPLv2). This is intentional and supported.
All scripts are Bash 3.x compatible.

If you prefer Bash 5+:

```bash
brew install bash
# Add /opt/homebrew/bin/bash to /etc/shells
# chsh -s /opt/homebrew/bin/bash
```

### WSL: Slow git operations

This is a known WSL issue. Consider:
- Store repositories in Linux filesystem (`/home/...`), not Windows (`/mnt/c/...`)
- Use WSL 2 instead of WSL 1
