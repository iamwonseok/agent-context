# agent-context

에이전트 기반 개발을 위한 워크플로 템플릿.
AI 에이전트가 CLI(`git`, `gh`, `glab`, `pm`)로 모든 작업을 수행하며 브라우저 전환을 최소화합니다.
**설계 철학**: Thin Skill / Thick Workflow 패턴 -- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) 참고.

---

## 사용자 빠른 시작

> 오프라인 환경에서도 Step 1~7까지 동작합니다.

### Step 1: 의존성 설치

**macOS (Homebrew):**
```bash
brew install git curl jq yq
pip3 install pre-commit
```

**Ubuntu/Debian/WSL:**
```bash
sudo apt-get update
sudo apt-get install -y git curl jq python3-pip

# yq (아키텍처 자동 감지)
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) YQ_BINARY="yq_linux_amd64" ;;
    aarch64|arm64) YQ_BINARY="yq_linux_arm64" ;;
esac
sudo wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/${YQ_BINARY}"
sudo chmod +x /usr/local/bin/yq

pip3 install --user pre-commit
```

**RHEL/CentOS/Fedora:**
```bash
sudo dnf install -y git curl jq python3 python3-pip

# yq (아키텍처 자동 감지)
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) YQ_BINARY="yq_linux_amd64" ;;
    aarch64|arm64) YQ_BINARY="yq_linux_arm64" ;;
esac
sudo wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/${YQ_BINARY}"
sudo chmod +x /usr/local/bin/yq

pip3 install --user pre-commit
```

상세 설정 (GitLab SSH/PAT 등): [docs/USER_GUIDE.md](docs/USER_GUIDE.md#필수-조건)

### Step 2: agent-context 클론 (글로벌 설치)

```bash
git clone git@gitlab.fadutec.dev:soc-ip/agentic-ai/agent-context.git ~/.agent-context
```

### Step 3: 글로벌 환경 초기화

```bash
~/.agent-context/bin/agent-context.sh init
```

**출력 예시:**
```
Agent-Context Global Initialization

[i] Checking dependencies...
[V] Found: bash
[V] Found: git
[V] Found: curl
[V] Found: jq
[i] Checking optional commands...
[V] Found: yq
[V] Found: glab
[V] Found: pre-commit
[i] Setting up secrets directory...
[V] Created: ~/.secrets (mode 700)

API Token Setup Guide

  Atlassian (Jira/Confluence):
    1. Visit: https://id.atlassian.com/manage-profile/security/api-tokens
    2. Click 'Create API token'
    3. Save token:
       echo 'your-token' > ~/.secrets/atlassian-api-token
       chmod 600 ~/.secrets/atlassian-api-token

[i] Configuring shell environment...
[i] The following will be added to /Users/you/.zshrc:
  ----------------------------------------
  # BEGIN AGENT_CONTEXT
  alias agent-context="~/.agent-context/bin/agent-context.sh"
  [[ -f ~/.secrets/atlassian-api-token ]] && export ATLASSIAN_API_TOKEN="$(cat ~/.secrets/atlassian-api-token)"
  # END AGENT_CONTEXT
  ----------------------------------------

  Proceed? [y/N]: y
[V] Added shell configuration to /Users/you/.zshrc
```

### Step 4: 쉘 재시작

쉘 설정을 반영하기 위해 다음 중 하나를 실행:

**zsh 사용자** (macOS 기본, 일부 Linux):
```bash
source ~/.zshrc
```

**bash 사용자**:
```bash
# Linux
source ~/.bashrc

# macOS (bash 사용 시)
source ~/.bash_profile
```

**또는**: 터미널 창을 닫고 새로 열기

### Step 5: API 토큰 설정

```bash
# Atlassian API 토큰 저장
echo 'your-atlassian-api-token' > ~/.secrets/atlassian-api-token
chmod 600 ~/.secrets/atlassian-api-token

# (선택) GitLab API 토큰
echo 'your-gitlab-token' > ~/.secrets/gitlab-api-token
chmod 600 ~/.secrets/gitlab-api-token
```

### Step 6: 프로젝트에 설치

```bash
cd /path/to/your-project
agent-context install
```

### Step 7: 설치 검증 (필수)

설치 직후 반드시 다음 두 명령으로 환경을 검증합니다:

```bash
# 환경 진단 (의존성, 인증, 프로젝트 설정)
agent-context doctor

# 빠른 상태 점검 (smoke test)
agent-context tests smoke
```

**정상 출력 예시:**
```
agent-context doctor
[V] bash >= 4.0
[V] git >= 2.0
[V] curl found
[V] jq found
[V] yq found (optional)
Summary: total=5 passed=5 failed=0 warned=0 skipped=0

agent-context tests smoke
[V] deps: all required dependencies found
[V] auth: secrets directory exists
[V] global: ~/.agent-context is valid
[V] project: .agent/ structure is valid
Summary: total=4 passed=4 failed=0 warned=0 skipped=0
```

실패 항목이 있으면 아래 [빠른 문제 해결](#빠른-문제-해결) 또는 [docs/USER_GUIDE.md](docs/USER_GUIDE.md#문제-해결) 참고.

### Step 8: (선택) 외부 연결 테스트

네트워크가 가능한 환경에서 외부 서비스 연결을 확인합니다:

```bash
# GitLab/Jira/Confluence 연결 확인
agent-context doctor connect

# PM CLI 연결 테스트
agent-context pm config show
agent-context pm jira me
```

---

## 주요 명령어

전체 CLI 트리입니다. 상세 옵션은 각 명령에 `--help`를 붙여 확인하세요.

| 명령어 | 설명 | 비고 |
|--------|------|------|
| `agent-context init` | 글로벌 환경 초기화 | `~/.secrets`, 쉘 alias 설정 |
| `agent-context install` | 현재 프로젝트에 설치 | `--profile minimal/full`, `--force`, `--non-interactive` |
| `agent-context update` | 소스 업데이트 (brew update와 유사) | 별칭: `up`. `--check`, `--force` |
| `agent-context upgrade` | 프로젝트 업그레이드 (brew upgrade와 유사) | `--apply`, `--prune`, `--rollback` |
| `agent-context doctor` | 환경 진단 (오프라인) | 별칭: `dr`. 하위: `deps`, `auth`, `project`, `connect` |
| `agent-context audit` | 저장소/프로젝트 감사 | `--repo` (개발자), `--project` (사용자) |
| `agent-context tests` | 테스트 실행 (CI 친화) | 하위: `list`, `smoke`, `e2e`. `--tags`, `--skip`, `--formula` |
| `agent-context log` | 실행 로그 조회 | `--list`, `--global`, `--project`, `--tail`, `--follow`, `--level` |
| `agent-context report` | 진단 리포트 생성 | `--output <file>`, `--issue` (GitLab 이슈 생성) |
| `agent-context clean` | 캐시/로그 정리 | `--logs`, `--global`, `--all`, `--force`, `--dry-run` |
| `agent-context demo` | 설치 데모 실행 | `demo/install.sh` 래퍼 |
| `agent-context pm <cmd>` | PM CLI (Jira/Confluence) | `pm config show`, `pm jira issue list` 등 |

**공통 옵션:** `--debug`, `--quiet`, `--verbose`, `--version`, `--help`

### 비대화형 설치 (CI/스크립트용)

```bash
agent-context install --non-interactive --force \
    --jira-url https://mycompany.atlassian.net \
    --jira-project DEMO \
    --jira-email developer@mycompany.com \
    --gitlab-url https://gitlab.mycompany.com
```

### 무엇을 실행해야 할까?

| 목적 | 명령 | 상세 문서 |
|------|------|-----------|
| 현재 환경이 정상인지 빠르게 확인 | `agent-context tests smoke` | [TESTING_GUIDE.md](docs/TESTING_GUIDE.md) |
| 처음부터 끝까지 설치 과정 재현 | `agent-context demo` | [demo/README.md](demo/README.md) |
| 특정 항목만 세밀하게 점검 | `agent-context tests --tags ...` | [TESTING_GUIDE.md](docs/TESTING_GUIDE.md) |
| Docker에서 크로스 플랫폼 검증 | `agent-context demo --os ubuntu` | [demo/README.md](demo/README.md) |
| CI 파이프라인에 점검 추가 | `agent-context tests smoke` | [TESTING_GUIDE.md](docs/TESTING_GUIDE.md) |

---

## 빠른 문제 해결

자주 발생하는 문제와 해결 방법입니다. 전체 문제 해결 가이드는 [docs/USER_GUIDE.md](docs/USER_GUIDE.md#문제-해결) 참고.

| 증상 | 원인 | 해결 |
|------|------|------|
| `doctor`에서 의존성 실패 | `jq`, `yq` 등 미설치 | Step 1 의존성 설치 재실행 |
| `tests smoke`에서 auth 실패 | `~/.secrets/` 디렉토리 없음 | `mkdir -p ~/.secrets && chmod 700 ~/.secrets` |
| `install` 후 `.project.yaml`에 `CHANGE_ME` | 대화형 설정 건너뜀 | `.project.yaml` 직접 편집 또는 `agent-context install --force`로 재설치 |
| `agent-context: command not found` | alias 미설정 또는 쉘 미재시작 | `source ~/.zshrc` (또는 `~/.bashrc`) 실행 |
| `upgrade --apply` 후 문제 발생 | 업그레이드 충돌 | `agent-context upgrade --rollback`으로 복원 |

---

## 개발자 빠른 시작

agent-context 자체를 개발하거나 기여합니다.

```bash
# 1. 저장소 클론
git clone git@gitlab.fadutec.dev:soc-ip/agentic-ai/agent-context.git
cd agent-context

# 2. 의존성 설치 (개발자 도구 포함)
pip install pre-commit
brew install jq yq shellcheck shfmt

# 3. (선택) VCS CLI 설치
brew install gh glab

# 4. pre-commit 훅 설정
pre-commit install

# 5. 피처 브랜치에서 작업
git checkout -b feat/my-feature
# ... make changes ...
pre-commit run --all-files
git commit -m "feat: add new feature"

# 6. 변경사항 검증
agent-context tests smoke          # 빠른 상태 점검
agent-context audit --repo         # 저장소 내부 감사

# 7. (선택) 데모로 E2E 검증
./demo/install.sh --skip-e2e --only 6
```

상세 가이드: [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)

---

## 프로젝트 구조

```
agent-context/
├── bin/                # CLI 진입점
│   └── agent-context.sh
├── lib/                # 공통 라이브러리
│   ├── logging.sh      # 로깅 ([V]/[X]/[!]/[i] 마커)
│   └── platform.sh     # 플랫폼 감지
├── builtin/            # 내장 명령어 (doctor, tests, audit 등)
│   ├── doctor.sh
│   ├── tests.sh
│   ├── audit.sh
│   ├── init.sh
│   ├── update.sh
│   ├── upgrade.sh
│   ├── clean.sh
│   ├── log.sh
│   └── report.sh
├── install.sh          # 프로젝트 설치 스크립트
├── docs/               # 문서
│   ├── ARCHITECTURE.md # 설계 철학 (SSOT)
│   ├── USER_GUIDE.md   # 사용자 가이드
│   ├── TESTING_GUIDE.md # 테스트 가이드
│   ├── CONTRIBUTING.md # 기여자 가이드
│   └── convention/     # 코딩 컨벤션
├── skills/             # 범용 스킬 템플릿 (Thin)
├── workflows/          # 컨텍스트 기반 워크플로 (Thick)
│   ├── solo/           # 개인 개발
│   ├── team/           # 팀 협업
│   └── project/        # 조직 레벨
├── tools/pm/           # JIRA/Confluence CLI
├── templates/          # 설치 시 복사되는 템플릿
├── demo/               # 데모 및 E2E 테스트
└── tests/              # 테스트
```

---

## 필수 도구

### 사용자 (필수)

| 도구 | 목적 | 설치 |
|------|------|------|
| `git` | 버전 관리 | 대부분 사전 설치 |
| `curl` | HTTP 요청 | 대부분 사전 설치 |
| `jq` | JSON 처리 | `brew install jq` / `apt install jq` |
| `yq` | YAML 처리 | `brew install yq` / [GitHub releases](https://github.com/mikefarah/yq/releases) |
| `pre-commit` | 린팅/포맷팅 | `pip install pre-commit` |

### 사용자 (선택)

| 도구 | 목적 | 설치 | 필요 시점 |
|------|------|------|-----------|
| `glab` | GitLab CLI | `brew install glab` | GitLab MR 관리 |
| `gh` | GitHub CLI | `brew install gh` | GitHub PR 관리 |

### 개발자 전용

| 도구 | 목적 | 설치 |
|------|------|------|
| `shellcheck` | 쉘 스크립트 린팅 | `brew install shellcheck` |
| `shfmt` | 쉘 스크립트 포맷팅 | `brew install shfmt` |
| `hadolint` | Dockerfile 린팅 | `brew install hadolint` |

---

## 문서

| 문서 | 설명 | 대상 |
|------|------|------|
| [docs/USER_GUIDE.md](docs/USER_GUIDE.md) | 설치, 설정, CLI 레퍼런스 | 사용자 |
| [docs/TESTING_GUIDE.md](docs/TESTING_GUIDE.md) | 테스트 시나리오 및 검증 가이드 | 개발자/QA |
| [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) | 개발 및 기여 | 개발자 |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | 설계 철학 (SSOT) | 모두 |
| [docs/convention/](docs/convention/) | 코딩 컨벤션 | 개발자 |
| [workflows/README.md](workflows/README.md) | 워크플로 공통 정책 | 모두 |
| [demo/README.md](demo/README.md) | 데모 가이드 (개발자/검증 전용) | 개발자 |

## 라이선스

MIT License - 자세한 내용은 [LICENSE](LICENSE)를 참고.
