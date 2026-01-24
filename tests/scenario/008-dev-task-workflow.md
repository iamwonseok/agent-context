# 008: Developer Task Workflow

**역할**: Developer (Dev)
**목적**: 할당받은 이슈를 Sprint 내에서 작업하고 완료하는 전체 플로우

---

## 시나리오 개요

개발자가 Sprint에 할당된 Task를 받아서:
1. 이슈 상태를 "In Progress"로 전환
2. 의존관계(블로커) 확인 및 관리
3. 코드 작업 및 커밋
4. 상태를 "Done"으로 전환
5. MR 제출

---

## 전제 조건

- Sprint가 활성화되어 있음
- 개발자에게 이슈가 할당되어 있음
- `.project.yaml` 설정 완료

---

## Step 1: 내 할당 이슈 확인

```bash
# 현재 사용자 확인
pm jira me

# 내 이슈 목록 확인
pm jira issue list --jql "assignee = currentUser() AND sprint in openSprints()"
```

**예상 출력**:
```
------------------------------------------------------------------------
Key          | Type     | Status       | Summary
------------------------------------------------------------------------
PROJ-10      | Task     | To Do        | 로그인 API 개발
PROJ-11      | Task     | To Do        | 회원가입 폼 구현
------------------------------------------------------------------------
```

---

## Step 2: 작업 시작 - 상태 전환

```bash
# 가능한 상태 전환 확인
pm jira workflow transitions PROJ-10

# To Do → In Progress
pm jira issue transition PROJ-10 "In Progress"
```

**예상 출력**:
```
(v) Transitioned PROJ-10 to In Progress
```

---

## Step 3: 의존관계(블로커) 확인

```bash
# 이 이슈의 링크(의존관계) 확인
pm jira link view PROJ-10
```

**예상 출력**:
```
==========================================
Links for PROJ-10
==========================================

------------------------------------------------------------------------
Link ID  | Issue        | Type                 | Direction
------------------------------------------------------------------------
12345    | PROJ-5       | Blocks               | inward: is blocked by
------------------------------------------------------------------------
```

블로커가 있다면:
```bash
# 블로커 이슈 상태 확인
pm jira issue view PROJ-5

# 블로커가 해결되었다면 링크 삭제
pm jira link delete 12345
```

---

## Step 4: Git 브랜치 생성 및 작업

```bash
# 브랜치 생성 및 작업 시작
agent dev start PROJ-10

# 코드 작업...
# ...

# 품질 체크
agent dev check

# 테스트 검증
agent dev verify
```

---

## Step 5: 관련 이슈 연결

작업 중 관련 이슈 발견 시:
```bash
# 관련 이슈 연결
pm jira link create PROJ-10 PROJ-15 "Relates"
```

버그 발견 시:
```bash
# 버그 생성 및 연결
pm jira issue create "API 응답 포맷 버그" --type Bug
# → PROJ-20 생성됨

pm jira link create PROJ-10 PROJ-20 "is blocked by"
```

---

## Step 6: 이슈 필드 업데이트

```bash
# 라벨 추가
pm jira issue update PROJ-10 --labels "backend,api"

# 우선순위 변경 (필요시)
pm jira issue update PROJ-10 --priority "High"
```

---

## Step 7: 작업 완료 - 상태 전환

```bash
# In Progress → Done
pm jira issue transition PROJ-10 "Done"
```

---

## Step 8: MR 제출

```bash
# 회고 (선택)
agent dev retro

# MR 제출
agent dev submit
```

---

## Manual Flow (Without Agent)

Agent CLI 없이 순수 `pm` + `git`으로 동일한 작업:

```bash
# 1. 상태 전환
pm jira issue transition PROJ-10 "In Progress"

# 2. Git 브랜치
git checkout -b feature/PROJ-10

# 3. 작업 및 커밋
git add . && git commit -m "feat: implement login API (PROJ-10)"

# 4. 상태 완료
pm jira issue transition PROJ-10 "Done"

# 5. Push 및 MR
git push -u origin feature/PROJ-10
pm gitlab mr create --source feature/PROJ-10 --title "feat: implement login API"
```

---

## 체크리스트

- [ ] 작업 시작 전 상태를 "In Progress"로 변경
- [ ] 블로커 이슈 확인 및 해결
- [ ] 관련 이슈 링크 연결
- [ ] 코드 품질 체크 (`agent dev check`)
- [ ] 테스트 통과 (`agent dev verify`)
- [ ] 작업 완료 시 상태를 "Done"으로 변경
- [ ] MR 제출
