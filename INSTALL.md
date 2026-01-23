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
/path/to/agent-context/setup.sh
```

Creates `.agent/` symlink or copies files to your project.

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

After installation, configure your project:

```bash
cd your-project
setup.sh  # Interactive configuration
```

This creates:
- `.cursorrules` - AI agent rules
- `configs/` - Project configuration templates
- `.secrets/` - API tokens (gitignored)
- `plan/` - Project planning directory
- `.project.yaml` - Project settings

### Secrets Setup

```bash
# JIRA API token
echo "your-jira-token" > .secrets/atlassian-api-token

# GitLab API token
echo "your-gitlab-token" > .secrets/gitlab-api-token
```

Or use environment variables:

```bash
export JIRA_TOKEN="your-jira-token"
export JIRA_EMAIL="your-email"
export GITLAB_TOKEN="your-gitlab-token"
```

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
