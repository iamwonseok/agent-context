# agent-context

에이전트 기반 개발을 위한 워크플로 템플릿.

**설계 철학**: Thin Skill / Thick Workflow 패턴은 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)를 참고.

## 왜 이 프로젝트인가?

**문제**:
- 새 프로젝트마다 워크플로를 처음부터 구성
- 반복 작업과 구조의 비일관성
- AI 에이전트 협업에 대한 표준 부재

**해결**:
| 구성요소 | 목적 | 위치 |
|-----------|---------|----------|
| Skills | 범용 템플릿 | `skills/` |
| Workflows | 컨텍스트 기반 오케스트레이션 | `workflows/` |
| CLI Tools | JIRA/Confluence 인터페이스 | `tools/pm/` |

**목표**: AI 에이전트가 CLI(`git`, `gh`, `glab`, `pm`)로 모든 작업을 수행하며 브라우저 전환을 최소화.

---

## 사용자 빠른 시작

### Step 1: 의존성 설치

**macOS (Homebrew):**
```bash
brew install git curl jq yq gh glab
pip install pre-commit
```

**Ubuntu/Debian/WSL:**
```bash
sudo apt-get update
sudo apt-get install -y git curl jq
# yq (YAML processor)
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
# gh (GitHub CLI)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt-get update && sudo apt-get install -y gh
pip install pre-commit
```

### Step 2: agent-context 클론 (글로벌 설치)

```bash
git clone https://github.com/your-org/agent-context.git ~/.agent-context
```

### Step 3: 글로벌 환경 초기화

```bash
~/.agent-context/agent-context.sh init
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
  alias agent-context="~/.agent-context/agent-context.sh"
  [[ -f ~/.secrets/atlassian-api-token ]] && export ATLASSIAN_API_TOKEN="$(cat ~/.secrets/atlassian-api-token)"
  # END AGENT_CONTEXT
  ----------------------------------------

  Proceed? [y/N]: y
[V] Added shell configuration to /Users/you/.zshrc
```

### Step 4: 쉘 재시작

```bash
source ~/.zshrc   # zsh 사용자
# source ~/.bashrc  # bash 사용자 (Linux)
# source ~/.bash_profile  # bash 사용자 (macOS)
```

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

**출력 및 입력 예시:**
```
============================================================
Agent-Context Installation
============================================================

Source:   /Users/you/.agent-context
Target:   /path/to/your-project
Profile:  full
Force:    false

[i] Installing core files...
[V] Created: .cursorrules (with index map)
[V] Installed: .agent/skills/
[V] Installed: .agent/workflows/
[V] Installed: .agent/docs/
[V] Installed: .agent/tools/pm/
[i] Configuring .project.yaml...

[i] Configure your platform settings (press Enter to skip):

  Jira URL [https://your-domain.atlassian.net]: https://mycompany.atlassian.net
  Jira Project Key [e.g., PROJ]: DEMO
  Atlassian Email [your-email@example.com]: developer@mycompany.com
  GitLab URL (optional) [https://gitlab.example.com]: https://gitlab.mycompany.com
  Confluence Space Key (optional) [e.g., DEV or ~user]: DEV
  GitHub Repo (optional) [e.g., owner/repo]:

[V] Created: .project.yaml (fully configured)
[i]   Jira: https://mycompany.atlassian.net (DEMO)
[i]   Email: developer@mycompany.com
[i]   GitLab: https://gitlab.mycompany.com
[i] Installing configuration files (full profile)...
[V] Installed: .editorconfig
[V] Installed: .pre-commit-config.yaml
[V] Updated: .gitignore (agent-context entries appended)
[V] Found global secrets: ~/.secrets
[V]   - Atlassian API token found

============================================================
Installation Complete
============================================================

[V] Agent-context installed successfully!
```

### Step 7: 설정 확인

```bash
cat .project.yaml
```

**출력 예시:**
```yaml
roles:
  vcs: gitlab
  issue: jira
  review: gitlab
  docs: confluence

platforms:
  jira:
    base_url: https://mycompany.atlassian.net
    project_key: DEMO
    email: developer@mycompany.com

  confluence:
    base_url: https://mycompany.atlassian.net/wiki
    space_key: DEV

  gitlab:
    base_url: https://gitlab.mycompany.com

branch:
  feature_prefix: feat/
  bugfix_prefix: fix/
  hotfix_prefix: hotfix/
```

### Step 8: 연결 테스트

```bash
agent-context pm config show
agent-context pm jira me
```

**출력 예시:**
```
[i] Configuration loaded from: .project.yaml
[V] Jira: https://mycompany.atlassian.net (DEMO)
[V] Email: developer@mycompany.com
[V] Token: ~/.secrets/atlassian-api-token

{
  "displayName": "Developer Name",
  "emailAddress": "developer@mycompany.com",
  "accountId": "..."
}
```

---

### 주요 명령어

| 명령어 | 설명 |
|--------|------|
| `agent-context init` | 글로벌 환경 초기화 |
| `agent-context install` | 현재 프로젝트에 설치 (대화형) |
| `agent-context install --force` | 기존 파일 덮어쓰기 |
| `agent-context install --profile minimal` | 최소 설치 (core만) |
| `agent-context install --non-interactive` | 비대화형 설치 |
| `agent-context pm <cmd>` | 프로젝트 PM CLI 실행 |

### 비대화형 설치 (CI/스크립트용)

```bash
agent-context install --non-interactive --force \
    --jira-url https://mycompany.atlassian.net \
    --jira-project DEMO \
    --jira-email developer@mycompany.com \
    --gitlab-url https://gitlab.mycompany.com
```

상세 가이드: [docs/USER_GUIDE.md](docs/USER_GUIDE.md)

---

## 개발자 빠른 시작

agent-context 자체를 개발하거나 기여합니다.

```bash
# 1. 저장소 클론
git clone https://github.com/your-org/agent-context.git
cd agent-context

# 2. 의존성 설치
pip install pre-commit
brew install gh glab jq yq shellcheck shfmt

# 3. pre-commit 훅 설정
pre-commit install

# 4. 피처 브랜치에서 작업
git checkout -b feat/my-feature
# ... make changes ...
pre-commit run --all-files
git commit -m "feat: add new feature"

# 5. 데모로 검증 (선택)
./demo/install.sh --skip-e2e --only 6
```

상세 가이드: [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)

---

## 프로젝트 구조

```
agent-context/
├── docs/               # 문서
│   ├── ARCHITECTURE.md # 설계 철학 (SSOT)
│   ├── USER_GUIDE.md   # 사용자 가이드
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

## CLI 도구 요약

| 도구 | 용도 | 주요 명령 |
|------|------|----------|
| `git` | 버전 관리 | `checkout`, `commit`, `push` |
| `gh` | GitHub | `pr create`, `pr merge` |
| `glab` | GitLab | `mr create`, `mr merge` |
| `pm` | JIRA/Confluence | `jira issue`, `confluence page` |

## 필수 도구

| 도구 | 목적 | 설치 |
|------|---------|---------|
| `git` | 버전 관리 | 대부분 사전 설치 |
| `gh` | GitHub CLI | `brew install gh` |
| `glab` | GitLab CLI | `brew install glab` |
| `pre-commit` | 린팅/포맷팅 | `pip install pre-commit` |
| `jq` | JSON 처리 | `brew install jq` |
| `yq` | YAML 처리 | `brew install yq` |

## 문서

| 문서 | 설명 | 대상 |
|------|------|------|
| [docs/USER_GUIDE.md](docs/USER_GUIDE.md) | 설치 및 사용법 | 사용자 |
| [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) | 개발 및 기여 | 개발자 |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | 설계 철학 | 모두 |
| [docs/convention/](docs/convention/) | 코딩 컨벤션 | 개발자 |
| [workflows/README.md](workflows/README.md) | 워크플로 공통 정책 | 모두 |
| [demo/README.md](demo/README.md) | 데모 가이드 | 개발자 |

## 라이선스

MIT License - 자세한 내용은 [LICENSE](LICENSE)를 참고.
