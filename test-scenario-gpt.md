# test-scenario-gpt.md

이 문서는 `agent-context` 저장소에서 제공하는 **명령어(구현 기준)**와 `why.md`의 **설계 의도**, 그리고 이를 활용한 **가능한 운영/개발 시나리오(개발자/매니저/혼용)**를 정리한 테스트용 시나리오 문서다.

---

### 1) 프로젝트 명령어 리스트(구현 기준)

#### 1.1 `agent` (Workflow CLI)

- **Common**
  - `agent help|--help|-h`
  - `agent version|--version|-v`
  - `agent status`
  - `agent config show`
  - `agent init`

- **Developer: `agent dev ...`**
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

- **Manager: `agent mgr ...` (실제 구현 확인됨)**
  - `agent mgr pending [--all] [--author <name>] [--limit <n>]`
  - `agent mgr review <mr-id> [--comment <msg>]`
  - `agent mgr approve <mr-id> [--force]`
    - 보호 동작: `human_only` 권한이면 executor가 `agent`일 때 승인 수행이 차단됨(사람이 실행해야 함)
  - `agent mgr status [id] [--verbose]`
    - `id` 미지정: 프로젝트 개요(최근 MR/이슈 일부)
    - `INIT-*`/`EPIC-*`: 현재는 placeholder 안내 중심(실제 집계 로직은 제한적)

#### 1.2 `pm` (Project Management CLI)

- **Config**
  - `pm config show`
  - `pm config init [--force]` (실제 옵션명은 `-f|--force`)

- **Jira**
  - `pm jira me`
  - `pm jira issue list [--jql <jql>] [--limit <n>]`
  - `pm jira issue view <KEY>`
  - `pm jira issue create <TITLE> [-t|--type <Task|Bug|...>] [-d|--description <text>]`

- **GitLab**
  - `pm gitlab me`
  - `pm gitlab mr list [--state <opened|...>] [--limit <n>]`
  - `pm gitlab mr view <IID>`
  - `pm gitlab mr create --source <branch> [--target <branch>] --title <t> [-d|--description <d>] [--draft]`
  - `pm gitlab issue list [--state <opened|...>] [--limit <n>]`

- **Convenience**
  - `pm create <TITLE> [-t|--type <Task|Bug>] [-w|--workflow <feature|bugfix|...>]`
  - `pm finish [--target <branch>] [--skip-lint] [--skip-tests] [--draft]`

#### 1.3 `lint` (Unified coding convention checker)

- `lint <language> [OPTIONS] [PATH]`
  - language: `c|cpp`, `python|py`, `bash|sh`, `make`, `yaml|dockerfile`
  - options: `-R|--recursive`, `--junit`, `-o|--output`, `-q|--quiet`
- 개별 엔트리: `lint-c`, `lint-python`, `lint-bash`, `lint-make`, `lint-yaml`

#### 1.4 기타(bin)

- `context`: 코딩 컨벤션/컨텍스트 초기화·테스트·업데이트 도구
- `commit-agent`: Ollama 기반 커밋 메시지 생성기(인터랙티브)
- `coding-agent`: Ollama 기반 로컬 자율 코딩 에이전트(저장소 자체 도구)

---

### 2) `why.md` 의도 요약

`why.md`의 핵심은 **“복잡한 강제 시스템” 대신 “단순한 흐름 + 명확한 피드백 + 사용자의 자율”**을 중심으로 에이전트 워크플로우를 설계하자는 것이다.

- **Simplicity Over Completeness**
  - 동작하는 단순한 해법을 우선, 복잡성은 “실제 pain”이 증명되면 점진적으로 추가
- **User Autonomy**
  - 하드 블로킹 대신 `[WARN]`/권고, 필요 시 `--force` 같은 탈출구 제공
- **Feedback Over Enforcement**
  - “왜 권장되는지”를 설명해 습관을 유도(강제보다 학습)
- **Composability**
  - 작은 스킬(원자) + 워크플로우(조합)로 확장
- **State Through Artifacts**
  - DB/복잡한 상태기계 대신 Git + 파일(.context, summary 등)로 상태/감사를 남김

또한 문서에는 **12-state FSM**(유지비/복잡도/우회 불가 문제)과 **강제 게이트**(응급 상황에서 방해, 숙련자 흐름 저해)를 “피해야 할 함정”으로 명시한다.

---

### 3) 가능한 시나리오(개발자/매니저/혼용)

아래 시나리오는 **(A) 현재 구현된 CLI 기준**과 **(B) 워크플로우 문서에 적힌 확장 시나리오**를 구분한다.

#### 3.0 시나리오 테스트 문서(명령어 시퀀스)

실제로 “따라 실행 가능한” 상세 시나리오(명령어 시퀀스 + 기대 결과)는 아래에 별도 정리했다.

**기본 플로우**

- `tests/scenario/001-dev-standard-loop.md`
  - 브레인스토밍 → 계획 → 할당 이후 개발/테스트/머지 루프(Dev)

**긴급/인시던트 대응**

- `tests/scenario/002-incident-idle-available.md`
  - 문제 발생 → 새 task 생성 → 유휴 인력 찾기(성공) → assign → 개발/테스트/머지 루프
- `tests/scenario/003-incident-idle-unavailable-replan.md`
  - 문제 발생 → 새 task 생성 → 유휴 인력 찾기(실패) → 강제 재할당/일정 변경 → 개발/테스트/머지 루프(PM)

**Git 워크플로우 심화**

- `tests/scenario/004-parallel-work-detached-mode.md`
  - 병렬 작업/A-B 테스팅: `--detached --try=<name>`으로 여러 접근법 동시 실험, worktree 관리
- `tests/scenario/005-rebase-conflict-resolution.md`
  - 리베이스 충돌 해결: `agent dev sync` 중 충돌 → 수동 해결 → `--continue`/`--abort`
- `tests/scenario/006-draft-mr-iterative-review.md`
  - Draft MR 반복 리뷰: `--draft` MR 생성 → 피드백 → 수정/push → 재요청 → 최종 승인 사이클

#### 3.1 개발자(Developer) 시나리오

- **Feature 개발 (권장 흐름)**
  - `agent dev start TASK-123`
  - 구현/수정 반복
  - `agent dev check` (린트/테스트/의도 정렬을 “경고 중심”으로 확인)
  - `agent dev verify` (검증 리포트 산출)
  - `agent dev retro` (회고/학습 기록)
  - `agent dev submit` (MR 생성 + 정리)

- **Bug fix**
  - 재현 테스트(또는 최소 재현) → 수정 → `agent dev check` → `agent dev submit`

- **Hotfix**
  - 최소 수정 + 핵심 테스트 중심 → `agent dev submit`
  - 리뷰는 사후 가능(운영 정책에 따름)

- **Refactor**
  - 목표/범위 설계 → 작은 변경/테스트/작은 커밋 반복 → 최종 `agent dev submit`

#### 3.2 매니저(Manager) 단독 시나리오(“매니저만으로 가능한 것”)

**A) 현재 구현된 CLI로 가능한 범위**

- **리뷰 인박스 운영**
  - `agent mgr pending`으로 대기 MR 확인
  - `agent mgr review <mr-id>`로 MR 상세 확인(+ 필요 시 코멘트)
  - `agent mgr approve <mr-id>`로 승인
    - 기본 전제: 승인 행위는 “사람이 실행”하는 보호 동작일 수 있음(`human_only`)

- **현황 브리핑/요약**
  - `agent mgr status`로 전체 개요 확인
  - `pm gitlab mr list/view`, `pm jira issue list/view`로 데이터 수집(현황/이슈 확인)

**B) 워크플로우 문서상(확장/로드맵 성격)**

- `workflows/manager/*`에는 initiative/epic/할당/리포트 자동화까지의 “이상적 운영 흐름”이 적혀 있으나,
  - 현재 `agent` 구현은 `pending/review/approve/status` 중심이며,
  - initiative/epic의 실제 집계/생성/조정 커맨드는 문서만 존재할 수 있다.

#### 3.3 혼용(개발자+매니저) 시나리오

- **표준 End-to-End(현실적인 운영)**
  - 매니저: `pm`으로 업무 큐 확인(Jira/GitLab) → 개발자에게 작업 요청/컨텍스트 제공
  - 개발자: `agent dev start ...` → 작업 → `agent dev submit`
  - 매니저: `agent mgr pending` → `agent mgr review` → `agent mgr approve`

- **리듬 예시**
  - 매니저(매일): `agent mgr pending` + `agent mgr status` + 필요한 `pm jira/gitlab` 조회
  - 개발자(수시): `agent dev list/status`로 병렬 작업(브랜치/워크트리) 관리

---

### 4) 메모(정확성/갭 관리)

- `workflows/manager/*`는 “역할 기반 시나리오 설계서”로서 가치가 크지만, **일부 커맨드는 현재 구현과 불일치**할 수 있다.
- 이 불일치를 “버그”로만 보기보다는, `why.md` 철학(최소 구현 → 점진 강화) 관점에서 **문서(목표 상태)와 구현(최소 기능)**이 공존하는 구조로 해석할 수도 있다.

#### 4.1 이번 시나리오(특히 PM) 관점에서의 갭

- **유휴 인력 탐색**
  - 가능(근사): `pm jira issue list --jql "assignee = ... AND statusCategory = \"In Progress\""`로 “진행중 업무 유무”를 조회
  - 한계: 팀 전체를 자동 집계하는 `agent mgr capacity` 같은 커맨드는 현재 구현에 없음(문서상 로드맵)
- **재할당/일정 변경**
  - 현재 `pm`에는 Jira issue “상태 전환/assignee 변경/due date/라벨/커스텀 필드 업데이트”를 직접 수행하는 서브커맨드가 노출되어 있지 않다.
  - 다만 `pm` 내부에는 `jira_transition()`이 존재하고(`pm finish`/`agent dev submit` 흐름에서 “In Review” 전환 시도), 필요 시 CLI 확장 후보가 될 수 있다.

