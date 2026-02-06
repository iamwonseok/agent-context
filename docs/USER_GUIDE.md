# 사용자 가이드

agent-context를 프로젝트에 설치하고 활용하는 방법을 안내합니다.

## 목차

- [설치](#설치)
- [설정](#설정)
- [워크플로 사용](#워크플로-사용)
- [CLI 도구](#cli-도구)
- [문제 해결](#문제-해결)

---

## 설치

### 필수 조건

#### 1. GitLab 접근 설정

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

#### 2. GitLab PAT 생성

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

#### 3. 의존성 설치

**macOS**:

```bash
brew install git jq yq glab
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

# glab
curl -s https://raw.githubusercontent.com/profclems/glab/trunk/scripts/install.sh | sudo sh

pip3 install --user pre-commit
```

**RHEL/CentOS/Fedora**:

```bash
sudo dnf install -y git curl jq python3 python3-pip
# yq, glab 설치는 Ubuntu와 동일
```

#### 4. glab 인증

```bash
glab auth login --hostname gitlab.fadutec.dev
# Protocol: SSH
# Login method: Paste a token
# Token: [저장한 PAT 붙여넣기]

glab auth status  # 확인
```

#### 5. Atlassian 토큰 설정 (옵션)

Jira/Confluence 연동이 필요한 경우:

1. https://id.atlassian.com/manage-profile/security/api-tokens 접속
2. "Create API token" 클릭
3. 토큰 저장:

```bash
read -sp "Atlassian Token: " token && echo "$token" > ~/.secrets/atlassian-api-token && chmod 600 ~/.secrets/atlassian-api-token && unset token
```

### 설치 방법

```bash
# 1. agent-context 클론 (글로벌 설치)
git clone git@gitlab.fadutec.dev:soc-ip/agentic-ai/agent-context.git ~/.agent-context

# 2. 글로벌 환경 초기화
~/.agent-context/agent-context.sh init

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
| `full` | minimal + `.editorconfig`, `.pre-commit-config.yaml` 등 |

### 설치 결과

```
your-project/
├── .cursorrules           # AI 에이전트 규칙
├── .project.yaml          # 프로젝트 설정
├── .agent/
│   ├── skills/            # 범용 스킬 템플릿
│   ├── workflows/         # 컨텍스트 기반 워크플로
│   └── tools/pm/          # JIRA/Confluence CLI
└── .editorconfig          # (full 프로필)
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

API 토큰은 `~/.secrets/` 디렉토리에 저장합니다:

```bash
# 디렉토리 생성
mkdir -p ~/.secrets && chmod 700 ~/.secrets

# Atlassian API 토큰
# https://id.atlassian.com/manage-profile/security/api-tokens
echo "YOUR_ATLASSIAN_TOKEN" > ~/.secrets/atlassian-api-token
chmod 600 ~/.secrets/atlassian-api-token

# GitLab API 토큰
echo "YOUR_GITLAB_TOKEN" > ~/.secrets/gitlab-api-token
chmod 600 ~/.secrets/gitlab-api-token
```

### 연결 테스트

```bash
# pm CLI를 PATH에 추가
export PATH="$PATH:$(pwd)/.agent/tools/pm/bin"

# 설정 확인
pm config show

# JIRA 연결 테스트
pm jira me

# Confluence 연결 테스트
pm confluence me
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

### 기본 작업 흐름

```bash
# 1. 피처 브랜치 생성
git checkout -b feat/TASK-123-description

# 2. 워크플로 참조하며 작업
# AI 에이전트가 .agent/workflows/solo/feature.md 참조

# 3. 변경사항 커밋
git add .
git commit -m "feat: add new feature"

# 4. 품질 검사
pre-commit run --all-files

# 5. PR/MR 생성
git push origin feat/TASK-123-description
gh pr create --title "TASK-123: Add new feature"
# 또는
glab mr create --title "TASK-123: Add new feature"
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

## CLI 도구

### pm (JIRA/Confluence)

```bash
# JIRA 이슈 관리
pm jira issue list                    # 이슈 목록
pm jira issue view TASK-123           # 이슈 상세
pm jira issue create "Title"          # 이슈 생성
pm jira issue transition TASK-123     # 상태 변경
pm jira issue comment add TASK-123 "comment"  # 코멘트 추가

# Confluence 페이지 관리
pm confluence page list               # 페이지 목록
pm confluence page create "Title"     # 페이지 생성
```

### Git 작업

```bash
# 브랜치 관리
git checkout -b feat/TASK-123         # 피처 브랜치
git checkout -b fix/TASK-456          # 버그픽스 브랜치
git checkout -b hotfix/TASK-789       # 핫픽스 브랜치

# 커밋 컨벤션
git commit -m "feat: add new feature"
git commit -m "fix: resolve bug"
git commit -m "refactor: improve code"
git commit -m "docs: update readme"
```

### GitHub CLI (gh)

```bash
gh pr create                          # PR 생성
gh pr list                            # PR 목록
gh pr view 123                        # PR 상세
gh pr merge 123                       # PR 머지
gh issue create                       # 이슈 생성
```

### GitLab CLI (glab)

```bash
glab mr create                        # MR 생성
glab mr list                          # MR 목록
glab mr view 123                      # MR 상세
glab mr merge 123                     # MR 머지
glab issue create                     # 이슈 생성
```

---

## 문제 해결

### "pm: command not found"

```bash
# PATH에 pm CLI 추가
export PATH="$PATH:$(pwd)/.agent/tools/pm/bin"

# 또는 .bashrc/.zshrc에 추가
echo 'export PATH="$PATH:$HOME/your-project/.agent/tools/pm/bin"' >> ~/.zshrc
```

### "Client must be authenticated" (JIRA)

```bash
# 이메일이 Atlassian 계정과 일치하는지 확인
pm config show

# .project.yaml의 email이 정확한지 확인
# 토큰이 유효한지 확인
cat ~/.secrets/atlassian-api-token
```

### "Secrets directory not found"

```bash
# 시크릿 디렉토리 생성
mkdir -p ~/.secrets && chmod 700 ~/.secrets

# 토큰 파일 생성
echo "YOUR_TOKEN" > ~/.secrets/atlassian-api-token
chmod 600 ~/.secrets/atlassian-api-token
```

### pre-commit 실패

```bash
# 개별 훅 실행하여 문제 확인
pre-commit run shellcheck --all-files
pre-commit run trailing-whitespace --all-files

# 훅 업데이트
pre-commit autoupdate
```

---

## 관련 문서

- [설계 철학 (ARCHITECTURE.md)](ARCHITECTURE.md)
- [워크플로 공통 정책 (workflows/README.md)](../workflows/README.md)
- [코딩 컨벤션 (convention/)](convention/)
