# 사용자 가이드

agent-context를 프로젝트에 설치하고 활용하는 방법을 안내합니다.

## 목차

- [필수 조건](#필수-조건)
- [설치](#설치)
- [설치 직후 검증 (필수)](#설치-직후-검증-필수)
- [명령어 레퍼런스](#명령어-레퍼런스)
- [일상 운영](#일상-운영)
- [워크플로 사용](#워크플로-사용)
- [데모 및 E2E](#데모-및-e2e)
- [문제 해결](#문제-해결)
- [오프라인 환경 설치](#오프라인-환경-설치)

---

## 필수 조건

### 1. GitLab 접근 설정

**SSH 키 생성** (없는 경우):

```bash
# 기존 키 확인
ls -la ~/.ssh/id_ed25519.pub

# 새로 생성
ssh-keygen -t ed25519 -C "your-email@fadutec.dev"

# SSH Agent에 추가
eval "$(ssh-agent -s)"

# macOS: Keychain에 저장 (재부팅 후에도 유지)
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# Linux: 일반 추가
ssh-add ~/.ssh/id_ed25519
```

**macOS 추가 설정** (선택):

`~/.ssh/config`에 다음을 추가하면 재부팅 후에도 Keychain에서 자동 로드:

```
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

**GitLab에 SSH 키 등록**:

1. https://gitlab.fadutec.dev/-/user_settings/ssh_keys 접속
2. `cat ~/.ssh/id_ed25519.pub` 출력 내용 복사
3. "Add new key" 클릭 후 붙여넣기

**SSH 연결 테스트**:

```bash
ssh -T git@gitlab.fadutec.dev
# 성공: "Welcome to GitLab, @username!"
```

### 2. GitLab PAT 생성

1. https://gitlab.fadutec.dev/-/user_settings/personal_access_tokens 접속
2. Token name: "agent-context" (또는 원하는 이름)
3. Scopes: `api`, `read_repository`, `write_repository`
4. "Create personal access token" 클릭
5. 토큰 복사 (다시 볼 수 없음)

```bash
# PAT 저장
mkdir -p ~/.secrets && chmod 700 ~/.secrets
read -sp "GitLab PAT: " token && echo "$token" > ~/.secrets/gitlab-api-token && chmod 600 ~/.secrets/gitlab-api-token && unset token
```

### 3. 의존성 설치

**macOS**:

```bash
brew install git jq yq
pip3 install pre-commit
```

**Ubuntu/Debian**:

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

**RHEL/CentOS/Fedora**:

```bash
sudo dnf install -y git curl jq python3 python3-pip
# yq 설치는 Ubuntu와 동일
```

**선택 도구** (GitLab/GitHub CLI):

```bash
# GitLab CLI
brew install glab                      # macOS
# 또는 https://gitlab.com/gitlab-org/cli 참고

# GitHub CLI (GitHub 사용 시)
brew install gh
```

### 4. glab 인증 (선택)

GitLab CLI를 사용하는 경우:

```bash
glab auth login --hostname gitlab.fadutec.dev
# Protocol: SSH
# Login method: Paste a token
# Token: [저장한 PAT 붙여넣기]

glab auth status  # 확인
```

### 5. Atlassian 토큰 설정 (선택)

Jira/Confluence 연동이 필요한 경우:

1. https://id.atlassian.com/manage-profile/security/api-tokens 접속
2. "Create API token" 클릭
3. 토큰 저장:

```bash
read -sp "Atlassian Token: " token && echo "$token" > ~/.secrets/atlassian-api-token && chmod 600 ~/.secrets/atlassian-api-token && unset token
```

---

## 설치

### 설치 방법

```bash
# 1. agent-context 클론 (글로벌 설치)
git clone git@gitlab.fadutec.dev:soc-ip/agentic-ai/agent-context.git ~/.agent-context

# 2. 글로벌 환경 초기화
~/.agent-context/bin/agent-context.sh init

# 3. 쉘 재시작
source ~/.zshrc   # zsh
# source ~/.bashrc  # bash (Linux)

# 4. 대상 프로젝트에 설치
cd /path/to/your-project
agent-context install

# 또는 프로필 지정
agent-context install --profile minimal
agent-context install --profile full
```

### 설치 프로필

| 프로필 | 포함 내용 |
|--------|----------|
| `minimal` | `.cursorrules`, `.project.yaml`, `.agent/*` |
| `full` | minimal + `.editorconfig`, `.pre-commit-config.yaml`, `.shellcheckrc`, `.yamllint.yml`, `.hadolint.yaml`, `.clang-format`, `.clang-tidy`, `.flake8` 등 |

### 설치 결과

```
your-project/
├── .cursorrules           # AI 에이전트 규칙
├── .project.yaml          # 프로젝트 설정
├── .agent/
│   ├── skills/            # 범용 스킬 템플릿
│   ├── workflows/         # 컨텍스트 기반 워크플로
│   ├── tools/pm/          # JIRA/Confluence CLI
│   └── templates/         # 템플릿 (vimrc 등)
└── .editorconfig          # (full 프로필)
```

---

## 설치 직후 검증 (필수)

설치가 완료되면 반드시 다음 세 단계로 환경을 검증합니다. 모두 오프라인에서 동작합니다.

### 1단계: 환경 진단 (doctor)

```bash
agent-context doctor
```

의존성, 인증 파일, 프로젝트 설정을 한 번에 점검합니다:

```
[V] bash >= 4.0
[V] git >= 2.0
[V] curl found
[V] jq found
[V] yq found (optional)
[V] ~/.secrets directory exists (mode 700)
[V] .project.yaml found
Summary: total=7 passed=7 failed=0 warned=0 skipped=0
```

실패 항목이 있으면 `doctor` 출력의 `[X]` 메시지를 확인하고 [문제 해결](#문제-해결) 참고.

### 2단계: 빠른 상태 점검 (tests smoke)

```bash
agent-context tests smoke
```

핵심 태그(`deps`, `auth`, `global`, `project`)를 한 번에 검사합니다:

```
[V] deps: all required dependencies found
[V] auth: secrets directory exists
[V] global: ~/.agent-context is valid
[V] project: .agent/ structure is valid
Summary: total=4 passed=4 failed=0 warned=0 skipped=0
```

### 3단계: 프로젝트 감사 (audit)

```bash
agent-context audit --project
```

`.agent/` 구조와 `.project.yaml` 설정의 정합성을 검사합니다. `CHANGE_ME` 같은 미완성 설정도 감지합니다.

### 전체 검증 한 줄 실행

```bash
agent-context doctor && agent-context tests smoke && agent-context audit --project
```

세 명령 모두 exit code 0이면 설치가 정상입니다.

---

## 명령어 레퍼런스

`bin/agent-context.sh --help` 출력과 1:1 매칭되는 전체 CLI 레퍼런스입니다.

### init -- 글로벌 환경 초기화

```bash
agent-context init
```

- 의존성 확인 (bash, git, curl, jq)
- `~/.secrets` 디렉토리 생성
- GitLab SSH/PAT 설정 (대화형)
- Atlassian 토큰 설정 (대화형)
- 쉘 alias 및 환경변수 추가

비대화형 CI 환경에서는 환경변수와 secrets 파일을 사전에 준비한 후 `init`을 실행합니다.

### install -- 프로젝트에 설치

```bash
agent-context install [options]
```

| 옵션 | 설명 |
|------|------|
| `-f`, `--force` | 기존 파일 덮어쓰기 (`.gitignore`는 병합) |
| `--profile <PROFILE>` | 설치 프로필: `full` (기본), `minimal` |
| `--non-interactive` | 프롬프트 건너뛰기 (기본값 또는 제공된 값 사용) |
| `--with-python` | `pyproject.toml` 포함 (Python 프로젝트용) |
| `--jira-url <URL>` | Jira 기본 URL |
| `--jira-project <KEY>` | Jira 프로젝트 키 |
| `--jira-email <EMAIL>` | Atlassian 계정 이메일 |
| `--gitlab-url <URL>` | GitLab 기본 URL |
| `--confluence-space <KEY>` | Confluence 스페이스 키 |
| `--github-repo <REPO>` | GitHub 저장소 (owner/repo) |

```bash
# 대화형 설치 (기본)
agent-context install

# 최소 설치
agent-context install --profile minimal

# CI용 비대화형 설치
agent-context install --non-interactive --force \
    --jira-url https://mycompany.atlassian.net \
    --jira-project DEMO \
    --jira-email dev@mycompany.com
```

### update (up) -- 소스 업데이트

```bash
agent-context update [options]
agent-context up [options]          # 별칭
```

`~/.agent-context` 저장소를 최신으로 업데이트합니다 (`brew update`와 유사).

| 옵션 | 설명 |
|------|------|
| `--check` | 업데이트 확인만 (적용하지 않음) |
| `--force` | 로컬 변경사항이 있어도 강제 업데이트 (stash 후 진행) |

```bash
# 업데이트 확인
agent-context update --check

# 최신으로 업데이트
agent-context update

# 로컬 변경사항이 있을 때 강제 업데이트
agent-context update --force
```

기본 동작: 커밋되지 않은 로컬 변경이 있으면 중단합니다 (`--force`로 stash 가능).

### upgrade -- 프로젝트 업그레이드

```bash
agent-context upgrade [options]
```

프로젝트의 `.agent/` 디렉토리를 최신 소스에 맞게 업그레이드합니다 (`brew upgrade`와 유사).

| 옵션 | 설명 |
|------|------|
| `--apply` | 변경사항 실제 적용 (기본: diff만 표시) |
| `--prune` | 소스에 없는 파일 삭제 (`--apply` 필요) |
| `--rollback` | 마지막 백업에서 복원 (`--apply` 실행 취소) |
| `--dry-run` | 변경 예상만 표시 (기본 동작과 동일) |

```bash
# 변경 사항 미리보기 (기본)
agent-context upgrade

# 변경 적용
agent-context upgrade --apply

# 변경 적용 + 불필요 파일 삭제
agent-context upgrade --apply --prune

# 문제 발생 시 복원
agent-context upgrade --rollback
```

`--apply` 사용 시 `.agent/.backup/`에 백업이 자동 생성됩니다. 1세대만 유지됩니다.

### doctor (dr) -- 환경 진단

```bash
agent-context doctor [subcommand]
agent-context dr [subcommand]       # 별칭
```

| 하위 명령 | 설명 | 네트워크 |
|-----------|------|:--------:|
| (없음) | 전체 진단 (deps + auth + project) | 불필요 |
| `deps` | 의존성만 확인 | 불필요 |
| `auth` | 인증/시크릿만 확인 | 불필요 |
| `project` | 프로젝트 설정만 확인 | 불필요 |
| `connect` | 외부 서비스 연결 테스트 | **필요** |

```bash
agent-context doctor            # 전체 (오프라인)
agent-context doctor deps       # 의존성만
agent-context doctor auth       # 인증만
agent-context doctor project    # 프로젝트 설정만
agent-context doctor connect    # 외부 연결 (네트워크)
```

### audit -- 저장소/프로젝트 감사

```bash
agent-context audit [options]
```

| 옵션 | 설명 |
|------|------|
| (없음) | 자동 감지 (저장소면 `--repo`, 프로젝트면 `--project`) |
| `--repo` | 개발자 모드: `~/.agent-context` 내부 템플릿/구조 검사 |
| `--project` | 사용자 모드: 프로젝트 `.agent/` 구조 및 `.project.yaml` 검사 |

```bash
agent-context audit             # 자동 감지
agent-context audit --repo      # 개발자 모드 (저장소 내부)
agent-context audit --project   # 사용자 모드 (프로젝트 설치)
```

### tests -- 테스트 실행

```bash
agent-context tests [subcommand] [options]
```

| 하위 명령/옵션 | 설명 |
|----------------|------|
| `list` | 사용 가능한 테스트 및 태그 목록 |
| `smoke` | 빠른 검사 (deps, auth, global, project) |
| `e2e` | 전체 E2E 테스트 (Docker 필요) |
| `--tags <tags>` | 지정 태그만 실행 (쉼표 구분) |
| `--skip <tags>` | 지정 태그 건너뛰기 |
| `--formula <expr>` | 부울 수식으로 태그 필터링 |

**사용 가능한 태그:**

| 태그 | 설명 |
|------|------|
| `deps` | 필수 의존성 확인 |
| `auth` | 인증 및 시크릿 |
| `global` | 글로벌 설치 (`~/.agent-context`) |
| `project` | 프로젝트 설치 (`.agent/`) |
| `connect` | 외부 연결 (네트워크 필요) |
| `auditRepo` | 저장소 템플릿 감사 |
| `auditProject` | 프로젝트 구조 감사 |
| `installNonInteractive` | 비대화형 설치 테스트 |

**formula 구문:** `and`/`&&`, `or`/`||`, `not`/`!`, 괄호 `()` 지원. 우선순위: not > and > or.

```bash
# 빠른 smoke 테스트
agent-context tests smoke

# 특정 태그 실행
agent-context tests --tags deps,auth

# smoke에서 project 제외
agent-context tests smoke --skip project

# formula: deps AND auth, NOT connect
agent-context tests --formula "deps and auth and not connect"

# formula: audit 중 하나 + deps
agent-context tests --formula "(auditRepo or auditProject) and deps"

# 사용 가능한 테스트 목록
agent-context tests list
```

**exit code:** 0(성공), 1(실패), 3(환경 스킵)

### log -- 실행 로그 조회

```bash
agent-context log [command] [options]
```

| 옵션 | 설명 |
|------|------|
| `[command]` | 명령어별 필터 (install, doctor 등) |
| `--list` | 로그 파일 목록 |
| `--global` | 글로벌 로그만 (`~/.local/state/agent-context/logs/`) |
| `--project` | 프로젝트 로그만 (`.agent/state/logs/`) |
| `--tail <N>` | 마지막 N줄 (기본: 50) |
| `--follow` | 실시간 추적 (`tail -f`) |
| `--level <LEVEL>` | 레벨 필터 (info, warn, error) |
| `--raw` | 민감 데이터 마스킹 없이 출력 |

```bash
agent-context log               # 최근 로그
agent-context log --list        # 로그 목록
agent-context log install       # install 관련 로그
agent-context log --follow      # 실시간 추적
agent-context log --level error # 에러만 표시
agent-context log --tail 100    # 마지막 100줄
```

### report -- 진단 리포트 생성

```bash
agent-context report [options]
```

| 옵션 | 설명 |
|------|------|
| `--output <file>` | 파일로 저장 |
| `--issue` | GitLab 이슈로 생성 (glab 필요, opt-in) |

```bash
agent-context report                    # stdout 출력
agent-context report --output report.md # 파일 저장
agent-context report --issue            # GitLab 이슈 생성
```

### clean -- 캐시/로그 정리

```bash
agent-context clean [options]
```

| 옵션 | 설명 |
|------|------|
| `--logs` | 로그도 포함하여 정리 |
| `--global` | 글로벌 상태 정리 (`~/.local/state/agent-context/`) |
| `--all` | 전체 정리 (`--force` 필요) |
| `--force` | 확인 프롬프트 건너뛰기 |
| `--dry-run` | 삭제 대상만 표시 (실제 삭제하지 않음) |

```bash
agent-context clean                 # 기본: .agent/state/* 정리
agent-context clean --dry-run       # 삭제 대상 미리보기
agent-context clean --logs          # 로그 포함
agent-context clean --global        # 글로벌 상태 정리
agent-context clean --all --force   # 전체 정리 (확인 없이)
```

### demo -- 설치 데모 실행

```bash
agent-context demo [options]
```

`demo/install.sh`의 래퍼입니다. 상세 사용법은 [demo/README.md](../demo/README.md) 참고.

### pm -- PM CLI 실행

```bash
agent-context pm <subcommand> [options]
```

현재 프로젝트의 `.agent/tools/pm/bin/pm`에 위임합니다.

```bash
agent-context pm config show           # 설정 확인
agent-context pm jira me               # Jira 계정 확인
agent-context pm jira issue list       # 이슈 목록
agent-context pm jira issue view KEY   # 이슈 상세
agent-context pm jira issue create "제목"   # 이슈 생성
agent-context pm confluence me         # Confluence 계정 확인
agent-context pm confluence page list  # 페이지 목록
```

### 공통 옵션

모든 명령에서 사용 가능한 옵션:

| 옵션 | 설명 |
|------|------|
| `-d`, `--debug` | 디버그 정보 출력 |
| `-q`, `--quiet` | 출력 최소화 (최종 Summary만) |
| `-v`, `--verbose` | 상세 출력 |
| `-V`, `--version` | 버전 정보 |
| `-h`, `--help` | 도움말 |

---

## 일상 운영

### update vs upgrade 차이

| 구분 | `update` | `upgrade` |
|------|----------|-----------|
| 대상 | `~/.agent-context` (소스 저장소) | 프로젝트 `.agent/` (설치된 파일) |
| 유사 도구 | `brew update` | `brew upgrade` |
| 기본 동작 | 소스를 git pull | diff만 표시 |
| 쓰기 | 항상 (git pull) | `--apply` 시에만 |

일반적인 업데이트 흐름:

```bash
# 1. 소스 업데이트
agent-context update

# 2. 변경 확인
agent-context upgrade

# 3. 변경 적용
agent-context upgrade --apply

# 4. 적용 후 검증
agent-context tests smoke
```

### 롤백

`upgrade --apply`가 문제를 일으킨 경우:

```bash
# 마지막 백업에서 복원
agent-context upgrade --rollback

# 복원 후 검증
agent-context tests smoke
```

### 로그 관리

```bash
# 최근 실행 로그 확인
agent-context log

# 실패한 install 로그 확인
agent-context log install --level error

# 로그 정리
agent-context clean --logs
```

### 진단 리포트

문제 발생 시 리포트를 생성하여 공유합니다:

```bash
# 파일로 저장
agent-context report --output diagnostic.md

# GitLab 이슈로 바로 생성
agent-context report --issue
```

---

## 설정

### .project.yaml 설정

설치 후 `.project.yaml`을 프로젝트에 맞게 수정합니다:

```yaml
project:
  name: "your-project"
  type: "firmware"         # firmware, webapp, library, etc.

platforms:
  jira:
    base_url: https://your-domain.atlassian.net
    project_key: PROJ
    email: your-email@example.com

  confluence:
    base_url: https://your-domain.atlassian.net/wiki
    space_key: YOUR_SPACE

  gitlab:
    base_url: https://gitlab.example.com
    project: namespace/project
```

### 시크릿 설정

API 토큰은 `~/.secrets/` 디렉토리에 저장합니다.

#### 디렉토리 구조 및 권한

```bash
# 디렉토리 생성 (반드시 700 권한)
mkdir -p ~/.secrets && chmod 700 ~/.secrets

# 토큰 파일 구조
~/.secrets/
├── atlassian-api-token   # Atlassian (Jira/Confluence) API 토큰
├── gitlab-api-token      # GitLab PAT
└── github-api-token      # GitHub PAT (선택)

# 모든 토큰 파일은 600 권한이어야 함
chmod 600 ~/.secrets/*
```

#### 환경 변수 우선순위

토큰은 다음 우선순위로 로드됩니다:

1. 환경 변수 (예: `ATLASSIAN_API_TOKEN`)
2. `~/.secrets/` 파일 (예: `~/.secrets/atlassian-api-token`)
3. 프로젝트 `.secrets/` 파일 (권장하지 않음)

#### 토큰 갱신 절차

토큰은 보안상 주기적으로 갱신해야 합니다 (권장: 1년).

```bash
# 1. 새 토큰 생성 (각 플랫폼 웹 UI에서)

# 2. 토큰 파일 업데이트
echo "NEW_TOKEN" > ~/.secrets/gitlab-api-token
chmod 600 ~/.secrets/gitlab-api-token

# 3. glab 재인증 (GitLab CLI 사용 시)
glab auth login --hostname gitlab.fadutec.dev

# 4. 연결 테스트
agent-context doctor connect
```

토큰 갱신 후 `init`을 다시 실행할 필요는 없습니다. `init`은 쉘 설정(alias/환경변수)을 관리하며, 토큰 파일 내용은 실행 시점에 읽힙니다.

#### CI/CD 환경 설정

CI/CD 파이프라인에서는 환경 변수로 토큰을 전달합니다:

**GitLab CI:**

```yaml
# .gitlab-ci.yml
variables:
  ATLASSIAN_API_TOKEN: $CI_ATLASSIAN_TOKEN
  GITLAB_API_TOKEN: $CI_JOB_TOKEN

test:
  script:
    - agent-context tests smoke
```

**GitHub Actions:**

```yaml
# .github/workflows/test.yml
jobs:
  test:
    runs-on: ubuntu-latest
    env:
      ATLASSIAN_API_TOKEN: ${{ secrets.ATLASSIAN_API_TOKEN }}
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    steps:
      - uses: actions/checkout@v4
      - run: agent-context tests smoke
```

---

## 워크플로 사용

### 워크플로 선택

작업 유형에 따라 적절한 워크플로를 선택합니다:

| 작업 유형 | 워크플로 | 파일 |
|----------|---------|------|
| 새 기능 개발 | Feature | `.agent/workflows/solo/feature.md` |
| 버그 수정 | Bugfix | `.agent/workflows/solo/bugfix.md` |
| 긴급 수정 | Hotfix | `.agent/workflows/solo/hotfix.md` |
| 스프린트 | Sprint | `.agent/workflows/team/sprint.md` |
| 릴리스 | Release | `.agent/workflows/team/release.md` |

### 기본 작업 흐름 (워크플로 연계)

agent-context 명령을 개발 워크플로에 자연스럽게 통합하는 권장 패턴입니다:

```bash
# === 작업 시작 전 ===
# 환경 진단 (의존성/인증/프로젝트 설정 한 번에 확인)
agent-context doctor

# 피처 브랜치 생성
git checkout -b feat/TASK-123-description

# === 작업 중 ===
# AI 에이전트가 .agent/workflows/solo/feature.md 참조하며 작업
# 변경사항 커밋
git add .
git commit -m "feat: add new feature"

# 품질 검사
pre-commit run --all-files

# === 작업 완료 후 ===
# 프로젝트 감사 (구조/설정 정합성 확인)
agent-context audit --project

# smoke 테스트 (CI에 올리기 전 로컬 확인)
agent-context tests smoke

# PR/MR 생성
git push origin feat/TASK-123-description
glab mr create --title "TASK-123: Add new feature"
# 또는
gh pr create --title "TASK-123: Add new feature"
```

### 워크플로 단계별 권장 명령

| 단계 | 명령 | 목적 |
|------|------|------|
| 작업 시작 전 | `agent-context doctor` | 환경 이상 조기 발견 |
| 작업 시작 전 | `agent-context update --check` | 소스 업데이트 확인 |
| 작업 완료 후 | `agent-context audit --project` | 설정 정합성 확인 |
| PR 생성 전 | `agent-context tests smoke` | CI 실패 사전 방지 |
| 주기적 | `agent-context update && agent-context upgrade --apply` | 최신 상태 유지 |

### CI/CD 통합

#### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - check
  - test

agent-context-check:
  stage: check
  image: ubuntu:22.04
  before_script:
    - apt-get update && apt-get install -y git curl jq
    # yq 설치
    - |
      ARCH=$(uname -m)
      case "$ARCH" in
        x86_64) YQ_BINARY="yq_linux_amd64" ;;
        aarch64|arm64) YQ_BINARY="yq_linux_arm64" ;;
      esac
      wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/${YQ_BINARY}"
      chmod +x /usr/local/bin/yq
    # agent-context 설치
    - git clone "$CI_REPOSITORY_URL" ~/.agent-context
  script:
    - ~/.agent-context/bin/agent-context.sh doctor deps
    - ~/.agent-context/bin/agent-context.sh tests smoke --skip connect
  allow_failure: false

agent-context-audit:
  stage: test
  image: ubuntu:22.04
  before_script:
    - apt-get update && apt-get install -y git curl jq
    - git clone "$CI_REPOSITORY_URL" ~/.agent-context
  script:
    - ~/.agent-context/bin/agent-context.sh audit --project
  allow_failure: true
```

#### GitHub Actions

```yaml
# .github/workflows/agent-context.yml
name: Agent-Context Check
on: [push, pull_request]

jobs:
  smoke-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup agent-context
        run: |
          sudo apt-get install -y jq
          sudo wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"
          sudo chmod +x /usr/local/bin/yq
          git clone "${{ github.server_url }}/${{ github.repository }}" ~/.agent-context
      - name: Run smoke tests
        run: |
          ~/.agent-context/bin/agent-context.sh doctor deps
          ~/.agent-context/bin/agent-context.sh tests smoke --skip connect
```

### 스킬 활용

워크플로 내에서 필요에 따라 스킬을 참조합니다:

| 스킬 | 용도 | 파일 |
|------|------|------|
| Analyze | 상황 이해, 코드 분석 | `.agent/skills/analyze.md` |
| Design | 설계 접근 | `.agent/skills/design.md` |
| Implement | 구현 | `.agent/skills/implement.md` |
| Test | 품질 검증 | `.agent/skills/test.md` |
| Review | 결과 확인 | `.agent/skills/review.md` |

---

## 데모 및 E2E

> **주의:** 데모/E2E 테스트는 실제 Jira/GitLab/Confluence에 리소스를 생성/수정합니다. 권한, 쿼터, 네트워크 사유로 실패가 정상일 수 있습니다.

| 목적 | 명령 |
|------|------|
| 설치 과정 재현 (오프라인) | `agent-context demo --skip-e2e` |
| 전체 E2E 재현 | `agent-context demo` |
| Docker 크로스 플랫폼 | `agent-context demo --os ubuntu` |

상세 사용법, 환경 설정, 결과 해석은 [demo/README.md](../demo/README.md) 참고.

테스트 시나리오 상세는 [TESTING_GUIDE.md](TESTING_GUIDE.md) 참고.

---

## 문제 해결

### 진단 도구 사용

문제 발생 시 먼저 `doctor` 명령으로 진단합니다:

```bash
# 전체 진단
agent-context doctor

# 특정 영역만 진단
agent-context doctor deps      # 의존성
agent-context doctor auth      # 인증
agent-context doctor project   # 프로젝트 설정
agent-context doctor connect   # 외부 연결 (네트워크 필요)
```

### 증상별 해결 방법

| 증상 | 원인 | 확인 명령 | 해결 |
|------|------|-----------|------|
| `doctor`에서 의존성 실패 | 도구 미설치 | `agent-context doctor deps` | 의존성 재설치 |
| `tests smoke`에서 auth 실패 | `~/.secrets/` 없음 | `agent-context doctor auth` | `mkdir -p ~/.secrets && chmod 700 ~/.secrets` |
| `.project.yaml`에 `CHANGE_ME` | 설정 미완료 | `agent-context audit --project` | `.project.yaml` 편집 또는 `install --force` |
| `agent-context: command not found` | alias 미설정 | `type agent-context` | `source ~/.zshrc` 또는 `init` 재실행 |
| `upgrade --apply` 후 문제 | 업그레이드 충돌 | `agent-context log upgrade` | `agent-context upgrade --rollback` |
| `update` 실패 (dirty tree) | 로컬 변경사항 | `cd ~/.agent-context && git status` | `agent-context update --force` |

### GitLab SSH 관련

#### "Permission denied (publickey)"

```bash
# 1. SSH 키 존재 확인
ls -la ~/.ssh/id_ed25519*

# 2. SSH Agent에 키 추가
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 3. GitLab에 키 등록 확인
# https://gitlab.fadutec.dev/-/user_settings/ssh_keys

# 4. 연결 테스트
ssh -T git@gitlab.fadutec.dev
```

#### "Host key verification failed"

```bash
# GitLab 호스트 키 추가
ssh-keyscan -H gitlab.fadutec.dev >> ~/.ssh/known_hosts

# 또는 처음 연결 시 수동 승인
ssh -T git@gitlab.fadutec.dev
# "yes" 입력
```

### GitLab API 관련

#### "401 Unauthorized" (GitLab API)

```bash
# 1. 토큰 파일 확인
cat ~/.secrets/gitlab-api-token

# 2. 토큰 유효성 확인 (API 호출)
curl -H "PRIVATE-TOKEN: $(cat ~/.secrets/gitlab-api-token)" \
  "https://gitlab.fadutec.dev/api/v4/user"

# 3. 토큰 재발급 필요 시
# https://gitlab.fadutec.dev/-/user_settings/personal_access_tokens
# 스코프: api, read_repository, write_repository
```

#### "glab: command not found"

```bash
# macOS
brew install glab

# Ubuntu/Debian
curl -s https://raw.githubusercontent.com/profclems/glab/trunk/scripts/install.sh | sudo sh

# 인증 설정
glab auth login --hostname gitlab.fadutec.dev
```

### JIRA/Confluence 관련

#### "Client must be authenticated" (JIRA)

```bash
# 1. 이메일이 Atlassian 계정과 일치하는지 확인
agent-context pm config show

# 2. .project.yaml의 email 확인
yq '.platforms.jira.email' .project.yaml

# 3. 토큰 유효성 확인
# https://id.atlassian.com/manage-profile/security/api-tokens 에서 확인
```

#### "Secrets directory not found"

```bash
# 시크릿 디렉토리 생성
mkdir -p ~/.secrets && chmod 700 ~/.secrets

# 토큰 파일 생성
echo "YOUR_TOKEN" > ~/.secrets/atlassian-api-token
chmod 600 ~/.secrets/atlassian-api-token
```

### 프로젝트 설정 관련

#### ".project.yaml contains CHANGE_ME"

```bash
# 1. CHANGE_ME 위치 확인
grep -n "CHANGE_ME" .project.yaml

# 2. 설정 편집
vi .project.yaml

# 3. 또는 대화형으로 재설치
agent-context install --force
```

### pre-commit 관련

#### pre-commit 실패

```bash
# 개별 훅 실행하여 문제 확인
pre-commit run shellcheck --all-files
pre-commit run trailing-whitespace --all-files

# 훅 업데이트
pre-commit autoupdate

# 캐시 정리 후 재시도
pre-commit clean
pre-commit run --all-files
```

---

## 오프라인 환경 설치

네트워크가 제한된 환경(air-gapped)에서 agent-context를 설치하는 방법입니다.

### 준비 단계 (온라인 환경에서)

```bash
# 1. agent-context 저장소를 tarball로 압축
cd ~/.agent-context
git archive --format=tar.gz --prefix=agent-context/ HEAD > agent-context-offline.tar.gz

# 2. 의존성 도구 다운로드 (필요한 경우)
# macOS
brew bundle dump  # Brewfile 생성

# Ubuntu/Debian
apt-get download git curl jq
```

### 설치 단계 (오프라인 환경에서)

```bash
# 1. tarball 압축 해제
tar -xzf agent-context-offline.tar.gz -C ~/
mv ~/agent-context ~/.agent-context

# 2. alias 설정
echo 'alias agent-context="~/.agent-context/bin/agent-context.sh"' >> ~/.zshrc
source ~/.zshrc

# 3. 프로젝트에 설치
cd /path/to/your-project
agent-context install --non-interactive --force

# 4. 설치 검증
agent-context doctor
agent-context tests smoke
```

### 제한 사항

오프라인 환경에서는 다음 기능이 제한됩니다:

| 기능 | 오프라인 지원 | 대안 |
|------|:------------:|------|
| `agent-context install` | O | 정상 동작 |
| `agent-context upgrade` | O | 정상 동작 |
| `agent-context doctor deps` | O | 정상 동작 |
| `agent-context tests smoke` | O | 정상 동작 |
| `agent-context doctor connect` | X | 네트워크 필요 |
| `agent-context pm jira` | X | Jira API 필요 |
| `pre-commit autoupdate` | X | 사전 준비 필요 |
| `glab`, `gh` 명령 | X | Git 플랫폼 API 필요 |

### 권장 사항

1. **의존성 사전 준비**: 온라인 환경에서 필요한 도구(git, jq, yq 등)를 사전에 설치 패키지로 준비
2. **pre-commit 훅 사전 설정**: `.pre-commit-config.yaml`의 repo를 로컬 경로로 변경하거나 훅 바이너리를 사전 설치
3. **토큰 파일 준비**: `~/.secrets/` 디렉토리와 토큰 파일을 사전에 준비

---

## 관련 문서

- [설계 철학 (ARCHITECTURE.md)](ARCHITECTURE.md)
- [테스트 가이드 (TESTING_GUIDE.md)](TESTING_GUIDE.md)
- [워크플로 공통 정책 (workflows/README.md)](../workflows/README.md)
- [기여자 가이드 (CONTRIBUTING.md)](CONTRIBUTING.md)
- [코딩 컨벤션 (convention/)](convention/)
- [데모 가이드 (demo/README.md)](../demo/README.md)
