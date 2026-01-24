# Agent-Context Tests

Docker 기반 테스트 환경입니다.

## 테스트 단계

| Stage | 이름 | 의존성 | 설명 |
|-------|------|--------|------|
| 1 | Smoke | 없음 | bootstrap, setup, CLI 기본 동작 |
| 2 | Local Git | Git (bare repo) | 브랜치 워크플로우, push, rebase |
| 3 | E2E | GitLab/JIRA 토큰 | MR 생성, 이슈 연동 |

## 빠른 시작

### Docker로 실행 (권장)

```bash
# 이미지 빌드
docker compose -f tests/docker-compose.test.yml build

# Stage 1-2 실행 (토큰 불필요)
docker compose -f tests/docker-compose.test.yml run all

# 개별 Stage 실행
docker compose -f tests/docker-compose.test.yml run smoke
docker compose -f tests/docker-compose.test.yml run local-git

# Stage 3 (토큰 필요)
export GITLAB_API_TOKEN=<your-token>
export GITLAB_URL=https://gitlab.com
docker compose -f tests/docker-compose.test.yml run e2e
```

### 로컬 실행

```bash
# Stage 1-2 (기본)
./tests/run-tests.sh

# 특정 Stage만
./tests/run-tests.sh --stages=1

# 모든 Stage (토큰 필요)
export GITLAB_API_TOKEN=<your-token>
./tests/run-tests.sh --all
```

## 테스트 상세

### Stage 1: Smoke Tests

토큰/리모트 없이 기본 동작 확인:

- `bootstrap.sh` 실행 가능
- `setup.sh`로 프로젝트 파일 생성
- `setup.sh` 재실행 안전성 (idempotent)
- `agent --version`, `agent --help`
- `agent status`
- `agent dev start` (브랜치 생성, `.context/` 생성)

### Stage 2: Local Git Tests

로컬 bare repo를 리모트로 사용하여 Git 워크플로우 테스트:

- Bare repo 생성 및 clone
- `agent dev start` → 브랜치 생성
- `agent dev commit` → 커밋
- `git push` → 리모트 push
- `agent dev sync` → rebase
- 선형 히스토리 검증

### Stage 3: E2E Tests

실제 GitLab/JIRA 연동 테스트:

- GitLab API 연결
- `agent dev submit` → MR 생성
- 이슈 연동

**필요 환경변수:**

```bash
export GITLAB_API_TOKEN=<personal-access-token>
export GITLAB_URL=https://gitlab.com  # 또는 self-hosted URL
export JIRA_API_TOKEN=<atlassian-api-token>  # optional
export JIRA_URL=https://your-org.atlassian.net  # optional
```

## 디렉터리 구조

```
tests/
├── Dockerfile.test           # 테스트 환경 정의
├── docker-compose.test.yml   # Docker Compose 설정
├── run-tests.sh              # 테스트 러너
├── README.md                 # 이 문서
├── smoke/
│   └── test_smoke.sh         # Stage 1
├── local-git/
│   └── test_local_git.sh     # Stage 2
└── e2e/
    └── test_e2e.sh           # Stage 3
```

## CI/CD 연동

`.gitlab-ci.yml`에서 사용:

```yaml
test:smoke:
  stage: test
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker compose -f tests/docker-compose.test.yml build
    - docker compose -f tests/docker-compose.test.yml run smoke
    - docker compose -f tests/docker-compose.test.yml run local-git

test:e2e:
  stage: test
  image: docker:latest
  services:
    - docker:dind
  variables:
    GITLAB_API_TOKEN: $CI_JOB_TOKEN
    GITLAB_URL: $CI_SERVER_URL
  script:
    - docker compose -f tests/docker-compose.test.yml build
    - docker compose -f tests/docker-compose.test.yml run e2e
  only:
    - main
```
