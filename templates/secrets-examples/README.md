# API Secrets Configuration

This directory contains API tokens for external services.
**All token files are gitignored for security.**

## Token Files

| File | Service | Auth Type |
|------|---------|-----------|
| `gitlab-api-token` | GitLab | Bearer Token |
| `github-api-token` | GitHub | Bearer Token |
| `atlassian-api-token` | JIRA, Confluence | Basic Auth (email:token) |

---

## 1. GitLab API Token

**File:** `gitlab-api-token`

**Setup:**
1. Go to GitLab -> User Settings -> Access Tokens
2. Create a token with scopes: `api`, `read_api`, `read_repository`, `write_repository`
3. Save token to `.secrets/gitlab-api-token`

```bash
echo "glpat-xxxxxxxxxxxx" > .secrets/gitlab-api-token
```

**Test:**
```bash
curl -s --header "PRIVATE-TOKEN: $(cat .secrets/gitlab-api-token)" \
  "https://gitlab.example.com/api/v4/user" | jq .username
```

---

## 2. GitHub API Token

**File:** `github-api-token`

**Setup:**
1. Go to https://github.com/settings/tokens
2. Generate new token (classic) with scopes:
   - `repo` - Full control of private repositories
   - `workflow` - Update GitHub Action workflows (optional)
3. Save token to `.secrets/github-api-token`

```bash
echo "ghp_xxxxxxxxxxxx" > .secrets/github-api-token
```

**Test:**
```bash
curl -s -H "Authorization: Bearer $(cat .secrets/github-api-token)" \
  "https://api.github.com/user" | jq .login
```

---

## 3. Atlassian API Token (JIRA + Confluence)

**File:** `atlassian-api-token`

> **Note:** One token works for both JIRA and Confluence (same Atlassian account).

**Setup:**
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Create an API token
3. Save token to `.secrets/atlassian-api-token`

```bash
echo "ATATT3xFfGF0xxxxxxxxxxxx" > .secrets/atlassian-api-token
```

**Test JIRA:**
```bash
curl -s -u "your-email@example.com:$(cat .secrets/atlassian-api-token)" \
  "https://your-domain.atlassian.net/rest/api/3/myself" | jq .displayName
```

**Test Confluence:**
```bash
curl -s -u "your-email@example.com:$(cat .secrets/atlassian-api-token)" \
  "https://your-domain.atlassian.net/wiki/rest/api/user/current" | jq .displayName
```

### Custom Domain Support

If using custom domains (e.g., `atlassian.jira.example.com`), the pm CLI auto-resolves to the actual Cloud URL via `serverInfo` API.

---

## .project.yaml Configuration

```yaml
# GitLab
gitlab:
  base_url: https://gitlab.example.com
  project: group/repo  # or project ID (e.g., 1094)

# GitHub
github:
  repo: owner/repo

# JIRA
jira:
  base_url: https://your-domain.atlassian.net  # or custom domain
  project_key: PROJ
  email: your-email@example.com

# Confluence
confluence:
  base_url: https://your-domain.atlassian.net
  space_key: SPACE
  email: your-email@example.com
```

---

## Quick Test (All Services)

```bash
# GitLab
pm gitlab me

# GitHub
pm github me

# JIRA
pm jira me

# Confluence (coming soon)
pm confluence me
```
