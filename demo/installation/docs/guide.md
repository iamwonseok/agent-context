# Docker Demo Installation Guide

이 문서는 Docker 환경에서 agent-context 설치 데모를 실행하는 방법을 설명한다.

## 목차

1. [사전 준비](#사전-준비)
2. [토큰 발급](#토큰-발급)
3. [시크릿 설정](#시크릿-설정)
4. [로컬 실행](#로컬-실행)
5. [Docker 실행](#docker-실행)
6. [트러블슈팅](#트러블슈팅)

---

## 사전 준비

### 필수 도구

| 도구 | 용도 | 설치 확인 |
|------|------|-----------|
| Docker | 컨테이너 실행 | `docker --version` |
| bash | 스크립트 실행 | `bash --version` |
| git | 버전 관리 | `git --version` |
| curl | API 호출 | `curl --version` |
| jq | JSON 처리 | `jq --version` |

### 권장 도구

| 도구 | 용도 | 설치 |
|------|------|------|
| yq | YAML 처리 | `brew install yq` (macOS) |
| glab | GitLab CLI | `brew install glab` |
| pre-commit | 코드 품질 | `pip install pre-commit` |

---

## 토큰 발급

### Atlassian (Jira/Confluence) API 토큰

1. [Atlassian API Token 페이지](https://id.atlassian.com/manage-profile/security/api-tokens) 접속
2. "Create API token" 클릭
3. Label 입력 (예: `agent-context-demo`)
4. 생성된 토큰 복사

**중요:** 토큰은 한 번만 표시된다. 안전한 곳에 저장할 것.

### GitLab Access Token

1. GitLab 로그인 후 Settings -> Access Tokens 이동
2. Token name 입력 (예: `agent-context-demo`)
3. Scopes 선택:
   - `api` (필수)
   - `read_repository` (권장)
   - `write_repository` (MR 생성 시)
4. "Create personal access token" 클릭
5. 생성된 토큰 복사

---

## 시크릿 설정

### 디렉토리 생성

```bash
mkdir -p ~/.secrets
chmod 700 ~/.secrets
```

### 토큰 저장

```bash
# Atlassian API 토큰
echo "your-atlassian-api-token" > ~/.secrets/atlassian-api-token
chmod 600 ~/.secrets/atlassian-api-token

# GitLab Access Token
echo "your-gitlab-token" > ~/.secrets/gitlab-api-token
chmod 600 ~/.secrets/gitlab-api-token
```

### 환경 변수 설정

```bash
# ~/.bashrc 또는 ~/.zshrc에 추가
export JIRA_EMAIL="your-email@example.com"
```

### 검증

```bash
# 토큰 파일 확인
ls -la ~/.secrets/

# 권한 확인 (600이어야 함)
stat -f "%A %N" ~/.secrets/*  # macOS
stat -c "%a %n" ~/.secrets/*  # Linux
```

---

## 로컬 실행

### 기본 실행 (full 프로파일)

```bash
# E2E 포함 전체 실행
JIRA_EMAIL="your-email@example.com" ./demo/install.sh

# E2E 제외 실행
./demo/install.sh --skip-e2e

# minimal 프로파일
./demo/install.sh --profile minimal --skip-e2e
```

### 단계별 실행

```bash
# 5단계까지만 실행
./demo/install.sh --only 5

# 특정 단계만 실행 (수동)
./demo/installation/001-prereq.sh run
./demo/installation/001-prereq.sh verify
```

### 실행 결과 확인

```bash
# 설치 보고서
cat /tmp/agent-context-demo-*/installation-report.md

# 설치된 프로젝트
ls -la /tmp/agent-context-demo-*/any-project/
```

---

## Docker 실행

### Ubuntu 이미지

```bash
# 빌드
docker build -t agent-context-demo-ubuntu \
  -f demo/docker/ubuntu/Dockerfile \
  demo/docker/ubuntu

# 실행 (E2E 포함)
docker run --rm -it \
  -v ~/.secrets:/root/.secrets:ro \
  -e JIRA_EMAIL="your-email@example.com" \
  agent-context-demo-ubuntu \
  /agent-context/demo/install.sh

# 실행 (E2E 제외)
docker run --rm -it \
  -v ~/.secrets:/root/.secrets:ro \
  agent-context-demo-ubuntu \
  /agent-context/demo/install.sh --skip-e2e
```

### UBI9 이미지 (Red Hat 계열)

```bash
# 빌드
docker build -t agent-context-demo-ubi9 \
  -f demo/docker/ubi9/Dockerfile \
  demo/docker/ubi9

# 실행
docker run --rm -it \
  -v ~/.secrets:/root/.secrets:ro \
  -e JIRA_EMAIL="your-email@example.com" \
  agent-context-demo-ubi9 \
  /agent-context/demo/install.sh
```

### demo/install.sh 통합 실행

```bash
# Ubuntu에서 실행
JIRA_EMAIL="your-email@example.com" ./demo/install.sh --os ubuntu

# UBI9에서 실행
JIRA_EMAIL="your-email@example.com" ./demo/install.sh --os ubi9

# 모든 옵션
./demo/install.sh \
  --os ubuntu \
  --profile full \
  --force \
  --skip-e2e \
  --run-id "test-001"
```

---

## 트러블슈팅

### 401 Unauthorized (Jira API)

**원인:** 잘못된 이메일 또는 토큰

**해결:**
1. `JIRA_EMAIL`이 Atlassian 계정 이메일과 일치하는지 확인
2. API 토큰이 유효한지 확인
3. 토큰 파일에 줄바꿈이나 공백이 없는지 확인

```bash
# 토큰 테스트
curl -s -u "${JIRA_EMAIL}:$(cat ~/.secrets/atlassian-api-token)" \
  "https://your-domain.atlassian.net/rest/api/3/myself" | jq .
```

### 403 Forbidden (GitLab API)

**원인:** 토큰 권한 부족 또는 프로젝트 접근 권한 없음

**해결:**
1. GitLab 토큰에 `api` 스코프가 있는지 확인
2. 프로젝트에 접근 권한이 있는지 확인

```bash
# glab 인증 확인
glab auth status

# 수동 인증
glab auth login --token $(cat ~/.secrets/gitlab-api-token)
```

### Docker: secrets not mounted

**원인:** 볼륨 마운트 누락 또는 경로 오류

**해결:**
```bash
# 올바른 마운트 확인
docker run --rm -v ~/.secrets:/root/.secrets:ro ubuntu ls -la /root/.secrets
```

### pre-commit 실패

**원인:** 필수 도구 미설치 또는 코드 품질 이슈

**해결:**
- pre-commit은 best-effort로 실행되므로 데모 진행에는 영향 없음
- 필요 시 개별 훅 도구 설치: `shellcheck`, `black`, `isort` 등

### pm jira me 실패

**원인:** .project.yaml 설정 오류

**확인:**
```bash
# 설정 확인
./.agent/tools/pm/bin/pm config show

# 디버그 모드
DEBUG=1 ./.agent/tools/pm/bin/pm jira me
```

---

## 참고

- [체크리스트 SSOT](checklist.md)
- [아키텍처 문서](../../../docs/ARCHITECTURE.md)
- [Atlassian API Token 발급](https://id.atlassian.com/manage-profile/security/api-tokens)
- [GitLab Access Token 발급](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html)
