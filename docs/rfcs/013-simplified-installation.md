# RFC-013: Simplified Installation & Minimal Core

**Status**: Draft
**Author**: wonseok
**Created**: 2026-01-29
**Related**: RFC-008 (Domain Extension & Installation)

---

## 1. Summary

agent-context의 설치 및 배포를 단순화합니다:

1. **Tools 전역 설치**: `agnt-c`, `pm`, `lint`를 시스템 전역에 한 번 설치
2. **Minimal Core**: 핵심 스킬 8개만 포함한 경량 버전
3. **프로젝트 초기화**: `agnt-c init`으로 프로젝트별 설정
4. **Docker E2E 테스트**: 깨끗한 환경에서 전체 플로우 검증

---

## 2. Motivation

### 2.1 현재 문제

| 문제 | 설명 |
|------|------|
| 파일 과다 | 289개 파일 (테스트 제외) |
| 복잡한 설치 | 395줄 setup.sh |
| PATH 설정 반복 | 프로젝트마다 PATH 설정 필요 |
| 테스트 어려움 | 깨끗한 환경에서 테스트 불가 |

### 2.2 개선 목표

| 항목 | 현재 | 개선 후 |
|------|------|---------|
| 파일 수 | 289개 | Minimal 15개 |
| 설치 | 복잡한 setup.sh (395줄) | git clone + install.sh (~80줄) |
| PATH 설정 | 프로젝트마다 수동 | 전역 한 번 설치 |
| 업데이트 | 수동 복사 | git pull |

---

## 3. Design

### 3.1 설치 시퀀스

```
Phase 1: Tools 설치 (시스템 전역, 한 번)
─────────────────────────────────────────
# 1. Clone
git clone https://github.com/user/agent-context.git ~/.agent-context

# 2. Install
~/.agent-context/install.sh

결과:
  ~/.agent-context/          # 소스 (git 관리)
  └── tools/
      ├── agent/bin/agnt-c
      ├── pm/bin/pm
      └── lint/bin/lint

  ~/.agent-tools/            # 심링크 또는 복사본
  └── bin/
      ├── agnt-c -> ~/.agent-context/tools/agent/bin/agnt-c
      ├── pm -> ~/.agent-context/tools/pm/bin/pm
      └── lint -> ~/.agent-context/tools/lint/bin/lint

PATH 자동 추가: ~/.bashrc 또는 ~/.zshrc

업데이트:
  cd ~/.agent-context && git pull


Phase 2: 프로젝트 초기화 (각 프로젝트)
─────────────────────────────────────────
cd my-project
agnt-c init              # minimal (핵심 8개 스킬)
agnt-c init --full       # full (모든 27개 스킬)
agnt-c init --bare       # 스킬 없이 설정만

결과:
  my-project/
  ├── .agent/
  │   ├── skills/        # 선택한 스킬
  │   └── workflows/     # 선택한 워크플로우
  ├── .project.yaml      # 프로젝트 설정
  └── .gitignore         # 자동 업데이트


Phase 3: Secrets 설정 (필수)
─────────────────────────────────────────
agnt-c config            # 대화형 설정 (secrets 포함)

필수 토큰:
  .secrets/atlassian-api-token   # JIRA + Confluence
  .secrets/gitlab-api-token      # GitLab

또는 환경 변수:
  export JIRA_TOKEN="..."
  export GITLAB_TOKEN="..."

CI 환경에서만 스킵 가능:
  agnt-c init --skip-secrets

Note: secrets 없이 init 시도 시 에러 + 가이드 출력
```

### 3.2 Minimal Core 구성

**핵심 스킬 (8개)**:

| 단계 | 스킬 | 파일명 |
|------|------|--------|
| Analyze | parse-requirement | parse-requirement.md |
| Plan | design-solution | design-solution.md |
| Execute | write-code | write-code.md |
| Validate | run-tests | run-tests.md |
| Validate | check-style | check-style.md |
| Validate | review-code | review-code.md |
| Integrate | commit-changes | commit-changes.md |
| Integrate | create-merge-request | create-mr.md |

**핵심 워크플로우 (2개)**:

| 워크플로우 | 파일명 |
|------------|--------|
| Feature 개발 | feature.md |
| 버그 수정 | bugfix.md |

**Minimal 구조 (~15개 파일)**:

```
.agent/
├── skills/
│   ├── parse-requirement.md
│   ├── design-solution.md
│   ├── write-code.md
│   ├── run-tests.md
│   ├── check-style.md
│   ├── review-code.md
│   ├── commit-changes.md
│   └── create-mr.md
├── workflows/
│   ├── feature.md
│   └── bugfix.md
└── README.md
```

### 3.3 Full 구성

모든 스킬 (27개) + 모든 워크플로우 + 도구

---

## 4. Command Logging (디버깅)

### 4.1 요구사항

| 시나리오 | 요구사항 |
|----------|----------|
| 여러 프로젝트 | 프로젝트별 로그 분리 |
| Worktree 병렬 | 동시 실행 구분 가능 |
| 브랜치별 작업 | 브랜치 정보 포함 |
| 히스토리 추적 | 시간순 정렬 가능 |

### 4.2 로그 위치 (Symlink + Worktree별 서브디렉터리)

```
my-project/
├── .context/                           # 메인에 모든 로그 집중
│   ├── logs/                           # 메인 브랜치 로그
│   │   ├── agent.log
│   │   └── workflow.log
│   │
│   ├── TASK-123/                       # worktree별 서브디렉터리
│   │   └── logs/
│   │       ├── agent.log
│   │       └── workflow.log
│   │
│   └── TASK-456/
│       └── logs/
│           ├── agent.log
│           └── workflow.log
│
└── .worktrees/
    ├── TASK-123/
    │   └── .context -> ../../.context  # symlink to main
    │
    └── TASK-456/
        └── .context -> ../../.context  # symlink to main
```

**Symlink 설정** (`.cursor/worktrees.json`):

```json
{
  "setup-worktree": [
    "./tools/worktree/add-symlink.sh .context"
  ]
}
```

**동작 원리**:
1. Cursor가 worktree 생성 시 `add-symlink.sh .context` 자동 실행
2. worktree의 `.context/`가 main의 `.context/`로 symlink됨
3. worktree에서 로그 쓸 때: `.context/{worktree-name}/logs/agent.log`
4. **main의 `.context/`에서 모든 worktree 로그를 한눈에 확인**

**로그 경로 결정 로직**:

```bash
# worktree에서 실행 시
# CWD: /project/.worktrees/TASK-123/src
# → worktree 이름 감지: TASK-123
# → 로그 경로: .context/TASK-123/logs/agent.log
# → 실제 경로: /project/.context/TASK-123/logs/agent.log (symlink 통해)

# main에서 실행 시
# CWD: /project/src
# → 로그 경로: .context/logs/agent.log
```

**장점**:
- main에서 `ls .context/` 하면 모든 worktree 로그 보임
- 각 worktree 로그가 디렉터리로 구분되어 깔끔함
- worktree 삭제 후에도 로그 유지 (main에 있으므로)
- grep으로 전체 검색 가능: `grep -r "ERROR" .context/*/logs/`

### 4.3 로그 형식 (동시 실행 지원)

```
[2026-01-29 10:30:45] [PID:12345] [branch:feature/TASK-123] CMD: agnt-c dev start TASK-123
[2026-01-29 10:30:45] [PID:12345] [branch:feature/TASK-123] CWD: /Users/wonseok/my-project
[2026-01-29 10:30:46] [PID:12345] [branch:feature/TASK-123] OUT: Creating branch...
[2026-01-29 10:30:48] [PID:12345] [branch:feature/TASK-123] EXIT: 0 (success)
---
[2026-01-29 10:30:46] [PID:12346] [branch:feature/TASK-456] CMD: agnt-c dev start TASK-456
[2026-01-29 10:30:46] [PID:12346] [branch:feature/TASK-456] CWD: /Users/wonseok/my-project/.worktrees/TASK-456
[2026-01-29 10:30:47] [PID:12346] [branch:feature/TASK-456] OUT: Creating branch...
[2026-01-29 10:30:49] [PID:12346] [branch:feature/TASK-456] EXIT: 0 (success)
```

**필드 설명**:
- `PID`: 프로세스 ID (동시 실행 구분)
- `branch`: 현재 브랜치 (worktree 구분)
- `CWD`: 실행 디렉터리 (worktree 경로 포함)

### 4.4 로깅 라이브러리

```bash
# tools/agent/lib/logging.sh

# 프로젝트 루트 찾기
_log_find_project_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.git" ]] || [[ -f "$dir/.project.yaml" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    echo "$PWD"
}

# Worktree 이름 감지
# - worktree 내부면: worktree 이름 반환 (예: TASK-123)
# - main이면: 빈 문자열 반환
_log_get_worktree_name() {
    local dir="$PWD"
    
    # .worktrees/TASK-XXX/ 패턴 확인
    if [[ "$dir" == *"/.worktrees/"* ]]; then
        # .worktrees/ 다음의 디렉터리 이름 추출
        echo "$dir" | sed 's|.*/.worktrees/\([^/]*\).*|\1|'
    else
        echo ""  # main worktree
    fi
}

# 로그 디렉터리 경로
# - main: .context/logs/
# - worktree: .context/{worktree-name}/logs/
_log_get_dir() {
    local project_root
    project_root=$(_log_find_project_root)
    
    local worktree_name
    worktree_name=$(_log_get_worktree_name)
    
    local log_dir
    if [[ -n "$worktree_name" ]]; then
        log_dir="$project_root/.context/$worktree_name/logs"
    else
        log_dir="$project_root/.context/logs"
    fi
    
    mkdir -p "$log_dir"
    echo "$log_dir"
}

# 로그 파일 경로
_log_get_file() {
    echo "$(_log_get_dir)/agent.log"
}

# workflow 로그 파일 경로
_log_get_workflow_file() {
    echo "$(_log_get_dir)/workflow.log"
}

# 현재 브랜치
_log_get_branch() {
    git branch --show-current 2>/dev/null || echo "unknown"
}

# 로그 접두사 (PID + branch)
_log_prefix() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local pid=$$
    local branch=$(_log_get_branch)
    echo "[$timestamp] [PID:$pid] [branch:$branch]"
}

# 로그 초기화 (명령어 시작 시)
log_init() {
    local log_file=$(_log_get_file)
    
    {
        echo "$(_log_prefix) CMD: $0 $*"
        echo "$(_log_prefix) CWD: $(pwd)"
        echo "$(_log_prefix) ENV: AGENT_MOCK=${AGENT_MOCK:-0}, AGENT_TASK_ID=${AGENT_TASK_ID:-}"
    } >> "$log_file"
}

# 출력 로그
log_out() {
    local log_file=$(_log_get_file)
    echo "$(_log_prefix) OUT: $*" >> "$log_file"
    echo "$*"  # 화면에도 출력
}

# 에러 로그
log_err() {
    local log_file=$(_log_get_file)
    echo "$(_log_prefix) ERR: $*" >> "$log_file"
    echo "[ERROR] $*" >&2
}

# 종료 로그
log_exit() {
    local exit_code=$1
    local log_file=$(_log_get_file)
    
    if [[ $exit_code -eq 0 ]]; then
        echo "$(_log_prefix) EXIT: 0 (success)" >> "$log_file"
    else
        echo "$(_log_prefix) EXIT: $exit_code (error)" >> "$log_file"
    fi
    echo "---" >> "$log_file"
}
```

### 4.5 사용 예시

```bash
# 현재 위치 로그 보기 (main 또는 worktree)
agnt-c log               # 최근 50줄
agnt-c log 100           # 최근 100줄

# 특정 worktree 로그 보기 (main에서)
agnt-c log --worktree TASK-123

# 모든 worktree 로그 보기 (main에서)
agnt-c log --all

# 에러만 보기
agnt-c log --errors

# 로그 파일 위치
agnt-c log --path
# main:     .context/logs/agent.log
# worktree: .context/TASK-123/logs/agent.log
```

**직접 파일 접근** (main에서):

```bash
# main 로그
cat .context/logs/agent.log

# 특정 worktree 로그
cat .context/TASK-123/logs/agent.log
cat .context/TASK-456/logs/workflow.log

# 모든 worktree 로그 검색
grep -r "ERROR" .context/*/logs/

# 모든 로그에서 특정 태스크 검색
grep -r "TASK-789" .context/

# 디렉터리 구조 확인
ls -la .context/
# logs/        (main)
# TASK-123/    (worktree)
# TASK-456/    (worktree)
```

### 4.7 Skill/Workflow 실행 로깅

CLI 명령어와 별개로, 에이전트가 실행한 skill/workflow 흐름 추적:

**로그 파일**:

```
.context/logs/
├── agent.log           # CLI 명령어 로그
└── workflow.log        # skill/workflow 실행 흐름 로그
```

**Workflow 로그 형식**:

```
[2026-01-29 10:30:45] [TASK:TASK-123] [session:abc123] WORKFLOW_START: developer/feature
[2026-01-29 10:30:45] [TASK:TASK-123] [session:abc123] WORKFLOW_PARAMS: {"task_id": "TASK-123", "branch": "feature/TASK-123"}
[2026-01-29 10:30:46] [TASK:TASK-123] [session:abc123] SKILL_START: analyze/parse-requirement
[2026-01-29 10:30:46] [TASK:TASK-123] [session:abc123] SKILL_INPUT: {"request": "UART driver implementation"}
[2026-01-29 10:31:20] [TASK:TASK-123] [session:abc123] SKILL_OUTPUT: {"design_doc": "design/uart.md"}
[2026-01-29 10:31:20] [TASK:TASK-123] [session:abc123] SKILL_END: analyze/parse-requirement (34s, OK)
[2026-01-29 10:31:21] [TASK:TASK-123] [session:abc123] SKILL_START: planning/design-solution
[2026-01-29 10:32:15] [TASK:TASK-123] [session:abc123] SKILL_END: planning/design-solution (54s, OK)
[2026-01-29 10:32:16] [TASK:TASK-123] [session:abc123] SKILL_START: execute/write-code
[2026-01-29 10:35:42] [TASK:TASK-123] [session:abc123] SKILL_ERROR: execute/write-code - lint failed
[2026-01-29 10:35:42] [TASK:TASK-123] [session:abc123] SKILL_RETRY: execute/write-code (attempt 2)
[2026-01-29 10:38:10] [TASK:TASK-123] [session:abc123] SKILL_END: execute/write-code (356s, OK after retry)
[2026-01-29 10:38:11] [TASK:TASK-123] [session:abc123] SKILL_START: validate/run-tests
[2026-01-29 10:39:45] [TASK:TASK-123] [session:abc123] SKILL_END: validate/run-tests (94s, OK)
[2026-01-29 10:39:46] [TASK:TASK-123] [session:abc123] SKILL_SKIP: validate/check-style (already passed in write-code)
[2026-01-29 10:39:47] [TASK:TASK-123] [session:abc123] WORKFLOW_END: developer/feature (9m 2s, OK)
---
```

**필드 설명**:

| 필드 | 설명 |
|------|------|
| `TASK` | 태스크 ID (JIRA 등) |
| `session` | 세션 ID (같은 워크플로우 실행 구분) |
| `WORKFLOW_START/END` | 워크플로우 시작/종료 |
| `SKILL_START/END` | 스킬 시작/종료 + 소요시간 |
| `SKILL_INPUT/OUTPUT` | 스킬 입출력 (JSON) |
| `SKILL_ERROR` | 스킬 실패 |
| `SKILL_RETRY` | 재시도 |
| `SKILL_SKIP` | 스킵 (조건 불충족 등) |

**로깅 라이브러리 (workflow용)**:

```bash
# tools/agent/lib/workflow-logging.sh

SESSION_ID=""

# 워크플로우 시작
wflog_workflow_start() {
    local workflow="$1"
    local task_id="${AGENT_TASK_ID:-unknown}"
    SESSION_ID=$(date +%s%N | sha256sum | head -c 8)
    
    local log_file=$(_log_get_file)
    local wf_log="${log_file%.log}.workflow.log"
    
    {
        echo "$(_wflog_prefix) WORKFLOW_START: $workflow"
        echo "$(_wflog_prefix) WORKFLOW_PARAMS: $(echo "$@" | tail -n +2 | jq -c '.' 2>/dev/null || echo '{}')"
    } >> "$wf_log"
}

# 스킬 시작
wflog_skill_start() {
    local skill="$1"
    local input="$2"
    
    local wf_log="${log_file%.log}.workflow.log"
    
    {
        echo "$(_wflog_prefix) SKILL_START: $skill"
        [[ -n "$input" ]] && echo "$(_wflog_prefix) SKILL_INPUT: $input"
    } >> "$wf_log"
    
    # 시작 시간 저장
    SKILL_START_TIME=$(date +%s)
}

# 스킬 종료
wflog_skill_end() {
    local skill="$1"
    local status="${2:-OK}"
    local output="$3"
    
    local wf_log="${log_file%.log}.workflow.log"
    local duration=$(($(date +%s) - SKILL_START_TIME))
    
    {
        [[ -n "$output" ]] && echo "$(_wflog_prefix) SKILL_OUTPUT: $output"
        echo "$(_wflog_prefix) SKILL_END: $skill (${duration}s, $status)"
    } >> "$wf_log"
}

# 스킬 에러
wflog_skill_error() {
    local skill="$1"
    local error="$2"
    
    local wf_log="${log_file%.log}.workflow.log"
    echo "$(_wflog_prefix) SKILL_ERROR: $skill - $error" >> "$wf_log"
}

# 스킬 재시도
wflog_skill_retry() {
    local skill="$1"
    local attempt="$2"
    
    local wf_log="${log_file%.log}.workflow.log"
    echo "$(_wflog_prefix) SKILL_RETRY: $skill (attempt $attempt)" >> "$wf_log"
}

# 접두사
_wflog_prefix() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local task_id="${AGENT_TASK_ID:-unknown}"
    echo "[$timestamp] [TASK:$task_id] [session:$SESSION_ID]"
}
```

**조회 명령어**:

```bash
# 전체 워크플로우 로그
agnt-c log --workflow

# 특정 태스크의 워크플로우
agnt-c log --workflow --task TASK-123

# 실패한 스킬만
agnt-c log --workflow --errors

# 특정 세션만
agnt-c log --workflow --session abc123

# 직접 grep
grep "TASK:TASK-123" .context/logs/workflow.log
grep "SKILL_ERROR" .context/logs/workflow.log
```

**Mermaid 시각화 (선택)**:

```bash
# 워크플로우 실행 흐름을 mermaid로 출력
agnt-c log --workflow --mermaid TASK-123

# 출력:
# ```mermaid
# graph TD
#     A[analyze/parse-requirement] -->|34s OK| B[planning/design-solution]
#     B -->|54s OK| C[execute/write-code]
#     C -->|FAIL| C2[execute/write-code retry]
#     C2 -->|356s OK| D[validate/run-tests]
#     D -->|94s OK| E[DONE]
# ```
```

### 4.8 로그 관리

**로그 로테이션**:

```bash
# 로그 크기 제한 (기본 10MB)
MAX_LOG_SIZE=10485760  # 10MB

rotate_log_if_needed() {
    local log_file=$(_log_get_file)
    if [[ -f "$log_file" ]]; then
        local size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null)
        if [[ $size -gt $MAX_LOG_SIZE ]]; then
            mv "$log_file" "$log_file.$(date +%Y%m%d)"
            gzip "$log_file.$(date +%Y%m%d)"  # 압축
        fi
    fi
}
```

**.gitignore 설정**:

```bash
# .context/logs/는 기본적으로 gitignore
# 디버깅 공유가 필요하면 선택적으로 커밋 가능

# .gitignore
.context/logs/          # 로그 제외 (기본)
!.context/logs/.keep    # 디렉터리는 유지
```

**로그 보존 정책**:

| 상황 | 권장 |
|------|------|
| 로컬 개발 | gitignore (기본) |
| 디버깅 공유 필요 | 선택적 커밋 |
| CI/CD | 아티팩트로 저장 |

---

## 5. Implementation

### 4.1 install.sh (Tools 전역 설치)

```bash
#!/bin/bash
# install.sh - Install agent-context tools globally
# 
# Prerequisites: git clone https://github.com/user/agent-context.git ~/.agent-context
# Usage: ~/.agent-context/install.sh

set -e

# Detect script location (should be in cloned repo)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR"

# Verify we're in the right place
if [[ ! -d "$REPO_DIR/tools/agent" ]]; then
    echo "[ERROR] This script must be run from agent-context repository"
    echo ""
    echo "Installation:"
    echo "  git clone https://github.com/user/agent-context.git ~/.agent-context"
    echo "  ~/.agent-context/install.sh"
    exit 1
fi

INSTALL_DIR="$HOME/.agent-tools"

echo "=========================================="
echo "Agent Context Tools Installation"
echo "=========================================="
echo ""
echo "Repository: $REPO_DIR"
echo "Install to: $INSTALL_DIR"
echo ""

# 1. Create bin directory with symlinks
mkdir -p "$INSTALL_DIR/bin"

echo "[INFO] Creating symlinks..."

# agnt-c
ln -sf "$REPO_DIR/tools/agent/bin/agnt-c" "$INSTALL_DIR/bin/agnt-c"
echo "  agnt-c -> $REPO_DIR/tools/agent/bin/agnt-c"

# pm
ln -sf "$REPO_DIR/tools/pm/bin/pm" "$INSTALL_DIR/bin/pm"
echo "  pm -> $REPO_DIR/tools/pm/bin/pm"

# lint
ln -sf "$REPO_DIR/tools/lint/bin/lint" "$INSTALL_DIR/bin/lint"
echo "  lint -> $REPO_DIR/tools/lint/bin/lint"

# 2. Add to PATH
SHELL_RC="$HOME/.bashrc"
[[ "$SHELL" == *"zsh"* ]] && SHELL_RC="$HOME/.zshrc"

if ! grep -q "agent-tools" "$SHELL_RC" 2>/dev/null; then
    echo ""
    echo "[INFO] Adding to PATH in $SHELL_RC..."
    {
        echo ""
        echo "# agent-context tools"
        echo "export PATH=\"$INSTALL_DIR/bin:\$PATH\""
        echo "export AGENT_CONTEXT_PATH=\"$REPO_DIR\""
    } >> "$SHELL_RC"
else
    echo "[INFO] PATH already configured in $SHELL_RC"
fi

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Reload shell:"
echo "   source $SHELL_RC"
echo ""
echo "2. Verify installation:"
echo "   agnt-c --version"
echo "   pm --help"
echo ""
echo "3. Initialize a project:"
echo "   cd your-project"
echo "   agnt-c init"
echo ""
echo "4. Update later:"
echo "   cd $REPO_DIR && git pull"
echo ""
echo "=========================================="
```

### 4.2 agnt-c init 명령어

```bash
# agnt-c init [--full|--bare] [--skip-secrets]
init_project() {
    local mode="${1:-minimal}"
    local skip_secrets="${2:-false}"
    
    echo "=== Initializing project ($mode) ==="
    
    # 1. Secrets 체크 (필수)
    if [[ "$skip_secrets" != "true" ]]; then
        check_secrets || {
            show_secrets_guide
            return 1
        }
    fi
    
    # 2. 프로젝트 구조 생성
    mkdir -p .agent/skills .agent/workflows
    
    case "$mode" in
        minimal)
            copy_minimal_skills
            copy_minimal_workflows
            ;;
        full)
            copy_all_skills
            copy_all_workflows
            ;;
        bare)
            # 설정만
            ;;
    esac
    
    # 3. 설정 파일 생성
    create_project_yaml
    setup_secrets_dir
    update_gitignore
    
    echo "[OK] Project initialized"
}

# Secrets 체크 함수
check_secrets() {
    # 환경 변수 체크
    if [[ -n "$JIRA_TOKEN" ]] && [[ -n "$GITLAB_TOKEN" ]]; then
        echo "[OK] Secrets found in environment variables"
        return 0
    fi
    
    # 글로벌 secrets 체크
    if [[ -f "$HOME/.secrets/atlassian-api-token" ]] && \
       [[ -f "$HOME/.secrets/gitlab-api-token" ]]; then
        echo "[OK] Secrets found in ~/.secrets/"
        return 0
    fi
    
    # 로컬 secrets 체크
    if [[ -f ".secrets/atlassian-api-token" ]] && \
       [[ -f ".secrets/gitlab-api-token" ]]; then
        echo "[OK] Secrets found in .secrets/"
        return 0
    fi
    
    return 1
}

# Secrets 가이드 출력
show_secrets_guide() {
    echo ""
    echo "========================================"
    echo "[ERROR] Secrets not configured"
    echo "========================================"
    echo ""
    echo "Platform integration requires API tokens."
    echo ""
    echo "Option 1: Environment variables (recommended for CI)"
    echo "  export JIRA_TOKEN='your-jira-api-token'"
    echo "  export JIRA_EMAIL='your-email@company.com'"
    echo "  export GITLAB_TOKEN='your-gitlab-token'"
    echo ""
    echo "Option 2: Global secrets (recommended for local dev)"
    echo "  mkdir -p ~/.secrets"
    echo "  echo 'your-jira-api-token' > ~/.secrets/atlassian-api-token"
    echo "  echo 'your-gitlab-token' > ~/.secrets/gitlab-api-token"
    echo ""
    echo "Option 3: Project secrets"
    echo "  mkdir -p .secrets"
    echo "  echo 'your-jira-api-token' > .secrets/atlassian-api-token"
    echo "  echo 'your-gitlab-token' > .secrets/gitlab-api-token"
    echo ""
    echo "How to get tokens:"
    echo "  JIRA:   https://id.atlassian.com/manage-profile/security/api-tokens"
    echo "  GitLab: https://gitlab.com/-/profile/personal_access_tokens"
    echo ""
    echo "Skip for CI: agnt-c init --skip-secrets"
    echo "========================================"
}
```

---

## 5. Testing

### 5.1 Docker E2E 테스트

**Dockerfile**:

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    git curl jq bash ca-certificates

WORKDIR /tests
COPY e2e/ /tests/

CMD ["bash", "/tests/run-all.sh"]
```

**테스트 시나리오**:

| 시나리오 | 파일 | 검증 내용 |
|----------|------|----------|
| Fresh install | 01-fresh-install.sh | curl 설치 → agnt-c 동작 |
| Project init | 02-project-init.sh | init minimal/full/bare |
| Mock workflow | 03-mock-workflow.sh | AGENT_MOCK=1 전체 플로우 |
| Config | 04-config.sh | .project.yaml 생성 |
| **Secrets required** | 05-secrets-required.sh | secrets 없이 init 실패 확인 |
| **Secrets guide** | 06-secrets-guide.sh | 가이드 메시지 출력 확인 |

**실행**:

```bash
# 로컬 테스트
docker build -t agent-context-e2e tests/e2e/
docker run --rm agent-context-e2e

# CI 통합
# .gitlab-ci.yml
e2e-test:
  stage: test
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t agent-context-e2e tests/e2e/
    - docker run --rm agent-context-e2e
```

### 5.2 테스트 시나리오 상세

**01-fresh-install.sh**:

```bash
#!/bin/bash
set -e

echo "=== Test: Fresh Install ==="

# 1. Clone
git clone --depth 1 https://github.com/user/agent-context.git ~/.agent-context

# 2. Install
~/.agent-context/install.sh

# 3. Setup PATH (simulating shell reload)
export PATH="$HOME/.agent-tools/bin:$PATH"
export AGENT_CONTEXT_PATH="$HOME/.agent-context"

# 4. Verify
agnt-c --version || exit 1
pm --version || exit 1

echo "[PASS] Fresh install"
```

**02-project-init.sh**:

```bash
#!/bin/bash
set -e

echo "=== Test: Project Init ==="

export PATH="$HOME/.agent-tools/bin:$PATH"

# Minimal
mkdir -p /tmp/test-minimal && cd /tmp/test-minimal
git init
agnt-c init
[[ -f .agent/skills/write-code.md ]] || exit 1
[[ $(ls .agent/skills/*.md | wc -l) -eq 8 ]] || exit 1

# Full
mkdir -p /tmp/test-full && cd /tmp/test-full
git init
agnt-c init --full
[[ $(ls .agent/skills/*.md | wc -l) -ge 20 ]] || exit 1

# Bare
mkdir -p /tmp/test-bare && cd /tmp/test-bare
git init
agnt-c init --bare
[[ -f .project.yaml ]] || exit 1
[[ ! -d .agent/skills ]] || exit 1

echo "[PASS] Project init"
```

**03-mock-workflow.sh**:

```bash
#!/bin/bash
set -e

echo "=== Test: Mock Workflow ==="

export PATH="$HOME/.agent-tools/bin:$PATH"
export AGENT_MOCK=1

mkdir -p /tmp/test-workflow && cd /tmp/test-workflow
git init
agnt-c init --skip-secrets  # CI 환경이므로 skip

# Start
agnt-c dev start TASK-123 2>&1 | grep -q "MOCK" || exit 1

# Done
agnt-c dev done 2>&1 | grep -q "MOCK" || exit 1

echo "[PASS] Mock workflow"
```

**05-secrets-required.sh**:

```bash
#!/bin/bash
set -e

echo "=== Test: Secrets Required ==="

export PATH="$HOME/.agent-tools/bin:$PATH"

# 환경 변수/파일 없는 상태 확보
unset JIRA_TOKEN GITLAB_TOKEN
rm -rf ~/.secrets /tmp/test-secrets/.secrets

mkdir -p /tmp/test-secrets && cd /tmp/test-secrets
git init

# secrets 없이 init 시도 → 실패해야 함
if agnt-c init 2>&1; then
    echo "[FAIL] Should have failed without secrets"
    exit 1
fi

# 에러 메시지에 가이드 포함 확인
agnt-c init 2>&1 | grep -q "Secrets not configured" || exit 1
agnt-c init 2>&1 | grep -q "JIRA_TOKEN" || exit 1

echo "[PASS] Secrets required"
```

**06-secrets-guide.sh**:

```bash
#!/bin/bash
set -e

echo "=== Test: Secrets with Environment Variables ==="

export PATH="$HOME/.agent-tools/bin:$PATH"
export JIRA_TOKEN="test-token"
export JIRA_EMAIL="test@example.com"
export GITLAB_TOKEN="test-token"

mkdir -p /tmp/test-env-secrets && cd /tmp/test-env-secrets
git init

# 환경 변수로 secrets 설정 → 성공해야 함
agnt-c init || exit 1

# 프로젝트 초기화 확인
[[ -f .agent/skills/write-code.md ]] || exit 1

echo "[PASS] Secrets with env vars"
```

---

## 6. Migration

### 6.1 기존 사용자

```bash
# 1. 기존 ~/.agent 백업
mv ~/.agent ~/.agent.bak

# 2. 새 설치
curl -sL https://.../install.sh | bash

# 3. 기존 프로젝트 마이그레이션
cd my-project
rm -rf .agent  # 기존 심링크 제거
agnt-c init --full
```

### 6.2 호환성

- 기존 `.project.yaml` 형식 유지
- 기존 `.secrets/` 구조 유지
- 기존 스킬 형식 (SKILL.md frontmatter) 유지

---

## 8. Success Criteria

**설치**:
- [ ] `git clone` + `install.sh`로 tools 설치 완료
- [ ] `agnt-c init` 한 줄로 프로젝트 초기화 완료
- [ ] Secrets 없이 init 시도 시 에러 + 가이드 출력
- [ ] Minimal 구성: 15개 파일 이내

**로깅**:
- [ ] CLI 명령어 로그: `.context/logs/agent.log`
- [ ] Skill/Workflow 흐름 로그: `.context/logs/workflow.log`
- [ ] PID/branch로 동시 실행 구분 가능
- [ ] `agnt-c log` / `agnt-c log --workflow` 명령어

**테스트**:
- [ ] Docker E2E 테스트 6개 시나리오 모두 통과
- [ ] 기존 사용자 마이그레이션 가이드 제공

---

## 9. Timeline

| Phase | 내용 | 기간 |
|-------|------|------|
| 1 | logging.sh (CLI 로깅) | 0.5일 |
| 2 | workflow-logging.sh (skill/workflow 로깅) | 0.5일 |
| 3 | install.sh 작성 | 0.5일 |
| 4 | agnt-c init 구현 (secrets 체크 포함) | 1일 |
| 5 | agnt-c log 명령어 (--workflow 포함) | 0.5일 |
| 6 | Minimal core 분리 | 1일 |
| 7 | Docker E2E 테스트 | 1일 |
| 8 | 문서화 | 0.5일 |

**Total: ~6일**

---

## References

- [Ralph Project](https://github.com/snarktank/ralph) - 단순한 설치 참고
- [RFC-008](008-domain-extension.md) - 기존 설치 개선 계획
- [ARCHITECTURE.md](../../ARCHITECTURE.md) - 설계 철학
