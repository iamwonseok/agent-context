# Manual Fallback Guide

Agent 없이 순수 Git + CLI로 모든 워크플로우를 수행하는 방법을 안내합니다.

## Philosophy: Why Manual Matters

> "Users should have freedom to make decisions" - why.md

Manual Fallback이 중요한 이유:

**1. Agent 이해**
- Agent가 실제로 무엇을 하는지 명확히 파악
- 블랙박스가 아닌 투명한 도구로 이해

**2. Agent 선택권**
- Agent 설치 없이 시작 가능
- 필요한 부분만 Agent 사용, 나머지는 직접 수행
- 학습 경로: Git → Git+Agent → Full Agent

**3. 환경 유연성**
- CI/CD 환경 (Agent 설치 부담)
- 긴급 상황 (빠른 Hotfix)
- 네트워크 제약 환경

**4. 디버깅**
- Agent 동작 문제 시 Manual로 우회
- Manual 방법과 비교하여 문제 진단

---

## Core Workflows Without Agent

### Feature Development (Manual)

**Agent 방식** (비교용):
```bash
agent dev start TASK-123
# ... work ...
agent dev check
git commit -m "feat: add feature"
agent dev verify
agent dev submit --sync
```

**Manual 방식** (순수 Git + CLI):
```bash
# 1. 브랜치 생성
git checkout -b feat/TASK-123 main

# 2. Context 생성 (선택사항)
mkdir -p .context/TASK-123/logs
cat > .context/TASK-123/summary.yaml << EOF
task_id: TASK-123
branch: feat/TASK-123
started_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
status: in_progress
EOF

# 3. 작업 수행
vim src/feature.py
vim tests/test_feature.py

# 4. 품질 체크
make lint  # 또는 flake8, pylint
make test  # 또는 pytest

# 5. 커밋
git add src/feature.py tests/test_feature.py
git commit -m "feat(scope): add feature description

- Detail 1
- Detail 2

Refs: TASK-123"

# 6. Verification 기록 (선택사항)
cat > .context/TASK-123/verification.md << EOF
# Verification Report

## Test Results
- Unit tests: PASS (10/10)
- Coverage: 87%

## Requirements
- [x] Requirement 1
- [x] Requirement 2
EOF

# 7. Sync & Push
git fetch origin
git rebase origin/main
git push -u origin feat/TASK-123

# 8. MR/PR 생성
# GitLab
glab mr create \
  --title "feat: add feature description" \
  --description "$(cat .context/TASK-123/verification.md)" \
  --label feature

# GitHub
gh pr create \
  --title "feat: add feature description" \
  --body-file .context/TASK-123/verification.md \
  --label feature

# 9. Jira 상태 전환 (선택사항)
# jira-cli 사용
jira issue transition TASK-123 "In Review"

# 또는 curl 직접
curl -X POST \
  -H "Authorization: Bearer $JIRA_TOKEN" \
  -H "Content-Type: application/json" \
  "$JIRA_URL/rest/api/3/issue/TASK-123/transitions" \
  -d '{"transition": {"id": "31"}}'

# 10. Context 정리 (MR 머지 후)
mv .context/TASK-123 .archive/$(date +%Y%m%d)-TASK-123
```

**Agent가 추가로 제공하는 것**:
- AI 기반 verification 리포트 자동 생성
- AI 기반 retrospective 자동 생성
- 한 번의 명령으로 sync + push + MR + Jira 처리
- Context 관리 자동화

---

### Bug Fix (Manual)

```bash
# 1. 브랜치 생성
git checkout -b fix/TASK-456 main

# 2. 재현 테스트 작성
cat > tests/test_bug_456.py << EOF
def test_bug_456_reproduction():
    """Reproduce bug TASK-456"""
    result = buggy_function()
    assert result == expected  # Should fail
EOF

pytest tests/test_bug_456.py  # 버그 확인

# 3. 버그 수정
vim src/buggy_module.py

# 4. 테스트 확인
pytest tests/test_bug_456.py  # Now passes

# 5. 전체 테스트
pytest tests/ -v

# 6. 커밋
git add src/buggy_module.py tests/test_bug_456.py
git commit -m "fix(module): resolve TASK-456

- Add reproduction test
- Fix root cause in buggy_function
- All tests pass

Fixes: TASK-456"

# 7. Push & MR
git push -u origin fix/TASK-456
glab mr create --title "fix: resolve TASK-456"
```

**Agent가 추가로 제공하는 것**:
- "Test first" 패턴 강제 (경고)
- 자동 lint + test 실행
- 빠른 리뷰 체크

---

### Hotfix (Manual - 가장 빠른 방법)

긴급 상황에서는 Manual이 Agent보다 빠릅니다:

```bash
# 최소 단계만 수행
git checkout -b hotfix/1.2.3 main
vim src/critical_module.py
pytest tests/test_critical_module.py  # 핵심 테스트만
git commit -am "fix: critical auth validation issue"
git push -u origin hotfix/1.2.3
glab mr create --title "URGENT: fix auth validation" --label urgent

# 수동 알림 (Slack/Email)
# "긴급 수정 MR-789 리뷰 요청"

# 사후 정리 (나중에)
# - 상세 테스트 추가
# - Post-mortem 작성
# - Jira에 근본 원인 분석 기록
```

**왜 Manual이 더 나은가**:
- Agent 설치/설정 시간 불필요
- 최소 단계만 수행 (ceremony 없음)
- 명확하고 빠른 실행

---

### Refactor (Manual)

```bash
# 1. 브랜치 생성
git checkout -b refactor/extract-repository main

# 2. 기존 테스트 확인 (Baseline)
pytest tests/ -v  # 모두 통과해야 함

# 3. 작은 단위로 리팩토링 (Loop)

# Step 1: Extract BaseRepository
vim src/repositories/base.py
pytest tests/  # 여전히 통과?
git add src/repositories/base.py
git commit -m "refactor: add BaseRepository interface"

# Step 2: Update UserService
vim src/services/user_service.py
pytest tests/  # 여전히 통과?
git add src/services/user_service.py
git commit -m "refactor: use BaseRepository in UserService"

# Step 3: Update OrderService
vim src/services/order_service.py
pytest tests/  # 여전히 통과?
git add src/services/order_service.py
git commit -m "refactor: use BaseRepository in OrderService"

# 4. 최종 확인
make lint
pytest tests/ -v --cov

# 5. Push & MR
git push -u origin refactor/extract-repository
glab mr create --title "refactor: extract repository pattern"
```

**Agent가 추가로 제공하는 것**:
- 테스트 존재 여부 검증
- 각 변경 후 자동 테스트 실행
- 동작 변경 없음 확인
- 복잡도 감소 분석 (AI)

---

## Context Management (Manual)

### Context Directory Structure

```
.context/
└── TASK-123/
    ├── summary.yaml          # 작업 메타데이터
    ├── logs/
    │   ├── check.log        # lint/test 결과
    │   └── build.log        # 빌드 로그
    ├── verification.md       # 검증 리포트
    └── retrospective.md      # 회고
```

### Manual Context Creation

```bash
# Bash 함수로 정의 (bashrc/zshrc에 추가 가능)
create_context() {
  local task_id=$1
  local context_dir=".context/$task_id"
  
  mkdir -p "$context_dir/logs"
  
  cat > "$context_dir/summary.yaml" << EOF
task_id: $task_id
branch: $(git branch --show-current)
started_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
status: in_progress
files_changed: []
commits: []
EOF

  cat > "$context_dir/verification.md" << EOF
# Verification Report - $task_id

## Test Results
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Coverage >= 80%

## Lint Results
- [ ] No lint errors
- [ ] No security issues

## Requirements
- [ ] Requirement 1
- [ ] Requirement 2
EOF

  cat > "$context_dir/retrospective.md" << EOF
# Retrospective - $task_id

## What went well

## What could be improved

## Lessons learned

## Action items
EOF

  echo "Created context: $context_dir"
}

# 사용
create_context TASK-123
```

### Updating Context

```bash
# summary.yaml 업데이트 함수
update_context_summary() {
  local task_id=$1
  local context_file=".context/$task_id/summary.yaml"
  
  # 변경된 파일 목록
  local files_changed=$(git diff --name-only main...HEAD | sed 's/^/  - /')
  
  # 커밋 목록
  local commits=$(git log main..HEAD --format='  - "%h: %s"')
  
  # YAML 업데이트 (yq 사용 시)
  yq eval -i ".updated_at = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" "$context_file"
  
  # 또는 수동으로 append
  cat >> "$context_file" << EOF
files_changed:
$files_changed
commits:
$commits
updated_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
}

# 사용
update_context_summary TASK-123
```

### Context Cleanup

```bash
# 아카이브
archive_context() {
  local task_id=$1
  local archive_dir=".archive/$(date +%Y%m%d)-$task_id"
  
  mkdir -p .archive
  mv ".context/$task_id" "$archive_dir"
  echo "Archived to: $archive_dir"
}

# 삭제 (주의!)
delete_context() {
  local task_id=$1
  rm -rf ".context/$task_id"
  echo "Deleted context: $task_id"
}

# 사용
archive_context TASK-123
```

---

## Worktree Management (Manual)

### Creating Worktrees (Parallel Work)

**Agent 방식**:
```bash
agent dev start TASK-100 --detached --try=approach-a
```

**Manual 방식**:
```bash
# 1. Worktree 디렉터리 준비
mkdir -p .worktrees

# 2. Worktree 생성
git worktree add .worktrees/TASK-100-approach-a \
  -b feat/TASK-100-approach-a \
  main

# 3. 작업 디렉터리로 이동
cd .worktrees/TASK-100-approach-a

# 4. Context 생성 (선택사항)
mkdir -p .context/TASK-100
cat > .context/TASK-100/summary.yaml << EOF
task_id: TASK-100
approach: approach-a
worktree: .worktrees/TASK-100-approach-a
started_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

# 5. 작업 수행
vim src/feature.py
git commit -m "feat: approach-a implementation"

# 6. 메인 디렉터리로 복귀
cd ../..
```

### Parallel Worktrees (A/B Testing)

```bash
# Approach A
git worktree add .worktrees/TASK-100-approach-a -b feat/TASK-100-a main
cd .worktrees/TASK-100-approach-a
# ... 작업 ...
git commit -m "feat: refactor-based approach"
cd ../..

# Approach B
git worktree add .worktrees/TASK-100-approach-b -b feat/TASK-100-b main
cd .worktrees/TASK-100-approach-b
# ... 작업 ...
git commit -m "feat: new-module approach"
cd ../..

# 비교
git log feat/TASK-100-a --oneline
git log feat/TASK-100-b --oneline

# 성능/복잡도 비교
cd .worktrees/TASK-100-approach-a
pytest tests/ --benchmark
radon cc src/ -s
cd ../../.worktrees/TASK-100-approach-b
pytest tests/ --benchmark
radon cc src/ -s
cd ../..

# 선택 후 제출 (approach-a 선택)
cd .worktrees/TASK-100-approach-a
git push -u origin feat/TASK-100-a
glab mr create --title "feat: TASK-100 (approach-a selected)"
cd ../..

# 정리
git worktree remove .worktrees/TASK-100-approach-a
git worktree remove .worktrees/TASK-100-approach-b
git branch -D feat/TASK-100-b  # 선택되지 않은 브랜치 삭제
```

### Worktree Operations

```bash
# 현재 worktree 목록
git worktree list

# 특정 worktree로 전환
cd .worktrees/TASK-100-approach-a

# Worktree 제거
git worktree remove .worktrees/TASK-100-approach-a

# 강제 제거 (변경사항 있어도)
git worktree remove --force .worktrees/TASK-100-approach-a

# 모든 worktree 제거 (주의!)
git worktree list --porcelain | \
  grep '^worktree' | \
  cut -d' ' -f2 | \
  grep '.worktrees/' | \
  xargs -I {} git worktree remove {}
```

### Worktree Cleanup Script

```bash
# .worktrees/ 하위 정리
cleanup_worktrees() {
  local pattern=${1:-.worktrees/}
  
  git worktree list --porcelain | \
    grep '^worktree' | \
    cut -d' ' -f2 | \
    grep "$pattern" | \
    while read -r wt; do
      echo "Removing: $wt"
      git worktree remove "$wt" || git worktree remove --force "$wt"
    done
}

# 사용
cleanup_worktrees "TASK-100"  # TASK-100 관련만 정리
cleanup_worktrees             # 모든 .worktrees/ 정리
```

---

## Command Mapping Reference

Agent 명령어와 Manual 대안 매핑표:

| Agent Command | Manual Alternative | Notes |
|---------------|-------------------|-------|
| `agent dev start <task>` | `git checkout -b feat/<task> main` | + context 생성 (선택) |
| `agent dev start --detached` | `git worktree add .worktrees/<task> -b feat/<task>` | Worktree 방식 |
| `agent dev status` | `git status && git branch --show-current` | |
| `agent dev list` | `git branch && git worktree list` | |
| `agent dev check` | `make lint && make test` | 또는 pre-commit |
| `agent dev verify` | (manual verification.md 작성) | Agent는 AI 생성 |
| `agent dev retro` | (manual retrospective.md 작성) | Agent는 AI 생성 |
| `agent dev sync` | `git fetch && git rebase origin/main` | |
| `agent dev sync --continue` | `git rebase --continue` | |
| `agent dev sync --abort` | `git rebase --abort` | |
| `agent dev submit` | `git push && glab mr create` | + Jira (선택) |
| `agent dev cleanup <task>` | `git worktree remove .worktrees/<task>` | |
| `agent mgr pending` | `glab mr list --state opened --reviewer @me` | |
| `agent mgr review <mr>` | `glab mr view <mr> && glab mr diff <mr>` | |
| `agent mgr approve <mr>` | `glab mr approve <mr>` | |

---

## Platform Integration (Manual)

### GitLab Integration

```bash
# MR 생성
glab mr create \
  --title "feat: title" \
  --description "description" \
  --label feature \
  --assignee @me

# Draft MR
glab mr create --draft --title "WIP: title"

# Draft → Ready
glab mr update <mr-id> --ready

# MR 목록
glab mr list --state opened

# MR 상세
glab mr view <mr-id>

# MR 승인
glab mr approve <mr-id>

# MR 머지
glab mr merge <mr-id>
```

### GitHub Integration

```bash
# PR 생성
gh pr create \
  --title "feat: title" \
  --body "description" \
  --label feature \
  --assignee @me

# Draft PR
gh pr create --draft --title "WIP: title"

# Draft → Ready
gh pr ready <pr-id>

# PR 목록
gh pr list --state open

# PR 상세
gh pr view <pr-id>

# PR 승인
gh pr review <pr-id> --approve

# PR 머지
gh pr merge <pr-id>
```

### Jira Integration

```bash
# jira-cli 사용
jira issue create \
  --type Task \
  --summary "Summary" \
  --project PROJ

# Issue 상태 전환
jira issue transition PROJ-123 "In Progress"

# 또는 curl 직접
curl -X POST \
  -H "Authorization: Bearer $JIRA_TOKEN" \
  -H "Content-Type: application/json" \
  "$JIRA_URL/rest/api/3/issue/PROJ-123/transitions" \
  -d '{"transition": {"id": "21"}}'
```

---

## When to Use Manual vs Agent

### Use Manual When:

**학습 단계**
- Agent가 무엇을 하는지 이해하고 싶을 때
- Git 워크플로우를 배우고 있을 때
- Manual 방법을 먼저 익히고 Agent로 전환

**환경 제약**
- Agent 설치가 불가능한 환경 (CI/CD)
- 새 머신에서 빠르게 작업해야 할 때
- 네트워크/권한 제약이 있을 때

**긴급 상황**
- Hotfix (Agent 설치 시간 아까움)
- 빠른 수정이 필요할 때
- 최소 단계만 수행하고 싶을 때

**커스텀 워크플로우**
- 표준 워크플로우와 다른 경우
- 특정 단계만 선택적으로 수행
- Agent가 지원하지 않는 특수 케이스

**디버깅**
- Agent 동작이 이상할 때
- Manual과 비교하여 문제 진단
- Agent 내부 동작 이해

### Use Agent When:

**표준 워크플로우**
- Feature, Bug-fix, Refactor 등 표준 작업
- 팀 프로세스 통일이 필요할 때
- 일관된 품질 게이트 적용

**AI 지원 활용**
- Verification 리포트 자동 생성
- Retrospective 자동 생성
- 코드 리뷰 제안

**통합 자동화**
- Jira + GitLab 자동 연동
- 한 번의 명령으로 여러 단계 수행
- Context 관리 자동화

**품질 강제**
- Pre-commit hook 자동 설치
- 표준 검증 절차 적용
- 팀 규칙 준수

### Hybrid Approach (추천)

대부분의 경우 Manual + Agent를 조합하여 사용:

```bash
# Manual로 시작
git checkout -b feat/TASK-123 main
vim src/code.py

# Agent로 품질 체크
agent dev check

# Manual로 커밋
git commit -m "feat: ..."

# Agent로 제출
agent dev submit
```

**장점**:
- 익숙한 Git 명령어 사용
- 필요한 부분만 Agent 활용
- 유연성과 자동화의 균형

---

## Examples

### Example 1: Full Manual (No Agent)

```bash
# 작업 시작
git checkout -b feat/USER-AUTH main

# 개발
vim src/auth.py
vim tests/test_auth.py

# 품질 체크
make lint
make test

# 커밋
git add .
git commit -m "feat(auth): add user authentication

- JWT token generation
- Login/logout endpoints
- Unit tests

Refs: USER-AUTH"

# Sync & Push
git fetch origin
git rebase origin/main
git push -u origin feat/USER-AUTH

# MR 생성
glab mr create \
  --title "feat: add user authentication" \
  --label feature

# Jira (선택)
jira issue transition USER-AUTH "In Review"
```

### Example 2: Hybrid (Manual + Agent)

```bash
# Manual로 시작
git checkout -b feat/USER-AUTH main
vim src/auth.py tests/test_auth.py

# Agent로 품질 체크
agent dev check

# Manual로 커밋
git commit -m "feat(auth): add user authentication"

# Agent로 검증 및 제출
agent dev verify
agent dev submit
```

### Example 3: Emergency Hotfix (Manual Only)

```bash
# 최소 단계
git checkout -b hotfix/auth-bypass main
vim src/auth.py
pytest tests/test_auth.py -k security
git commit -am "fix: critical auth bypass vulnerability"
git push -u origin hotfix/auth-bypass
glab mr create --title "URGENT: fix auth bypass" --label urgent

# 수동 알림 (Slack)
# "긴급 보안 수정 MR-999, 즉시 리뷰 요청합니다"
```

---

## Tips & Best Practices

### 1. Context는 선택사항

Context 디렉터리(`.context/`)는 **선택사항**입니다:
- 간단한 작업: Context 없이 진행
- 복잡한 작업: Context로 상태 추적
- 팀 요구사항에 따라 결정

### 2. MR Description에 로그 포함

Issue가 없는 경우 MR description에 로그 포함:
```bash
glab mr create \
  --title "feat: title" \
  --description "$(cat .context/TASK-123/verification.md)"
```

### 3. Commit Message 규칙 준수

```
<type>(<scope>): <subject>

<body>

<footer>
```

예:
```
feat(auth): add JWT authentication

- Implement token generation
- Add login/logout endpoints
- Add unit tests

Refs: USER-AUTH
```

### 4. Rebase 전략

```bash
# 항상 최신 상태 유지
git fetch origin
git rebase origin/main

# 충돌 시
git status  # 충돌 파일 확인
vim <conflict-file>  # 수동 해결
git add <conflict-file>
git rebase --continue

# 포기하고 싶으면
git rebase --abort
```

### 5. Worktree 활용 팁

```bash
# 메인 작업 방해 없이 실험
git worktree add .worktrees/experiment -b experiment main
cd .worktrees/experiment
# ... 실험 ...
cd ../..
git worktree remove .worktrees/experiment
git branch -D experiment  # 실패 시 삭제
```

---

## Troubleshooting

### 문제: MR 생성 실패

```bash
# glab/gh CLI 설치 확인
glab version
gh version

# 인증 확인
glab auth status
gh auth status

# 재인증
glab auth login
gh auth login
```

### 문제: Jira API 호출 실패

```bash
# 토큰 확인
echo $JIRA_TOKEN
echo $JIRA_URL

# 수동 테스트
curl -H "Authorization: Bearer $JIRA_TOKEN" \
  "$JIRA_URL/rest/api/3/myself"
```

### 문제: Rebase 충돌

```bash
# 충돌 파일 확인
git status

# 충돌 해결 도구 사용
git mergetool

# 또는 수동 해결 후
git add <resolved-files>
git rebase --continue

# 포기
git rebase --abort
```

---

## Conclusion

Manual Fallback은 Agent의 **대안**이 아니라 **기반**입니다:

1. **이해**: Manual 방법을 알면 Agent가 무엇을 하는지 이해
2. **선택**: 상황에 따라 Manual ↔ Agent 자유 선택
3. **유연성**: 환경 제약 시 Manual로 우회
4. **성장**: Manual → Hybrid → Full Agent로 점진적 학습

**권장 학습 경로**:
1. Manual로 시작 (이 가이드 참조)
2. Hybrid로 전환 (Manual + Agent 조합)
3. Full Agent로 진화 (필요 시)

Agent는 **편의 도구**입니다. 필수가 아닙니다.

---

**작성일**: 2026-01-24  
**대상**: Agent-context 사용자  
**목적**: Agent-optional 워크플로우 구현
