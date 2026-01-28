# agnt-c 시작 가이드

AI 에이전트 기반 개발 워크플로우를 위한 `agnt-c` CLI 설치 및 사용 가이드입니다.

## 목차

1. [설치](#설치)
2. [프로젝트 적용](#프로젝트-적용)
3. [기본 사용법](#기본-사용법)
4. [워크플로우 예시](#워크플로우-예시)
5. [문제 해결](#문제-해결)

---

## 설치

### 방법 1: 프로젝트-로컬 설치 (권장)

프로젝트별로 버전을 고정하고 싶을 때 사용합니다.

```bash
# 1. 프로젝트 디렉토리로 이동
cd your-project
git init  # git 저장소가 아니면 초기화

# 2. agent-context를 .agent 디렉토리로 클론
git clone https://github.com/iamwonseok/agent-context.git .agent

# 3. 현재 세션에서 활성화
source .agent/activate.sh

# 4. 버전 확인
agnt-c --version
# 출력: agnt-c version 2.0.0
```

**장점:**
- 프로젝트별 버전 고정 가능
- 다른 도구와 충돌 없음
- 팀원 간 동일한 버전 보장

### 방법 2: 글로벌 설치

모든 프로젝트에서 공통으로 사용하고 싶을 때 사용합니다.

```bash
# 1. 클론
git clone https://github.com/iamwonseok/agent-context.git ~/.agent

# 2. 글로벌 설치 실행
cd ~/.agent
./setup.sh --global

# 3. 쉘 프로파일에 추가 (~/.bashrc 또는 ~/.zshrc)
export AGENT_CONTEXT_PATH="$HOME/.agent"
export PATH="$HOME/.agent/tools/agent/bin:$HOME/.agent/tools/pm/bin:$HOME/.agent/tools/lint/bin:$PATH"

# 4. 쉘 재시작 또는 적용
source ~/.bashrc  # 또는 source ~/.zshrc

# 5. 확인
agnt-c --version
```

### 사전 요구사항

| 도구 | 용도 | 설치 확인 |
|------|------|----------|
| git | 버전 관리 | `git --version` |
| bash | 스크립트 실행 | `bash --version` |
| curl | (선택) HTTP 요청 | `curl --version` |

---

## 프로젝트 적용

### 1. 템플릿 설치

새 프로젝트 또는 기존 프로젝트에 agent-context 템플릿을 설치합니다.

```bash
cd your-project

# 프로젝트-로컬 설치인 경우
source .agent/activate.sh

# 템플릿 설치 (처음 또는 업데이트)
agnt-c setup

# 기존 파일 덮어쓰기
agnt-c setup --force
```

**생성되는 파일:**

| 파일/디렉토리 | 설명 |
|--------------|------|
| `.cursorrules` | AI 에이전트 행동 규칙 |
| `configs/` | 코드 스타일 설정 (clang-format, flake8 등) |
| `plan/` | 프로젝트 계획 템플릿 |
| `.gitignore` 항목 | `.context/`, `.worktrees/`, `.secrets/` |

### 2. JIRA/GitLab 연동 설정 (선택)

대화형 설정을 실행하여 프로젝트 설정을 구성합니다.

```bash
# 대화형 설정 (JIRA/GitLab URL, 프로젝트 키 등)
./setup.sh
# 또는
.agent/setup.sh

# CI 환경에서 (비대화형)
./setup.sh --non-interactive --skip-secrets
```

**생성되는 파일:**

| 파일 | 설명 |
|------|------|
| `.project.yaml` | 프로젝트 설정 (JIRA URL, GitLab 프로젝트 등) |
| `.secrets/` | API 토큰 (gitignore됨) |

### 3. API 토큰 설정 (선택)

JIRA/GitLab 연동을 사용하려면 토큰을 설정합니다.

**방법 A: 파일로 설정**

```bash
# GitLab 토큰
echo "glpat-xxx" > .secrets/gitlab-api-token

# GitHub 토큰
echo "ghp_xxx" > .secrets/github-api-token

# Atlassian (JIRA/Confluence) 토큰
echo "ATATT3xFfGF0xxx" > .secrets/atlassian-api-token
```

**방법 B: 환경변수로 설정**

```bash
export GITLAB_TOKEN="glpat-xxx"
export GITHUB_TOKEN="ghp_xxx"
export JIRA_TOKEN="your-atlassian-token"
export JIRA_EMAIL="your-email@example.com"
```

---

## 기본 사용법

### 명령어 구조

```
agnt-c [role] <action> [options]

Roles:
  dev    개발자 명령어 (기본값)
  mgr    매니저 명령어
```

### 개발자 명령어 (agnt-c dev)

| 명령어 | 설명 | 예시 |
|--------|------|------|
| `start <task-id>` | 작업 시작 (브랜치 생성) | `agnt-c dev start TASK-123` |
| `list` | 활성 작업 목록 | `agnt-c dev list` |
| `status` | 현재 상태 확인 | `agnt-c dev status` |
| `check` | 품질 검사 (lint, test) | `agnt-c dev check` |
| `sync` | 베이스 브랜치와 동기화 | `agnt-c dev sync` |
| `submit` | MR 생성 및 제출 | `agnt-c dev submit` |
| `cleanup <task-id>` | 완료된 작업 정리 | `agnt-c dev cleanup TASK-123` |

**단축 명령어** (`dev` 생략 가능):

```bash
agnt-c start TASK-123   # = agnt-c dev start TASK-123
agnt-c sync             # = agnt-c dev sync
agnt-c submit           # = agnt-c dev submit
agnt-c check            # = agnt-c dev check
```

### 매니저 명령어 (agnt-c mgr)

| 명령어 | 설명 | 예시 |
|--------|------|------|
| `pending` | 대기 중인 MR 목록 | `agnt-c mgr pending` |
| `review <mr-id>` | MR 상세 검토 | `agnt-c mgr review 123` |
| `approve <mr-id>` | MR 승인 | `agnt-c mgr approve 123` |
| `status [id]` | 상태 확인 | `agnt-c mgr status EPIC-1` |

### 공통 명령어

```bash
agnt-c --help           # 도움말
agnt-c --version        # 버전 확인
agnt-c status           # 전체 상태
agnt-c config show      # 설정 확인
agnt-c init             # 프로젝트 초기화
agnt-c setup            # 템플릿 설치
```

---

## 워크플로우 예시

### 예시 1: 기능 개발 (Feature)

```bash
# 1. 작업 시작
agnt-c dev start TASK-123
# → feat/TASK-123 브랜치 생성
# → .context/TASK-123/ 컨텍스트 디렉토리 생성

# 2. 코드 작성
vim src/feature.c

# 3. 품질 검사
agnt-c dev check

# 4. 커밋
git add -A
git commit -m "feat: implement new feature"

# 5. 베이스 브랜치와 동기화
agnt-c dev sync

# 6. MR 생성 및 제출
agnt-c dev submit
```

### 예시 2: 버그 수정 (Bug Fix)

```bash
# 1. 버그 수정 작업 시작
agnt-c dev start BUG-456
# → fix/BUG-456 브랜치 생성

# 2. 수정 후 커밋
git commit -m "fix: resolve timeout issue"

# 3. 제출
agnt-c dev submit
```

### 예시 3: 핫픽스 (Hotfix)

```bash
# main에서 직접 분기
agnt-c dev start HOTFIX-789 --from=main
# → hotfix/HOTFIX-789 브랜치 생성

# 긴급 수정 후 제출
agnt-c dev submit
```

### 예시 4: 병렬 실험 (A/B Testing)

```bash
# 접근법 A 시도 (워크트리 모드)
agnt-c dev start TASK-123 --detached --try="approach-a"
# → .worktrees/TASK-123-approach-a/ 생성

# 접근법 B 시도 (별도 워크트리)
agnt-c dev start TASK-123 --detached --try="approach-b"
# → .worktrees/TASK-123-approach-b/ 생성

# 활성 작업 확인
agnt-c dev list

# 성공한 접근법 제출
cd .worktrees/TASK-123-approach-a
agnt-c dev submit
```

---

## 작업 모드

### Interactive Mode (기본)

현재 디렉토리에서 Git 브랜치로 작업합니다.

```bash
agnt-c dev start TASK-123
# 생성: feat/TASK-123 브랜치
# 생성: .context/TASK-123/ 디렉토리
```

**적합한 경우:**
- 단일 작업에 집중
- 실시간 작업 확인
- 빠른 반복 작업

### Detached Mode (워크트리)

별도의 워크트리 디렉토리에서 독립적으로 작업합니다.

```bash
agnt-c dev start TASK-123 --detached
# 생성: .worktrees/TASK-123/ 디렉토리
# 생성: .worktrees/TASK-123/.context/
```

**적합한 경우:**
- 백그라운드 작업
- 여러 실험 병렬 진행
- 현재 작업 중단 없이 새 작업

---

## 디렉토리 구조

### 프로젝트 구조 (설치 후)

```
your-project/
├── .agent/                    # agent-context (프로젝트-로컬 설치)
├── .cursorrules               # AI 에이전트 규칙
├── .project.yaml              # 프로젝트 설정 (JIRA/GitLab)
├── .secrets/                  # API 토큰 (gitignore됨)
│   ├── gitlab-api-token
│   └── atlassian-api-token
├── .context/                  # 작업 컨텍스트 (gitignore됨)
│   └── TASK-123/
│       ├── try.yaml
│       └── attempts/
├── .worktrees/                # 워크트리 (gitignore됨)
│   └── TASK-123-approach-a/
├── configs/                   # 코드 스타일 설정
├── plan/                      # 프로젝트 계획
└── src/                       # 소스 코드
```

### 컨텍스트 구조

```
.context/TASK-123/
├── try.yaml           # 작업 세션 정보
├── attempts/          # 시도 기록
│   ├── attempt-001.yaml
│   └── attempt-002.yaml
├── verification.md    # 검증 보고서 (agnt-c dev verify)
├── retrospective.md   # 회고 문서 (agnt-c dev retro)
└── summary.yaml       # 요약 (제출 시 생성)
```

---

## 문제 해결

### "command not found: agnt-c"

PATH가 설정되지 않았습니다.

**프로젝트-로컬 설치:**
```bash
source .agent/activate.sh
```

**글로벌 설치:**
```bash
# ~/.bashrc 또는 ~/.zshrc에 추가
export PATH="$HOME/.agent/tools/agent/bin:$PATH"
source ~/.bashrc
```

### 다른 'agent' 명령어와 충돌

`agnt-c`는 이러한 충돌을 피하기 위해 고유한 이름을 사용합니다.

```bash
# 어떤 agent가 실행되는지 확인
which agent
which agnt-c

# agnt-c가 agent-context의 것인지 확인
agnt-c --version
# 출력: agnt-c version 2.0.0
```

### Git 저장소가 아닌 곳에서 실행

```bash
$ agnt-c status
[WARN] Not in a git repository

# 해결: git 초기화
git init
```

### JIRA/GitLab 연동 오류

```bash
# 토큰 확인
cat .secrets/gitlab-api-token
cat .secrets/atlassian-api-token

# 환경변수 확인
echo $GITLAB_TOKEN
echo $JIRA_TOKEN

# 설정 확인
agnt-c config show
```

### Rebase 충돌

```bash
# 충돌 발생 시
agnt-c dev sync
# [ERROR] Rebase conflict detected

# 1. 충돌 파일 수정
vim src/conflict-file.c

# 2. 해결 후 스테이징
git add src/conflict-file.c

# 3. 계속 진행
agnt-c dev sync --continue

# 또는 취소
agnt-c dev sync --abort
```

---

## 다음 단계

- [Cursor 모드 가이드](cursor-modes-guide.md) - AI 에이전트 모드 활용
- [수동 대체 가이드](manual-fallback-guide.md) - CLI 실패 시 수동 진행
- [문제 해결](troubleshooting.md) - 상세 문제 해결 가이드
- [플랫폼 설정 예시](platform-setup-examples.md) - JIRA/GitLab 상세 설정

---

## 빠른 참조

```bash
# 설치 (프로젝트-로컬)
git clone https://github.com/iamwonseok/agent-context.git .agent
source .agent/activate.sh
agnt-c setup

# 일반적인 워크플로우
agnt-c start TASK-123       # 작업 시작
# ... 코드 작성 및 커밋 ...
agnt-c check                # 품질 검사
agnt-c sync                 # 동기화
agnt-c submit               # 제출

# 도움말
agnt-c --help
agnt-c dev --help
agnt-c mgr --help
```
