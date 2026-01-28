# Project Management CLI

> **User manual**: [docs/cli/pm.md](../../docs/cli/pm.md)

Jira/Confluence/GitLab integration CLI for development workflow automation.

## Requirements

- Bash 4.0+
- jq (JSON processor)
- curl
- git
- pandoc (for export commands only)

```bash
# macOS
brew install jq pandoc

# Ubuntu/Debian
apt-get install jq pandoc
```

## Installation

Add to PATH or create alias:

```bash
# Option 1: Add to PATH
export PATH="$PATH:/path/to/agent-context/tools/pm/bin"

# Option 2: Alias
alias pm='/path/to/agent-context/tools/pm/bin/pm'
```

## Configuration

### 1. Create `.project.yaml`

```bash
pm config init
```

This creates `.project.yaml` in your project root:

```yaml
jira:
  base_url: https://your-domain.atlassian.net
  project_key: PROJ
  email: your-email@example.com

# Confluence shares Atlassian token with Jira
confluence:
  base_url: https://your-domain.atlassian.net
  space_key: SPACE
  email: your-email@example.com

gitlab:
  base_url: https://gitlab.example.com
  project: namespace/project

branch:
  feature_prefix: feat/
  bugfix_prefix: fix/
  hotfix_prefix: hotfix/
```

### 2. Configure API Tokens

**Option A: Environment Variables (Recommended)**

```bash
export JIRA_TOKEN="your-jira-api-token"
export JIRA_EMAIL="your-email@example.com"
export GITLAB_TOKEN="your-gitlab-token"
```

**Option B: Secret Files**

```bash
echo "your-jira-token" > .secrets/atlassian-api-token
echo "your-gitlab-token" > .secrets/gitlab-api-token
```

### 3. Verify Configuration

```bash
pm config show
```

## Commands

### Configuration

```bash
pm config show          # Show current configuration
pm config init          # Create .project.yaml
pm config init --force  # Overwrite existing config
```

### Jira

```bash
pm jira me                          # Show current user
pm jira issue list                  # List issues
pm jira issue list --jql "assignee=currentUser()"
pm jira issue list --limit 50
pm jira issue view PROJ-123         # View issue details
pm jira issue create "Title"        # Create issue
pm jira issue create "Bug" --type Bug
pm jira issue create "Task" --description "Details here"

# Export issues to Markdown
pm jira export --project SPF --output ./export/jira/
pm jira export --jql "project=SPF AND status!=Done" --output ./export/jira/
pm jira export --project SPF --output ./export/jira/ --include-comments
pm jira export --project SPF --output ./export/jira/ --limit 100
```

### Confluence

```bash
pm confluence me                        # Show current user
pm confluence space list                # List spaces
pm confluence space list --limit 50
pm confluence page list                 # List pages (uses default space)
pm confluence page list --space SFP     # List pages in specific space
pm confluence page view 7574650944      # View page details (by ID)
pm confluence page text 7574650944      # View page as plain text
pm confluence page create --space SFP --title "New Page" --content "<p>Hello</p>"
pm confluence page create --space SFP --title "Child Page" --parent 7574650944
pm confluence search "type=page AND space=SFP"
pm confluence search "title ~ 'Review'"

# Export pages to Markdown
pm confluence export --space SFP --output ./export/confluence/
pm confluence export --space SFP --output ./export/confluence/ --limit 50
```

### GitLab

```bash
pm gitlab me                        # Show current user
pm gitlab mr list                   # List open MRs
pm gitlab mr list --state merged    # List merged MRs
pm gitlab mr list --limit 50
pm gitlab mr view 123               # View MR details
pm gitlab mr create --source feat/test --title "Test MR"
pm gitlab mr create --source feat/test --title "WIP" --draft
pm gitlab issue list                # List issues
pm gitlab issue list --state closed
pm gitlab issue create "Title"      # Create issue
pm gitlab issue create "Bug report" --description "Details here"
```

### GitHub

```bash
pm github me                        # Show current user
pm github pr list                   # List open PRs
pm github pr list --state closed    # List closed PRs
pm github pr list --limit 50
pm github pr view 123               # View PR details
pm github pr create --head feat/test --title "Test PR"
pm github pr create --head feat/test --title "WIP" --draft
pm github issue list                # List issues
pm github issue list --state closed
pm github issue create "Title"      # Create issue
pm github issue create "Bug report" --body "Details here"
```

### Workflow

```bash
# Start new feature
pm create "Add UART driver"
# -> Creates Jira issue
# -> Creates GitLab issue
# -> Creates branch: feat/PROJ-123-add-uart-driver

# Start bugfix
pm create "Fix DMA timeout" --type Bug --workflow bugfix
# -> Creates branch: fix/PROJ-124-fix-dma-timeout

# Start hotfix
pm create "Fix watchdog reset" --workflow hotfix
# -> Creates branch: hotfix/PROJ-125-fix-watchdog-reset

# Finish feature
pm finish
# -> Runs lint (if configured)
# -> Runs tests (if configured)
# -> Pushes branch
# -> Creates MR
# -> Updates Jira status

# Finish with options
pm finish --skip-lint --skip-tests
pm finish --draft
pm finish --target develop
```

## Workflow Example

```bash
# 1. Start feature
$ pm create "Add UART driver"
[INFO] Creating Jira issue...
(v) Jira issue: SVI-456
[INFO] Creating GitLab issue...
(v) GitLab issue: #789
[INFO] Creating branch...
(v) Branch: feat/SVI-456-add-uart-driver

Initialization complete.

# 2. Develop...
$ git add .
$ git commit -m "feat(uart): implement ring buffer"

# 3. Finish
$ pm finish
[INFO] Running lint checks...
(v) Lint passed
[INFO] Running tests...
(v) Tests passed
[INFO] Pushing feat/SVI-456-add-uart-driver...
(v) Branch pushed
[INFO] Creating merge request...
(v) Created: !123
    URL: https://gitlab.example.com/ns/proj/-/merge_requests/123
[INFO] Updating Jira status...
(v) Jira updated: SVI-456 -> In Review

Feature complete.
```

## Project Structure

```
tools/pm/
+-- bin/
|   +-- pm                    # Main CLI script
+-- lib/
|   +-- config.sh             # Configuration loader
|   +-- jira.sh               # Jira API functions
|   +-- confluence.sh         # Confluence API functions
|   +-- gitlab.sh             # GitLab API functions
|   +-- github.sh             # GitHub API functions
|   +-- workflow.sh           # Workflow functions (init, finish)
|   +-- export.sh             # Export functions (Markdown export)
+-- README.md
```

## API Token Setup

### Jira API Token

1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click "Create API token"
3. Copy the token

### Confluence API Token

Confluence uses the same Atlassian API token as Jira. If you've configured Jira, Confluence will automatically use the same token.

For Confluence-only setup:
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click "Create API token"
3. Copy the token
4. Store in `.secrets/atlassian-api-token` or set `CONFLUENCE_TOKEN` environment variable

### GitLab Personal Access Token

1. Go to GitLab -> User Settings -> Access Tokens
2. Create token with scopes: `api`, `read_api`, `read_repository`, `write_repository`
3. Copy the token

### GitHub Personal Access Token

1. Go to GitHub -> Settings -> Developer settings -> Personal access tokens -> Tokens (classic)
2. Click "Generate new token (classic)"
3. Select scopes: `repo`, `read:user`
4. Copy the token
5. Store in `.secrets/github-api-token` or set `GITHUB_TOKEN` environment variable

## Troubleshooting

### "jq: command not found"

Install jq:
```bash
brew install jq  # macOS
apt install jq   # Ubuntu
```

### "Jira not configured"

Check `.project.yaml` has valid `jira` section and token is set.

### "GitLab not configured"

Check `.project.yaml` has valid `gitlab` section and token is set.

### Authentication errors

Verify tokens are valid:

```bash
# Test Jira
curl -s -u "email:token" "https://your-domain.atlassian.net/rest/api/2/myself" | jq .displayName

# Test GitLab
curl -s -H "PRIVATE-TOKEN: token" "https://gitlab.example.com/api/v4/user" | jq .username
```
