# Demo Directory

> **개발자/검증 전용** -- 이 디렉토리는 agent-context의 설치 과정 재현 및 E2E 검증을 위한 것입니다. 일반 사용자는 [README.md](../README.md)의 빠른 시작을 참고하세요.

> **E2E 테스트 경고:** E2E 테스트는 실제 Jira/GitLab/Confluence에 리소스를 생성/수정합니다. 권한, 쿼터, 네트워크, API Rate Limit 등의 사유로 실패가 정상일 수 있습니다. 실패 시 아래 [결과 해석 가이드](#결과-해석-가이드)를 먼저 확인하세요.

## 구조

```
demo/
├── .env.example           # 환경 변수 템플릿
├── .env                   # 실제 환경 설정 (gitignored)
├── install.sh             # 설치 데모 러너
├── run-docker-parallel.sh # 병렬 Docker 테스트 러너
├── verify-e2e-results.sh  # E2E 결과 검증
├── docker/                # Docker 이미지 정의
│   ├── ubuntu/            # Ubuntu 기반 이미지
│   └── ubi9/              # Red Hat UBI9 기반 이미지
├── installation/          # 설치 데모 (단계별 스크립트)
│   ├── README.md          # 설치 데모 가이드
│   ├── lib.sh             # 공통 라이브러리
│   └── 001-*.sh ~ 010-*.sh
├── scenario/              # E2E 시나리오 데모 (AITL)
│   ├── demo.sh            # 시나리오 실행 스크립트
│   ├── cleanup.sh         # 정리 스크립트
│   ├── lib/               # 시나리오 라이브러리
│   └── sample/            # 샘플 데이터
└── export/                # 데모 실행 결과 (로컬 전용)
    ├── runs/              # 실행별 결과
    └── latest/            # 최신 실행 결과
```

---

## 빠른 시작 (오프라인)

API 호출 없이 설치 과정만 검증합니다:

```bash
# E2E 제외, 6단계까지 (오프라인)
./demo/install.sh --skip-e2e --only 6

# 또는 agent-context 래퍼 사용
agent-context demo --skip-e2e --only 6
```

---

## 데모 토큰 설정

E2E 테스트를 실행하려면 데모 전용 계정의 토큰이 필요합니다.

### 1단계: demo/.env 생성

```bash
cp demo/.env.example demo/.env
# demo/.env 편집 (기본값은 데모 계정 URL이 이미 설정됨)
```

### 2단계: Secrets 파일 준비

```bash
mkdir -p ~/.secrets && chmod 700 ~/.secrets

# Atlassian API 토큰 (wonseok.ko@outlook.com 계정)
# 발급: https://id.atlassian.com/manage-profile/security/api-tokens
echo 'your-atlassian-token' > ~/.secrets/atlassian-api-token
chmod 600 ~/.secrets/atlassian-api-token

# GitLab API 토큰
# 발급: https://gitlab.com/-/user_settings/personal_access_tokens
echo 'your-gitlab-token' > ~/.secrets/gitlab-api-token
chmod 600 ~/.secrets/gitlab-api-token
```

### 환경변수 우선순위

`demo/.env`가 존재하면 `install.sh`와 `run-docker-parallel.sh`가 자동으로 로딩합니다.

| 우선순위 | 출처 | 예시 |
|:--------:|------|------|
| 1 (최고) | 명시적 `export` | `export JIRA_BASE_URL=https://...` |
| 2 | `demo/.env` 파일 | `JIRA_BASE_URL=https://wonseokko.atlassian.net` |
| 3 (최저) | 스크립트 기본값 | `:=` 연산자로 설정된 값 |

---

## 설치 데모 (installation/)

agent-context를 임의의 프로젝트에 설치하고 검증하는 데모입니다.

`demo/installation/`은 `demo/install.sh`가 실행하는 러너 스텝 모음(001-010)이며, E2E 시나리오의 실제 실행은 `demo/scenario/`가 담당합니다.

### 단계별 목적

| 단계 | 스크립트 | 목적 | 전제조건 |
|------|----------|------|----------|
| 001 | prereq | 의존성 확인 | 없음 |
| 002 | workdir | 작업 디렉토리 준비 | 001 |
| 003 | install | `install.sh` 실행 | 002 |
| 004 | configure | `.project.yaml` 설정 | 003 |
| 005 | pm-test | PM CLI 연결 테스트 | 004 + 네트워크 |
| 006 | static-tests | 정적 검사 (doctor, tests) | 003 |
| 007 | demo-check | E2E 전제조건 확인 | 004 |
| 008 | demo-run | E2E 시나리오 실행 | 007 + 네트워크 |
| 009 | precommit | pre-commit 검사 (best-effort) | 003 |
| 010 | summary | 결과 리포트 생성 | 모든 단계 |

### 실행 방법

```bash
# 전체 실행
./demo/install.sh

# E2E 제외 (오프라인)
./demo/install.sh --skip-e2e

# 통합 모드 (오프라인 + E2E optional)
# 오프라인 단계를 항상 수행, E2E 전제조건 충족 시에만 E2E 추가 실행
./demo/install.sh --e2e-optional

# Docker에서 실행
./demo/install.sh --os ubuntu
./demo/install.sh --os ubi9
```

자세한 내용은 [설치 데모 가이드](installation/README.md) 참조.

---

## AITL 시나리오 (scenario/)

Jira/GitLab/Confluence E2E 시나리오 데모입니다. 설치 데모(installation/)와는 별도의 시나리오입니다.

```bash
# 의존성 확인
./demo/scenario/demo.sh check

# 시나리오 실행
./demo/scenario/demo.sh run
```

자세한 내용은 [시나리오 README](scenario/README.md) 참조.

---

## Docker 테스트 (run-docker-parallel.sh)

Ubuntu와 UBI9(RedHat) Docker를 동시/순차 실행하여 설치 + E2E 테스트를 수행합니다.

### 기본 실행

```bash
# E2E 포함 (순차 권장 -- 리소스 충돌 방지)
export JIRA_EMAIL="wonseok.ko@outlook.com"
./demo/run-docker-parallel.sh --serial

# 오프라인 병렬 테스트
./demo/run-docker-parallel.sh --skip-e2e

# 특정 단계까지만
./demo/run-docker-parallel.sh --skip-e2e --only 6
```

### 옵션

| 옵션 | 설명 |
|------|------|
| `--serial` | 순차 실행 (Ubuntu 먼저, 성공 시 UBI9) |
| `--skip-e2e` | E2E 데모 단계 건너뛰기 |
| `--only <step>` | 특정 단계만 실행 (예: `--only 008`) |
| `--jira-project <key>` | Jira 프로젝트 키 지정 (기본: `SVI4`) |
| `--gitlab-group <path>` | GitLab 그룹 경로 지정 (기본: `soc-ip/agentic-ai`) |

### 출력 구조

```
/tmp/agent-context-parallel-<timestamp>/
├── ubuntu/                    # Ubuntu 테스트 결과
│   ├── docker-build.log       # Docker 빌드 로그
│   ├── docker-run.log         # 컨테이너 실행 로그
│   ├── installation-report.md
│   └── demo-output/           # E2E 시나리오 결과
├── ubi9/                      # UBI9 테스트 결과
│   └── ...
└── parallel-summary.md        # 통합 요약 리포트
```

### 결과 검증

```bash
export JIRA_EMAIL="wonseok.ko@outlook.com"
./demo/verify-e2e-results.sh
```

### 리소스 재생성/정리 동작

기본값(`RECREATE_*=true`, `SKIP_CLEANUP=true`) 기준 동작:

| 리소스 | 동작 |
|--------|------|
| GitLab repo | `demo-agent-context-install-*` 패턴 영구 삭제 후 재생성 |
| Jira boards | `demo-agent-context-install*` 보드/필터 삭제 후 재생성 |
| Jira issues | 자동 정리는 제한적이며 실행 이력이 누적될 수 있음 (필요 시 수동 정리 권장) |
| Docker 이미지 | `--no-cache`로 매번 새로 빌드 |
| WORKDIR | OS별 분리 (`/tmp/...-ubuntu`, `/tmp/...-ubi9`) |

---

## 결과 해석 가이드

### 성공/실패 판단 기준

| 출력 마커 | 의미 | 조치 |
|-----------|------|------|
| `[V]` | 통과 | 정상 |
| `[X]` | 실패 | 아래 원인 확인 |
| `[!]` | 경고 | 기능에 영향 없음, 확인 권장 |
| `[-]` | 건너뜀 | 전제조건 미충족 (정상일 수 있음) |

### E2E 실패가 정상인 경우

다음 상황에서는 E2E 실패가 예상되며, 정상입니다:

| 상황 | 증상 | 대응 |
|------|------|------|
| Atlassian 토큰 미설정 | `[X] auth` 실패 | `~/.secrets/atlassian-api-token` 설정 |
| GitLab 토큰 미설정 | `[X] glab auth` 실패 | `~/.secrets/gitlab-api-token` 설정 |
| 네트워크 차단 | `[X] connect` 실패 | `--skip-e2e` 사용 |
| API Rate Limit | `[X]` 간헐적 실패 | 시간을 두고 재시도 |
| GitLab 프로젝트 삭제 대기 중 | `[X]` 이름 충돌 | 7일 대기 또는 다른 RUN_ID 사용 |

### 오프라인 단계 실패 시

001~006 단계가 실패하면 실제 문제입니다:

```bash
# 실패 로그 확인
cat /tmp/agent-context-demo-*/docker-run.log | tail -50

# 특정 단계 재시도
WORKDIR=/tmp/agent-context-demo-xxx ./demo/install.sh --only 003
```

### 주요 확인 명령어

```bash
# 요약 보기
cat /tmp/agent-context-parallel-*/parallel-summary.md

# 실패 시 로그 확인
cat /tmp/agent-context-parallel-*/ubuntu/docker-run.log | tail -100
cat /tmp/agent-context-parallel-*/ubi9/docker-run.log | tail -100
```

---

## `agent-context demo` 래퍼

`agent-context demo` 명령은 `demo/install.sh`의 래퍼입니다:

```bash
# 다음 두 명령은 동일
agent-context demo --skip-e2e
./demo/install.sh --skip-e2e

# Docker 실행
agent-context demo --os ubuntu --skip-e2e
```

---

## Docker 환경 (docker/)

Ubuntu 및 UBI9 기반 테스트 환경.

### 베이스 이미지 및 툴 버전 (고정)

| 구분 | Ubuntu | UBI9 (RHEL) |
|------|--------|-------------|
| Base Image | `ubuntu:22.04` | `registry.access.redhat.com/ubi9/ubi:latest` |
| Python | 3.x (distro) | 3.x (distro) |

| 패키지 | 버전 | 용도 | 설치 방식 |
|--------|------|------|-----------|
| glab | 1.81.0 | GitLab CLI | tarball (amd64/arm64) |
| yq | v4.40.5 | YAML 처리 | binary |
| jq | (distro) | JSON 처리 | apt/dnf |
| pandoc | 3.1.11 (UBI9) | Markdown 변환 | apt/tarball |
| openssh-client | (distro) | Git SSH clone/push | apt/dnf |
| pre-commit | (pip) | 코드 품질 검사 | pip3 |

### Docker 실행 시 마운트

| 호스트 경로 | 컨테이너 경로 | 모드 | 용도 |
|-------------|---------------|------|------|
| `~/.secrets` | `/root/.secrets` | ro | API 토큰 |
| `~/.ssh` | `/root/.ssh` | ro | Git SSH 키 |
| `${WORKDIR}` | `${WORKDIR}` | rw | 로그/결과물 지속성 |

---

## 환경 변수

`.env.example`을 복사하여 `.env`로 사용:

```bash
cp demo/.env.example demo/.env
# .env 파일 편집
```

**주의:** `.env` 파일은 git에 커밋하지 않음 (`.gitignore`에 포함됨).

### 필수/선택 환경 변수

| 변수 | 설명 | E2E 필수 |
|------|------|:--------:|
| `JIRA_EMAIL` | Atlassian 계정 이메일 | O |
| `JIRA_BASE_URL` | Jira 기본 URL | - |
| `JIRA_PROJECT_KEY` | Jira 프로젝트 키 | - |
| `CONFLUENCE_BASE_URL` | Confluence 기본 URL | - |
| `CONFLUENCE_SPACE_KEY` | Confluence 스페이스 키 | - |
| `GITLAB_BASE_URL` | GitLab 서버 URL | - |
| `GITLAB_PROJECT` | GitLab 프로젝트 경로 | - |

### 데모 시나리오 환경 변수

E2E 시나리오 (Step 008) 실행 시 사용되는 추가 환경 변수:

| 변수 | 설명 |
|------|------|
| `DEMO_REPO_NAME` | GitLab 저장소 이름 |
| `DEMO_JIRA_PROJECT` | 데모용 Jira 프로젝트 키 |
| `DEMO_GITLAB_GROUP` | GitLab 그룹/네임스페이스 |
| `DEMO_CONFLUENCE_SPACE` | 데모용 Confluence 스페이스 |
| `RECREATE_REPO` | GitLab repo 삭제 후 재생성 (`true`/`false`) |
| `RECREATE_BOARD` | Jira board 삭제 후 재생성 (`true`/`false`) |
| `RECREATE_ISSUES` | Jira issues 삭제 후 재생성 (`true`/`false`) |
| `SKIP_CLEANUP` | 정리 단계 건너뛰기 (`true`/`false`) |
| `HITL_ENABLED` | Human-in-the-Loop 활성화 |

---

## 제약사항

### 1. 병렬 실행 시 Race Condition

병렬 모드에서 Ubuntu와 UBI9 테스트가 동시에 실행되면:
- 동일한 Jira 보드를 삭제/생성하려 시도
- GitLab 리소스 충돌 가능

**권장: `--serial` 옵션 사용**

### 2. GitLab 프로젝트 삭제 지연

GitLab에서 삭제된 프로젝트는 즉시 삭제되지 않고 "scheduled for deletion" 상태가 됩니다.
- 기본 7일 후 완전 삭제
- 같은 이름으로 재생성 시 충돌 발생 가능

대응 방법:
1. 다른 Run ID 사용 (`--jira-project` 옵션으로 다른 프로젝트 지정)
2. GitLab Admin에서 즉시 삭제 요청
3. 충분한 시간 간격 두기 (7일 대기)

### 3. Jira API Eventual Consistency

Jira 보드/필터 생성 후 즉시 조회하면 404가 발생할 수 있습니다.
- 코드에 retry 로직 포함 (최대 3회, 1초 간격)

### 4. SSH Signing 필수 환경

GitLab 서버에서 commit 서명이 필수로 설정된 경우:
- SSH 키로 commit signing 자동 설정됨
- `~/.ssh/id_ed25519.pub` 파일 필수

### 5. Network 요구사항

Docker 컨테이너에서 다음 호스트에 접근 가능해야 합니다:
- `gitlab.com` (SSH: 22, HTTPS: 443)
- `wonseokko.atlassian.net` (HTTPS: 443)

---

## 리소스 정리

테스트 후 생성된 리소스를 정리하려면:

### Jira 리소스

```bash
# 보드 삭제 (API)
pm jira board delete <board-id>

# 이슈 삭제 (웹 UI에서 Bulk Delete 권장)
```

Jira 이슈 Bulk Delete 권장 흐름(웹 UI):
- Issue Navigator에서 JQL로 대상만 필터링 후 Bulk delete
- 예시 JQL:

```text
project = SVI4 AND summary ~ "demo-agent-context-install"
```

### GitLab 리소스

```bash
# 프로젝트 삭제
glab api -X DELETE "projects/<project-id>"

# 또는 웹 UI에서 Settings > General > Delete project
```

### 프로젝트 키 분리 실행 팁

같은 Jira 프로젝트에서 반복 실행하면 이슈가 누적됩니다. E2E 전용 프로젝트 키로 분리 실행을 권장합니다:

```bash
export JIRA_EMAIL="wonseok.ko@outlook.com"
export JIRA_PROJECT_KEY="SVI4E2E"
export DEMO_JIRA_PROJECT="SVI4E2E"
./demo/run-docker-parallel.sh --serial
```

---

## 문제 해결

### SSH 연결 실패

```
[X] SSH preflight check failed
```

1. SSH 키가 `~/.ssh/id_ed25519`에 있는지 확인
2. GitLab에 SSH 키가 등록되었는지 확인
3. `ssh -T git@gitlab.com`으로 수동 테스트

### MR 생성 실패

```
{"message":{"source_branch":["is invalid"]}}
```

- Branch가 main과 동일한 상태인지 확인
- GitLab에서 해당 branch 존재 여부 확인

### Jira Board 생성 실패

```
[X] Jira board verification failed
```

- Jira 프로젝트 권한 확인
- Atlassian Token 유효성 확인

---

## 관련 문서

- [README.md](../README.md) -- 빠른 시작
- [docs/USER_GUIDE.md](../docs/USER_GUIDE.md) -- 사용자 가이드
- [docs/TESTING_GUIDE.md](../docs/TESTING_GUIDE.md) -- 테스트 가이드 (`tests` 명령 시나리오)
- [installation/README.md](installation/README.md) -- 설치 데모 상세
- [scenario/README.md](scenario/README.md) -- AITL 시나리오 상세

*Last Updated: 2026-02-06*
