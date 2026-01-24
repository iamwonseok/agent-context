# 009: Manager Sprint Planning

**역할**: Manager (Mgr)
**목적**: Sprint 계획 수립, Epic 하위 이슈 일괄 생성, 팀원 할당 및 진행 모니터링

---

## 시나리오 개요

매니저가 새 Sprint를 계획하면서:
1. Epic 확인 및 하위 Task 일괄 생성
2. 팀원에게 이슈 할당
3. Sprint에 이슈 배치
4. 의존관계 설정
5. 진행 상황 모니터링

---

## 전제 조건

- Jira 프로젝트 Admin 또는 담당자 권한
- Epic이 이미 생성되어 있음 (UI에서 생성)
- 팀원 이메일 목록 파악

---

## Step 1: 프로젝트 현황 파악

```bash
# 현재 이슈 목록
pm jira issue list

# 보드 및 Sprint 확인
pm jira sprint list
pm jira sprint list 217  # board_id
```

**예상 출력**:
```
==========================================
Boards for project PROJ
==========================================
[217] Project Board (simple)

------------------------------------------------------------------------
ID     | State      | Name                           | Dates
------------------------------------------------------------------------
266    | active     | Sprint 1                       | 2026-01-20 - 2026-02-03
267    | future     | Sprint 2                       | N/A - N/A
------------------------------------------------------------------------
```

---

## Step 2: 팀원 확인

```bash
# 팀원 검색
pm jira user search "alex"
pm jira user search "kim"
pm jira user search "@fadutec.com"
```

---

## Step 3: Epic 하위 이슈 일괄 생성

### CSV 파일 준비

```bash
cat > sprint2-tasks.csv << 'EOF'
summary,type,assignee_email,description,epic
API 인증 모듈 개발,Task,alex@fadutec.com,JWT 기반 인증 구현,PROJ-1
DB 스키마 설계,Task,kim@fadutec.com,사용자 테이블 설계,PROJ-1
프론트엔드 로그인 UI,Task,lee@fadutec.com,로그인 폼 구현,PROJ-1
API 테스트 작성,Task,alex@fadutec.com,인증 API 테스트,PROJ-1
통합 테스트,Task,kim@fadutec.com,E2E 테스트,PROJ-1
EOF
```

### 일괄 생성 실행

```bash
pm jira bulk-create sprint2-tasks.csv
```

**예상 출력**:
```
==========================================
Jira Bulk Create from CSV
==========================================
File: sprint2-tasks.csv
Project: PROJ

[2] Creating: API 인증 모듈 개발... PROJ-20 (Epic: PROJ-1) -> alex@fadutec.com
[3] Creating: DB 스키마 설계... PROJ-21 (Epic: PROJ-1) -> kim@fadutec.com
[4] Creating: 프론트엔드 로그인 UI... PROJ-22 (Epic: PROJ-1) -> lee@fadutec.com
[5] Creating: API 테스트 작성... PROJ-23 (Epic: PROJ-1) -> alex@fadutec.com
[6] Creating: 통합 테스트... PROJ-24 (Epic: PROJ-1) -> kim@fadutec.com

==========================================
Result: 5 created, 0 failed
==========================================
```

---

## Step 4: Sprint에 이슈 배치

```bash
# Sprint 2 (ID: 267)에 이슈 할당
pm jira sprint move PROJ-20 267
pm jira sprint move PROJ-21 267
pm jira sprint move PROJ-22 267
pm jira sprint move PROJ-23 267
pm jira sprint move PROJ-24 267
```

---

## Step 5: 의존관계 설정

```bash
# DB 설계 → API 개발 (DB가 먼저 되어야 API 개발 가능)
pm jira link create PROJ-20 PROJ-21 "Blocks"

# API 개발 → API 테스트 (API가 있어야 테스트 가능)
pm jira link create PROJ-23 PROJ-20 "Blocks"

# 모든 개발 → 통합 테스트
pm jira link create PROJ-24 PROJ-20 "Blocks"
pm jira link create PROJ-24 PROJ-22 "Blocks"
```

---

## Step 6: 이슈 우선순위/마감일 설정

```bash
# 핵심 이슈 우선순위 높임
pm jira issue update PROJ-21 --priority "High"
pm jira issue update PROJ-20 --priority "High"

# 마감일 설정
pm jira issue update PROJ-21 --due-date "2026-01-25"
pm jira issue update PROJ-20 --due-date "2026-01-28"
pm jira issue update PROJ-24 --due-date "2026-02-02"

# 라벨 추가
pm jira issue update PROJ-20 --labels "backend,auth"
pm jira issue update PROJ-22 --labels "frontend,ui"
```

---

## Step 7: 진행 상황 모니터링

```bash
# Sprint 내 이슈 현황
pm jira issue list --jql "sprint = 267"

# 특정 담당자 이슈
pm jira issue list --jql "assignee = 'alex@fadutec.com' AND sprint = 267"

# 블로커 확인
pm jira link view PROJ-20
```

---

## Step 8: MR 리뷰 관리

```bash
# 대기 중인 MR 확인
agent mgr pending

# MR 리뷰
agent mgr review 15 --comment "LGTM, 테스트 추가 필요"

# 승인
agent mgr approve 15
```

---

## Manual Flow (Without Agent)

순수 `pm` + `curl`로 동일한 작업:

```bash
# 1. CSV 일괄 생성
pm jira bulk-create sprint2-tasks.csv

# 2. Sprint 이동
pm jira sprint move PROJ-20 267

# 3. 의존관계 설정
pm jira link create PROJ-20 PROJ-21 "Blocks"

# 4. 필드 업데이트
pm jira issue update PROJ-20 --priority "High" --due-date "2026-01-28"

# 5. 모니터링
pm jira issue list --jql "sprint = 267"
```

---

## 체크리스트

- [ ] Epic 하위 Task 목록 CSV 준비
- [ ] 팀원별 적정 업무량 배분
- [ ] bulk-create로 일괄 생성
- [ ] Sprint에 이슈 배치
- [ ] 의존관계(Blocks) 설정
- [ ] 우선순위 및 마감일 설정
- [ ] 주기적 진행 상황 모니터링
- [ ] MR 리뷰 및 승인
