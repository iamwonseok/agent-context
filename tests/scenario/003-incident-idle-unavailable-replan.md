# 003 - 급작스런 상황(PM): 문제 발생 → 새 task 생성 → 유휴 인력 찾기(실패) → 강제 재할당/일정 변경 → 개발/테스트/머지 루프

## 목적

- “유휴 인력이 없을 때(실패)” PM이 어떻게 **재계획/재할당**을 수행하고, 그 결과가 Dev 루프로 이어지는지 점검합니다.
- 특히 아래 요구를 “현재 명령어 조합으로 가능한지” 검토합니다.
  - 기존 작업을 `inprogress → pending`으로 되돌려 “days 계산에서 제외”
  - Report(Jira) 연동(링크/처리 방법 기록)
  - deadline 초과 시 팀장 보고

## 핵심 결론(현재 구현 기준)

- 가능한 것(현재 구현):
  - Jira 이슈 생성/조회: `pm jira issue create|list|view`
  - GitLab MR 생성 및 Jira “In Review” 전환 시도: `agent dev submit` 또는 `pm finish`
  - “진행 중인 작업 목록 확인”을 JQL로 근사: `pm jira issue list --jql ...`
- 갭(현재 CLI에 없음, 수동/추가 구현 필요):
  - Jira assignee 변경(재할당) 커맨드 미노출
  - Jira due date/스프린트/커스텀 필드(days 계산 제외) 업데이트 커맨드 미노출
  - `agent mgr`의 capacity/assign 등 “PM 자동 할당” 커맨드 미구현(문서상 로드맵)

## 전제/준비

- `.project.yaml`에 `jira` 설정이 있어야 합니다.
- 팀 멤버 식별자를 알고 있어야 합니다(플레이스홀더 사용).

## 시나리오 상황

- 심각한 문제(P1)가 발생하여 “즉시 처리”가 필요합니다.
- 팀원 모두가 `In Progress` 상태의 작업을 이미 가지고 있어 유휴 인력이 없습니다.
- PM은 한 명을 지정해 현재 작업을 잠시 중단(대기)시키고, 새 P1을 우선 처리하도록 재계획합니다.

## 커맨드 시퀀스

### 0) P1 이슈 생성

```bash
pm jira issue create "P1 Incident: payment callback delayed" --type Bug --description "Impact: ...\nSLO breach risk: ...\nImmediate action: ..."
```

**기대 결과**
- `(v) Jira issue: <P1_KEY>` 출력

### 1) 유휴 인력 찾기(실패를 확인)

> 아래 예시에서는 2명만 보여주지만, 실제 팀원 전체에 대해 반복합니다.

```bash
pm jira issue list --jql "assignee = <ASSIGNEE_A> AND statusCategory = \"In Progress\"" --limit 50
pm jira issue list --jql "assignee = <ASSIGNEE_B> AND statusCategory = \"In Progress\"" --limit 50
```

**기대 결과**
- 모든 멤버가 1개 이상 “In Progress” 이슈를 가지고 있어, 유휴 인력이 없음을 확인

### 2) 재할당 대상 선택(강제)

> 여기서부터는 조직 정책/우선순위 기준이 들어가므로, “기록 가능한 형태”로 남기는 것이 핵심입니다.

- 선택 기준(예시):
  - 고객 영향도 낮은 작업을 보유한 사람
  - 마감이 상대적으로 여유 있는 작업
  - 대체 가능성이 높은 작업

### 3) (갭) 기존 작업을 pending으로 되돌리고(스케줄에서 제외) 문서화

현재 CLI만으로는 아래 변경을 자동으로 수행하기 어렵습니다(추가 구현 또는 Jira UI 필요).

- Jira UI에서 수행(권장, 수동)
  - `<ONGOING_KEY>`를 `In Progress → To Do`(또는 `Blocked`)로 전환
  - Due date 조정 / 스프린트 변경 / 라벨(예: `deprioritized`) 추가
  - 코멘트로 “P1 때문에 중단” 사유와 재개 조건 기록

이 단계에서 남길 “리포트/링크/처리방법” 텍스트 템플릿(예시):

```text
[Replan]
- Trigger: <P1_KEY> (P1 incident)
- Action: pause <ONGOING_KEY> and reassign owner to <P1_KEY>
- Rationale: customer impact / deadline risk
- Resume criteria: P1 mitigated + manager approval
- Links: MR/PR URL, runbook URL, dashboard URL
```

### 4) (갭) Assignee 재할당

- Jira UI에서 `<P1_KEY>`의 Assignee를 선택된 인원으로 변경
- `<ONGOING_KEY>`는 pending 상태로 유지

### 5) 개발자가 P1 작업 시작

```bash
agent dev start <P1_KEY>
agent dev check
git add -A
git commit -m "fix: mitigate payment callback delay"
agent dev verify
agent dev retro
agent dev submit --sync
```

### 6) (보고) 데드라인 영향/팀장 보고(수동)

현재 구현된 CLI 범위에서 “팀장 보고” 전용 커맨드는 없으므로,
- Jira 코멘트/이슈 링크로 근거를 남기고
- Slack/Email/회의 등 조직 채널로 보고합니다.

보고 템플릿(예시):

```text
[Escalation] P1 Incident requires replanning
- P1: <P1_KEY>
- Paused: <ONGOING_KEY> (moved to pending)
- Expected impact: deadline slip by X days
- Mitigation: add buffer / ask for extra reviewer / split scope
```

## 체크리스트(기록용)

| 항목 | 확인 | 결과 |
|------|------|------|
| 유휴 인력 “없음”을 JQL로 확인 | `statusCategory="In Progress"` | [ ] |
| 재계획 근거를 Jira에 남김 | 코멘트/링크/처리방법 | [ ] |
| 기존 작업을 pending으로 이동 | status 전환/라벨 | [ ] |
| P1 작업을 Dev 루프로 처리 | start → submit | [ ] |
| 데드라인 영향 보고 | 팀장/채널/근거 링크 | [ ] |

## 개선 제안(후속 작업 후보)

이 시나리오를 “명령어만으로” 완결하려면 최소 기능이 필요합니다.

- `pm jira issue transition <KEY> "<Transition Name>"`
  - 내부 함수 `jira_transition()`은 이미 존재하므로 CLI 노출만 추가하면 됨
- `pm jira issue assign <KEY> <ASSIGNEE>`
- (선택) `pm jira issue update <KEY> --due-date ... --labels ...`

