# Plan: Agent Workflow System v2.0

**Based on**: [agent-workflow-system-plan.md](agent-workflow-system-plan.md)  
**Version**: 2.0  
**Date**: 2026-01-24  
**Status**: Draft

---

## What's New in v2.0

### Core Paradigm Shift

**"명확한 자율성(Clear Autonomy)"**
> 에이전트가 자율적으로 작동하되, 그 의도와 경계를 명확히 표현하여 사용자가 신뢰하고 제어할 수 있는 시스템

### Key Enhancements

1. **State Visibility Layer** (SDD 영감)
   - State Assertion: 에이전트 의도 명시
   - Mode Boundaries: 작업 범위 명시
   - Cursor Mode Integration: IDE 최적화

2. **Feedback Loops Layer** (vi2 영감)
   - Knowledge Caching: llm_context.md
   - Question-Driven Planning: questions.md + debrief
   - Self-Correction Protocol: 오류 조기 감지

3. **Flexible Execution Layer** (기존 유지)
   - Skill Composition
   - Warnings + --force
   - Git + Issue as Truth

### Reference Projects

- [spec-kit-command-cursor (SDD v3.0)](https://github.com/madebyaris/spec-kit-command-cursor)
- [vibe-coding-v2 (vi2)](https://github.com/paslavsky/vibe-coding-v2)
- [Ralph Project](https://github.com/snarktank/ralph) (Phase 3 참고)

---

## Design

[design/workflow-expansion-brainstorming.md](../design/workflow-expansion-brainstorming.md)

---

## Requirements Checklist

이 Plan을 작성하기 전에 반드시 아래 요구사항이 명확해야 합니다.

### Core Requirements (v1.0)

- [x] CLI 구조 정의 (`agent <role> <action> <parameters>`, role 생략 가능)
- [x] Role 정의 (Developer, Manager)
- [x] Atomic Skills 구조 (analyze, plan, execute, validate, integrate)
- [x] Skill 네이밍 규칙 (동사-명사, kebab-case)
- [x] Workflow = Skill의 조합

### v2.0 New Requirements

#### State Visibility Requirements

- [ ] **State Assertion**: 모든 Skill 실행 시 에이전트 의도 출력
  - Mode (planning|implementation|verification|research)
  - Purpose (구체적 목적)
  - Boundaries (Will/Will NOT)
  
- [ ] **Cursor Mode Integration**: Workflow/Skill에 최적 Cursor Mode 매핑
  - Plan: 명세 작성, 코드 변경 없음
  - Ask: 읽기 전용 탐색
  - Agent: 다중 파일 변경
  - Debug: 런타임 증거 수집

- [ ] **Mode Boundaries**: 각 Mode별 권장/비권장 행동 정의 (경고만, 강제 아님)
  - planning: 분석/설계/문서화 권장 (코드 변경 시 경고)
  - implementation: 코드 작성/테스트 권장 (요구사항 변경 시 경고)
  - verification: 테스트/리뷰 권장 (새 기능 추가 시 경고)
  - research: 탐색/읽기 권장 (파일 수정 시 경고)
  - **User Autonomy**: 모든 경고는 무시 가능, --force로 우회 가능

#### Feedback Loop Requirements

- [ ] **Knowledge Caching**: LLM 효율성 향상
  - llm_context.md: 기술 결정, 외부 참조, 아키텍처 맥락
  - 평균 20% 토큰 절감 목표
  - 임시 파일 (.gitignore), MR 후 삭제

- [ ] **Question-Driven Planning**: 요구사항 명확화
  - questions.md: 계획 단계에서 질문 생성
  - agent dev debrief: 답변 처리 및 설계 갱신
  - 요구사항 오해율 15% → 5% 목표

- [ ] **Self-Correction Protocol**: 오류 조기 감지 및 제안
  - DETECT → WARN → SUGGEST → (User decides)
  - Mode 위반 감지 시 경고 표시 (planning 중 코드 변경 등)
  - **제안만, 자동 수정 없음** (User Autonomy 유지)
  - 사용자가 무시하면 그대로 진행

- [ ] **AI-Optimized Summary**: MR 리뷰 효율화
  - quick-summary.md: 3-5 bullet points
  - MR 리뷰 시간 30% 단축 목표
  - Context Window 최적화

#### Context Management Requirements (v2.0 확장)

기존 `.context/{task-id}/` 디렉터리에 추가:

```
.context/TASK-123/
├── summary.yaml              # (v1.0) 작업 메타데이터
├── mode.txt                  # (v2.0) 현재 모드 추적
├── llm_context.md            # (v2.0) Knowledge cache
├── questions.md              # (v2.0) 질문-답변 로그
├── quick-summary.md          # (v2.0) AI-optimized 요약
├── logs/
│   ├── check.log            # (v1.0) lint/test 결과
│   └── build.log            # (v1.0) 빌드 로그
├── verification.md           # (v1.0) 검증 리포트
└── retrospective.md          # (v1.0) 회고
```

#### Skill Template Requirements (v2.0)

모든 Skill은 다음 메타데이터 필수 포함:

```yaml
---
name: skill-name
category: analyze|plan|execute|validate|integrate
mode: planning|implementation|verification|research
cursor_mode: plan|ask|agent|debug
agent_role: |
  You are a [role] agent.
  You WILL: [Specific actions]
  You will NOT: [Forbidden actions]
---
```

### Workflow Requirements (v1.0 유지)

- [x] Developer workflows: feature, bug-fix, hotfix, refactor
- [x] Manager workflows: initiative, epic, task-assignment, monitoring, approval
- [x] Human vs Agent 수행 구분
- [x] 동적 workflow 적용 규칙 (skip, retry, human intervention)

### Git Strategy & Context Requirements (v1.0 유지)

- [x] Hybrid Mode 지원 (Interactive vs Detached)
- [x] Interactive Mode: Branch 방식
- [x] Detached Mode: Worktree 방식
- [x] Try 메커니즘 (경량화)
- [x] Attempt 기록 구조

### Integration Requirements (v1.0 유지)

- [x] MR 생성 시 로그를 Issue에 업로드
- [x] 업로드 후 로컬 context/worktree 삭제
- [x] JIRA/GitLab 연동 (pm CLI)
- [x] Issue N/A 정책: MR description에 로그 포함

### Setup Requirements (v1.0 유지)

- [x] Bootstrap (시스템 레벨)
- [x] Setup (프로젝트 레벨)
- [x] Config template 제공
- [x] OS별 패키지 설치 지원
- [x] Secrets 설정 강제화 (--skip-secrets 우회 가능)

### Deployment Model Requirements (v1.0 유지)

- [x] 전역 설치: `~/.agent`
- [x] 로컬 설치: `project/.agent`
- [x] 경로 해석 우선순위
- [x] Docker 기반 테스트

### Quality Requirements (v1.0 유지)

- [x] Context window 제약 고려
- [x] 유지보수 용이성 (단순한 구조)
- [x] 문서 언어 정책: 본 템플릿 repo의 `.md` 문서는 한국어 허용

### v2.0 Quality Gates

- [ ] **Complexity Budget 준수**:
  - Skill: 200 lines
  - Workflow: 100 lines
  - CLI command: 100 lines
  - Helper library: 300 lines

- [ ] **why.md 철학 준수**:
  - Simplicity Over Completeness
  - User Autonomy (warnings + --force)
  - Feedback Over Enforcement
  - Composability
  - Artifacts as State

- [ ] **Manual Fallback 유지**:
  - 모든 Agent 기능은 Manual 대안 제공
  - Hybrid 접근 권장 (Manual + Agent)

### Mode-specific Cleanup Policy (v1.0 유지 + v2.0 확장)

- [x] Interactive Mode: `.context/{task-id}/` 정리
- [x] Detached Mode: worktree 전체 삭제
- [ ] **v2.0 추가**: llm_context.md, questions.md, quick-summary.md는 MR description에 포함 후 삭제

---

## Overview

| Item | Value |
|------|-------|
| Purpose | 협업 환경에서 Developer/Manager가 사용할 Workflow 시스템 및 CLI v2.0 |
| Scope | Skills, Workflows, CLI, Context Management, Issue Integration, **State Visibility, Feedback Loops** |
| Version | 2.0 (Clear Autonomy) |
| Based on | v1.0 + SDD v3.0 + vi2 framework |
| Issue | N/A (Enhancement) |

---

## Design Principles

### v1.0 Principles (유지)

1. **Simplicity Over Completeness**
   - Simple solutions that work > Complex solutions
   - 100 lines that everyone understands > 1000 lines that only author understands
   - Progressive enhancement > Big bang implementation

2. **User Autonomy**
   - Users and agents have freedom to make decisions
   - Hard blocking reserved for critical cases
   - Override options (`--force`) exist for edge cases

3. **Feedback Over Enforcement**
   - Clear feedback teaches better than hard blocks
   - Show what's recommended, don't mandate it

4. **Composability**
   - Small, focused skills > Large, monolithic workflows
   - Skills independently usable
   - Workflows = Skill composition

5. **State Through Artifacts**
   - Git is the source of truth
   - Files (YAML, Markdown) > Complex state machines
   - Human-readable > Machine-optimized

### v2.0 Enhancements

6. **State Visibility**
   - 에이전트 의도를 명시적으로 표현
   - Mode와 Boundaries를 시각화
   - 사용자 신뢰도 향상

7. **Feedback Loops**
   - LLM 효율성 극대화 (Knowledge Caching)
   - 요구사항 명확화 (Question-Driven Planning)
   - 오류 조기 감지 (Self-Correction)

8. **Clear Autonomy**
   - 자율성 유지 + 의도 명확화
   - Warnings over Blocking (여전히)
   - State Assertion은 "가시성 도구"로만 사용

---

## Architecture

### v1.0 Architecture (유지)

```
agent (CLI)
├── dev (Developer commands)
│   ├── start, status, list
│   ├── check, verify, retro
│   ├── sync, submit, cleanup
│   └── try (A/B testing)
├── mgr (Manager commands)
│   ├── pending, review, approve
│   └── monitor, assign
└── init, setup, config
```

### v2.0 Triple-Layer Architecture (추가)

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: State Visibility                                   │
│ - State Assertion (에이전트 의도 명시)                       │
│ - Mode Boundaries (작업 범위 명시)                           │
│ - Cursor Mode Integration (IDE 최적화)                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 2: Feedback Loops                                     │
│ - Knowledge Caching (llm_context.md)                        │
│ - Question-Driven Planning (questions.md)                   │
│ - Self-Correction Protocol (오류 조기 감지)                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 3: Flexible Execution (v1.0 유지)                      │
│ - Skill Composition (재사용성)                               │
│ - Warnings + --force (자율성)                                │
│ - Git + Issue as Truth (단순성)                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Implementation Plan

### Phase 1: 핵심 패턴 도입 (Week 1-2)

**목표**: State Visibility Layer 구현

#### Task 1.1: State Assertion 패턴

**파일 변경**:
- `skills/_template/SKILL.md`: 메타데이터 추가 (mode, cursor_mode, agent_role)
- `tools/agent/lib/executor.sh`: State Assertion 출력 함수
- `.cursorrules`: Agent State Assertion 규칙 추가

**성공 기준**:
- 모든 Skill에 State Assertion 출력
- Mode, Purpose, Boundaries 명확히 표시

**예상 소요**: 3-4일

#### Task 1.2: Self-Correction Protocol

**파일 변경**:
- `skills/validate/check-intent/SKILL.md`: Self-Correction 프로토콜 정의
- `tools/agent/lib/checks.sh`: detect_mode_violation, self_correct 함수
- `tools/agent/bin/agent`: cmd_dev_check에 통합

**성공 기준**:
- Mode 위반 자동 감지
- DETECT → STOP → CORRECT → RESUME 흐름 동작
- 월 5회 이상 Self-Correction 발동 (목표)

**예상 소요**: 3-4일

#### Task 1.3: Cursor Mode Integration

**파일 변경**:
- 모든 `workflows/**/*.md`: cursor_mode 필드 추가
- 모든 `skills/**/SKILL.md`: cursor_mode 필드 추가
- `docs/cursor-modes-guide.md`: 가이드 문서 생성

**성공 기준**:
- 100% Workflow/Skill에 cursor_mode 매핑
- cursor-modes-guide.md 완성

**예상 소요**: 2-3일

**Phase 1 Milestone (M1)**:
- State Assertion 활용률: 80% 이상
- Self-Correction 발동: 월 5회 이상
- Cursor Mode 가이드 완성

---

### Phase 2: Context 관리 개선 (Week 3-5)

**목표**: Feedback Loops Layer 구현

#### Task 2.1: Knowledge Caching

**파일 추가**:
- `tools/agent/resources/llm_context.md`: 템플릿
- `tools/agent/lib/context.sh`: create_llm_context, add_technical_decision 함수

**파일 변경**:
- `tools/agent/bin/agent`: cmd_dev_start, cmd_dev_design, cmd_dev_check 통합

**성공 기준**:
- llm_context.md 자동 생성
- 기술 결정 자동 기록
- 평균 20% 토큰 절감

**예상 소요**: 4-5일

#### Task 2.2: Question-Driven Planning

**파일 추가**:
- `tools/agent/resources/questions.md`: 템플릿
- `tools/agent/lib/context.sh`: create_questions, process_questions 함수

**파일 변경**:
- `tools/agent/bin/agent`: cmd_dev_debrief 명령 추가
- `skills/analyze/parse-requirement/SKILL.md`: questions.md 생성 로직

**성공 기준**:
- questions.md 자동 생성
- agent dev debrief 동작
- 요구사항 오해율 15% → 5%

**예상 소요**: 4-5일

#### Task 2.3: AI-Optimized Summary

**파일 추가**:
- `tools/agent/lib/markdown.sh`: generate_quick_summary 함수

**파일 변경**:
- `tools/agent/bin/agent`: cmd_dev_verify, cmd_dev_submit 통합

**성공 기준**:
- quick-summary.md 자동 생성
- MR description에 포함
- MR 리뷰 시간 30% 단축

**예상 소요**: 3-4일

**Phase 2 Milestone (M2)**:
- 토큰 절감: 평균 20%
- 리뷰 시간 단축: 평균 30%
- 요구사항 오해율: 5% 이하

---

### Phase 3: 선택적 기능 추가 (Week 6-12, 조건부)

> **Note**: Phase 3 상세 내용은 [future-work.md](future-work.md)로 이동되었습니다.
> Phase 2 완료 후 일괄 리뷰 예정입니다.

**목표**: Advanced Features (사용자 피드백 후 결정)

#### Task 3.1: Automated Execution

**철학 검증**:
- ⚠️ User Autonomy 충돌 가능
- 완화: 기본값 비활성화, --auto-submit 플래그

**파일 변경**:
- `tools/agent/bin/agent`: auto_execute_workflow 함수

**Go/No-Go 기준**:
- Phase 2 성공 지표 달성
- 사용자 만족도 4.0/5.0 이상

**예상 소요**: 5-7일

#### Task 3.2: Fresh Context Loop

**철학 검증**:
- ⚠️ Simplicity 충돌 (복잡도 증가)
- 완화: Detached Mode 전용, 옵트인

**파일 변경**:
- `tools/agent/lib/git-strategy.sh`: loop 로직 추가

**Go/No-Go 기준**:
- Complexity Budget 여유 확인
- Detached Mode 사용률 확인

**예상 소요**: 5-7일

**Phase 3 Milestone (M3, 조건부)**:
- --auto-submit 사용률: 20% 이상
- 사용자 만족도: 4.0/5.0 이상
- Complexity Budget 준수

---

## Skills

### v1.0 Skills (유지)

#### analyze/ (분석)
- parse-requirement: 요구사항 분석
- inspect-codebase: 코드베이스 탐색
- inspect-logs: 로그 분석
- assess-status: 현황 평가
- evaluate-priority: 우선순위 평가

#### plan/ (계획)
- design-solution: 솔루션 설계
- breakdown-work: 작업 분해
- estimate-effort: 노력 추정
- allocate-resources: 리소스 할당
- schedule-timeline: 일정 수립

#### execute/ (실행)
- write-code: 코드 작성
- refactor-code: 리팩토링
- fix-defect: 버그 수정
- update-documentation: 문서 업데이트
- manage-issues: 이슈 관리

#### validate/ (검증)
- run-tests: 테스트 실행
- check-style: 스타일 검사
- review-code: 코드 리뷰
- verify-requirements: 요구사항 검증
- analyze-impact: 영향도 분석
- **check-intent** (v2.0): 의도 검증 (Self-Correction)

#### integrate/ (통합)
- commit-changes: 변경사항 커밋
- create-merge-request: MR 생성
- merge-changes: 변경사항 병합
- notify-stakeholders: 이해관계자 알림
- publish-report: 리포트 발행

### v2.0 Skill Template Updates

모든 Skill은 다음 섹션 추가:

```markdown
## State Assertion (Agent Requirement)

**Before starting this skill, output:**

```
AGENT MODE: [skill-name]
Mode: [planning|implementation|verification|research]
Purpose: [Specific purpose]
Implementation: [AUTHORIZED|BLOCKED]
Boundaries: Will [actions], Will NOT [forbidden]
```

## Cursor Mode

**Recommended**: [plan|ask|agent|debug]

## Self-Correction Triggers

- [Specific mode violations to detect]
- [Workflow violations to detect]
```

---

## Workflows

### v1.0 Workflows (유지)

#### Developer Workflows
- **feature**: Full feature development
- **bug-fix**: Standard bug fix
- **hotfix**: Emergency fix
- **refactor**: Code refactoring

#### Manager Workflows
- **initiative**: Strategic initiative
- **epic**: Large feature set
- **task-assignment**: Task delegation
- **monitoring**: Status tracking
- **approval**: MR approval

### v2.0 Workflow Updates

모든 Workflow에 다음 필드 추가:

```yaml
---
name: workflow-name
cursor_mode: plan|ask|agent|debug  # Overall workflow mode
skills:
  - skill-1  # cursor_mode: ask
  - skill-2  # cursor_mode: plan
  - skill-3  # cursor_mode: agent
---
```

**Cursor Mode 매핑 예시**:

| Workflow | Primary Mode | Phase-specific Modes |
|----------|--------------|----------------------|
| feature | Agent | Ask (analyze) → Plan (design) → Agent (code) → Debug (test) |
| bug-fix | Debug | Ask (logs) → Agent (fix) → Debug (verify) |
| hotfix | Agent | Agent (fast) → Debug (critical tests) |
| refactor | Agent | Plan (plan) → Agent (refactor) → Debug (regression) |

---

## Context Management

### v1.0 Context Structure (유지)

```
.context/TASK-123/
├── summary.yaml
├── logs/
│   ├── check.log
│   └── build.log
├── verification.md
└── retrospective.md
```

### v2.0 Context Expansion

```
.context/TASK-123/
├── summary.yaml              # (v1.0) 작업 메타데이터
├── mode.txt                  # (v2.0) 현재 모드 추적
├── llm_context.md            # (v2.0) Knowledge cache
├── questions.md              # (v2.0) 질문-답변 로그
├── quick-summary.md          # (v2.0) AI-optimized 요약
├── logs/
│   ├── check.log            # (v1.0)
│   └── build.log            # (v1.0)
├── verification.md           # (v1.0)
└── retrospective.md          # (v1.0)
```

### Context Lifecycle (v2.0)

1. **Creation** (agent dev start):
   - summary.yaml
   - mode.txt (초기값: planning)
   - llm_context.md (템플릿)
   - questions.md (템플릿)

2. **Update** (작업 중):
   - mode.txt: 각 단계에서 갱신
   - llm_context.md: 기술 결정 추가
   - questions.md: 질문-답변 추가

3. **Finalize** (agent dev verify):
   - quick-summary.md 생성

4. **Cleanup** (agent dev submit):
   - MR description에 quick-summary.md 포함
   - llm_context.md, questions.md는 MR description에 첨부 또는 삭제
   - .context/{task-id}/ 전체 archive 또는 삭제

---

## CLI Commands

### v1.0 Commands (유지)

```bash
# Developer commands
agent dev start <task-id> [--detached] [--try=name]
agent dev status
agent dev list
agent dev check
agent dev verify
agent dev retro
agent dev sync [--continue|--abort]
agent dev submit [--sync]
agent dev cleanup <task-id>

# Manager commands
agent mgr pending
agent mgr review <mr-id>
agent mgr approve <mr-id>
agent mgr monitor
agent mgr assign <task-id> <assignee>

# Setup commands
agent init
agent setup
agent config
```

### v2.0 New Commands

```bash
# Question-Driven Planning
agent dev debrief
# → Process questions.md and update design documents

# Mode management (internal)
# Automatically tracked in .context/{task-id}/mode.txt
```

### v2.0 Command Flow Enhancement

**Feature Development with v2.0**:

```bash
# 1. Start (creates llm_context.md, questions.md)
agent dev start TASK-123

# 2. Analyze (generates questions)
agent dev analyze
# → questions.md populated with clarification questions

# 3. User answers questions
vim .context/TASK-123/questions.md

# 4. Debrief (processes answers)
agent dev debrief
# → design/*.md updated
# → llm_context.md updated with decisions

# 5. Design (reads llm_context.md)
agent dev design
# → No duplicate questions, uses cached knowledge

# 6. Code (reads llm_context.md)
agent dev code
# → Implements based on recorded decisions

# 7. Check (Self-Correction enabled)
agent dev check
# → Detects mode violations
# → DETECT → STOP → CORRECT → RESUME

# 8. Verify (generates quick-summary.md)
agent dev verify

# 9. Submit (includes quick-summary in MR)
agent dev submit
```

---

## Success Metrics

### Phase 1 Metrics (Week 2)

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| State Assertion 활용률 | 0% | 80% | Skill 실행 시 출력 확인 |
| Self-Correction 발동 | 0회/월 | 5회/월 | 로그 분석 |
| 에이전트 의도 명확성 | 3.0/5.0 | 4.7/5.0 | 사용자 설문 |

### Phase 2 Metrics (Week 5)

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| Context Window 토큰 절감 | 기준선 | -20% | 로그 분석 |
| MR 리뷰 시간 | 기준선 | -30% | GitLab/JIRA 메트릭 |
| 요구사항 오해율 | 15% | 5% | 재작업 발생 비율 |

### Phase 3 Metrics (Week 12, 조건부)

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| --auto-submit 사용률 | 0% | 20% | 로그 분석 |
| 사용자 만족도 | 3.5/5.0 | 4.0/5.0 | 설문 조사 |

---

## Risk Management

### Phase 1 Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Complexity 증가 | 중간 | 중간 | Progressive rollout, 기본값 유지 |
| 사용자 혼란 | 중간 | 낮음 | 문서화, 점진적 도입 |

### Phase 2 Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Context 관리 오버헤드 | 낮음 | 낮음 | 자동화, 선택적 기능 |
| LLM 호환성 문제 | 낮음 | 중간 | 다양한 LLM 테스트 |

### Phase 3 Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Autonomy 충돌 | 낮음 | 높음 | 기본값 비활성화, 사용자 피드백 |
| Complexity Budget 초과 | 중간 | 중간 | 엄격한 코드 리뷰, 리팩토링 |

---

## Testing Strategy

### Unit Tests (v1.0 유지)

- `tests/smoke/`: 기본 CLI 동작
- `tests/local-git/`: Git 연동
- `tests/e2e/`: End-to-end 시나리오

### v2.0 Test Additions

#### State Assertion Tests

```bash
# Test: State Assertion 출력 확인
test_state_assertion_output() {
    output=$(agent dev code)
    assert_contains "$output" "AGENT MODE:"
    assert_contains "$output" "Mode:"
    assert_contains "$output" "Cursor Mode:"
}
```

#### Self-Correction Tests

```bash
# Test: Mode 위반 감지
test_mode_violation_detection() {
    echo "mode: planning" > .context/TASK-123/mode.txt
    touch test.c
    git add test.c
    
    output=$(agent dev check)
    assert_contains "$output" "VIOLATION: Code changes detected in planning mode"
    assert_contains "$output" "SELF-CORRECTION TRIGGERED"
}
```

#### Context Management Tests

```bash
# Test: llm_context.md 생성
test_llm_context_creation() {
    agent dev start TASK-123
    assert_file_exists .context/TASK-123/llm_context.md
}

# Test: questions.md 생성
test_questions_creation() {
    agent dev analyze
    assert_file_exists .context/TASK-123/questions.md
}

# Test: quick-summary.md 생성
test_quick_summary_creation() {
    agent dev verify
    assert_file_exists .context/TASK-123/quick-summary.md
}
```

---

## Documentation Updates

### New Documentation (v2.0)

1. **docs/cursor-modes-guide.md**
   - Cursor Mode 통합 가이드
   - Workflow/Skill 매핑
   - 베스트 프랙티스

2. **docs/state-assertion-guide.md**
   - State Assertion 개념
   - Mode Boundaries 정의
   - 사용 예시

3. **docs/knowledge-caching-guide.md**
   - llm_context.md 사용법
   - 기술 결정 기록 방법
   - 토큰 절감 팁

4. **docs/question-driven-planning-guide.md**
   - questions.md 사용법
   - agent dev debrief 워크플로우
   - 요구사항 명확화 베스트 프랙티스

### Updated Documentation (v2.0)

1. **README.md**
   - v2.0 주요 변경사항
   - "명확한 자율성" 패러다임 소개

2. **skills/_template/SKILL.md**
   - State Assertion 섹션 추가
   - Cursor Mode 섹션 추가
   - Self-Correction Triggers 섹션 추가

3. **docs/manual-fallback-guide.md**
   - v2.0 기능의 Manual 대안 추가
   - llm_context.md 수동 작성 방법
   - questions.md 수동 작성 방법

---

## Timeline

```
Week 1-2: Phase 1
├── Task 1.1: State Assertion (3-4일)
├── Task 1.2: Self-Correction (3-4일)
└── Task 1.3: Cursor Mode (2-3일)
Milestone M1: State Visibility Layer Complete

Week 3-5: Phase 2
├── Task 2.1: Knowledge Caching (4-5일)
├── Task 2.2: Question Planning (4-5일)
└── Task 2.3: Quick Summary (3-4일)
Milestone M2: Feedback Loops Layer Complete

Week 6: User Validation
└── 피드백 수집, Phase 3 Go/No-Go 결정
Milestone M3: User Validation Complete

Week 7-12: Phase 3 (조건부)
├── Task 3.1: Auto-Submit (5-7일)
├── Task 3.2: Fresh Context Loop (5-7일)
└── Buffer: 테스트 및 조정
Milestone M4: Full Rollout (조건부)
```

---

## Rollout Strategy

### Progressive Rollout

1. **Week 1-2**: 새 프로젝트에 Phase 1 적용
2. **Week 3-5**: Phase 2 기능 추가
3. **Week 6**: 사용자 피드백 수집
4. **Week 7+**: 기존 프로젝트 확산 (Phase 3 Go 시)

### Backward Compatibility

- v1.0 기능 완전 유지
- v2.0 기능은 추가 (비파괴적)
- Manual Fallback 항상 가능
- 기존 스크립트 호환성 보장

---

## Philosophy Compliance

### why.md 5대 원칙 준수 검증

| 원칙 | v2.0 준수 방법 | 위반 리스크 | 완화 방안 |
|------|--------------|------------|----------|
| **Simplicity** | Progressive rollout | Phase 2-3 복잡도 | Complexity Budget, 옵트인 |
| **Autonomy** | State Assertion = 가시성만 | Self-Correction 강제 | 제안만, --force 유지 |
| **Feedback** | DETECT→STOP→CORRECT→RESUME | 없음 | - |
| **Composability** | Skill 구조 유지 | 없음 | - |
| **Artifacts** | llm_context.md 임시 파일 | .context/ 증가 | MR 후 삭제 |

**결론**: ✅ v2.0은 why.md 철학과 완전 양립

---

## Test Plan

### Test Strategy

**Scope:**
- Phase 1: State Visibility Layer (State Assertion, Self-Correction, Cursor Mode)
- Phase 2: Feedback Loops Layer (Knowledge Caching, Question Planning, Quick Summary)

**Levels:**
| Level | Description | Tools |
|-------|-------------|-------|
| Unit | Function-level tests | bash assertions |
| Integration | Workflow tests | Docker + test scripts |
| E2E | Full scenario | Manual + automated |

### Test Cases

#### Unit Tests

| ID | Component | Test Case | Expected |
|----|-----------|-----------|----------|
| UT-1 | executor.sh | State Assertion output | Displays AGENT MODE block |
| UT-2 | checks.sh | detect_mode_violation() | Catches planning mode violations |
| UT-3 | context.sh | create_llm_context() | Creates llm_context.md |
| UT-4 | context.sh | add_technical_decision() | Appends decision to llm_context.md |
| UT-5 | context.sh | create_questions() | Creates questions.md |
| UT-6 | markdown.sh | generate_quick_summary() | Creates quick-summary.md |

#### Integration Tests

| ID | Scenario | Steps | Expected |
|----|----------|-------|----------|
| IT-1 | Feature workflow | start → analyze → design → code → verify → submit | All files created, MR submitted |
| IT-2 | Self-Correction | Change code in planning mode | VIOLATION detected |
| IT-3 | Debrief cycle | questions.md → debrief → design update | Design updated |

### Success Criteria

**Must Have:**
- [ ] State Assertion works on all skills
- [ ] Self-Correction detects violations
- [ ] llm_context.md reduces repeated questions
- [ ] quick-summary.md included in MR

**Should Have:**
- [ ] Token reduction >= 20%
- [ ] Review time reduction >= 30%
- [ ] Requirement misunderstanding <= 5%

### Validation Checklist

- [ ] Unit tests pass (bash assertions)
- [ ] Integration tests pass (Docker)
- [ ] Metrics collected
- [ ] Philosophy compliance verified

---

## Related Documents

- [why.md](../why.md): 설계 철학
- [docs/proposal-v2.md](../docs/proposal-v2.md): v2.0 제안서
- [docs/manual-fallback-guide.md](../docs/manual-fallback-guide.md): Manual Fallback
- [skills/](../skills/): Atomic Skills
- [workflows/](../workflows/): Workflows

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-XX | Initial implementation |
| 2.0 | 2026-01-24 | Clear Autonomy paradigm, State Visibility, Feedback Loops |

---

**Plan Owner**: Agent Context Team  
**Status**: Draft (v2.0)  
**Next Review**: Week 2 (M1 Milestone)

---

**End of Plan v2.0**
