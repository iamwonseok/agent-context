# E2E Tests (Stage 3) - Local Only

End-to-end tests requiring real GitLab/GitHub/JIRA connections.

> **Note**: E2E 테스트는 실제 API 토큰이 필요하므로 **로컬에서만 실행**합니다.
> CI에서는 실행되지 않습니다.

## Prerequisites

```bash
export GITLAB_API_TOKEN=<your-token>
export GITLAB_URL=https://gitlab.com
# Optional:
export JIRA_API_TOKEN=<your-token>
export GITHUB_TOKEN=<your-token>
```

## Run

```bash
# Via Docker (recommended)
docker compose -f tests/docker-compose.test.yml run e2e

# Direct execution
./tests/e2e/test_e2e.sh
```

## Test Coverage

- GitLab API connection
- `agent dev submit` → MR creation
- JIRA issue integration (if configured)

## Dependencies

- Stage 1 (Smoke) and Stage 2 (Local Git) should pass first
- Real API tokens with appropriate permissions
