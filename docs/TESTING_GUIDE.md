# 테스트 가이드

agent-context CLI의 전체 테스트 시나리오 및 검증 방법을 정리한 문서입니다.
`tests` 명령의 모든 시나리오를 담당합니다. 데모(E2E) 시나리오는 [demo/README.md](../demo/README.md) 참고.

## 목차

- [테스트 아키텍처](#테스트-아키텍처)
- [공통 규격](#공통-규격)
- [레벨 1: 기본 조회](#레벨-1-기본-조회)
- [레벨 2: 환경 진단](#레벨-2-환경-진단)
- [레벨 3: 상태 확인](#레벨-3-상태-확인)
- [레벨 4: 설치/업데이트](#레벨-4-설치업데이트)
- [레벨 5: 고급/위험 작업](#레벨-5-고급위험-작업)

---

## 테스트 아키텍처

테스트는 4개 Layer로 구성됩니다:

| Layer | 이름 | 토큰 필요 | 네트워크 | 설명 |
|-------|------|:--------:|:--------:|------|
| 0 | Static/Contract | X | X | 템플릿, 스킬, 워크플로우 파일 구조 검증 |
| 1 | Offline Functional | X | X | CLI 도움말, 버전, 설치 기능 검증 |
| 2 | Mock Integration | X | X | Mock 서버 기반 API 통합 테스트 |
| 3 | Real E2E | O | O | 실제 SaaS(Jira, GitLab) 연동 테스트 |

### Smoke 테스트 (Layer 0 + 1)

MR 파이프라인에서 필수로 실행되는 토큰 불필요 테스트:

```bash
agent-context tests smoke
```

포함 태그: `deps`, `templates-contract`, `skills-spec`, `workflows-chain`,
`cli-help-contract`, `cli-version`, `cli-error-handling`, `tests-runner-contract`,
`install-non-interactive`, `install-artifacts`, `pm-offline`, `secrets-mask`

### 사용 가능한 테스트 태그

```bash
agent-context tests list
```

| 태그 | Layer | 설명 |
|------|:-----:|------|
| `deps` | 0 | 필수 바이너리 및 권한 검사 |
| `templates-contract` | 0 | 템플릿 파일/토큰 계약 검증 |
| `skills-spec` | 0 | Thin Skill 스펙 검증 |
| `workflows-chain` | 0 | 워크플로우 스킬 체인 순서 검증 |
| `cli-help-contract` | 1 | 모든 CLI 서브커맨드 --help exit 0 |
| `cli-version` | 1 | CLI 버전 출력 검증 |
| `cli-error-handling` | 1 | CLI 에러 케이스 검증 |
| `tests-runner-contract` | 1 | 테스트 러너 자기 검증 |
| `install-non-interactive` | 1 | 비대화형 설치 검증 |
| `install-artifacts` | 1 | 설치 산출물 검증 |
| `pm-offline` | 1 | PM 오프라인 기능 검증 |
| `secrets-mask` | 1 | 시크릿 마스킹 검증 |
| `jira-auth-mock` | 2 | Jira 인증 (Mock 서버) |
| `confluence-auth-mock` | 2 | Confluence 인증 (Mock 서버) |
| `pm-jira-mock` | 2 | PM Jira 명령 (Mock 서버) |
| `pm-confluence-mock` | 2 | PM Confluence 명령 (Mock 서버) |
| `audit-repo` | - | 저장소 템플릿 감사 |
| `audit-project` | - | 프로젝트 구조 감사 |

### 레거시 태그 (DEPRECATED)

다음 태그들은 `doctor` 서브커맨드로 이관되었습니다:

| 레거시 태그 | 대체 명령 |
|------------|----------|
| `auth` | `agent-context doctor auth` |
| `global` | `agent-context doctor global` |
| `project` | `agent-context doctor project` |
| `connect` | `agent-context doctor connect` |

### 로컬 CI 실행

```bash
# 전체 CI 파이프라인 시뮬레이션 (Docker/E2E 제외)
./tests/ci/run-all.sh --skip-docker --skip-e2e

# Docker 테스트 포함
./tests/ci/run-all.sh --skip-e2e

# 특정 단계만 실행
./tests/ci/run-all.sh --only smoke
```

### Mock 서버 테스트 (Layer 2)

```bash
# Mock 서버 시작
python3 tests/mock/server/mock_server.py --port 8899 &

# Layer 2 테스트 실행
MOCK_API_HOST=localhost MOCK_API_PORT=8899 \
  agent-context tests --tags jira-auth-mock,confluence-auth-mock

# Mock 서버 종료
pkill -f mock_server.py
```

---

## 공통 규격

모든 테스트 시나리오에 적용되는 규격입니다.

### Summary 포맷

모든 명령의 최종 출력은 다음 형식을 따릅니다:

```
Summary: total=N passed=N failed=N warned=N skipped=N
```

### Exit Code

| 코드 | 의미 |
|------|------|
| 0 | 성공 (모든 검사 통과) |
| 1 | 실패 (하나 이상의 검사 실패) |
| 2 | 사용 오류 (잘못된 명령/옵션) |
| 3 | 환경 스킵 (전제 조건 미충족으로 실행 불가) |

### 출력 마커

| 마커 | 의미 |
|------|------|
| `[V]` | 통과 (pass) |
| `[X]` | 실패 (fail) |
| `[!]` | 경고 (warn) |
| `[-]` | 건너뜀 (skip) |
| `[i]` | 정보 (info) |
| `[*]` | 진행 (progress) |

### 민감 정보 규칙

- stdout 및 로그 파일에 토큰, 비밀번호, API 키가 노출되면 안 됨
- `log --raw` 옵션만 마스킹 없이 출력 (명시적 opt-in)

### 테스트 항목 표준 포맷

이 문서의 각 테스트 항목은 다음 구조를 따릅니다:

- **목적**: 1줄 설명
- **시나리오**: 표 (#, 시나리오명, 명령어, 기대 결과)
- **체크리스트**: 확인 항목
- **확인 방법**: bash 검증 스크립트

---

## 레벨 1: 기본 조회

읽기 전용, 외부 의존 없음. 가장 단순한 명령으로 CLI 자체가 정상 동작하는지 확인합니다.

### version -- 버전 출력

- **목적**: CLI 버전 문자열이 정상 출력되는지 확인

| # | 시나리오 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| 1-1 | `--version` 플래그 | `agent-context --version` | `Agent-Context ... vX.Y.Z` 형식 출력, exit 0 |
| 1-2 | `-V` 단축 플래그 | `agent-context -V` | 1-1과 동일 |
| 1-3 | `version` 하위 명령 | `agent-context version` | 1-1과 동일 |

**체크리스트:**

- 출력에 버전 번호(`X.Y.Z` 패턴)가 포함
- exit code = 0
- stderr 출력 없음

**확인 방법:**

```bash
output=$(agent-context --version 2>&1)
echo "$output" | grep -qE '[0-9]+\.[0-9]+\.[0-9]+'
test $? -eq 0 && echo "[V] version output valid" || echo "[X] version output invalid"
```

### help -- 도움말 출력

- **목적**: 도움말이 전체 명령어 목록을 포함하여 출력되는지 확인

| # | 시나리오 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| 1-4 | `--help` 플래그 | `agent-context --help` | USAGE/COMMANDS 섹션 포함, exit 0 |
| 1-5 | `-h` 단축 플래그 | `agent-context -h` | 1-4와 동일 |
| 1-6 | `help` 하위 명령 | `agent-context help` | 1-4와 동일 |
| 1-7 | 인자 없이 실행 | `agent-context` | 1-4와 동일 (도움말 출력) |

**체크리스트:**

- 출력에 `USAGE:` 포함
- 출력에 `COMMANDS:` 포함
- 13개 주요 명령어(init, update, install, upgrade, clean, doctor, audit, tests, log, report, demo, pm) 전체 나열
- exit code = 0

**확인 방법:**

```bash
output=$(agent-context --help 2>&1)
for cmd in init update install upgrade clean doctor audit tests log report demo pm; do
    echo "$output" | grep -q "$cmd" \
        && echo "[V] help contains: $cmd" \
        || echo "[X] help missing: $cmd"
done
```

### log --list -- 로그 목록

- **목적**: 로그 파일 목록이 오류 없이 출력되는지 확인

| # | 시나리오 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| 1-8 | 로그 목록 조회 | `agent-context log --list` | 로그 파일 경로 목록 또는 빈 출력, exit 0 |

**체크리스트:**

- exit code = 0
- 로그가 없으면 빈 출력 또는 안내 메시지
- 로그가 있으면 파일 경로 나열

**확인 방법:**

```bash
agent-context log --list
test $? -eq 0 && echo "[V] log --list succeeded" || echo "[X] log --list failed"
```

---

## 레벨 2: 환경 진단

읽기 전용이지만 로컬 환경을 분석합니다. 외부 네트워크 호출은 없습니다.

### doctor -- 전체 진단

- **목적**: 의존성, 인증, 프로젝트 설정을 종합 점검

| # | 시나리오 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| 2-1 | 전체 진단 | `agent-context doctor` | Summary 출력, exit 0 (모두 통과 시) |
| 2-2 | 의존성만 | `agent-context doctor deps` | deps 관련 `[V]`/`[X]` 출력, exit 0/1 |
| 2-3 | 인증만 | `agent-context doctor auth` | auth 관련 `[V]`/`[X]` 출력, exit 0/1 |
| 2-4 | 프로젝트만 | `agent-context doctor project` | project 관련 `[V]`/`[X]` 출력, exit 0/1 |

**체크리스트:**

- `doctor` (인자 없음)은 deps + auth + project를 모두 실행
- 각 하위 명령은 해당 영역만 검사
- Summary 포맷 준수
- `[V]`/`[X]` 마커 사용
- exit code가 결과에 맞게 설정 (0=모두 통과, 1=하나라도 실패)

**확인 방법:**

```bash
# 전체 진단
output=$(agent-context doctor 2>&1)
echo "$output" | grep -q "Summary:"
test $? -eq 0 && echo "[V] doctor has Summary" || echo "[X] doctor missing Summary"

# 의존성 진단
agent-context doctor deps
test $? -eq 0 && echo "[V] doctor deps passed" || echo "[X] doctor deps failed"

# 인증 진단
agent-context doctor auth
test $? -eq 0 && echo "[V] doctor auth passed" || echo "[X] doctor auth failed"

# 프로젝트 진단 (프로젝트 디렉토리에서 실행)
agent-context doctor project
test $? -eq 0 && echo "[V] doctor project passed" || echo "[X] doctor project failed"
```

### audit -- 저장소/프로젝트 감사

- **목적**: 저장소 또는 프로젝트의 구조적 정합성 검사

| # | 시나리오 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| 2-5 | 자동 감지 | `agent-context audit` | 컨텍스트에 따라 repo 또는 project 모드 실행 |
| 2-6 | 개발자 모드 | `agent-context audit --repo` | `~/.agent-context` 내부 템플릿/구조 검사 |
| 2-7 | 사용자 모드 | `agent-context audit --project` | `.agent/` 구조 및 `.project.yaml` 검사 |

**체크리스트:**

- 자동 감지 모드: `~/.agent-context`에서 실행 시 `--repo`, 프로젝트에서 실행 시 `--project`
- `--repo` 모드: 템플릿 파일 존재, 디렉토리 구조 정합성
- `--project` 모드: `.agent/` 하위 구조, `.project.yaml` 필수 필드, `CHANGE_ME` 잔존 감지
- Summary 포맷 준수

**확인 방법:**

```bash
# 프로젝트 디렉토리에서
agent-context audit --project
test $? -eq 0 && echo "[V] audit --project passed" || echo "[X] audit --project failed"

# 저장소에서 (개발자)
cd ~/.agent-context
agent-context audit --repo
test $? -eq 0 && echo "[V] audit --repo passed" || echo "[X] audit --repo failed"
```

### tests list -- 테스트 목록

- **목적**: 사용 가능한 테스트와 태그 목록을 확인

| # | 시나리오 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| 2-8 | 테스트 목록 | `agent-context tests list` | 태그 이름 및 설명 목록, exit 0 |

**체크리스트:**

- 출력에 사용 가능한 태그 나열 (deps, templates-contract, cli-help-contract 등)
- Smoke 테스트 태그 목록 표시
- exit code = 0

**확인 방법:**

```bash
output=$(agent-context tests list 2>&1)
echo "$output" | grep -q "deps"
test $? -eq 0 && echo "[V] tests list contains deps tag" || echo "[X] tests list missing deps tag"
```

### log -- 로그 조회

- **목적**: 실행 로그를 다양한 옵션으로 조회

| # | 시나리오 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| 2-9 | 최근 로그 | `agent-context log` | 최근 로그 내용 또는 "no logs" 안내, exit 0 |
| 2-10 | 글로벌 로그 | `agent-context log --global` | `~/.local/state/agent-context/logs/` 로그 |
| 2-11 | 프로젝트 로그 | `agent-context log --project` | `.agent/state/logs/` 로그 |
| 2-12 | tail 제한 | `agent-context log --tail 10` | 마지막 10줄만 출력 |
| 2-13 | 레벨 필터 | `agent-context log --level error` | error 레벨만 필터링 |
| 2-14 | 마스킹 해제 | `agent-context log --raw` | 민감 데이터 마스킹 없이 출력 |

**체크리스트:**

- 각 옵션이 오류 없이 실행
- `--tail N`: 출력 줄 수가 N 이하
- `--level`: 해당 레벨 로그만 포함
- 기본 출력에서 민감 데이터 마스킹 (`--raw` 없이)
- `--raw` 사용 시 마스킹 해제
- exit code = 0

**확인 방법:**

```bash
# 각 옵션 실행 확인
for opt in "" "--global" "--project" "--tail 10" "--level error"; do
    agent-context log $opt 2>/dev/null
    test $? -le 1 && echo "[V] log $opt ok" || echo "[X] log $opt failed"
done
```

---

## 레벨 3: 상태 확인

외부 서비스 호출을 포함합니다. 네트워크가 필요한 테스트가 있으며, CI 환경에서 주로 사용합니다.

### doctor connect -- 외부 연결 테스트

- **목적**: GitLab/Jira/Confluence 등 외부 서비스 연결을 확인

| # | 시나리오 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| 3-1 | 외부 연결 | `agent-context doctor connect` | 각 서비스별 `[V]`/`[X]`, exit 0/1 |

**체크리스트:**

- 네트워크 가용 시: 각 서비스 연결 결과 표시
- 네트워크 불가 시: `[X]` 또는 `[-]` (스킵), exit 1 또는 3
- Summary 포맷 준수

**확인 방법:**

```bash
agent-context doctor connect
rc=$?
if [ $rc -eq 0 ]; then
    echo "[V] doctor connect: all services reachable"
elif [ $rc -eq 3 ]; then
    echo "[-] doctor connect: skipped (environment)"
else
    echo "[X] doctor connect: some services unreachable"
fi
```

### tests smoke -- 빠른 상태 점검

- **목적**: MR 파이프라인에서 토큰 없이 실행 가능한 필수 테스트 (Layer 0 + 1)

| # | 시나리오 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| 3-2 | smoke 테스트 | `agent-context tests smoke` | Layer 0+1 테스트 12개 실행, Summary, exit 0/1 |
| 3-3 | smoke + skip | `agent-context tests smoke --skip install-non-interactive` | 특정 태그 제외하고 실행 |

**체크리스트:**

- `smoke`는 Layer 0(Static/Contract) + Layer 1(Offline Functional) 테스트 실행
- 포함 태그: `deps`, `templates-contract`, `skills-spec`, `workflows-chain`,
  `cli-help-contract`, `cli-version`, `cli-error-handling`, `tests-runner-contract`,
  `install-non-interactive`, `install-artifacts`, `pm-offline`, `secrets-mask`
- `--skip`으로 특정 태그 제외 가능
- Summary 포맷 준수
- exit code: 0(모두 통과), 1(실패 있음)

**확인 방법:**

```bash
# 기본 smoke (Layer 0+1 전체)
agent-context tests smoke
test $? -eq 0 && echo "[V] smoke passed" || echo "[X] smoke failed"

# 특정 태그 제외
agent-context tests smoke --skip install-non-interactive
```

### tests --tags -- 태그 기반 실행

- **목적**: 특정 태그만 선택하여 테스트 실행

| # | 시나리오 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| 3-4 | 단일 태그 | `agent-context tests --tags deps` | deps 테스트만 실행 |
| 3-5 | 복수 태그 | `agent-context tests --tags deps,auth` | deps + auth 실행 |
| 3-6 | connect 태그 | `agent-context tests --tags connect` | 네트워크 연결 테스트 |

**체크리스트:**

- 지정된 태그만 실행
- 쉼표 구분 복수 태그 지원
- Summary에 total이 지정 태그 수와 일치
- 존재하지 않는 태그 지정 시 적절한 오류/경고

**확인 방법:**

```bash
# deps 태그만
output=$(agent-context tests --tags deps 2>&1)
echo "$output" | grep -q "Summary:"
test $? -eq 0 && echo "[V] --tags deps has Summary" || echo "[X] --tags deps missing Summary"

# deps + auth
agent-context tests --tags deps,auth
test $? -eq 0 && echo "[V] --tags deps,auth passed" || echo "[X] --tags deps,auth failed"
```

### tests --skip -- 태그 건너뛰기

- **목적**: 특정 태그를 제외하고 테스트 실행

| # | 시나리오 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| 3-7 | connect 제외 | `agent-context tests --tags deps,auth,connect --skip connect` | connect 제외, deps+auth만 실행 |

**체크리스트:**

- `--skip`으로 지정한 태그는 실행되지 않음
- `--tags`와 `--skip` 조합 동작

**확인 방법:**

```bash
output=$(agent-context tests --tags deps,connect --skip connect 2>&1)
echo "$output" | grep -qi "connect.*\[V\]\|connect.*\[X\]" \
    && echo "[X] connect should be skipped" \
    || echo "[V] connect correctly skipped"
```

### tests --formula -- 부울 수식 필터

- **목적**: 복잡한 조건으로 테스트를 필터링

| # | 시나리오 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| 3-8 | AND 조합 | `agent-context tests --formula "deps and auth"` | deps와 auth 모두 포함하는 테스트 |
| 3-9 | NOT 조합 | `agent-context tests --formula "deps and not connect"` | deps이면서 connect가 아닌 테스트 |
| 3-10 | 괄호 조합 | `agent-context tests --formula "(auditRepo or auditProject) and deps"` | audit 중 하나 + deps |

**체크리스트:**

- `and`/`&&`, `or`/`||`, `not`/`!` 연산자 동작
- 괄호 `()` 그룹핑 동작
- 우선순위: not > and > or
- 잘못된 수식 시 exit code = 2

**확인 방법:**

```bash
# AND 조합
agent-context tests --formula "deps and auth"
test $? -le 1 && echo "[V] formula AND works" || echo "[X] formula AND failed"

# NOT 조합
agent-context tests --formula "deps and not connect"
test $? -le 1 && echo "[V] formula NOT works" || echo "[X] formula NOT failed"
```

### report -- 진단 리포트 생성

- **목적**: 현재 환경의 진단 정보를 리포트로 생성

| # | 시나리오 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| 3-11 | stdout 출력 | `agent-context report` | Markdown 형식 리포트, exit 0 |
| 3-12 | 파일 저장 | `agent-context report --output /tmp/test-report.md` | 파일 생성, exit 0 |
| 3-13 | GitLab 이슈 | `agent-context report --issue` | GitLab 이슈 생성 (glab 필요), exit 0/1 |

**체크리스트:**

- 기본 출력은 Markdown 형식
- `--output`은 지정 경로에 파일 생성
- `--issue`는 glab이 인증된 상태에서만 동작
- 리포트에 민감 정보 미포함
- exit code = 0 (성공 시)

**확인 방법:**

```bash
# stdout 리포트
output=$(agent-context report 2>&1)
test -n "$output" && echo "[V] report generated" || echo "[X] report empty"

# 파일 저장
agent-context report --output /tmp/test-report.md
test -f /tmp/test-report.md && echo "[V] report file created" || echo "[X] report file missing"
rm -f /tmp/test-report.md
```

---

## 레벨 4: 설치/업데이트

쓰기 작업을 포함합니다. 파일 시스템을 변경하므로 격리된 환경(임시 디렉토리, Docker)에서 실행을 권장합니다.

### init -- 글로벌 환경 초기화

- **목적**: `~/.secrets`, 쉘 설정 등 글로벌 환경을 초기화

| # | 시나리오 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| 4-1 | 기본 초기화 | `agent-context init` | 대화형 실행, `~/.secrets` 생성, 쉘 설정 추가 |
| 4-2 | GitLab 건너뛰기 | `agent-context init --skip-gitlab` | GitLab 관련 설정 건너뜀 |
| 4-3 | Atlassian 건너뛰기 | `agent-context init --skip-atlassian` | Atlassian 관련 설정 건너뜀 |
| 4-4 | CI 비대화형 | 환경변수 사전 설정 + `agent-context init` | 프롬프트 없이 실행 |

**체크리스트:**

- `~/.secrets` 디렉토리 생성 (mode 700)
- 쉘 RC 파일에 `# BEGIN AGENT_CONTEXT` ... `# END AGENT_CONTEXT` 블록 추가
- alias가 `~/.agent-context/bin/agent-context.sh`를 가리킴
- `--skip-*` 옵션이 해당 단계를 건너뜀
- 중복 실행 시 기존 설정을 덮어쓰지 않거나 안전하게 교체

**확인 방법:**

```bash
# 초기화 후 확인 (실제 환경 주의)
test -d ~/.secrets && echo "[V] ~/.secrets exists" || echo "[X] ~/.secrets missing"
stat -f "%Lp" ~/.secrets 2>/dev/null | grep -q "700" \
    && echo "[V] ~/.secrets mode 700" \
    || echo "[X] ~/.secrets mode incorrect"
grep -q "AGENT_CONTEXT" ~/.zshrc 2>/dev/null \
    && echo "[V] shell config found" \
    || echo "[X] shell config missing"
```

### install -- 프로젝트 설치

- **목적**: 현재 디렉토리에 agent-context를 설치

| # | 시나리오 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| 4-5 | 대화형 설치 (full) | `agent-context install` | `.agent/`, `.cursorrules`, `.project.yaml` 생성 |
| 4-6 | 비대화형 | `agent-context install --non-interactive` | 프롬프트 없이 기본값으로 설치 |
| 4-7 | 강제 설치 | `agent-context install --force` | 기존 파일 덮어쓰기 |
| 4-8 | minimal 프로필 | `agent-context install --profile minimal` | core 파일만 설치 |
| 4-9 | full 프로필 | `agent-context install --profile full` | core + 설정 파일 |
| 4-10 | Python 포함 | `agent-context install --with-python` | `pyproject.toml` 추가 |
| 4-11 | 설정 옵션 | `agent-context install --non-interactive --jira-url URL --jira-project KEY` | 지정 값으로 `.project.yaml` 생성 |

**체크리스트:**

- `.agent/skills/`, `.agent/workflows/`, `.agent/tools/pm/` 디렉토리 생성
- `.cursorrules` 파일 생성 (index map 포함)
- `.project.yaml` 생성 (설정 값 반영)
- `--profile minimal`: `.editorconfig` 등 미생성
- `--profile full`: `.editorconfig`, `.pre-commit-config.yaml` 등 생성
- `--force`: 기존 파일 덮어쓰기 (`.gitignore`는 병합)
- `--with-python`: `pyproject.toml` 생성
- `--non-interactive` + 설정 옵션: `.project.yaml`에 지정 값 반영

**확인 방법:**

```bash
# 임시 디렉토리에서 테스트
TESTDIR=$(mktemp -d)
cd "$TESTDIR"

agent-context install --non-interactive --force --profile full
test -d .agent/skills && echo "[V] skills installed" || echo "[X] skills missing"
test -d .agent/workflows && echo "[V] workflows installed" || echo "[X] workflows missing"
test -f .cursorrules && echo "[V] .cursorrules created" || echo "[X] .cursorrules missing"
test -f .project.yaml && echo "[V] .project.yaml created" || echo "[X] .project.yaml missing"
test -f .editorconfig && echo "[V] .editorconfig created (full)" || echo "[X] .editorconfig missing"

# 정리
rm -rf "$TESTDIR"
```

### update (up) -- 소스 업데이트

- **목적**: `~/.agent-context` 소스 저장소를 최신으로 업데이트

| # | 시나리오 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| 4-12 | 업데이트 확인 | `agent-context update --check` | 업데이트 가용 여부 표시, exit 0 |
| 4-13 | 기본 업데이트 | `agent-context update` | git pull 실행, exit 0 |
| 4-14 | dirty tree 시 | `agent-context update` (로컬 변경 있을 때) | 중단, exit 1 |
| 4-15 | 강제 업데이트 | `agent-context update --force` (로컬 변경 있을 때) | stash 후 pull, exit 0 |

**체크리스트:**

- `--check`: 실제 변경 없이 확인만
- 기본 동작: dirty tree면 중단 (exit 1)
- `--force`: 로컬 변경사항을 stash 후 pull
- 업데이트 성공 후 버전 변경 여부 출력

**확인 방법:**

```bash
# 업데이트 확인
agent-context update --check
test $? -eq 0 && echo "[V] update --check ok" || echo "[X] update --check failed"
```

### upgrade -- 프로젝트 업그레이드

- **목적**: 프로젝트의 `.agent/` 파일을 최신 소스에 맞게 갱신

| # | 시나리오 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| 4-16 | diff 미리보기 | `agent-context upgrade` | 변경 사항 diff 출력, 파일 변경 없음 |
| 4-17 | 적용 | `agent-context upgrade --apply` | `.agent/` 파일 갱신, 백업 생성 |
| 4-18 | 적용 + 삭제 | `agent-context upgrade --apply --prune` | 소스에 없는 파일도 삭제 |
| 4-19 | 롤백 | `agent-context upgrade --rollback` | `.agent/.backup/`에서 복원 |

**체크리스트:**

- 기본 동작: diff만 표시 (파일 변경 없음)
- `--apply`: 파일 실제 갱신 + `.agent/.backup/` 생성
- `--apply --prune`: 불필요 파일 삭제
- `--rollback`: 백업에서 복원
- 백업은 1세대만 유지

**확인 방법:**

```bash
# diff 미리보기
agent-context upgrade
test $? -eq 0 && echo "[V] upgrade preview ok" || echo "[X] upgrade preview failed"

# 적용 + 롤백
agent-context upgrade --apply
test -d .agent/.backup && echo "[V] backup created" || echo "[X] backup missing"
agent-context upgrade --rollback
echo "[V] rollback completed"
```

---

## 레벨 5: 고급/위험 작업

파괴적 작업이나 외부 리소스 생성을 포함합니다. 반드시 격리된 환경에서 실행하세요.

### clean -- 전체 정리

- **목적**: 캐시, 상태 파일, 로그를 정리

| # | 시나리오 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| 5-1 | dry-run | `agent-context clean --dry-run` | 삭제 대상 표시, 실제 삭제 없음 |
| 5-2 | 기본 정리 | `agent-context clean` | `.agent/state/*` 정리 (로그 제외) |
| 5-3 | 로그 포함 | `agent-context clean --logs` | 로그도 함께 정리 |
| 5-4 | 글로벌 정리 | `agent-context clean --global` | `~/.local/state/agent-context/` 정리 |
| 5-5 | 전체 강제 정리 | `agent-context clean --all --force` | 모든 상태 데이터 삭제 (확인 없이) |

**체크리스트:**

- `--dry-run`: 파일이 실제로 삭제되지 않음
- `--all` 단독 사용 시 `--force` 요구
- `--force`: 확인 프롬프트 건너뜀
- 정리 대상이 없으면 안내 메시지
- exit code = 0

**확인 방법:**

```bash
# dry-run 확인
agent-context clean --dry-run
test $? -eq 0 && echo "[V] clean --dry-run ok" || echo "[X] clean --dry-run failed"

# 기본 정리
agent-context clean
test $? -eq 0 && echo "[V] clean ok" || echo "[X] clean failed"
```

### tests e2e -- E2E 테스트

- **목적**: 실제 SaaS(Jira, GitLab) 연동 테스트 (Layer 3)

| # | 시나리오 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| 5-6 | E2E 테스트 | `agent-context tests e2e` | Docker 환경에서 전체 테스트, Summary 출력 |
| 5-7 | install-non-interactive | `agent-context tests --tags install-non-interactive` | 비대화형 설치 테스트 |

**체크리스트:**

- 토큰이 필요한 테스트는 환경변수 설정 필요 (`JIRA_API_TOKEN`, `GITLAB_API_TOKEN` 등)
- Docker가 설치/실행 중이어야 함 (Docker 기반 테스트 시)
- Docker 미설치 시 exit code = 3 (환경 스킵)
- E2E 실패는 외부 요인(네트워크, 권한 등)일 수 있음
- Summary 포맷 준수

**로컬 실행:**

```bash
# 전체 로컬 CI (Docker/E2E 제외)
./tests/ci/run-all.sh --skip-docker --skip-e2e

# Docker 포함
./tests/ci/run-all.sh --skip-e2e
```

### 전체 라이프사이클 통합 시나리오

- **목적**: init부터 clean까지 전체 명령어 흐름을 순차 검증

```bash
# 전체 라이프사이클 (임시 디렉토리에서)
TESTDIR=$(mktemp -d)

# 1. init (이미 완료된 상태 가정)
# 2. install
cd "$TESTDIR"
agent-context install --non-interactive --force
test $? -eq 0 && echo "[V] install ok" || echo "[X] install failed"

# 3. doctor
agent-context doctor
test $? -eq 0 && echo "[V] doctor ok" || echo "[X] doctor failed"

# 4. tests smoke
agent-context tests smoke
test $? -eq 0 && echo "[V] tests smoke ok" || echo "[X] tests smoke failed"

# 5. audit
agent-context audit --project
test $? -eq 0 && echo "[V] audit ok" || echo "[X] audit failed"

# 6. update (소스)
agent-context update --check
test $? -eq 0 && echo "[V] update check ok" || echo "[X] update check failed"

# 7. upgrade (프로젝트)
agent-context upgrade
test $? -eq 0 && echo "[V] upgrade preview ok" || echo "[X] upgrade preview failed"

# 8. log
agent-context log --list
test $? -eq 0 && echo "[V] log list ok" || echo "[X] log list failed"

# 9. report
agent-context report --output "$TESTDIR/report.md"
test -f "$TESTDIR/report.md" && echo "[V] report ok" || echo "[X] report failed"

# 10. clean
agent-context clean --dry-run
test $? -eq 0 && echo "[V] clean ok" || echo "[X] clean failed"

# 정리
rm -rf "$TESTDIR"
```

### CI/CD 파이프라인 통합

**GitLab CI 구성:**

현재 `.gitlab-ci.yml`의 주요 테스트 Job:

| Job | 설명 | 실행 조건 |
|-----|------|----------|
| `lint` | pre-commit 린트 검사 | MR/main |
| `test:smoke` | Layer 0+1 smoke 테스트 | MR/main |
| `test:unit` | 버전, 도움말, tests list 검증 | MR/main |
| `test:workflow` | Docker 기반 워크플로우 테스트 | MR/main |
| `test:docker-install` | Ubuntu/UBI9 설치 테스트 | MR/main |
| `test:meta` | skills/workflows 변경 시 메타 검증 | 조건부 |
| `test:mock-integration` | PM/Mock 변경 시 Layer 2 테스트 | 조건부 |
| `test:e2e` | 토큰 필요 E2E (수동/스케줄) | manual |

**커스텀 프로젝트 CI 예시:**

```yaml
# .gitlab-ci.yml
stages:
  - check

agent-context-smoke:
  stage: check
  image: ubuntu:22.04
  variables:
    AGENT_CONTEXT_DIR: $CI_PROJECT_DIR
  before_script:
    - apt-get update && apt-get install -y git curl jq yq
  script:
    - ./bin/agent-context.sh tests smoke
  allow_failure: false
```

### Docker 크로스 플랫폼

| 플랫폼 | 명령 |
|--------|------|
| Ubuntu | `agent-context demo --os ubuntu --skip-e2e` |
| UBI9 (RHEL) | `agent-context demo --os ubi9 --skip-e2e` |

상세 Docker 실행 방법은 [demo/README.md](../demo/README.md#docker-환경-docker) 참고.

### 공통 옵션 일관성 테스트

- **목적**: `--debug`, `--quiet`, `--verbose`가 모든 명령에서 일관되게 동작하는지 확인

| # | 시나리오 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| 5-8 | debug 모드 | `agent-context doctor --debug` | 디버그 출력 추가 |
| 5-9 | quiet 모드 | `agent-context tests smoke --quiet` | Summary만 출력 |
| 5-10 | verbose 모드 | `agent-context doctor --verbose` | 상세 출력 |

**확인 방법:**

```bash
# quiet 모드: Summary만 출력
output=$(agent-context tests smoke --quiet 2>&1)
lines=$(echo "$output" | wc -l)
test "$lines" -le 3 && echo "[V] quiet mode concise" || echo "[!] quiet mode verbose ($lines lines)"

# verbose 모드: 기본보다 출력 많음
normal=$(agent-context doctor 2>&1 | wc -l)
verbose=$(agent-context doctor --verbose 2>&1 | wc -l)
test "$verbose" -ge "$normal" && echo "[V] verbose >= normal" || echo "[X] verbose < normal"
```

### 에러 복구 시나리오

- **목적**: 비정상 입력이나 상황에서의 에러 처리 확인

| # | 시나리오 | 명령어 | 기대 결과 |
|---|----------|--------|-----------|
| 5-11 | 알 수 없는 명령 | `agent-context foobar` | 에러 메시지 + 도움말 안내, exit 2 |
| 5-12 | 잘못된 옵션 | `agent-context doctor --invalid` | 에러 메시지, exit 2 |
| 5-13 | 권한 부족 | `chmod 000 ~/.secrets && agent-context doctor auth` | `[X]` 출력, exit 1 |
| 5-14 | rollback 없이 | `agent-context upgrade --rollback` (백업 없을 때) | 에러 메시지, exit 1 |

**확인 방법:**

```bash
# 알 수 없는 명령
agent-context foobar 2>/dev/null
test $? -eq 2 && echo "[V] unknown command: exit 2" || echo "[X] unknown command: unexpected exit code"

# 잘못된 옵션
agent-context doctor --invalid 2>/dev/null
test $? -eq 2 && echo "[V] invalid option: exit 2" || echo "[X] invalid option: unexpected exit code"
```

---

## 관련 문서

- [README.md](../README.md) -- 빠른 시작
- [USER_GUIDE.md](USER_GUIDE.md) -- CLI 레퍼런스 및 설정 가이드
- [demo/README.md](../demo/README.md) -- 데모/E2E 시나리오 (쓰기 작업 포함)
- [CONTRIBUTING.md](CONTRIBUTING.md) -- 개발자 워크플로
