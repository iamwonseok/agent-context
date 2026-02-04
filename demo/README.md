# Demo Directory

agent-context 데모 및 테스트 환경을 위한 디렉토리.

## 구조

```
demo/
├── .env.example           # 환경 변수 템플릿
├── install.sh             # 설치 데모 러너
├── run-docker-parallel.sh # 병렬 Docker 테스트 러너
├── docker/                # Docker 이미지 정의
│   ├── ubuntu/            # Ubuntu 기반 이미지
│   └── ubi9/              # Red Hat UBI9 기반 이미지
├── installation/          # 설치 데모 (단계별 스크립트)
│   ├── README.md          # 설치 데모 가이드
│   ├── lib.sh             # 공통 라이브러리
│   └── 001-*.sh ~ 010-*.sh
├── scenario/              # E2E 시나리오 데모
│   ├── demo.sh            # 시나리오 실행 스크립트
│   ├── cleanup.sh         # 정리 스크립트
│   ├── lib/               # 시나리오 라이브러리
│   └── sample/            # 샘플 데이터
└── export/                # 데모 실행 결과 (로컬 전용)
    ├── runs/              # 실행별 결과
    └── latest/            # 최신 실행 결과
```

## 설치 데모 (installation/)

agent-context를 임의의 프로젝트에 설치하고 검증하는 데모.

`demo/installation/`은 `demo/install.sh`가 실행하는 **러너 스텝 모음(001-010)** 이며, E2E 시나리오의 실제 실행은 `demo/scenario/`가 담당합니다.

```bash
# 전체 실행
./demo/install.sh

# E2E 제외 (오프라인)
./demo/install.sh --skip-e2e

# 통합 모드 (오프라인 + E2E optional)
# - 오프라인(설치/정적검증)을 항상 수행
# - E2E 전제조건이 충족되면 E2E까지 수행, 아니면 E2E는 스킵
./demo/install.sh --e2e-optional

# Docker에서 실행
./demo/install.sh --os ubuntu
./demo/install.sh --os ubi9
```

자세한 내용은 [설치 데모 가이드](installation/README.md) 참조.

## 병렬 Docker 테스트 (run-docker-parallel.sh)

Ubuntu와 UBI9(RedHat) Docker를 동시에 실행하여 설치 + E2E 테스트를 병렬로 수행.

E2E 테스트 전제조건(필수 secrets/SSH 키/네트워크)과 권장 실행 방식은
아래 "E2E Test Guide" 섹션 참고.

```bash
# E2E 포함 병렬 테스트
export JIRA_EMAIL="your-email@example.com"
./demo/run-docker-parallel.sh

# 오프라인 병렬 테스트
./demo/run-docker-parallel.sh --skip-e2e

# 특정 단계까지만
./demo/run-docker-parallel.sh --skip-e2e --only 6
```

권장 실행 (리소스 충돌 방지, 순차 모드):

```bash
export JIRA_EMAIL="your-email@example.com"
./demo/run-docker-parallel.sh --serial
```

결과 검증:

```bash
export JIRA_EMAIL="your-email@example.com"
./demo/verify-e2e-results.sh
```

### 출력 구조

```
/tmp/agent-context-parallel-<timestamp>/
├── ubuntu/                    # Ubuntu 테스트 결과
│   ├── docker-build.log       # Docker 빌드 로그
│   ├── docker-run.log         # 컨테이너 실행 로그
│   ├── installation-report.md
│   └── demo-output/           # E2E 시나리오 결과
├── ubi9/                      # UBI9 테스트 결과
│   ├── docker-build.log
│   ├── docker-run.log
│   ├── installation-report.md
│   └── demo-output/
└── parallel-summary.md        # 통합 요약 리포트
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

수동 정리 방법은 아래 "리소스 정리" 섹션 참고.

## E2E Test Guide

Agent-Context Demo E2E 테스트 실행 가이드.

### 관리자 문의가 필요한 필수 전제조건

E2E는 실제 Jira/GitLab/Confluence에 리소스를 생성/수정합니다. 아래 항목이 준비되지 않으면 실패가 정상이며, 발급/권한/등록은 조직의 시스템 관리자(또는 Jira/GitLab/Confluence 관리자)에게 문의해야 할 수 있습니다.

필수(공통):
- `JIRA_EMAIL` (Atlassian 계정 이메일)
- `~/.secrets/atlassian-api-token` (Atlassian API token, 권한 600 권장)

GitLab 통합(E2E에서 Git 작업 포함 시):
- `~/.secrets/gitlab-api-token` (GitLab personal access token, scope: `api` 권장)
- `~/.ssh/id_ed25519`, `~/.ssh/id_ed25519.pub` (passphrase 없는 키, GitLab SSH Keys에 등록 필요)
- (조직 정책에 따라) commit signing/보호 브랜치/MR 승인 규칙 충족 필요

프로젝트/스페이스 정보(환경에 맞게 설정):
- Jira 프로젝트 키(`JIRA_PROJECT_KEY` 또는 `DEMO_JIRA_PROJECT`)
- Confluence space key(`CONFLUENCE_SPACE_KEY` 또는 `DEMO_CONFLUENCE_SPACE`)

---

### 실행 방법

#### 기본 실행 (순차 모드 권장)

```bash
JIRA_EMAIL="your-email@example.com" ./demo/run-docker-parallel.sh --serial
```

#### 병렬 실행

```bash
JIRA_EMAIL="your-email@example.com" ./demo/run-docker-parallel.sh
```

#### 결과 검증

```bash
JIRA_EMAIL="your-email@example.com" ./demo/verify-e2e-results.sh
```

---

### 필수 환경 변수

| 변수 | 설명 | 예시 |
|------|------|------|
| `JIRA_EMAIL` | Jira/Atlassian 계정 이메일 (필수) | `wonseok@fadutec.com` |

#### 자동 설정되는 변수

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `GIT_USER_NAME` | `${JIRA_EMAIL%%@*}` | Git commit author name |
| `GIT_USER_EMAIL` | `${JIRA_EMAIL}` | Git commit author email |

---

### 필수 Secrets

`~/.secrets/` 디렉토리에 다음 파일들이 필요합니다:

| 파일 | 내용 |
|------|------|
| `atlassian-api-token` | Atlassian API Token |
| `gitlab-api-token` | GitLab Personal Access Token |

#### Secrets 생성 방법

```bash
mkdir -p ~/.secrets
echo "your-atlassian-token" > ~/.secrets/atlassian-api-token
echo "your-gitlab-token" > ~/.secrets/gitlab-api-token
chmod 600 ~/.secrets/*
```

---

### SSH 키 요구사항

Docker 컨테이너는 GitLab에 SSH로 접근합니다. 호스트의 `~/.ssh` 디렉토리가 read-only로 마운트됩니다.

#### 필수 파일

| 파일 | 설명 |
|------|------|
| `~/.ssh/id_ed25519` | SSH Private Key |
| `~/.ssh/id_ed25519.pub` | SSH Public Key (commit signing에 사용) |

#### 제약사항

- **Passphrase 없는 SSH 키만 지원** (Docker 환경에서 passphrase 입력 불가)
- SSH 키는 GitLab에 등록되어 있어야 함
- SSH 키로 commit signing이 설정됨 (GitLab GPG 서명 요구사항 충족)

#### SSH 키 생성 (없는 경우)

```bash
ssh-keygen -t ed25519 -C "your-email@example.com" -N ""
# GitLab Settings > SSH Keys 에 public key 등록
```

---

### 옵션

| 옵션 | 설명 |
|------|------|
| `--serial` | 순차 실행 (Ubuntu 먼저, 성공 시 UBI9) |
| `--skip-e2e` | E2E 데모 단계 건너뛰기 |
| `--only <step>` | 특정 단계만 실행 (예: `--only 008`) |
| `--jira-project <key>` | Jira 프로젝트 키 지정 (기본: `SVI4`) |
| `--gitlab-group <path>` | GitLab 그룹 경로 지정 (기본: `soc-ip/agentic-ai`) |

---

### Fail-Fast 동작

다음 작업이 실패하면 **즉시 테스트가 중단**됩니다:

| 작업 | 검증 방식 | 실패 시 |
|------|----------|---------|
| Jira Epic/Task 생성 | `pm_ws jira issue view <key>` | `[X]` + 즉시 종료 |
| Jira Board 생성 | `jira_ws_api GET /board/<id>` (3회 retry) | `[X]` + 즉시 종료 |
| GitLab Repository 생성 | `glab api projects/<id>` | `[X]` + 즉시 종료 |
| GitLab Issue 생성 | `glab api projects/<id>/issues/<iid>` | `[X]` + 즉시 종료 |
| Git Branch Push | `git ls-remote origin refs/heads/<branch>` | `[X]` + 즉시 종료 |
| GitLab MR 생성 | `glab api projects/<id>/merge_requests/<iid>` | `[X]` + 즉시 종료 |

검증 로그 형식:

```
<verify> GitLab issue #123 exists ... [V]   # 성공
<verify> GitLab MR !456 exists ... [X]      # 실패 -> 즉시 종료
```

---

### 제약사항

#### 1. 병렬 실행 시 Race Condition

병렬 모드에서 Ubuntu와 UBI9 테스트가 동시에 실행되면:
- 동일한 Jira 보드를 삭제/생성하려 시도
- GitLab 리소스 충돌 가능

**권장: `--serial` 옵션 사용**

#### 2. GitLab 프로젝트 삭제 지연

GitLab에서 삭제된 프로젝트는 즉시 삭제되지 않고 "scheduled for deletion" 상태가 됩니다.
- 기본 7일 후 완전 삭제
- 같은 이름으로 재생성 시 충돌 발생 가능
- **삭제 예정 상태의 repo를 사용하려고 하면 즉시 에러로 중단됨**

대응 방법:
1. 다른 Run ID 사용 (`--jira-project` 옵션으로 다른 프로젝트 지정)
2. GitLab Admin에서 즉시 삭제 요청
3. 충분한 시간 간격 두기 (7일 대기)

#### 3. Jira API Eventual Consistency

Jira 보드/필터 생성 후 즉시 조회하면 404가 발생할 수 있습니다.
- 코드에 retry 로직 포함 (최대 3회, 1초 간격)

#### 4. GitLab GPG/SSH Signing 필수

GitLab 서버에서 commit 서명이 필수로 설정된 경우:
- SSH 키로 commit signing 자동 설정됨
- `~/.ssh/id_ed25519.pub` 파일 필수

#### 5. Network 요구사항

Docker 컨테이너에서 다음 호스트에 접근 가능해야 합니다:
- `gitlab.fadutec.dev` (SSH: 22, HTTPS: 443)
- `fadutec.atlassian.net` (HTTPS: 443)

---

### 결과 확인

#### 테스트 출력 디렉토리

```
/tmp/agent-context-parallel-<timestamp>/
├── ubuntu/
│   ├── docker-run.log      # 실행 로그
│   ├── parallel-runner.log # 상세 로그
│   └── demo-output/        # 데모 결과물
└── ubi9/
    └── ...
```

#### 주요 확인 명령어

```bash
# 요약 보기
cat /tmp/agent-context-parallel-*/parallel-summary.md

# 실패 시 로그 확인
cat /tmp/agent-context-parallel-*/ubuntu/docker-run.log | tail -100
cat /tmp/agent-context-parallel-*/ubi9/docker-run.log | tail -100
```

---

### 문제 해결

#### SSH 연결 실패

```
[X] SSH preflight check failed
```

1. SSH 키가 `~/.ssh/id_ed25519`에 있는지 확인
2. GitLab에 SSH 키가 등록되었는지 확인
3. `ssh -T git@gitlab.fadutec.dev`로 수동 테스트

#### MR 생성 실패

```
{"message":{"source_branch":["is invalid"]}}
```

- Branch가 main과 동일한 상태인지 확인
- GitLab에서 해당 branch 존재 여부 확인

#### Jira Board 생성 실패

```
[X] Jira board verification failed
```

- Jira 프로젝트 권한 확인
- Atlassian Token 유효성 확인

---

### 리소스 정리

테스트 후 생성된 리소스를 정리하려면:

#### Jira 리소스

```bash
# 보드 삭제 (API)
pm jira board delete <board-id>

# 이슈 삭제 (웹 UI에서 Bulk Delete 권장)
```

`<board-id>` 확인 방법:

- `./demo/run-docker-parallel.sh` 실행 로그의 `Created Jira board: ... (id: NNNN)`
- `./demo/verify-e2e-results.sh` 출력의 `Board exists: ... (id: NNNN)`

Jira 이슈 Bulk Delete 권장 흐름(웹 UI):

- Issue Navigator에서 JQL로 대상만 필터링 후 Bulk delete
- 예시 JQL (프로젝트 키는 환경에 맞게 변경):

```text
project = SVI4 AND summary ~ "demo-agent-context-install"
```

#### GitLab 리소스

```bash
# 프로젝트 삭제
glab api -X DELETE "projects/<project-id>"

# 또는 웹 UI에서 Settings > General > Delete project
```

#### 프로젝트 키 분리 실행 팁 (이슈/보드 누적 방지)

같은 Jira 프로젝트에서 반복 실행하면 이슈가 누적되기 쉬워서, 가능하면 E2E 전용 프로젝트 키로 분리해서 실행하는 것을 권장합니다:

```bash
export JIRA_EMAIL="your-email@example.com"
export JIRA_PROJECT_KEY="SVI4E2E"     # 사전에 존재하는 Jira 프로젝트 키 사용
export DEMO_JIRA_PROJECT="SVI4E2E"    # (기본값: JIRA_PROJECT_KEY)
./demo/run-docker-parallel.sh --serial
```

자동 삭제/재생성을 줄이고 싶다면(기존 리소스 보호):

```bash
export RECREATE_BOARD=false
export RECREATE_ISSUES=false
export RECREATE_REPO=false
./demo/run-docker-parallel.sh --serial
```

---

*Last Updated: 2026-02-04*

## 시나리오 데모 (scenario/)

Jira/GitLab/Confluence E2E 시나리오 데모.

```bash
# 의존성 확인
./demo/scenario/demo.sh check

# 시나리오 실행
./demo/scenario/demo.sh run
```

자세한 내용은 [시나리오 README](scenario/README.md) 참조.

## Docker 환경 (docker/)

Ubuntu 및 UBI9 기반 테스트 환경.

### 베이스 이미지 및 툴 버전 (고정)

재현 가능한 테스트를 위해 다음 버전을 고정합니다:

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

### 이미지 빌드

```bash
# Ubuntu 이미지 빌드
docker build -t agent-context-demo-ubuntu -f demo/docker/ubuntu/Dockerfile demo/docker/ubuntu

# UBI9 이미지 빌드
docker build -t agent-context-demo-ubi9 -f demo/docker/ubi9/Dockerfile demo/docker/ubi9
```

**참고:** `install.sh --os <os>`로 실행하면 항상 `--pull --no-cache`로 클린 빌드를 수행합니다.

### Docker 실행 시 마운트

| 호스트 경로 | 컨테이너 경로 | 모드 | 용도 |
|-------------|---------------|------|------|
| `~/.secrets` | `/root/.secrets` | ro | API 토큰 |
| `~/.ssh` | `/root/.ssh` | ro | Git SSH 키 |
| `${WORKDIR}` | `${WORKDIR}` | rw | 로그/결과물 지속성 |

### 실행 예시

```bash
# 기본 실행 (E2E 제외)
./demo/install.sh --os ubuntu --skip-e2e

# E2E 포함 실행 (실시간 로그 스트리밍)
./demo/install.sh --os ubuntu

# 특정 단계만 실행
./demo/install.sh --os ubuntu --only 008
```

로그는 다음 위치에 저장되며, 실행 중 실시간으로 출력됩니다:

- `${WORKDIR}/docker-build.log` - Docker 이미지 빌드 로그
- `${WORKDIR}/docker-run.log` - 컨테이너 실행 로그 (설치 + E2E)

## 환경 변수

`.env.example`을 복사하여 `.env`로 사용:

```bash
cp demo/.env.example demo/.env
# .env 파일 편집
```

**주의:** `.env` 파일은 git에 커밋하지 않음.

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

## Export 디렉토리 (export/)

시나리오 데모 실행 시 생성되는 결과물 저장 디렉토리.

```
export/
├── runs/              # 실행별 격리된 결과
│   └── <DEMO_REPO_NAME>/  # e.g., demo-agent-context-install-ubuntu
│       ├── jira/          # Jira 이슈 내보내기
│       ├── DASHBOARD.md
│       └── DEMO_REPORT.md
└── latest/            # 최신 실행 결과 (심볼릭 링크)
    ├── DASHBOARD.md
    └── DEMO_REPORT.md
```

**정책:**
- 로컬 전용 디렉토리 (git에 커밋되지 않음)
- `.gitignore`에 `demo/export/` 포함됨
- 각 실행은 `DEMO_REPO_NAME`으로 식별
- `latest/`는 최근 실행 결과를 빠르게 확인하기 위한 심볼릭 링크

**결과 확인:**

```bash
# 최신 대시보드 확인
cat demo/export/latest/DASHBOARD.md

# 특정 실행 결과 확인
cat demo/export/runs/20260201-143052/DEMO_REPORT.md
```
