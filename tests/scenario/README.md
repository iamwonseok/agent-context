# Scenario Tests

이 디렉터리는 `agent` / `pm` CLI 조합으로 **운영 시나리오를 실제로 따라 실행**할 수 있도록 정리한 문서 모음입니다.

---

## 설계 철학 요약

`ARCHITECTURE.md`의 핵심은 **"복잡한 강제 시스템" 대신 "단순한 흐름 + 명확한 피드백 + 사용자의 자율"**을 중심으로 에이전트 워크플로우를 설계하자는 것입니다.

| 원칙 | 설명 |
|------|------|
| Simplicity Over Completeness | 동작하는 단순한 해법을 우선, 복잡성은 "실제 pain"이 증명되면 점진적으로 추가 |
| User Autonomy | 하드 블로킹 대신 `[WARN]`/권고, 필요 시 `--force` 같은 탈출구 제공 |
| Feedback Over Enforcement | "왜 권장되는지"를 설명해 습관을 유도(강제보다 학습) |
| Composability | 작은 스킬(원자) + 워크플로우(조합)로 확장 |
| State Through Artifacts | DB/복잡한 상태기계 대신 Git + 파일(.context, summary 등)로 상태/감사를 남김 |

---

## 공통 전제

- 이 시나리오 문서는 "명령어 흐름 검증" 목적입니다.
- 실제 GitLab/JIRA 연동은 토큰/프로젝트 설정이 필요합니다.

### PATH 설정(예시)

```bash
export PATH="$PATH:$(pwd)/tools/agent/bin:$(pwd)/tools/pm/bin"
```

### 설정 확인

```bash
pm config show
agent status
```

---

## 명령어 레퍼런스

### `agent` (Workflow CLI)

**Common**
- `agent help|--help|-h`
- `agent version|--version|-v`
- `agent status`
- `agent config show`
- `agent init`

**Developer: `agent dev ...`**
- `agent dev start <task-id> [--detached] [--try=<name>] [--from=<branch>]`
- `agent dev list`
- `agent dev switch <branch|worktree>`
- `agent dev status`
- `agent dev check`
- `agent dev verify`
- `agent dev retro`
- `agent dev sync [--continue|--abort]`
- `agent dev submit [--sync] [--draft] [--force]`
- `agent dev cleanup <task-id>`

**Manager: `agent mgr ...`**
- `agent mgr pending [--all] [--author <name>] [--limit <n>]`
- `agent mgr review <mr-id> [--comment <msg>]`
- `agent mgr approve <mr-id> [--force]`
- `agent mgr status [id] [--verbose]`

### `pm` (Project Management CLI)

**Config**
- `pm config show`
- `pm config init [--force]`

**Jira**
- `pm jira me`
- `pm jira user search <QUERY>` - 사용자 검색 (email/name)
- `pm jira issue list [--jql <jql>] [--limit <n>]`
- `pm jira issue view <KEY>`
- `pm jira issue create <TITLE> [-t|--type <Task|Bug|...>] [-d|--description <text>]`
- `pm jira issue assign <KEY> <EMAIL>` - Assignee 할당
- `pm jira issue update <KEY> [--labels <a,b>] [--priority <High>] [--due-date <YYYY-MM-DD>]`
- `pm jira issue transition <KEY> <STATUS>` - 상태 전환 (To Do → In Progress → Done)
- `pm jira sprint list [BOARD_ID]` - Sprint 목록 (board_id 없으면 보드 목록)
- `pm jira sprint move <KEY> <SPRINT_ID>` - Issue를 Sprint로 이동
- `pm jira workflow transitions <KEY>` - 가능한 상태 전환 조회
- `pm jira workflow statuses` - 전체 상태 목록
- `pm jira link types` - 링크 타입 목록 (Blocks, Relates 등)
- `pm jira link view <KEY>` - Issue의 링크(의존관계) 조회
- `pm jira link create <FROM> <TO> <TYPE>` - 링크 생성 (예: "Blocks")
- `pm jira link delete <LINK_ID>` - 링크 삭제
- `pm jira bulk-create --csv <FILE>` - CSV 일괄 생성 (summary,type,assignee,desc,epic)

**GitLab**
- `pm gitlab me`
- `pm gitlab mr list [--state <opened|...>] [--limit <n>]`
- `pm gitlab mr view <IID>`
- `pm gitlab mr create --source <branch> [--target <branch>] --title <t> [-d|--description <d>] [--draft]`
- `pm gitlab issue list [--state <opened|...>] [--limit <n>]`

**Convenience**
- `pm create <TITLE> [-t|--type <Task|Bug>] [-w|--workflow <feature|bugfix|...>]`
- `pm finish [--target <branch>] [--skip-lint] [--skip-tests] [--draft]`

### `lint` (Coding convention checker)

- `lint <language> [OPTIONS] [PATH]`
  - language: `c|cpp`, `python|py`, `bash|sh`, `make`, `yaml|dockerfile`
  - options: `-R|--recursive`, `--junit`, `-o|--output`, `-q|--quiet`

---

## 시나리오 목록

### 기본 플로우

- `001-dev-standard-loop.md`
  - 브레인스토밍 → 계획 → task assign 이후 개발-테스트-머지 루프(Dev)

### 긴급/인시던트 대응

- `002-incident-idle-available.md`
  - 문제 발생 → 새 task 생성 → 현재 task 없는 사람 찾기(성공) → assign → 개발-테스트-머지 루프
- `003-incident-idle-unavailable-replan.md`
  - 문제 발생 → 새 task 생성 → 현재 task 없는 사람 찾기(실패) → 강제 재할당/일정 변경 → 개발-테스트-머지 루프(PM)

### Git 워크플로우 심화

- `004-parallel-work-detached-mode.md`
  - 병렬 작업/A-B 테스팅: Detached Mode + Worktree를 활용한 여러 접근법 동시 실험
- `005-rebase-conflict-resolution.md`
  - 리베이스 충돌 해결: `agent dev sync` 중 충돌 발생 → 해결 → `--continue`/`--abort`
- `006-draft-mr-iterative-review.md`
  - Draft MR 반복 리뷰: 초안 MR → 피드백 → 수정 → 재요청 → 최종 승인 사이클

### 프로젝트 세팅

- `007-project-setup-bulk-assign.md`
  - 프로젝트 초기 세팅: CSV 일괄 이슈 생성 + Assignee 할당 (pm jira bulk-create)

### Jira 워크플로우 (역할별)

- `008-dev-task-workflow.md` **(Dev)**
  - 개발자 Task 워크플로우: 할당 이슈 → 상태 전환 → 의존관계 관리 → MR 제출
- `009-mgr-sprint-planning.md` **(Mgr)**
  - 매니저 Sprint 계획: Epic 하위 이슈 일괄 생성 → Sprint 배치 → 의존관계 설정 → 모니터링
- `010-agile-full-cycle.md` **(Dev + Mgr)**
  - 전체 Agile 사이클: Sprint Planning → Development → Review → Retrospective

---

## 역할별 시나리오 가이드

### 개발자(Developer) 시나리오

| 시나리오 | 흐름 | 문서 |
|----------|------|------|
| Feature 개발 | `start` → 구현 → `check` → `verify` → `retro` → `submit` | 001 |
| Bug fix | 재현 테스트 → 수정 → `check` → `submit` | 002 |
| Hotfix | 최소 수정 + 핵심 테스트 → `submit` (리뷰는 사후 가능) | - |
| Refactor | 목표/범위 설계 → 작은 변경/테스트/작은 커밋 반복 → `submit` | - |
| **Task 워크플로우** | 상태 전환 → 의존관계 확인 → 작업 → 완료 → MR 제출 | **008** |

### 매니저(Manager) 시나리오

| 시나리오 | 흐름 | 문서 |
|----------|------|------|
| 리뷰 인박스 운영 | `mgr pending` → `mgr review` → `mgr approve` | - |
| 현황 브리핑 | `mgr status` + `pm gitlab mr list` + `pm jira issue list` | - |
| **Sprint 계획** | CSV 준비 → bulk-create → Sprint 배치 → 의존관계 설정 → 모니터링 | **009** |
| **프로젝트 세팅** | CSV 일괄 생성 + Assignee 할당 | **007** |

### 혼용(End-to-End) 시나리오

| 시나리오 | 흐름 | 문서 |
|----------|------|------|
| 기본 E2E | Mgr: 작업 요청 → Dev: 작업 → Mgr: 리뷰/승인 | - |
| **Agile Full Cycle** | Sprint Planning → Development → Review → Retrospective | **010** |

#### 기본 E2E 흐름
1. 매니저: `pm`으로 업무 큐 확인 → 개발자에게 작업 요청
2. 개발자: `agent dev start` → 작업 → `agent dev submit`
3. 매니저: `agent mgr pending` → `mgr review` → `mgr approve`

#### Agile Full Cycle 흐름 (010)
1. 매니저: `pm jira bulk-create` → Sprint 배치 → 의존관계 설정
2. 개발자: 상태 전환 → 블로커 확인 → 작업 → MR 제출
3. 매니저: MR 리뷰 → 승인 → 다음 Sprint 계획

---

## 실행 팁

- Stage 1-2(토큰 불필요): `./tests/run-tests.sh`
- 실제 연동(E2E)은 `tests/README.md`의 Stage 3 가이드를 따르세요.
