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

