# 010: Agile Full Cycle (Dev + Mgr)

**역할**: Manager + Developer 협업
**목적**: Sprint 계획부터 완료까지 전체 Agile/Scrum 사이클 수행

---

## 시나리오 개요

전체 Sprint 사이클:

```
[Mgr] Sprint Planning → [Mgr] Issue 생성/할당 → [Dev] 작업 시작
    ↓
[Dev] 코드 작업 → [Dev] MR 제출 → [Mgr] 리뷰/승인
    ↓
[Dev] 상태 완료 → [Mgr] Sprint 회고 → [Mgr] 다음 Sprint 계획
```

---

## Phase 1: Sprint Planning (Mgr)

### 1.1 현황 파악

```bash
# [Mgr] 현재 프로젝트 상태 확인
pm jira issue list
pm jira sprint list 217
```

### 1.2 Sprint 2 이슈 생성

```bash
# [Mgr] CSV 준비
cat > sprint2.csv << 'EOF'
summary,type,assignee_email,description,epic
User Authentication API,Task,alex@fadutec.com,JWT 인증 구현,PROJ-1
User Registration Form,Task,kim@fadutec.com,회원가입 UI 구현,PROJ-1
Password Reset Feature,Task,lee@fadutec.com,비밀번호 재설정,PROJ-1
Auth Unit Tests,Task,alex@fadutec.com,인증 테스트 작성,PROJ-1
EOF

# [Mgr] 일괄 생성
pm jira bulk-create sprint2.csv
# → PROJ-30, PROJ-31, PROJ-32, PROJ-33 생성
```

### 1.3 Sprint 배치 및 의존관계 설정

```bash
# [Mgr] Sprint 2에 배치
pm jira sprint move PROJ-30 268
pm jira sprint move PROJ-31 268
pm jira sprint move PROJ-32 268
pm jira sprint move PROJ-33 268

# [Mgr] 의존관계 설정
pm jira link create PROJ-31 PROJ-30 "Blocks"  # Form은 API 필요
pm jira link create PROJ-32 PROJ-30 "Blocks"  # Reset은 API 필요
pm jira link create PROJ-33 PROJ-30 "Blocks"  # Test는 API 필요

# [Mgr] 우선순위 설정
pm jira issue update PROJ-30 --priority "High" --labels "backend,critical-path"
```

### 1.4 팀 공지

```bash
# [Mgr] Sprint 시작 (UI에서 "Start Sprint" 클릭)
# → 팀 채널에 Sprint 계획 공유
```

---

## Phase 2: Development Cycle (Dev)

### 2.1 Alex: API 작업 시작

```bash
# [Dev-Alex] 내 할당 확인
pm jira issue list --jql "assignee = currentUser() AND sprint in openSprints()"

# [Dev-Alex] 작업 시작
pm jira issue transition PROJ-30 "In Progress"

# [Dev-Alex] 브랜치 생성
agent dev start PROJ-30

# [Dev-Alex] 코드 작업...
# ... JWT 인증 구현 ...

# [Dev-Alex] 품질 체크
agent dev check
agent dev verify
```

### 2.2 Alex: MR 제출

```bash
# [Dev-Alex] 작업 완료 상태
pm jira issue transition PROJ-30 "Done"

# [Dev-Alex] MR 제출
agent dev submit
# → MR #15 생성
```

---

## Phase 3: Code Review (Mgr)

### 3.1 MR 리뷰

```bash
# [Mgr] 대기 MR 확인
agent mgr pending

# [Mgr] MR 리뷰
agent mgr review 15 --comment "코드 품질 좋음. 테스트 커버리지 확인 필요."

# [Mgr] 승인 (또는 변경 요청)
agent mgr approve 15
```

### 3.2 블로커 해제 알림

```bash
# [Mgr] 의존 이슈 담당자에게 알림
# PROJ-30 완료 → PROJ-31, PROJ-32, PROJ-33 작업 가능

# [Mgr] 블로커 상태 확인
pm jira link view PROJ-31
# → PROJ-30이 Done이므로 작업 가능
```

---

## Phase 4: Parallel Development (Dev Team)

### 4.1 Kim: Form 작업

```bash
# [Dev-Kim] 블로커 해제 확인
pm jira link view PROJ-31
pm jira issue view PROJ-30  # Status: Done 확인

# [Dev-Kim] 작업 시작
pm jira issue transition PROJ-31 "In Progress"
agent dev start PROJ-31

# ... 구현 ...

pm jira issue transition PROJ-31 "Done"
agent dev submit
```

### 4.2 Lee: Password Reset 작업

```bash
# [Dev-Lee] 작업 시작
pm jira issue transition PROJ-32 "In Progress"
agent dev start PROJ-32

# ... 구현 ...

pm jira issue transition PROJ-32 "Done"
agent dev submit
```

### 4.3 Alex: Test 작업

```bash
# [Dev-Alex] 테스트 작성
pm jira issue transition PROJ-33 "In Progress"
agent dev start PROJ-33

# ... 테스트 작성 ...

pm jira issue transition PROJ-33 "Done"
agent dev submit
```

---

## Phase 5: Sprint Review & Retrospective (Mgr)

### 5.1 Sprint 현황 확인

```bash
# [Mgr] Sprint 2 완료 현황
pm jira issue list --jql "sprint = 268"
```

**예상 결과**:
```
------------------------------------------------------------------------
Key          | Type     | Status       | Summary
------------------------------------------------------------------------
PROJ-30      | Task     | Done         | User Authentication API
PROJ-31      | Task     | Done         | User Registration Form
PROJ-32      | Task     | Done         | Password Reset Feature
PROJ-33      | Task     | Done         | Auth Unit Tests
------------------------------------------------------------------------
```

### 5.2 MR 머지 상태 확인

```bash
# [Mgr] 머지된 MR 확인
pm gitlab mr list --state merged
```

### 5.3 다음 Sprint 계획

```bash
# [Mgr] Sprint 3 이슈 준비
cat > sprint3.csv << 'EOF'
summary,type,assignee_email,description,epic
OAuth Integration,Task,alex@fadutec.com,Google/GitHub OAuth,PROJ-1
Session Management,Task,kim@fadutec.com,세션 관리 개선,PROJ-1
Security Audit,Task,lee@fadutec.com,보안 감사,PROJ-1
EOF

pm jira bulk-create sprint3.csv
```

---

## Timeline Summary

```
Day 1-2:   [Mgr] Sprint Planning + Issue 생성
Day 3:     [Dev-Alex] API 작업 시작
Day 5:     [Dev-Alex] API 완료 + MR 제출
Day 5:     [Mgr] MR 리뷰/승인
Day 6-8:   [Dev-Kim, Lee, Alex] 병렬 작업
Day 9:     [Dev-All] MR 제출
Day 10:    [Mgr] 최종 리뷰/승인
Day 10:    [Mgr] Sprint 회고 + 다음 Sprint 계획
```

---

## 명령어 요약

### Manager 주요 명령어

```bash
pm jira bulk-create <csv>              # 이슈 일괄 생성
pm jira sprint move <key> <sprint-id>  # Sprint 배치
pm jira link create <from> <to> <type> # 의존관계 설정
pm jira issue update <key> --priority  # 우선순위 설정
agent mgr pending                      # 대기 MR 확인
agent mgr review <mr-id>               # MR 리뷰
agent mgr approve <mr-id>              # MR 승인
```

### Developer 주요 명령어

```bash
pm jira issue list --jql "..."         # 내 이슈 확인
pm jira issue transition <key> <status> # 상태 전환
pm jira link view <key>                # 블로커 확인
agent dev start <task-id>              # 작업 시작
agent dev check                        # 품질 체크
agent dev submit                       # MR 제출
```

---

## 체크리스트

### Sprint Planning (Mgr)
- [ ] Epic 하위 Task CSV 준비
- [ ] bulk-create로 이슈 생성
- [ ] Sprint에 이슈 배치
- [ ] 의존관계 설정
- [ ] 우선순위/마감일 설정
- [ ] Sprint 시작

### Development (Dev)
- [ ] 할당된 이슈 확인
- [ ] 블로커 이슈 확인
- [ ] 상태 → In Progress
- [ ] 코드 작업 및 테스트
- [ ] 상태 → Done
- [ ] MR 제출

### Review & Merge (Mgr)
- [ ] MR 리뷰
- [ ] 피드백 제공
- [ ] 승인 및 머지
- [ ] Sprint 회고
- [ ] 다음 Sprint 계획
