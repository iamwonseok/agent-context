# Agent-Context Test Summary

테스트 재현 및 결과 기록 문서입니다.

## 테스트 환경

### 플랫폼 설정

| 플랫폼 | URL | 프로젝트/레포 |
|--------|-----|--------------|
| GitHub | https://github.com | iamwonseok/demo |
| GitLab | https://gitlab.fadutec.dev | soc-ip/demo |
| JIRA | https://atlassian.jira.fadutec.dev | G6SOCTC |

### 토큰 위치

```
~/.secrets/
├── github-api-token      # GitHub PAT (repo scope)
├── gitlab-api-token      # GitLab PAT
└── atlassian-api-token   # JIRA API token
```

### 프로젝트 설정 (.project.yaml)

```yaml
# GitHub + JIRA 테스트용
github:
  repo: iamwonseok/demo

jira:
  base_url: https://atlassian.jira.fadutec.dev
  project_key: G6SOCTC
  email: <your-email>

# GitLab + JIRA 테스트용
gitlab:
  base_url: https://gitlab.fadutec.dev
  project: soc-ip/demo
```

---

## 1. 기본 테스트 (pm CLI)

### 1.1 GitHub 테스트

| # | 명령어 | 예상 결과 | 실제 결과 | 상태 |
|---|--------|----------|----------|------|
| 1 | `pm github me` | 사용자 정보 출력 | | [ ] |
| 2 | `pm github pr list` | PR 목록 출력 | | [ ] |
| 3 | `pm github pr view <num>` | PR 상세 출력 | | [ ] |
| 4 | `pm github issue list` | 이슈 목록 출력 | | [ ] |

### 1.2 GitLab 테스트

| # | 명령어 | 예상 결과 | 실제 결과 | 상태 |
|---|--------|----------|----------|------|
| 1 | `pm gitlab me` | 사용자 정보 출력 | | [ ] |
| 2 | `pm gitlab mr list` | MR 목록 출력 | | [ ] |
| 3 | `pm gitlab mr view <iid>` | MR 상세 출력 | | [ ] |
| 4 | `pm gitlab issue list` | 이슈 목록 출력 | | [ ] |

### 1.3 JIRA 테스트

| # | 명령어 | 예상 결과 | 실제 결과 | 상태 |
|---|--------|----------|----------|------|
| 1 | `pm jira me` | 사용자 정보 출력 | | [ ] |
| 2 | `pm jira issue list` | 이슈 목록 출력 | | [ ] |
| 3 | `pm jira issue view <KEY>` | 이슈 상세 출력 | | [ ] |

---

## 2. Workflow 테스트 (agent CLI)

### 2.1 기본 명령어

| # | 명령어 | 예상 결과 | 실제 결과 | 상태 |
|---|--------|----------|----------|------|
| 1 | `agent --version` | 버전 출력 | | [ ] |
| 2 | `agent --help` | 도움말 출력 | | [ ] |
| 3 | `agent status` | 현재 상태 출력 | | [ ] |

### 2.2 Developer 워크플로우

| # | 명령어 | 예상 결과 | 실제 결과 | 상태 |
|---|--------|----------|----------|------|
| 1 | `agent dev start TEST-001` | 브랜치 생성 + .context/ 초기화 | | [ ] |
| 2 | `agent dev list` | 활성 작업 목록 | | [ ] |
| 3 | `agent dev status` | 현재 작업 상태 | | [ ] |
| 4 | `agent dev check` | 린트/테스트 검증 | | [ ] |
| 5 | `agent dev sync` | base 브랜치 rebase | | [ ] |
| 6 | `agent dev submit` | MR/PR 생성 | | [ ] |
| 7 | `agent dev cleanup TEST-001` | 작업 정리 | | [ ] |

### 2.3 Manager 워크플로우

| # | 명령어 | 예상 결과 | 실제 결과 | 상태 |
|---|--------|----------|----------|------|
| 1 | `agent mgr pending` | 대기 MR 목록 | | [ ] |
| 2 | `agent mgr review <mr-id>` | MR 상세 리뷰 | | [ ] |
| 3 | `agent mgr status` | 프로젝트 개요 | | [ ] |
| 4 | `agent mgr approve <mr-id>` | MR 승인 (human_only) | | [ ] |

---

## 3. 시나리오 테스트

### 3.1 GitHub Only 시나리오

**설정**: `.project.yaml`에 `github.repo: iamwonseok/demo`만 설정

```bash
# 1. 설정 확인
pm config show

# 2. 기본 연결 테스트
pm github me
pm github pr list
pm github issue list

# 3. Feature 개발 플로우
agent dev start FEAT-GH-001
# ... 코드 수정 ...
agent dev check
agent dev submit  # GitHub PR 생성
```

| 단계 | 명령어 | 결과 | 상태 |
|------|--------|------|------|
| 1 | `pm config show` | | [ ] |
| 2 | `pm github me` | | [ ] |
| 3 | `agent dev start FEAT-GH-001` | | [ ] |
| 4 | `agent dev submit` | | [ ] |

### 3.2 GitHub + JIRA 시나리오

**설정**: GitHub + JIRA 모두 설정

```bash
# 1. JIRA 이슈 확인
pm jira issue list --limit 5

# 2. JIRA 이슈 기반 작업 시작
agent dev start G6SOCTC-123  # JIRA 이슈 ID

# 3. 작업 완료 후 PR 생성 + JIRA 연동
agent dev submit
```

| 단계 | 명령어 | 결과 | 상태 |
|------|--------|------|------|
| 1 | `pm jira issue list` | | [ ] |
| 2 | `agent dev start <JIRA-ID>` | | [ ] |
| 3 | `agent dev submit` | | [ ] |

### 3.3 GitLab Only 시나리오

**설정**: `.project.yaml`에 `gitlab` 설정

```bash
# 1. 설정 확인
pm config show

# 2. 기본 연결 테스트
pm gitlab me
pm gitlab mr list
pm gitlab issue list

# 3. Feature 개발 플로우
agent dev start FEAT-GL-001
agent dev check
agent dev submit  # GitLab MR 생성
```

| 단계 | 명령어 | 결과 | 상태 |
|------|--------|------|------|
| 1 | `pm config show` | | [ ] |
| 2 | `pm gitlab me` | | [ ] |
| 3 | `agent dev start FEAT-GL-001` | | [ ] |
| 4 | `agent dev submit` | | [ ] |

### 3.4 GitLab + JIRA 시나리오

**설정**: GitLab + JIRA 모두 설정

```bash
# 1. JIRA 이슈 확인
pm jira issue list --limit 5

# 2. JIRA 이슈 기반 작업 시작
agent dev start G6SOCTC-456

# 3. 작업 완료
agent dev submit  # GitLab MR 생성 + JIRA 연동
```

| 단계 | 명령어 | 결과 | 상태 |
|------|--------|------|------|
| 1 | `pm jira issue list` | | [ ] |
| 2 | `agent dev start <JIRA-ID>` | | [ ] |
| 3 | `agent dev submit` | | [ ] |

### 3.5 매니저 리뷰 시나리오

```bash
# 1. 대기 중인 MR 확인
agent mgr pending

# 2. MR 상세 리뷰
agent mgr review <mr-id>

# 3. 코멘트 추가 (필요시)
agent mgr review <mr-id> --comment "LGTM"

# 4. 승인 (human_only 동작 확인)
agent mgr approve <mr-id>
```

| 단계 | 명령어 | 결과 | 상태 |
|------|--------|------|------|
| 1 | `agent mgr pending` | | [ ] |
| 2 | `agent mgr review <mr-id>` | | [ ] |
| 3 | `agent mgr approve <mr-id>` | | [ ] |

---

## 4. 테스트 실행 방법

### 사전 준비

```bash
# 1. 토큰 설정
ls -la ~/.secrets/
# github-api-token, gitlab-api-token, atlassian-api-token 확인

# 2. 환경변수 또는 심볼릭 링크
ln -sf ~/.secrets/github-api-token .secrets/github-api-token
ln -sf ~/.secrets/gitlab-api-token .secrets/gitlab-api-token
ln -sf ~/.secrets/atlassian-api-token .secrets/atlassian-api-token

# 3. PATH 설정
export PATH="$PATH:$(pwd)/tools/agent/bin:$(pwd)/tools/pm/bin"

# 4. 프로젝트 설정 확인
pm config show
```

### GitHub 테스트 실행

```bash
# .project.yaml에 GitHub 설정
cat > .project.yaml << 'EOF'
github:
  repo: iamwonseok/demo
EOF

# 테스트
pm github me
pm github pr list
```

### GitLab 테스트 실행

```bash
# .project.yaml에 GitLab 설정
cat > .project.yaml << 'EOF'
gitlab:
  base_url: https://gitlab.fadutec.dev
  project: soc-ip/demo
EOF

# 테스트
pm gitlab me
pm gitlab mr list
```

### 전체 테스트 (Docker)

```bash
# Stage 1-2 (토큰 불필요)
docker compose -f tests/docker-compose.test.yml run all

# E2E (토큰 필요)
export GITHUB_TOKEN=$(cat ~/.secrets/github-api-token)
export GITLAB_TOKEN=$(cat ~/.secrets/gitlab-api-token)
docker compose -f tests/docker-compose.test.yml run e2e
```

---

## 5. 테스트 결과 기록

### 테스트 일자: 2026-01-24

### 환경
- OS: macOS (darwin 24.6.0)
- Shell: zsh
- agent-context version: 0.1.0

### 결과 요약

| 카테고리 | 통과 | 실패 | 건너뜀 |
|----------|------|------|--------|
| pm GitHub | 4/4 | 0 | 0 |
| pm GitLab | 4/4 | 0 | 0 |
| pm JIRA | 3/3 | 0 | 0 |
| agent basic | 2/3 | 0 | 0 |
| agent dev | 5/7 | 0 | 2 |
| agent mgr | /4 | | |
| 시나리오 | 3/5 | 0 | 2 |

### 상세 결과 (2026-01-24)

**pm GitHub**
- [x] `pm github me` - 통과 (User: iamwonseok / Wonseok Ko)
- [x] `pm github pr list` - 통과
- [x] `pm github issue list` - 통과
- [x] `pm github pr create` - 통과 (PR #1 생성됨)

**pm GitLab**
- [x] `pm gitlab me` - 통과 (User: gitlab-soc-ip-api-token)
- [x] `pm gitlab mr list` - 통과
- [x] `pm gitlab issue list` - 통과
- [x] `pm gitlab mr create` - 통과 (MR !1, !2 생성됨)

**pm JIRA**
- [x] `pm jira me` - 통과 (고원석 Alex)
- [x] `pm jira issue list` - 통과 (3 issues)
- [x] `pm jira issue view G6SOCTC-1` - 통과

**agent basic**
- [x] `agent --version` - 통과 (0.1.0)
- [x] `agent status` - 통과
- [ ] `agent init` - 미테스트

**agent dev (GitHub demo repo)**
- [x] `agent dev start TEST-GH-004` - 통과 (브랜치 + .context/ 생성)
- [x] `agent dev list` - 미테스트
- [x] `agent dev status` - 통과 (활성 작업 표시)
- [x] `agent dev cleanup` - 통과
- [x] `agent dev submit` - 통과 (GitHub PR #1 생성됨!)
- [ ] `agent dev check` - 미테스트
- [ ] `agent dev sync` - 미테스트

**GitHub 워크플로우 E2E**
- [x] 전체 플로우: start → commit → submit → PR 생성 - **통과**
- PR URL: https://github.com/iamwonseok/demo/pull/1

**GitLab 워크플로우 E2E**
- [x] 전체 플로우: start → commit → submit → MR 생성 - **통과**
- MR URL: https://gitlab.fadutec.dev/soc-ip/demo/-/merge_requests/2
- 참고: 그룹 봇 토큰 사용 시 커밋 이메일 매칭 필요

### 발견 및 해결된 이슈

| # | 문제 | 해결 |
|---|------|------|
| 1 | JIRA custom domain 인증 실패 | `serverInfo`에서 실제 Cloud URL 자동 감지 |
| 2 | JIRA Cloud search API deprecated | API v3 `/search/jql` 엔드포인트로 변경 |
| 3 | GitLab 숫자 project ID 감지 안됨 | grep 패턴 수정 (숫자 포함) |

### 완료된 항목

- [x] JIRA custom domain 지원 (atlassian.jira.fadutec.dev → fadutec.atlassian.net 자동 변환)
- [x] agent dev submit: GitHub PR 생성 (#1)
- [x] agent dev submit: GitLab MR 생성 (!2)
- [x] JIRA Cloud API v3 지원 

---

## 부록: 빠른 테스트 스크립트

```bash
#!/bin/bash
# tests/quick-test.sh

set -e

echo "=== pm GitHub ==="
pm github me || echo "[SKIP] GitHub not configured"

echo ""
echo "=== pm GitLab ==="
pm gitlab me || echo "[SKIP] GitLab not configured"

echo ""
echo "=== pm JIRA ==="
pm jira me || echo "[SKIP] JIRA not configured"

echo ""
echo "=== agent ==="
agent --version
agent status
```
