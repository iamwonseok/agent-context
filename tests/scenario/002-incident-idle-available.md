# 002 - 급작스런 상황(PM/Dev 혼용): 문제 발생 → 새 task 생성 → 유휴 인력 찾기(성공) → assign → 개발/테스트/머지 루프

## 목적

- “급작스런 문제 발생” 시, `pm`으로 이슈를 만들고 `agent dev` 루프로 처리할 수 있는지 확인합니다.
- “현재 task가 없는 사람 찾기(성공)”을 **Jira JQL 조회 기반**으로 재현합니다.

## 핵심 결론(현재 구현 기준)

- 가능한 것(현재 구현):
  - Jira 이슈 생성/조회: `pm jira issue create|list|view`
  - 개발 루프: `agent dev start/check/verify/retro/submit`
  - (제한적) Jira 상태 전환: `pm finish` 또는 `agent dev submit` 과정에서 “In Review” 전환 시도
- 갭(현재 CLI에 없음):
  - “assignee 할당”을 CLI로 직접 수행하는 서브커맨드(`pm jira issue assign` 등)는 현재 노출되어 있지 않음
  - 따라서 assignee 변경은 Jira UI에서 수행하거나, 별도 자동화(추가 구현)가 필요

## 전제/준비

- `.project.yaml`에 `jira`가 설정되어 있어야 합니다.
- 팀 멤버의 Jira 계정 식별자(예: `accountId` 또는 JQL에서 사용 가능한 assignee 값)를 알고 있어야 합니다.
  - Jira Cloud는 보통 `assignee = <accountId>` 형태가 필요할 수 있습니다.
  - 여기서는 **플레이스홀더**로 `<ASSIGNEE_A>`, `<ASSIGNEE_B>`를 사용합니다.

## 시나리오 상황

- 운영/테스트 중 장애성 이슈가 발생했고, 즉시 처리해야 합니다.
- 현 시점에 “In Progress” 업무가 없는 사람(유휴 인력)이 있어 그 사람에게 배정합니다.

## 커맨드 시퀀스

### 0) 문제 이슈 생성(Bug)

```bash
pm jira issue create "Incident: login API returns 500" --type Bug --description "Repro: ...\nImpact: ...\nMitigation: ..."
```

**기대 결과**
- `(v) Jira issue: <KEY>` 형태의 키가 출력됨

### 1) 유휴 인력 찾기(성공 케이스)

> “유휴”의 정의를 단순화합니다: 현재 `statusCategory = "In Progress"` 이슈가 0개인 사람.

```bash
pm jira issue list --jql "assignee = <ASSIGNEE_A> AND statusCategory = \"In Progress\"" --limit 50
pm jira issue list --jql "assignee = <ASSIGNEE_B> AND statusCategory = \"In Progress\"" --limit 50
```

**판정 규칙**
- 출력 결과에서 `<ASSIGNEE_X>`의 목록이 비어 있으면(또는 Total 0에 준하는 출력) 그 사람이 유휴 인력 후보입니다.

### 2) (갭) 이슈에 assignee 할당

현재 `pm` CLI에 “assignee 변경” 커맨드가 노출되어 있지 않으므로, 아래 중 하나로 진행합니다.

- 선택지 A(권장, 수동): Jira UI에서 방금 생성한 `<KEY>`의 Assignee를 유휴 인력으로 지정
- 선택지 B(확장 필요): `pm jira issue assign` 같은 커맨드를 추가 구현(이 문서 범위 밖)

### 3) 개발자가 작업 시작

```bash
agent dev start <KEY>
agent dev status
```

**기대 결과**
- 브랜치 + `.context/<KEY>/` 생성

### 4) 개발/테스트 루프

```bash
agent dev check
git add -A
git commit -m "fix: handle 500 on login API"
agent dev verify
agent dev retro
```

### 5) 제출(MR 생성)

```bash
agent dev submit --sync
```

**기대 결과**
- MR 생성 시도 및 URL 출력
- Jira 연동이 되어 있고 브랜치명에서 키를 추출할 수 있으면 “In Review” 전환을 시도

### 6) 매니저 리뷰

```bash
agent mgr pending
agent mgr review <mr-id>
```

## 체크리스트(기록용)

| 단계 | 확인 항목 | 결과 |
|------|----------|------|
| 0 | Jira Bug 이슈가 생성되었는가 | [ ] |
| 1 | JQL로 유휴 인력을 판정할 수 있었는가 | [ ] |
| 2 | (수동) Assignee를 변경했는가 | [ ] |
| 3 | `agent dev start <KEY>`로 작업을 시작했는가 | [ ] |
| 4 | `agent dev submit`로 MR을 만들었는가 | [ ] |

---

## Manual Flow (Without Agent)

Agent 없이 순수 CLI + UI로 급작스런 문제를 처리하는 방법입니다.

### Git Only & CLI Commands

```bash
# 1. Jira Issue 생성 (jira-cli 사용)
jira issue create \
  --type Bug \
  --summary "Incident: login API returns 500" \
  --description "Repro: ...\nImpact: ...\nMitigation: ..." \
  --project G6SOCTC

# Issue 키 확인 (예: G6SOCTC-456)

# 2. 유휴 인력 찾기 (JQL 조회)
jira issue list \
  --jql "assignee = <ASSIGNEE_A> AND statusCategory = \"In Progress\"" \
  --limit 50

jira issue list \
  --jql "assignee = <ASSIGNEE_B> AND statusCategory = \"In Progress\"" \
  --limit 50

# 판정: 결과가 0개인 사람이 유휴 인력

# 3. Assignee 할당 (갭: CLI 미지원, UI 사용)
# → Jira UI에서 Issue의 Assignee 필드 변경

# 4. 개발자가 작업 시작
git checkout -b fix/G6SOCTC-456 main

# 5. 개발/테스트
vim src/auth_api.py
make lint && make test

# 6. 커밋
git add src/auth_api.py
git commit -m "fix: handle 500 error on login API

- Add null check for user object
- Add error logging
- Add unit test for edge case

Fixes: G6SOCTC-456"

# 7. Push & MR
git push -u origin fix/G6SOCTC-456
glab mr create --title "fix: handle 500 on login API"

# 8. Jira 상태 전환 (선택)
jira issue transition G6SOCTC-456 "In Review"
```

### UI Steps (플랫폼별 작업)

**Jira UI에서 필수 작업**:
- Issue 생성 (또는 jira-cli)
- Assignee 할당 (현재 CLI 미지원)
- 상태 전환 (또는 jira-cli)

**GitLab/GitHub UI**:
- MR/PR 생성 (또는 glab/gh CLI)
- 리뷰/승인
- 머지

---

## Responsibility Boundary

### CLI Responsibilities

**Jira 조회**:
- Issue 생성 (`jira-cli` 또는 `pm jira issue create`)
- JQL 조회로 유휴 인력 찾기
- 상태 전환 (`jira-cli` 또는 `pm`)

**Git 작업**:
- 브랜치 생성/커밋/Push
- MR/PR 생성 (`glab`/`gh`)

**품질 체크**:
- Lint/Test (`make lint`, `make test`)

### UI Responsibilities (Platform-specific)

**Jira UI** (일부 CLI 가능):
- Issue 생성 (jira-cli로도 가능)
- **Assignee 할당** (현재 CLI 미지원, UI 필수)
- 상태 전환 (jira-cli로도 가능)
- 우선순위/라벨 설정

**GitLab/GitHub UI**:
- MR/PR 리뷰/승인/머지
- 인라인 코멘트
- Draft → Ready 전환

### 현재 갭 (추가 구현 필요)

- `pm jira issue assign <KEY> <ASSIGNEE>`: CLI로 assignee 할당
- `pm jira issue transition <KEY> "<Status>"`: CLI로 상태 전환 (내부 함수는 존재)

