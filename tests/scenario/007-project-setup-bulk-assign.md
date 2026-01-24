# 007 - 프로젝트 초기 세팅: CSV 일괄 이슈 생성 + Assignee 할당

## 목적

- 프로젝트 킥오프 시 전체 작업 목록을 **CSV 파일**로 정의하고 **일괄 Jira 이슈 생성 + Assignee 할당**을 수행합니다.
- 외부 도구(jira-cli 등) 의존 없이 `pm` CLI만으로 초기 세팅을 완료합니다.

## 핵심 결론(현재 구현 기준)

- 가능한 것(현재 구현):
  - `pm jira user search EMAIL`: email로 Jira accountId 조회
  - `pm jira issue assign KEY EMAIL`: Issue에 assignee 할당
  - `pm jira issue transition KEY STATUS`: Issue 상태 전환
  - `pm jira bulk-create --csv FILE`: CSV에서 일괄 이슈 생성 + 할당

## 전제/준비

- `.project.yaml`에 `jira`가 설정되어 있어야 합니다.
- Jira API 토큰이 환경변수에 설정되어 있어야 합니다.
- CSV 파일 형식:
  ```csv
  summary,type,assignee_email,description
  "로그인 기능 구현",Task,alice@company.com,"JWT 토큰 기반 인증"
  "버그 수정: 타임아웃",Bug,bob@company.com,""
  "문서 업데이트",Task,charlie@company.com,"API 문서 갱신"
  ```

## 시나리오 상황

- 신규 프로젝트 킥오프
- PM이 전체 작업 목록을 Excel/CSV로 정리
- 팀원별 email로 업무 할당 완료
- Jira에 일괄 업로드하여 트래킹 시작

---

## 커맨드 시퀀스

### 0) 사전 준비

```bash
# 설정 확인
pm config show

# Jira 연결 확인
pm jira me
```

**기대 결과**
- Jira 계정 정보 출력
- Project Key 확인 (예: `PROJ`)

### 1) CSV 파일 준비

```bash
# 예시 CSV 생성
cat > tasks.csv << 'EOF'
summary,type,assignee_email,description
"로그인 기능 구현",Task,alice@company.com,"JWT 토큰 기반 인증 구현"
"회원가입 API",Task,alice@company.com,"이메일 인증 포함"
"DMA 타임아웃 버그",Bug,bob@company.com,"재현 조건: 대용량 전송 시"
"API 문서 업데이트",Task,charlie@company.com,"OpenAPI 스펙 갱신"
"성능 테스트 스크립트",Task,bob@company.com,""
EOF
```

### 2) 팀원 계정 확인 (선택)

```bash
# email로 Jira 계정 검색
pm jira user search "alice@company.com"
pm jira user search "bob@company.com"
pm jira user search "charlie@company.com"
```

**기대 결과**
- 각 사용자의 `Account ID`, `Display Name`, `Email` 출력

### 3) 일괄 이슈 생성 + 할당

```bash
pm jira bulk-create --csv tasks.csv
```

**기대 결과**
```
==========================================
Jira Bulk Create from CSV
==========================================
File: tasks.csv
Project: PROJ

[1] Creating: 로그인 기능 구현... PROJ-101 -> alice@company.com
[2] Creating: 회원가입 API... PROJ-102 -> alice@company.com
[3] Creating: DMA 타임아웃 버그... PROJ-103 -> bob@company.com
[4] Creating: API 문서 업데이트... PROJ-104 -> charlie@company.com
[5] Creating: 성능 테스트 스크립트... PROJ-105 -> bob@company.com

==========================================
Result: 5 created, 0 failed
==========================================
```

### 4) 결과 확인

```bash
# 생성된 이슈 목록 확인
pm jira issue list --limit 10

# 특정 이슈 상세 확인
pm jira issue view PROJ-101
```

**기대 결과**
- Assignee가 올바르게 할당됨
- Type이 CSV에 지정한 대로 설정됨

### 5) 상태 전환 (선택)

```bash
# 특정 이슈를 "In Progress"로 전환
pm jira issue transition PROJ-101 "In Progress"
```

**기대 결과**
- `(v) Transitioned PROJ-101 to In Progress`

---

## 체크리스트(기록용)

| 단계 | 확인 항목 | 결과 |
|------|----------|------|
| 0 | `pm jira me`가 계정 정보를 출력하는가 | [ ] |
| 1 | CSV 파일이 올바른 형식인가 | [ ] |
| 2 | `pm jira user search`로 팀원 계정을 찾을 수 있는가 | [ ] |
| 3 | `pm jira bulk-create`가 이슈를 생성하는가 | [ ] |
| 3 | Assignee가 올바르게 할당되는가 | [ ] |
| 4 | `pm jira issue list`에서 생성된 이슈를 확인할 수 있는가 | [ ] |
| 5 | `pm jira issue transition`으로 상태 전환이 되는가 | [ ] |

---

## Manual Flow (Without Agent)

Agent/pm 없이 순수 CLI + curl로 동일한 작업을 수행하는 방법입니다.

### curl + jq (순수 REST API)

```bash
# 환경변수 설정
export JIRA_URL="https://your-company.atlassian.net"
export JIRA_EMAIL="admin@company.com"
export JIRA_TOKEN="your-api-token"
export PROJECT_KEY="PROJ"

AUTH=$(echo -n "$JIRA_EMAIL:$JIRA_TOKEN" | base64)

# 1. 사용자 검색 (email → accountId)
curl -s -X GET \
  -H "Authorization: Basic $AUTH" \
  -H "Accept: application/json" \
  "$JIRA_URL/rest/api/3/user/search?query=alice@company.com" | jq '.[0].accountId'

# 2. 이슈 생성
curl -s -X POST \
  -H "Authorization: Basic $AUTH" \
  -H "Content-Type: application/json" \
  "$JIRA_URL/rest/api/3/issue" \
  -d '{
    "fields": {
      "project": {"key": "PROJ"},
      "summary": "로그인 기능 구현",
      "issuetype": {"name": "Task"},
      "description": "JWT 토큰 기반 인증"
    }
  }' | jq '.key'

# 3. Assignee 할당
curl -s -X PUT \
  -H "Authorization: Basic $AUTH" \
  -H "Content-Type: application/json" \
  "$JIRA_URL/rest/api/3/issue/PROJ-101" \
  -d '{
    "fields": {
      "assignee": {"accountId": "5b10a2844c20165700ede21g"}
    }
  }'

# 4. 상태 전환 (transition ID 필요)
# 먼저 가능한 전환 조회
curl -s -X GET \
  -H "Authorization: Basic $AUTH" \
  "$JIRA_URL/rest/api/3/issue/PROJ-101/transitions" | jq '.transitions[] | {id, name}'

# 전환 실행
curl -s -X POST \
  -H "Authorization: Basic $AUTH" \
  -H "Content-Type: application/json" \
  "$JIRA_URL/rest/api/3/issue/PROJ-101/transitions" \
  -d '{"transition": {"id": "21"}}'
```

### Bash 스크립트 (일괄 처리)

```bash
#!/bin/bash
# bulk-jira-upload.sh

CSV_FILE=$1
AUTH=$(echo -n "$JIRA_EMAIL:$JIRA_TOKEN" | base64)

# accountId 캐시
declare -A ACCOUNT_CACHE

get_account_id() {
    local email=$1
    if [[ -n "${ACCOUNT_CACHE[$email]}" ]]; then
        echo "${ACCOUNT_CACHE[$email]}"
        return
    fi
    
    local id=$(curl -s -X GET \
        -H "Authorization: Basic $AUTH" \
        "$JIRA_URL/rest/api/3/user/search?query=$email" | jq -r '.[0].accountId')
    
    ACCOUNT_CACHE[$email]=$id
    echo "$id"
}

# CSV 처리 (header 스킵)
tail -n +2 "$CSV_FILE" | while IFS=',' read -r summary type email desc; do
    # 이슈 생성
    key=$(curl -s -X POST \
        -H "Authorization: Basic $AUTH" \
        -H "Content-Type: application/json" \
        "$JIRA_URL/rest/api/3/issue" \
        -d "{\"fields\":{\"project\":{\"key\":\"$PROJECT_KEY\"},\"summary\":$summary,\"issuetype\":{\"name\":$type}}}" \
        | jq -r '.key')
    
    echo -n "Created: $key"
    
    # Assignee 할당
    if [[ -n "$email" ]]; then
        account_id=$(get_account_id "$email")
        curl -s -X PUT \
            -H "Authorization: Basic $AUTH" \
            -H "Content-Type: application/json" \
            "$JIRA_URL/rest/api/3/issue/$key" \
            -d "{\"fields\":{\"assignee\":{\"accountId\":\"$account_id\"}}}"
        echo " -> $email"
    else
        echo ""
    fi
done
```

---

## Responsibility Boundary

### CLI Responsibilities

**pm CLI** (agent-context 제공):
- `pm jira user search`: email로 accountId 조회
- `pm jira issue create`: 단일 이슈 생성
- `pm jira issue assign`: Assignee 할당
- `pm jira issue transition`: 상태 전환
- `pm jira bulk-create`: CSV 일괄 생성 + 할당

**순수 curl**:
- REST API 직접 호출 (위 Manual Flow 참조)

### UI Responsibilities (Platform-specific)

**Jira UI**:
- CSV Import (Jira 자체 기능) - 단, 세부 제어 제한
- 복잡한 필드 설정 (Custom fields, Components 등)
- 워크플로우 설정

### pm CLI vs Jira CSV Import

| 항목 | pm CLI | Jira CSV Import |
|------|--------|-----------------|
| Assignee 자동 할당 | ✅ email로 자동 매핑 | ❌ accountId 직접 지정 필요 |
| 실시간 피드백 | ✅ 각 이슈별 결과 출력 | ❌ 일괄 결과만 |
| 스크립트 통합 | ✅ CI/CD 파이프라인 가능 | ❌ UI만 지원 |
| Custom fields | ❌ 기본 필드만 | ✅ 지원 |
| 대용량 처리 | ⚠️ 순차 처리 | ✅ 최적화됨 |

---

## 확장 시나리오

### A) 팀별 할당

```csv
summary,type,assignee_email,description
"백엔드 API",Task,backend-team@company.com,""
"프론트엔드 UI",Task,frontend-team@company.com,""
```

### B) 스프린트 연동 (추가 구현 필요)

```csv
summary,type,assignee_email,sprint,description
"기능 A",Task,alice@company.com,Sprint 1,""
```

### C) Epic 연결 (추가 구현 필요)

```csv
summary,type,assignee_email,epic_key,description
"서브태스크 1",Sub-task,alice@company.com,PROJ-100,""
```

---

## 주의사항

- **대용량 CSV**: 100개 이상 이슈 생성 시 Jira API Rate Limit 주의
- **email 불일치**: Jira에 등록되지 않은 email은 할당 실패 (경고 출력)
- **Type 불일치**: 프로젝트에 없는 Issue Type은 생성 실패
- **중복 실행**: 동일 CSV 재실행 시 중복 이슈 생성됨 (idempotent 아님)

---

**작성일**: 2026-01-24  
**대상**: 프로젝트 PM, 팀 리드  
**목적**: 프로젝트 초기 세팅 자동화
