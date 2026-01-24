# 001 - 일반적인 상황(Dev): 브레인스토밍 → 계획 → 할당 → 개발/테스트/머지 루프

## 목적

- “일반적인 개발 루프(dev)”가 `agent dev` + (선택) `pm` 조합으로 **일관되게 재현 가능한지** 확인합니다.

## 전제/준비

- 이 저장소 루트에서 실행합니다.
- `pm` 연동을 쓸 경우 `.project.yaml` + 토큰이 준비되어 있어야 합니다.
- 토큰이 없으면 “Git/Jira/GitLab 실제 생성” 단계는 건너뛰고, “로컬 상태/출력” 위주로 확인합니다.

## 시나리오 상황

- 신규 기능 요청이 들어왔고, 브레인스토밍으로 방향을 정리한 뒤 계획을 세우고 작업을 시작합니다.
- 개발 완료 후 품질 확인을 거쳐 MR을 만들고(또는 PR), 매니저가 리뷰/승인합니다.

## 커맨드 시퀀스(권장)

### 0) 상태 확인

```bash
agent status
pm config show
```

**기대 결과**
- `agent status`가 “Project Root”, “Workflow Status” 등을 출력
- `pm config show`가 설정을 출력(또는 “not configured”류의 경고를 출력해도 크래시 없이 종료)

### 1) (선택) PM이 이슈를 만들고 브랜치까지 준비

> `pm create`는 (설정에 따라) Jira/GitLab 이슈 생성 + 브랜치 생성을 같이 시도합니다.

```bash
pm create "Add feature: improve task assignment flow" --type Task --workflow feature
```

**기대 결과**
- Jira가 설정된 경우: `(v) Jira issue: <KEY>` 출력
- GitLab이 설정된 경우: `(v) GitLab issue: #<IID>` 출력
- 브랜치 생성: `(v) Branch: feat/<KEY>-<slug>` 또는 `feat/<slug>`

### 2) 개발자가 작업을 시작(컨텍스트 생성)

> Jira 키가 있으면 그 키를 task-id로 쓰는 것을 권장합니다.

```bash
agent dev start G6SOCTC-123
agent dev status
agent dev list
```

**기대 결과**
- 브랜치 생성 및 `.context/<task-id>/` 생성
- `agent dev status`에 현재 브랜치/모드/컨텍스트 정보가 표시

### 3) 개발/테스트 루프(최소)

> 이 문서는 저장소 자체 구현을 바꾸지 않습니다. 실제 코드 수정은 사용자 작업에 맞게 진행하세요.

```bash
agent dev check
```

**기대 결과**
- Lint/Test/Intent 체크를 실행하고, 실패해도 “경고 중심”으로 종료(하드 블로킹이 아님)

### 4) 커밋

```bash
git status
git add -A
git commit -m "feat: improve task assignment flow"
```

**기대 결과**
- 커밋이 생성됨

### 5) 검증/회고 아티팩트 생성

```bash
agent dev verify
agent dev retro
```

**기대 결과**
- `.context/<task-id>/verification.md`, `.context/<task-id>/retrospective.md` 생성/갱신

### 6) 제출(MR/PR 생성)

```bash
agent dev submit --sync
```

**기대 결과**
- 리모트 push 시도
- `pm`을 통해 MR 생성 시도(설정되어 있으면 MR/URL 출력)
- Jira가 설정되어 있고 브랜치명에 `<PROJECT>-<num>`이 포함되면 “In Review” 전환을 시도

### 7) 매니저 리뷰 루프

```bash
agent mgr pending
agent mgr review <mr-id>
agent mgr review <mr-id> --comment "LGTM"
agent mgr approve <mr-id>
```

**기대 결과**
- `pending/review`는 read-only로 동작(설정이 없으면 경고/에러 메시지 출력 가능)
- `approve`는 기본값이 `human_only`로 보호될 수 있음(사람이 실행해야 승인 가능)

## 체크리스트(기록용)

| 단계 | 확인 항목 | 결과 |
|------|----------|------|
| 1 | `pm create`가 브랜치를 만들었는가 | [ ] |
| 2 | `agent dev start`가 `.context/`를 만들었는가 | [ ] |
| 3 | `agent dev check`가 크래시 없이 종료했는가 | [ ] |
| 4 | `agent dev verify/retro`가 산출물을 만들었는가 | [ ] |
| 5 | `agent dev submit`이 MR 생성까지 진행했는가 | [ ] |
| 6 | `agent mgr pending/review`가 MR을 조회했는가 | [ ] |
| 7 | `agent mgr approve`가 human_only로 보호되는지 확인했는가 | [ ] |

---

## Manual Flow (Without Agent)

Agent 없이 순수 Git + CLI로 동일한 워크플로우를 수행하는 방법입니다.

### Git Only (핵심 명령어)

```bash
# 1. 브랜치 생성
git checkout -b feat/G6SOCTC-123 main

# 2. Context 생성 (선택사항)
mkdir -p .context/G6SOCTC-123/logs
cat > .context/G6SOCTC-123/summary.yaml << EOF
task_id: G6SOCTC-123
branch: feat/G6SOCTC-123
started_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
status: in_progress
EOF

# 3. 개발 작업
vim src/task_assignment.py
vim tests/test_task_assignment.py

# 4. 품질 체크
make lint  # 또는 flake8, pylint
make test  # 또는 pytest

# 5. 커밋
git add src/task_assignment.py tests/test_task_assignment.py
git commit -m "feat(assignment): improve task assignment flow

- Add priority-based assignment
- Optimize capacity calculation
- Add unit tests

Refs: G6SOCTC-123"

# 6. 검증 기록 (선택사항)
cat > .context/G6SOCTC-123/verification.md << EOF
# Verification Report

## Test Results
- Unit tests: 12/12 PASS
- Integration tests: 5/5 PASS
- Coverage: 87%

## Requirements
- [x] Priority-based assignment implemented
- [x] Capacity calculation optimized
- [x] Unit tests added
EOF

# 7. Sync & Push
git fetch origin
git rebase origin/main
git push -u origin feat/G6SOCTC-123

# 8. MR 생성
# GitLab
glab mr create \
  --title "feat: improve task assignment flow" \
  --description "$(cat << 'DESC'
## Summary
- Priority-based assignment
- Optimized capacity calculation

## Test Plan
- [x] Unit tests: 12/12 pass
- [x] Integration tests: 5/5 pass
- [x] Performance test: 30% improvement

## Verification
See .context/G6SOCTC-123/verification.md
DESC
)" \
  --label feature

# GitHub
gh pr create \
  --title "feat: improve task assignment flow" \
  --body "..." \
  --label feature

# 9. Jira 상태 전환 (선택사항)
# jira-cli
jira issue transition G6SOCTC-123 "In Review"

# curl
curl -X POST \
  -H "Authorization: Bearer $JIRA_TOKEN" \
  -H "Content-Type: application/json" \
  "$JIRA_URL/rest/api/3/issue/G6SOCTC-123/transitions" \
  -d '{"transition": {"id": "31"}}'
```

### UI Steps (플랫폼별 작업)

Manual Flow에서 UI로 수행해야 하는 작업:

**MR/PR 생성** (선택: CLI 또는 UI)
- GitLab/GitHub UI에서 "New MR/PR" 버튼 클릭
- 또는 `glab mr create` / `gh pr create` CLI 사용

**리뷰 & 승인**
- MR/PR 페이지에서 코멘트 작성
- 승인 버튼 클릭 (권한 필요)
- 플랫폼 설정에 따라 승인 정책 상이

**머지**
- MR/PR 페이지에서 "Merge" 버튼 클릭
- 또는 `glab mr merge <id>` / `gh pr merge <id>` CLI 사용
- 플랫폼 설정에 따라 머지 옵션 상이 (Fast-forward, Squash, Merge commit)

**Context 정리** (MR 머지 후)
```bash
# 아카이브
mv .context/G6SOCTC-123 .archive/$(date +%Y%m%d)-G6SOCTC-123

# 브랜치 정리
git checkout main
git pull
git branch -d feat/G6SOCTC-123
```

---

## Responsibility Boundary

Agent-based 워크플로우와 Manual 워크플로우에서 CLI와 UI의 책임 구분:

### CLI Responsibilities

**Git 작업**
- 브랜치 생성/전환/삭제 (`git checkout`, `git branch`)
- 커밋 (`git add`, `git commit`)
- Sync (`git fetch`, `git rebase`)
- Push (`git push`)

**품질 체크**
- Lint (`make lint`, `flake8`, `pylint`)
- Test (`make test`, `pytest`)
- Pre-commit hook 설정 (선택사항)

**Context 관리**
- `.context/` 디렉터리 생성/관리
- `summary.yaml`, `verification.md`, `retrospective.md` 작성

**통합 (CLI 가능)**
- MR/PR 생성 (`glab mr create`, `gh pr create`)
- Jira 상태 전환 (`jira-cli`, `curl`)

### UI Responsibilities (Platform-specific)

**MR/PR 관리** (일부는 CLI로도 가능)
- MR/PR 생성 (GitLab/GitHub UI 또는 glab/gh CLI)
- Draft → Ready 전환 (UI 또는 `glab mr update --ready`)
- 인라인 코멘트 작성 (UI 권장)
- 코드 리뷰 (UI)

**승인 & 머지** (권한 필요)
- MR/PR 승인 (UI 또는 `glab mr approve <id>`)
- MR/PR 머지 (UI 또는 `glab mr merge <id>`)
- 머지 옵션 선택 (Fast-forward, Squash, Merge commit)

**이슈 관리** (일부는 CLI로도 가능)
- Jira/GitLab Issue 생성/조회 (UI 또는 CLI)
- 라벨/마일스톤 관리 (UI)
- 할당자 변경 (UI)

### Optional CLI Automation

다음 작업들은 **선택적으로** CLI로 자동화 가능:

- `glab` / `gh` CLI: MR/PR 생성, 승인, 머지
- `jira-cli`: Jira 이슈 생성, 상태 전환
- `pm` CLI (agent-context 제공): 통합 wrapper

**주의**: 플랫폼 설정(권한, 정책)에 따라 CLI 동작이 제한될 수 있음

