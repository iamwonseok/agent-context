# Project Management CLI

JIRA/Confluence integration CLI for development workflow automation.

For GitLab/GitHub operations, use the official CLIs:
- **GitLab**: [glab](https://gitlab.com/gitlab-org/cli) - `brew install glab`
- **GitHub**: [gh](https://cli.github.com) - `brew install gh`

## Requirements

- Bash 4.0+
- jq (JSON processor)
- curl
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

confluence:
  base_url: https://your-domain.atlassian.net
  space_key: SPACE
  email: your-email@example.com
```

### Optional: Git Workflow Policy

You can optionally define your team's Git workflow policy in `.project.yaml`:

```yaml
git:
  merge:
    # Strategy options: ff-only | squash | rebase | merge-commit
    strategy: ff-only
    # If true, delete the source branch after it is merged.
    delete_merged_branch: true
  push:
    # If true, do not push unless pre-commit checks pass.
    require_precommit_pass: true
```

### 2. Configure API Tokens

**Option A: Environment Variables (Recommended)**

```bash
export JIRA_TOKEN="your-jira-api-token"
export JIRA_EMAIL="your-email@example.com"
```

**Option B: Secret Files**

```bash
echo "your-jira-token" > .secrets/atlassian-api-token
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

### JIRA

```bash
pm jira me                          # Show current user
pm jira issue list                  # List issues
pm jira issue list --jql "assignee=currentUser()"
pm jira issue list --limit 50
pm jira issue view PROJ-123         # View issue details
pm jira issue create "Title"        # Create issue
pm jira issue create "Bug" --type Bug
pm jira issue create "Task" --description "Details here"
pm jira issue assign PROJ-123 user@example.com
pm jira issue transition PROJ-123 "In Progress"
pm jira issue update PROJ-123 --summary "New title"

# Sprints
pm jira sprint list
pm jira sprint move PROJ-123 123

# Workflows
pm jira workflow list
pm jira workflow transitions PROJ-123
pm jira workflow statuses

# Links (dependencies)
pm jira link types
pm jira link view PROJ-123
pm jira link create PROJ-123 PROJ-124 "Blocks"
pm jira link delete 12345

# Bulk operations
pm jira bulk-create --csv issues.csv

# Export issues to Markdown
pm jira export --project PROJ --output ./export/jira/
pm jira export --jql "project=PROJ AND status!=Done"
pm jira export --include-comments --limit 100
```

### Confluence

```bash
pm confluence me                        # Show current user

# Spaces
pm confluence space list
pm confluence space list --limit 50
pm confluence space view SPACE
pm confluence space create --key NEW --name "New Space"
pm confluence space permissions SPACE
pm confluence space delete SPACE --force

# Pages
pm confluence page list                 # List pages (uses default space)
pm confluence page list --space SPACE
pm confluence page view 7574650944      # View page details (by ID)
pm confluence page text 7574650944      # View page as plain text
pm confluence page create --space SPACE --title "New Page" --content "<p>Hello</p>"
pm confluence page create --space SPACE --title "Child Page" --parent 7574650944

# Search
pm confluence search "type=page AND space=SPACE"
pm confluence search "title ~ 'Review'"

# Export pages to Markdown
pm confluence export --space SPACE --output ./export/confluence/
pm confluence export --preserve-hierarchy --limit 50
```

## GitLab/GitHub

Use the official CLIs instead:

### GitLab (glab)

```bash
# Install
brew install glab

# Authenticate
glab auth login

# Usage
glab mr list
glab mr create --title "Feature" --source-branch feat/xyz
glab mr view 123
glab issue list
glab issue create --title "Bug report"
```

### GitHub (gh)

```bash
# Install
brew install gh

# Authenticate
gh auth login

# Usage
gh pr list
gh pr create --title "Feature" --head feat/xyz
gh pr view 123
gh issue list
gh issue create --title "Bug report"
```

## Project Structure

```
tools/pm/
+-- bin/
|   +-- pm              # Main CLI script
+-- lib/
|   +-- config.sh       # Configuration loader
|   +-- jira.sh         # JIRA API functions
|   +-- confluence.sh   # Confluence API functions
|   +-- export.sh       # Export functions (Markdown)
+-- README.md
```

## API Token Setup

### JIRA/Confluence API Token

Both use the same Atlassian API token:

1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click "Create API token"
3. Copy the token
4. Store in `.secrets/atlassian-api-token` or set `JIRA_TOKEN` environment variable

## Troubleshooting

### "jq: command not found"

Install jq:
```bash
brew install jq  # macOS
apt install jq   # Ubuntu
```

### "JIRA not configured"

Check `.project.yaml` has valid `jira` section and token is set.

### Authentication errors

Verify token is valid:

```bash
# Test JIRA
curl -s -u "email:token" "https://your-domain.atlassian.net/rest/api/2/myself" | jq .displayName
```
