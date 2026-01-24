# Handoff: Agent-Context 개선 작업

## 최근 완료 (2026-01-25)

### feat/pm-jira-assign-bulk → main Merge

**11개 커밋 Merge 완료**:
- `a8dac79` feat(pm): add Jira assignee allocation and bulk create
- `23abe60` fix(pm): use Atlassian Document Format for Jira Cloud API v3
- `77ff502` feat(pm): add issue update, sprint, workflow, and confluence space features
- `a7066e9` feat(pm): add Jira issue link (dependency) management
- `10273d7` fix(pm): use curl -u for Jira Cloud auth instead of base64
- `de80063` feat(pm): add Epic link support in bulk-create CSV
- `6d4e0f4` docs(scenario): add role-based Jira workflow scenarios
- `7a01bec` refactor(scenario): rename files with role prefix convention
- `97ffb9b` feat(manager): add Jira issue linking best practices for project oversight
- `835f5e6` feat(lint): add hybrid mode with external tool integration
- `eec5aa3` docs: add references directory for external resources

**주요 기능 추가**:
- PM CLI: Jira Assignee 할당, Bulk Create, Issue Link, Sprint 관리
- Confluence 연동
- Lint Hybrid Mode (외부 도구 통합)
- 시나리오 006-010 추가 (Manager/Developer 워크플로우)

---

## 다음 작업 (우선순위 순)

### 1. RFC 005: Manual Fallback 개선 - P1 (CLI 코드 변경)

**참조**: `docs/rfcs/005-manual-fallback-improvement.md`

#### Task 1-1: agent dev submit 옵션 확장

**파일**: `tools/agent/lib/dev.sh` (~100 LOC)

```bash
# 새 옵션
--only=<step>[,<step>,...]  # 지정 단계만 실행
--skip=<step>[,<step>,...]  # 지정 단계 건너뛰기

# 허용 값: sync, push, pr, jira
# 실행 순서: sync → push → pr → jira
```

**예시**:
```bash
agent dev submit --only=sync      # rebase만
agent dev submit --only=push,pr   # push + MR 생성
agent dev submit --skip=jira      # Jira 제외
```

#### Task 1-2: Pre-commit Hook 관리

**파일**: 
- `tools/agent/lib/check.sh` (~50 LOC)
- `tools/agent/resources/pre-commit.hook.sh` (신규)

```bash
agent dev check --install-hook    # Hook 설치
agent dev check --uninstall-hook  # Hook 제거
agent dev check --status          # 상태 확인
```

#### Task 1-3: 짧은 Alias 추가 (선택)

**파일**: `tools/agent/lib/aliases.sh` (~20 LOC)

```bash
agent sync    # = agent dev sync
agent check   # = agent dev check
agent submit  # = agent dev submit
```

---

### 2. RFC 002/004: Agent Workflow System v2.0 - Phase 1

**참조**: 
- `docs/rfcs/002-proposal.md` (통합 제안서)
- `docs/rfcs/004-agent-workflow-system.md` (구현 계획)

**핵심 패러다임**: "명확한 자율성(Clear Autonomy)"

#### Task 1.1: State Assertion 패턴 (3-4일)

**목표**: 에이전트가 작업 전 역할, 모드, 경계를 명시

**파일**:
- `skills/_template/SKILL.md` - 메타데이터 추가 (mode, cursor_mode, agent_role)
- `tools/agent/lib/executor.sh` - State Assertion 출력 함수
- `.cursorrules` - Agent State Assertion 규칙 추가

**출력 형식**:
```
AGENT MODE: [skill-name]
Mode: [planning|implementation|verification|research]
Purpose: [Specific purpose]
Implementation: [AUTHORIZED|BLOCKED]
Boundaries: Will [actions], Will NOT [forbidden]
```

#### Task 1.2: Self-Correction Protocol (3-4일)

**목표**: 에이전트가 실수를 조기 감지하고 자동 수정

**파일**:
- `skills/validate/check-intent/SKILL.md` - Self-Correction 프로토콜 정의
- `tools/agent/lib/checks.sh` - detect_mode_violation, self_correct 함수

**흐름**: DETECT → STOP → CORRECT → RESUME

#### Task 1.3: Cursor Mode Integration (2-3일)

**목표**: Workflow/Skill에 최적 Cursor Mode 매핑

**파일**:
- 모든 `workflows/**/*.md` - cursor_mode 필드 추가
- 모든 `skills/**/SKILL.md` - cursor_mode 필드 추가
- `docs/cursor-modes-guide.md` - 가이드 문서 생성

**매핑**:
| Cursor Mode | 용도 | agent-context 매핑 |
|-------------|------|-------------------|
| Plan | 명세 작성, 코드 변경 없음 | agent dev design |
| Ask | 읽기 전용 탐색 | agent dev analyze |
| Agent | 다중 파일 변경 | agent dev code |
| Debug | 런타임 증거 수집 | agent dev check |

---

### 3. RFC 002/004: v2.0 - Phase 2 (Phase 1 완료 후)

#### Task 2.1: Knowledge Caching (4-5일)

**파일**: 
- `tools/agent/resources/llm_context.md` - 템플릿
- `tools/agent/lib/context.sh` - create_llm_context 함수

**목표**: 토큰 20% 절감, LLM amnesia 방지

#### Task 2.2: Question-Driven Planning (4-5일)

**파일**:
- `tools/agent/resources/questions.md` - 템플릿
- `tools/agent/bin/agent` - cmd_dev_debrief 명령 추가

**목표**: 요구사항 오해율 15% → 5%

#### Task 2.3: AI-Optimized Summary (3-4일)

**파일**: `tools/agent/lib/markdown.sh` - generate_quick_summary 함수

**목표**: MR 리뷰 시간 30% 단축

---

## 완료된 작업 기록

### 2026-01-24: P0 문서 정비

- ✅ `docs/manual-fallback-guide.md` 작성 (~500줄)
- ✅ 시나리오 템플릿 표준화 (6개 → 10개 파일)
- ✅ 워크플로우 구현 상태 표기 (9개 파일)
- ✅ 철학 점수 3.6 → 4.0 (코드 0 LOC로 달성)

### 2026-01-25: PM/Jira 기능 확장

- ✅ Task 1-4 (005 RFC): Jira Assignee 할당 + CSV 일괄 생성
- ✅ Jira Issue Link (dependency) 관리
- ✅ Sprint 관리, Confluence 연동
- ✅ Lint Hybrid Mode

---

## 권장 다음 세션 시작 시

```bash
# 1. 현재 상태 확인
git log --oneline -5
git status

# 2. P1 작업 시작 (권장: Task 1-1)
git checkout -b feat/agent-submit-options main

# 3. 작업 후
agent dev check
agent dev submit
```

---

## 참고 문서

**RFC 문서**:
- [002-proposal.md](../rfcs/002-proposal.md) - v2.0 통합 제안서
- [004-agent-workflow-system.md](../rfcs/004-agent-workflow-system.md) - v2.0 구현 계획
- [005-manual-fallback-improvement.md](../rfcs/005-manual-fallback-improvement.md) - Manual Fallback 개선

**가이드**:
- [Manual Fallback Guide](../guides/manual-fallback-guide.md)
- [CLI Reference](../cli/)

---

**작성일**: 2026-01-25  
**이전 작성자**: AI Agent (Claude Sonnet 4.5)  
**갱신 사유**: feat/pm-jira-assign-bulk 브랜치 main merge 완료
