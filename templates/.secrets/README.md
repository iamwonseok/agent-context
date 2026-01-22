# API Secrets Configuration

This directory contains API tokens for external services.
**All token files are gitignored for security.**

## Required Tokens

### 1. GitLab API Token

**File:** `gitlab-api-token`

**Setup:**
1. Go to GitLab -> User Settings -> Access Tokens
2. Create a token with appropriate scopes (api, read_api, read_repository, write_repository)
3. Save token to `.secrets/gitlab-api-token`

**Usage:**
```bash
curl --header "PRIVATE-TOKEN: $(cat .secrets/gitlab-api-token)" \
  "https://gitlab.fadutec.dev/api/v4/user"
```

**Endpoints:**
- Base URL: `https://gitlab.fadutec.dev/api/v4`
- Project: `soc-ip/agentic`

---

### 2. Atlassian (Jira) API Token

**File:** `atlassian-api-token`

**Setup:**
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Create an API token
3. Save token to `.secrets/atlassian-api-token`

**Usage:**
```bash
curl -u "YOUR_EMAIL:$(cat .secrets/atlassian-api-token)" \
  "https://fadutec.atlassian.net/rest/api/2/myself"
```

**Endpoints:**
- Base URL: `https://fadutec.atlassian.net/rest/api/2`
- Display URL: `https://atlassian.jira.fadutec.dev`

**Projects:**
| Key | Name | Description |
|-----|------|-------------|
| SVI | SoC VnV | New project (to be used) |
| SPF | SoC Platform FW | Current project |

---

## Quick Test

```bash
# Test GitLab
curl -s --header "PRIVATE-TOKEN: $(cat .secrets/gitlab-api-token)" \
  "https://gitlab.fadutec.dev/api/v4/user" | jq .username

# Test Jira (replace EMAIL)
curl -s -u "EMAIL:$(cat .secrets/atlassian-api-token)" \
  "https://fadutec.atlassian.net/rest/api/2/myself" | jq .displayName
```
