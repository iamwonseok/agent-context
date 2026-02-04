# Demo Installation Runner

agent-context 설치 데모를 실행하는 러너입니다.

이 러너는 **installation steps(001-006)** + **e2e steps(007-008)** 를 포함합니다. E2E의 실제 시나리오 실행은 `demo/scenario/`가 담당합니다.

## Quick Start

```bash
# 1. 오프라인 모드 (E2E 테스트 제외)
./demo/install.sh --skip-e2e

# 1.5 통합 모드 (오프라인 + E2E optional)
# - 오프라인(설치/정적검증)을 항상 수행
# - E2E 전제조건이 충족되면 E2E까지 수행, 아니면 E2E는 스킵
./demo/install.sh --e2e-optional

# 2. 특정 단계까지만 실행
./demo/install.sh --skip-e2e --only 6

# 3. Docker에서 실행 (Ubuntu)
./demo/install.sh --os ubuntu --skip-e2e

# 4. Ubuntu/UBI9 병렬 테스트 (권장)
export JIRA_EMAIL="your-email@example.com"
./demo/run-docker-parallel.sh
```

## 단계별 설명

| Step | Script | Description |
|------|--------|-------------|
| 001 | prereq.sh | 필수 도구 및 시크릿 확인 |
| 002 | workdir.sh | 작업 디렉토리 준비 |
| 003 | install.sh | agent-context 설치 실행 |
| 004 | configure.sh | .project.yaml 설정 |
| 005 | pm-test.sh | PM CLI 연결 테스트 |
| 006 | static-tests.sh | 정적 테스트 (skills/workflows 검증) |
| 007 | demo-check.sh | 데모 전제조건 확인 |
| 008 | demo-run.sh | E2E 데모 실행 |
| 009 | precommit.sh | Pre-commit 훅 실행 (best-effort) |
| 010 | summary.sh | 결과 요약 리포트 |

구분:
- 001-006: installation steps (오프라인 가능)
- 007-008: e2e steps (내부에서 `demo/scenario/` 실행)

## 사용법

### 기본 실행

```bash
# 전체 실행 (E2E 포함)
export JIRA_EMAIL="your-email@example.com"
./demo/install.sh

# 오프라인 모드 (시크릿 없이 테스트)
./demo/install.sh --skip-e2e
```

### 단계별 실행

```bash
# 설치까지만 (Step 1-3)
./demo/install.sh --skip-e2e --only 3

# 정적 테스트까지 (Step 1-6)
./demo/install.sh --skip-e2e --only 6

# 특정 작업 디렉토리 사용
./demo/install.sh --skip-e2e --workdir /tmp/my-test
```

### Docker 실행

```bash
# Ubuntu 컨테이너 (오프라인)
./demo/install.sh --os ubuntu --skip-e2e

# UBI9 컨테이너 (RHEL-based)
./demo/install.sh --os ubi9 --skip-e2e

# E2E 포함 실행 (실시간 로그 스트리밍)
export JIRA_EMAIL="your-email@example.com"
./demo/install.sh --os ubuntu

# 특정 단계만 실행
./demo/install.sh --os ubuntu --only 008

# GitLab 통합 E2E 실행
export JIRA_EMAIL="your-email@example.com"
export DEMO_GITLAB_GROUP="your-group/subgroup"
./demo/install.sh --os ubuntu
```

Docker 실행 시 자동 마운트:

| 경로 | 용도 |
|------|------|
| `~/.secrets` | API 토큰 (read-only) |
| `~/.ssh` | Git SSH 키 (read-only) |
| `${WORKDIR}` | 로그 및 결과물 (read-write) |

실행 로그는 `${WORKDIR}/docker-run.log`에 저장됩니다.

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--profile PROFILE` | 설치 프로필 (full, minimal) | full |
| `-f, --force` | 기존 파일 덮어쓰기 | false |
| `--os OS` | Docker 실행 (ubuntu, ubi9) | - |
| `--run-id ID` | 실행 ID | timestamp |
| `--skip-e2e` | E2E 테스트 건너뛰기 | false |
| `--e2e-optional` | 오프라인은 실행, E2E는 전제조건 충족 시에만 실행 | false |
| `--only N` | Step N까지만 실행 | - |
| `--secrets-mode MODE` | 시크릿 처리 방식 (mount, copy) | mount |
| `--workdir DIR` | 작업 디렉토리 | /tmp/agent-context-demo-{run-id} |

## 환경 변수

### 기본 설정

| Variable | Description | Required |
|----------|-------------|----------|
| `JIRA_EMAIL` | Atlassian 계정 이메일 | E2E only |
| `JIRA_BASE_URL` | Jira 기본 URL | Optional |
| `JIRA_PROJECT_KEY` | Jira 프로젝트 키 | Optional |
| `CONFLUENCE_BASE_URL` | Confluence 기본 URL | Optional |
| `CONFLUENCE_SPACE_KEY` | Confluence 스페이스 키 | Optional |
| `GITLAB_BASE_URL` | GitLab 서버 URL | Optional |
| `GITLAB_PROJECT` | GitLab 프로젝트 경로 (예: `group/project`) | Optional |

### 데모 시나리오 설정 (Step 008)

| Variable | Description |
|----------|-------------|
| `DEMO_REPO_NAME` | GitLab 저장소 이름 |
| `DEMO_JIRA_PROJECT` | 데모용 Jira 프로젝트 키 |
| `DEMO_GITLAB_GROUP` | GitLab 그룹/네임스페이스 |
| `DEMO_CONFLUENCE_SPACE` | 데모용 Confluence 스페이스 |
| `RECREATE_REPO` | GitLab repo 삭제 후 재생성 (`true`/`false`) |
| `RECREATE_BOARD` | Jira board 삭제 후 재생성 (`true`/`false`) |
| `RECREATE_ISSUES` | Jira issues 삭제 후 재생성 (`true`/`false`) |
| `SKIP_CLEANUP` | 정리 단계 건너뛰기 (`true`/`false`) |
| `HITL_ENABLED` | Human-in-the-Loop 활성화 |

### 런타임 설정

| Variable | Description |
|----------|-------------|
| `WORKDIR` | 작업 디렉토리 (Docker에서 호스트와 공유) |

---

## E2E 필수 요청사항(관리자 문의)

E2E는 실제 Jira/GitLab/Confluence에 리소스를 생성/수정합니다. 아래 항목이 준비되지 않으면 실패가 정상이며, 토큰 발급/권한 부여/SSH 키 등록은 조직의 시스템 관리자(또는 각 시스템 관리자)에게 문의해야 할 수 있습니다.

필수(공통):
- `JIRA_EMAIL` (Atlassian 계정 이메일)
- `~/.secrets/atlassian-api-token` (Atlassian API token)

GitLab 통합(E2E에서 Git 작업 포함 시):
- `~/.secrets/gitlab-api-token` (GitLab personal access token, scope: `api` 권장)
- `~/.ssh/id_ed25519`, `~/.ssh/id_ed25519.pub` (passphrase 없는 키, GitLab에 등록 필요)
- (조직 정책에 따라) commit signing/보호 브랜치/MR 승인 규칙 충족 필요

프로젝트/스페이스 정보(환경에 맞게 설정):
- Jira 프로젝트 키(`JIRA_PROJECT_KEY` 또는 `DEMO_JIRA_PROJECT`)
- Confluence space key(`CONFLUENCE_SPACE_KEY` 또는 `DEMO_CONFLUENCE_SPACE`)

## 검증 방법

### 오프라인 테스트

시크릿 없이 기본 설치 검증:

```bash
# 임시 HOME에서 실행 (시크릿 없음)
HOME=$(mktemp -d) bash demo/install.sh --skip-e2e --only 6
```

### 설치 결과 확인

```bash
# 작업 디렉토리 확인
ls -la /tmp/agent-context-demo-*/any-project/

# 설치 리포트 확인
cat /tmp/agent-context-demo-*/installation-report.md

# PM CLI 테스트
/tmp/agent-context-demo-*/any-project/.agent/tools/pm/bin/pm config show
```

## Gate Rules

각 단계는 `run` 후 `verify`를 실행합니다:
- `verify` 실패 시 즉시 중단
- 예외: Step 009 (pre-commit)는 best-effort

## Troubleshooting

### "Secrets directory not found"

```bash
# 오프라인 모드 사용
./demo/install.sh --skip-e2e

# 또는 시크릿 디렉토리 생성
mkdir -p ~/.secrets && chmod 700 ~/.secrets
```

### "Step N verification failed"

```bash
# 해당 단계부터 재시도
WORKDIR=/tmp/agent-context-demo-xxx ./demo/install.sh --only N
```

### Docker build 실패

```bash
# Docker 데몬 확인
docker info

# 이미지 직접 빌드
docker build -t agent-context-demo-ubuntu demo/docker/ubuntu/
```

### 병렬 테스트 실행

Ubuntu와 UBI9를 동시에 테스트하려면:

```bash
export JIRA_EMAIL="your-email@example.com"
./demo/run-docker-parallel.sh

# 오프라인 모드
./demo/run-docker-parallel.sh --skip-e2e

# 결과 확인
cat /tmp/agent-context-parallel-*/parallel-summary.md
```

병렬 실행 시 각 OS는 독립된 WORKDIR과 GitLab repo를 사용하여 충돌을 방지합니다.

### GitLab clone URL 실패 (Docker)

```bash
# SSH 키 마운트 확인
ls -la ~/.ssh/id_rsa  # 또는 id_ed25519

# glab 인증 상태 확인 (컨테이너 내부)
glab auth status
```

### Jira 이슈 생성 실패

```bash
# Jira 프로젝트 키에 숫자가 포함된 경우 정상 지원 (예: SVI4)
# 이메일이 Atlassian 계정과 정확히 일치하는지 확인
./tools/pm/bin/pm jira me
```

### Docker 실행 결과물 확인

```bash
# 실행 ID 확인 (호스트에서)
ls -la /tmp/agent-context-demo-*/

# 로그 확인
cat /tmp/agent-context-demo-*/docker-run.log

# 데모 결과물 확인 (Docker WORKDIR 마운트)
cat /tmp/agent-context-demo-*/export/latest/DEMO_REPORT.md
```

## 툴 버전 요구사항

Docker 이미지에 포함된 고정 버전:

| 패키지 | 버전 | 비고 |
|--------|------|------|
| glab | 1.81.0 | GitLab CLI |
| yq | v4.40.5 | YAML 처리 |
| jq | (distro) | JSON 처리 |
| pandoc | 3.1.11 | Markdown 변환 (UBI9) |
| pre-commit | (pip) | 코드 품질 검사 |

로컬 실행 시 위 버전 이상을 권장합니다.

## Related Documentation

- [../README.md](../README.md) - 데모 개요
- [../scenario/README.md](../scenario/README.md) - 시나리오 데모 상세
- [../../install.sh](../../install.sh) - 설치 스크립트 소스
