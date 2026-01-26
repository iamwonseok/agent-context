# Platform Setup Examples

Configuration examples for different platform combinations.

---

## Overview

Agent-context supports multiple platforms via unified abstraction:
- **Issue Tracker:** JIRA, GitLab Issues, GitHub Issues
- **Repository:** GitLab, GitHub
- **Documentation:** Confluence (future)

Configuration is defined in `.agent/config.yaml` at project root.

---

## Configuration File Structure

```yaml
# .agent/config.yaml
platform:
  issue_tracker: jira|gitlab|github
  repository: gitlab|github
  documentation: confluence  # optional

# Platform-specific settings
jira:
  # JIRA configuration

gitlab:
  # GitLab configuration

github:
  # GitHub configuration
```

---

## Example 1: GitLab Only (Simplest)

Use GitLab for both issues and repository.

### Configuration

```yaml
# .agent/config.yaml
platform:
  issue_tracker: gitlab
  repository: gitlab

gitlab:
  url: https://gitlab.company.com
  project_id: 123
  api_token: ${GITLAB_API_TOKEN}
```

### Environment Setup

```bash
# .secrets/.env
GITLAB_API_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx
```

### Token Generation

1. Go to GitLab Settings → Access Tokens
2. Create token with scopes:
   - `api` (full API access)
   - `read_repository`
   - `write_repository`
3. Copy token to `.secrets/.env`

### Verify Setup

```bash
# Test API connection
pm issue get PROJ-123

# Test repository access
git push origin feat/TASK-123
```

---

## Example 2: JIRA + GitHub

Use JIRA for issue tracking, GitHub for repository.

### Configuration

```yaml
# .agent/config.yaml
platform:
  issue_tracker: jira
  repository: github

jira:
  url: https://your-org.atlassian.net
  email: your-email@company.com
  project_key: PROJ
  api_token: ${JIRA_API_TOKEN}

github:
  owner: your-org
  repo: your-repo
  api_token: ${GITHUB_TOKEN}
```

### Environment Setup

```bash
# .secrets/.env
JIRA_API_TOKEN=ATATT3xFfGF0xxxxxxxxxxxxxxxxxxxxx
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
```

### Token Generation

**JIRA:**
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Create API token
3. Copy to `.secrets/.env`

**GitHub:**
1. Go to Settings → Developer Settings → Personal Access Tokens
2. Generate token with scopes:
   - `repo` (full control)
   - `workflow` (if using GitHub Actions)
3. Copy to `.secrets/.env`

### Verify Setup

```bash
# Test JIRA
pm issue get PROJ-123

# Test GitHub
gh pr create --title "Test PR"
```

---

## Example 3: JIRA + GitLab

Use JIRA for issue tracking, GitLab for repository.

### Configuration

```yaml
# .agent/config.yaml
platform:
  issue_tracker: jira
  repository: gitlab

jira:
  url: https://your-org.atlassian.net
  email: your-email@company.com
  project_key: PROJ
  api_token: ${JIRA_API_TOKEN}

gitlab:
  url: https://gitlab.company.com
  project_id: 123
  api_token: ${GITLAB_API_TOKEN}
```

### Environment Setup

```bash
# .secrets/.env
JIRA_API_TOKEN=ATATT3xFfGF0xxxxxxxxxxxxxxxxxxxxx
GITLAB_API_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx
```

### Issue-MR Linking

```bash
# Create MR linked to JIRA issue
agent dev submit
# Automatically adds JIRA issue link to MR description
```

---

## Example 4: GitHub Only

Use GitHub for both issues and repository.

### Configuration

```yaml
# .agent/config.yaml
platform:
  issue_tracker: github
  repository: github

github:
  owner: your-org
  repo: your-repo
  api_token: ${GITHUB_TOKEN}
```

### Environment Setup

```bash
# .secrets/.env
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
```

### Verify Setup

```bash
# Test issue access
pm issue get #123

# Test PR creation
agent dev submit
```

---

## Example 5: Self-Hosted GitLab

Use self-hosted GitLab instance.

### Configuration

```yaml
# .agent/config.yaml
platform:
  issue_tracker: gitlab
  repository: gitlab

gitlab:
  url: https://git.internal.company.com
  project_id: 456
  api_token: ${GITLAB_API_TOKEN}
  # Optional: SSL verification
  verify_ssl: true
```

### Environment Setup

```bash
# .secrets/.env
GITLAB_API_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx
```

### Custom CA Certificate (if needed)

```bash
# Add CA certificate
export SSL_CERT_FILE=/path/to/ca-bundle.crt

# Or disable SSL verification (not recommended)
# In config.yaml:
gitlab:
  verify_ssl: false
```

---

## Example 6: Future - Full Stack (JIRA + GitLab + Confluence)

Planned configuration for all platforms.

### Configuration

```yaml
# .agent/config.yaml
platform:
  issue_tracker: jira
  repository: gitlab
  documentation: confluence

jira:
  url: https://your-org.atlassian.net
  email: your-email@company.com
  project_key: PROJ
  api_token: ${JIRA_API_TOKEN}

gitlab:
  url: https://gitlab.company.com
  project_id: 123
  api_token: ${GITLAB_API_TOKEN}

confluence:
  url: https://your-org.atlassian.net/wiki
  space_key: TECH
  api_token: ${CONFLUENCE_API_TOKEN}
```

### Use Cases

- Issues tracked in JIRA
- Code in GitLab
- Design docs in Confluence
- Auto-link across platforms

---

## Configuration Best Practices

### 1. Use Environment Variables

Never commit tokens to git:

```yaml
# Good: Reference environment variable
api_token: ${GITLAB_API_TOKEN}

# Bad: Hardcoded token
api_token: glpat-1234567890
```

### 2. Store Tokens in .secrets/

Keep `.secrets/` in `.gitignore`:

```bash
# .gitignore
.secrets/
```

### 3. Use Project-Specific Config

Each project should have its own `.agent/config.yaml`:

```bash
project1/
  .agent/config.yaml  # JIRA + GitLab

project2/
  .agent/config.yaml  # GitHub only
```

### 4. Validate Configuration

```bash
# Test configuration
agent status

# Should show:
# [INFO] Platform: JIRA + GitLab
# [INFO] Issue tracker: Connected
# [INFO] Repository: Connected
```

---

## Token Scopes Required

### GitLab

Minimum scopes:
- `api` - Full API access
- `read_repository` - Read repo
- `write_repository` - Push code

Optional:
- `read_user` - Read user info
- `sudo` - Admin operations

### GitHub

Minimum scopes:
- `repo` - Full repository access
- `workflow` - GitHub Actions (if used)

Optional:
- `read:org` - Read organization info
- `admin:repo_hook` - Manage webhooks

### JIRA

API token has full access (no scope selection).  
Use dedicated service account for automation.

---

## Migration Between Platforms

### From GitHub to GitLab

1. Update `.agent/config.yaml`:
   ```yaml
   platform:
     issue_tracker: gitlab  # was: github
     repository: gitlab      # was: github
   ```

2. Migrate issues:
   ```bash
   # Export GitHub issues
   gh issue list --json number,title,body > issues.json

   # Import to GitLab (manual or via API)
   ```

3. Update remote:
   ```bash
   git remote set-url origin https://gitlab.com/org/repo.git
   ```

### From JIRA to GitLab Issues

1. Export JIRA issues (CSV or API)
2. Import to GitLab (via UI or API)
3. Update config:
   ```yaml
   platform:
     issue_tracker: gitlab  # was: jira
   ```

---

## Troubleshooting

### "API token invalid"

**Check token expiration:**
```bash
# GitLab: Check token at Settings → Access Tokens
# JIRA: Tokens don't expire, but account may be deactivated
# GitHub: Check token at Settings → Developer Settings
```

**Regenerate token:**
1. Revoke old token
2. Create new token with same scopes
3. Update `.secrets/.env`

### "Project not found"

**Verify project ID/key:**
```bash
# GitLab: Get project ID from project settings
# JIRA: Project key is in issue prefix (e.g., PROJ-123 → PROJ)
# GitHub: owner/repo format
```

### "SSL certificate verification failed"

**Option 1: Add CA certificate**
```bash
export SSL_CERT_FILE=/path/to/ca-bundle.crt
```

**Option 2: Disable verification (not recommended)**
```yaml
gitlab:
  verify_ssl: false
```

---

## Examples Directory

Sample configurations are in:
```
templates/configs/
├── gitlab-only.yaml
├── jira-gitlab.yaml
├── jira-github.yaml
└── github-only.yaml
```

Copy and customize for your project:
```bash
cp templates/configs/jira-gitlab.yaml .agent/config.yaml
# Edit with your values
```

---

## References

- [PM Tools Documentation](../cli/pm.md)
- [Agent CLI Documentation](../cli/agent-dev.md)
- [Unified Platform Abstraction RFC](../rfcs/006-unified-platform-abstraction.md)
- [Manual Fallback Guide](manual-fallback-guide.md)

---

*Last updated: 2026-01-26*
