# agent init

## NAME

agent init - Initialize project for agent workflow

## SYNOPSIS

    agent init [OPTIONS]
    agent config show
    agent config init

## DESCRIPTION

The `agent init` command initializes a project for use with the agent workflow system. It creates necessary directories, configuration files, and git hooks.

## COMMANDS

### agent init

Initialize the current project.

    agent init [OPTIONS]

**Options:**

    -f, --force
        Overwrite existing configuration.

    --no-hooks
        Skip git hooks installation.

**Actions performed:**

1. Create `.context/` directory
2. Add entries to `.gitignore`
3. Install git hooks (pre-commit, commit-msg)
4. Validate secrets configuration

### agent config show

Display current configuration.

    agent config show

**Output:**

    ==================================================
    Agent Configuration
    ==================================================
    
    Project Root: /path/to/project
    
    [Role]
      Current Role: Developer
      AGENT_ROLE env: (not set)
    
    [Git Strategy]
      Default Mode: Interactive (branch)
      Worktree Root: .worktrees/
    
    [Context]
      Interactive: .context/{task-id}/
      Detached: .worktrees/{task-id}/.context/
    
    [Integration]
      pm CLI: /path/to/pm

### agent config init

Create `.project.yaml` configuration file.

    agent config init [--force]

This is a wrapper for `pm config init`.

## CONFIGURATION FILES

### .project.yaml

Main project configuration:

```yaml
# Project configuration
project:
  name: my-project
  type: embedded  # or: web, library, service

# JIRA integration
jira:
  url: https://jira.example.com
  project_key: PROJ
  issue_types:
    - Task
    - Bug
    - Story

# GitLab integration
gitlab:
  url: https://gitlab.example.com
  project: group/project-name

# Agent settings
agent:
  default_mode: interactive  # or: detached
  merge_strategy: ff-only    # or: squash, merge-commit
```

### .secrets/

Directory for API tokens (gitignored):

    .secrets/
    ├── atlassian-api-token    # JIRA API token
    └── gitlab-api-token       # GitLab API token

Token files should contain only the token value, no newlines.

**Alternative:** Use environment variables:
- `JIRA_TOKEN`
- `GITLAB_TOKEN`

### .gitignore entries

The following entries are added automatically:

```gitignore
# Agent workflow
.context/
.worktrees/
.secrets/
```

## GIT HOOKS

### pre-commit

Runs lint checks before commit:

```bash
#!/bin/bash
# Skip if SKIP_HOOKS is set
if [[ -n "$SKIP_HOOKS" ]]; then
    exit 0
fi

# Run lint check if available
if command -v lint >/dev/null 2>&1; then
    lint check || exit 1
fi
```

### commit-msg

Validates conventional commit format:

```
<type>[optional scope]: <description>

Types: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert
```

**Examples:**
- `feat: add user authentication`
- `fix(api): handle null response`
- `docs: update README`

**Bypass:** `SKIP_HOOKS=1 git commit -m "message"`

## SECRETS VALIDATION

During initialization, secrets are validated:

```
[Secrets Validation]
  [OK] JIRA token (.secrets/atlassian-api-token)
  [WARN] GitLab token not found
```

Warnings don't block initialization but some features will be limited.

## EXAMPLES

Initialize a new project:

    $ cd my-project
    $ agent init
    =========================================
    Agent Project Initialization
    =========================================
    
    Project: /path/to/my-project
    Agent Context: /home/user/.agent
    
    [Secrets Validation]
      [OK] JIRA token (.secrets/atlassian-api-token)
      [OK] GitLab token (.secrets/gitlab-api-token)
    
    [Git Hooks]
      [OK] Installed pre-commit hook
      [OK] Installed commit-msg hook
    
    =========================================
    Initialization Complete
    =========================================
    
    Next steps:
      1. Configure secrets in .secrets/ or environment variables
      2. Edit .project.yaml for your project settings
      3. Start working: agent dev start TASK-123

Reinitialize with force:

    $ agent init --force

Skip hooks during init:

    $ agent init --no-hooks

## PATH RESOLUTION

Agent-context is resolved in this order:

1. `.agent/` - Project local installation
2. `.project.yaml` → `agent_context` setting
3. `$AGENT_CONTEXT_PATH` environment variable
4. `~/.agent` - Global default

## SEE ALSO

[agent](agent.md), [agent-dev](agent-dev.md), [agent-mgr](agent-mgr.md)
