# agent-context 프레임워크 개선 제안서

**제안일**: 2026-01-24  
**작성자**: Agent Context Team  
**문서 버전**: 1.0

---

## Part I: 경영진 제안서 (Executive Summary)

### 1. 제안 배경

#### 1.1 현황 분석

agent-context 프레임워크는 AI 에이전트 기반 협업 워크플로우 시스템으로, 현재 다음과 같은 구조를 갖추고 있습니다:

- **26개 Atomic Skills** (5개 카테고리: analyze, plan, execute, validate, integrate)
- **9개 Workflow** (Developer 4개, Manager 5개)
- **하이브리드 Git 전략** (Interactive/Detached Mode)
- **3단계 테스트 인프라** (smoke → local-git → e2e)

#### 1.2 문제 인식

Cursor AI 생태계의 선도 프로젝트들을 벤치마킹한 결과, 다음과 같은 개선 영역을 발견했습니다:

| 영역 | 현재 상태 | 개선 필요성 |
|------|-----------|-------------|
| **에이전트 명확성** | 암묵적 상태 관리 | 에이전트 의도 불명확, 사용자 혼란 가능 |
| **오류 조기 감지** | 사후 검증 중심 | Mode 위반, 실수를 늦게 발견 |
| **Context Window 관리** | Rolling Summary 미구현 | 반복 설명으로 토큰 낭비 |
| **요구사항 명확화** | parse-requirement만 존재 | 질문-답변 피드백 루프 부재 |

#### 1.3 벤치마킹 대상

| 프로젝트 | 핵심 강점 | 참고 가능성 |
|----------|-----------|-------------|
| **spec-kit-command-cursor (SDD v3.0)** | Agentic-First Architecture, State Assertion | ★★★★★ |
| **vibe-coding-v2 (vi2)** | LLM State Management, Knowledge Caching | ★★★★☆ |
| **cursor-commands** | 구조 참고용 | ★★☆☆☆ |

### 2. 제안 목적

#### 2.1 핵심 목표

세 가지 레퍼런스 프로젝트의 설계 철학과 구현 패턴을 분석하여, agent-context의 **사용자 경험**, **에이전트 신뢰성**, **개발 생산성**을 향상시킵니다.

#### 2.2 기대 성과

| 지표 | 현재 | 목표 | 개선율 |
|------|------|------|--------|
| **에이전트 의도 명확성** | 60% | 95% | +58% |
| **Mode 위반 조기 감지** | 사후 발견 | 실시간 감지 | - |
| **Context Window 토큰 절감** | 기준선 | -20% | 20% 절감 |
| **MR 리뷰 시간** | 기준선 | -30% | 30% 단축 |
| **요구사항 오해율** | 추정 15% | 5% | -67% |

### 3. 제안 방안

#### 3.1 개선 항목 (6개 핵심 패턴)

##### (1) State Assertion 패턴 도입 (SDD)

**개념**: 에이전트가 작업 전 자신의 역할, 모드, 경계를 명시적으로 선언합니다.

**예시**:
```
[에이전트 출력]
SDD MODE: execute/write-code
Mode: implementation
Purpose: Implement feature code with TDD
Implementation: AUTHORIZED
Boundaries: Will NOT modify requirements, Will NOT skip tests
```

**효과**:
- 사용자가 에이전트 의도를 즉시 이해
- Mode 위반 조기 감지 (예: 코드 작성 중 요구사항 변경 시도)
- 작업 범위 명확화

##### (2) Self-Correction Protocol (SDD)

**개념**: 에이전트가 실수를 스스로 감지하고 수정하는 명시적 프로토콜입니다.

**흐름**: DETECT (감지) → STOP (중단) → CORRECT (수정) → RESUME (재개)

**예시**:
```
[에이전트 감지]
DETECT: I attempted to write code during analyze mode
STOP: Halting code generation
CORRECT: "I apologize - I was writing code in analyze mode. 
          Returning to requirement analysis."
RESUME: Continuing with parse-requirement skill
```

**효과**:
- 실수 즉시 수정으로 재작업 감소
- Quality gate 효과성 향상
- 사용자 신뢰도 증가

##### (3) Knowledge Caching (vi2)

**개념**: LLM이 작업 중 내린 기술 결정과 외부 문서를 캐싱하여 재사용합니다.

**파일**: `.context/{task-id}/llm_context.md`

**내용**:
- 기술 결정 (Decision: Use JWT RS256, Rationale: Better security)
- 외부 참조 (JWT Best Practices 요약)
- 아키텍처 맥락 (컴포넌트 다이어그램)

**효과**:
- 동일한 설명 반복 불필요 → 토큰 절감
- LLM amnesia 방지
- 일관된 기술 결정 유지

##### (4) Question-Driven Planning (vi2)

**개념**: 계획 단계에서 질문 목록을 생성하고, 답변 후 설계 문서를 갱신합니다.

**파일**: `.context/{task-id}/questions.md`

**흐름**:
```
1. agent dev analyze → questions.md 생성
2. 사용자가 답변 추가
3. agent dev debrief → design 문서 자동 갱신
```

**효과**:
- 요구사항 오해 사전 방지
- 명확한 피드백 루프
- 설계 품질 향상

##### (5) AI-Optimized Summary (SDD)

**개념**: MR 제출 전 AI에 최적화된 간결한 요약을 생성합니다.

**파일**: `.context/{task-id}/quick-summary.md`

**내용**:
- 핵심 변경사항 (3-5 bullet points)
- 기술 결정 요약
- 테스트 결과 요약

**효과**:
- MR description 간결화
- 리뷰어 이해도 향상 → 리뷰 시간 단축
- Context Window 최적화

##### (6) Cursor Mode 매핑 (SDD)

**개념**: 각 Workflow와 Skill에 최적 Cursor IDE 모드를 매핑합니다.

| agent-context Command | Cursor Mode | 이유 |
|----------------------|-------------|------|
| agent dev analyze | Ask | 읽기 전용 탐색 |
| agent dev design | Plan | 명세 작성, 코드 변경 없음 |
| agent dev code | Agent | 다중 파일 변경 |
| agent dev check | Debug | 런타임 증거 수집 |

**효과**:
- Cursor IDE 기능 최적 활용
- 사용자 경험 향상
- 작업 효율 증가

#### 3.2 구현 우선순위

**Phase 1 (즉시 도입, 1-2주)**:
1. State Assertion 패턴
2. Self-Correction Protocol
3. Cursor Mode 매핑

**Phase 2 (단기 도입, 2-3주)**:
4. Knowledge Caching
5. Question-Driven Planning
6. AI-Optimized Summary

**Phase 3 (장기 검토, 선택적)**:
- Automated Execution (--auto-submit 플래그)
- Manual Change Sync 확장

#### 3.3 투자 대비 효과

| Phase | 투자 (인시) | 예상 효과 | ROI |
|-------|------------|-----------|-----|
| Phase 1 | 40-60h | 에이전트 명확성 +58%, 오류 조기 감지 | ★★★★★ |
| Phase 2 | 60-80h | 토큰 절감 20%, 리뷰 시간 30% 단축 | ★★★★☆ |
| Phase 3 | 80-120h | 생산성 향상 (선택적) | ★★★☆☆ |

### 4. 기대 효과

#### 4.1 정량적 효과

1. **토큰 비용 절감**: llm_context.md로 평균 20% 토큰 사용 감소
2. **리뷰 시간 단축**: quick-summary로 평균 30% 리뷰 시간 감소
3. **오류 감소**: Self-Correction으로 월 평균 5회 이상 Mode 위반 조기 감지
4. **요구사항 오해율 감소**: questions.md로 15% → 5%로 개선

#### 4.2 정성적 효과

1. **사용자 신뢰도 향상**: 에이전트 의도가 명확하여 안심하고 사용
2. **개발 품질 향상**: 명세 중심 개발로 일관성 유지
3. **협업 효율 증가**: MR 리뷰 품질 향상으로 팀 생산성 증가
4. **LLM 효율성 향상**: Context Window 최적 활용

#### 4.3 리스크 관리

| 리스크 | 확률 | 영향 | 완화 방안 |
|--------|------|------|-----------|
| 복잡도 증가 | 중간 | 중간 | Progressive rollout, 기본값 유지 |
| 철학 충돌 (Autonomy vs Gate) | 낮음 | 중간 | State Assertion은 "가시성" 도구로만 |
| Context 관리 오버헤드 | 낮음 | 낮음 | 자동화, 선택적 기능 |
| 사용자 혼란 | 중간 | 낮음 | 문서화, 점진적 도입 |

### 5. 결론 및 권고사항

#### 5.1 핵심 결론

1. **레퍼런스 프로젝트 분석 결과**, SDD의 Agentic-First Architecture와 vi2의 Knowledge Caching은 agent-context에 즉시 적용 가능한 검증된 패턴입니다.

2. **agent-context의 철학 (Simplicity, Autonomy, Composability)은 유지**하되, 에이전트 명확성과 Context 관리를 강화하여 **"명확한 자율성(Clear Autonomy)"** 패러다임으로 진화합니다.

3. **ROI가 가장 높은 Phase 1 (State Assertion, Self-Correction, Cursor Mode)**을 우선 도입하고, Phase 2를 단계적으로 진행합니다.

#### 5.2 권고사항

**즉시 실행 (Phase 1)**:
- ✅ State Assertion 패턴 도입
- ✅ Self-Correction Protocol 구현
- ✅ Cursor Mode 매핑 추가

**단기 실행 (Phase 2)**:
- ✅ Knowledge Caching 시스템 구축
- ✅ Question-Driven Planning 구현
- ✅ AI-Optimized Summary 생성

**장기 검토 (Phase 3)**:
- ⚠️ Automated Execution (선택적)
- ⚠️ Manual Change Sync (효과 검증 후)

#### 5.3 성공 지표

1. **State Assertion 활용률**: 80% 이상
2. **Self-Correction 발동**: 월 5회 이상
3. **토큰 절감**: 평균 20%
4. **리뷰 시간 단축**: 평균 30%
5. **사용자 만족도**: 4.0/5.0 이상

---

## Part II: 기술 제안서 (Technical Proposal)

### 1. 레퍼런스 프로젝트 심층 분석

#### 1.1 spec-kit-command-cursor (SDD v3.0)

**프로젝트 개요**:
- **목적**: Spec-Driven Development - "Stop coding blindly. Start building with purpose."
- **GitHub**: https://github.com/madebyaris/spec-kit-command-cursor
- **핵심 철학**: Agentic-First Architecture
- **Stars**: 129, **Forks**: 14

**핵심 설계 패턴**:

##### 1.1.1 Agentic-First Template Structure

모든 명령어 템플릿이 다음 구조를 따릅니다:

```markdown
# /command Command

[Brief description]

---

## IMPORTANT: This is [Mode] Mode

**You are a [role].** Your job is to [purpose].

**Your role:**
- [What you will do 1]
- [What you will do 2]

**Mode boundaries (What you will NOT do):**
- [Forbidden action 1]
- [Forbidden action 2]

**Recommended Cursor Mode:** [Mode]

---

## State Assertion (REQUIRED)

**Before starting, output:**

**SDD MODE: [Command]**
Mode: [planning|implementation|research|verification]
Purpose: [Specific purpose]
Implementation: [BLOCKED|AUTHORIZED]

---

## Self-Correction Protocol

**DETECT**: If you find yourself...
**STOP**: Immediately halt
**CORRECT**: "I apologize - I was [mistake]. Let me return to [correct mode]."
**RESUME**: Continue correctly

---

## Instructions
[Phase 1: Analysis → Phase 2: Planning → Phase 3: Execution → Phase 4: Verification]

---

## Output (REQUIRED)
[Exact format for completion message]
```

**적용 가능성**:
- ✅ **즉시 적용 가능**: agent-context의 Skill 템플릿과 구조적으로 호환
- ✅ **철학 일치**: "명확한 지시"는 agent-context의 Feedback Over Enforcement와 양립 가능
- ⚠️ **주의**: "Implementation: BLOCKED"는 User Autonomy와 충돌 가능 → "가시성" 도구로만 사용

##### 1.1.2 Cursor Mode Integration

| SDD Command | Cursor Mode | agent-context 매핑 |
|-------------|-------------|--------------------|
| /brief | Plan | agent dev design |
| /research | Ask | agent dev analyze |
| /specify | Plan | agent dev design (상세) |
| /plan | Plan | agent dev plan |
| /implement | Agent | agent dev code |
| /audit | Debug | agent dev check (확장) |

**구현 계획**:
1. Workflow YAML에 `cursor_mode` 필드 추가
2. Skill YAML에 `cursor_mode` 필드 추가
3. `docs/cursor-modes-guide.md` 생성

##### 1.1.3 --until-finish Flag (Automated Execution)

**개념**: 전체 프로젝트를 자동 실행하는 "fire and forget" 모드

```bash
/execute-task epic-001 --until-finish
# → Task 1 ✅ → Task 2 ✅ → Task 3 ❌ Error → STOP → Fix → Resume
```

**agent-context 적용 시 고려사항**:
- ⚠️ **철학 충돌**: User Autonomy와 상충
- ✅ **선택적 도입**: `--auto-submit` 플래그로 선택적 제공
- ✅ **기본값 유지**: 단계별 승인은 여전히 기본값

**구현 계획** (Phase 3, 선택적):
```bash
agent dev start TASK-123 --auto-submit
# → check → commit → verify → submit 자동 실행
# → 에러 발생 시 즉시 중단 및 알림
```

##### 1.1.4 Shared Agent Protocols

SDD는 `_shared/` 디렉터리에 공통 프로토콜을 저장합니다:

```
.cursor/commands/_shared/
├── agent-manual.md
├── self-correction.md
└── cursor-modes.md
```

**agent-context 적용**:
- `skills/_shared/`: 공통 프로토콜
- `skills/_shared/state-assertion.md`
- `skills/_shared/self-correction.md`
- `skills/_shared/cursor-modes.md`

#### 1.2 vibe-coding-v2 (vi2 framework)

**프로젝트 개요**:
- **목적**: "Structured workflow replacing chaotic AI interactions"
- **GitHub**: https://github.com/paslavsky/vibe-coding-v2
- **핵심 철학**: Consistent state management for LLM-driven development
- **Stars**: 1, **Forks**: 0

**핵심 설계 패턴**:

##### 1.2.1 Temporary State Directory (.vi2/)

vi2는 모든 상태를 임시 `.vi2/` 디렉터리에 저장합니다:

```
.vi2/
├── llm_context.md       # Knowledge snapshot
├── tasks.md             # Execution checklist
└── questions.md         # Question log
```

**작업 완료 시**: `/vi2/done` 명령으로 최종 리포트 생성 후 `.vi2/` 삭제

**agent-context 적용**:
- 현재: `.context/{task-id}/` (이미 유사한 구조)
- 추가: `llm_context.md`, `questions.md`
- 유지: `try.yaml`, `attempts/`, `summary.yaml`

##### 1.2.2 Knowledge Caching (llm_context.md)

**목적**: LLM amnesia 방지, 기술 결정 기록

**파일 구조**:
```markdown
# llm_context.md

## Technical Decisions
- [Date] Decision 1
  - Rationale: [Why]
  - Trade-off: [Pros/Cons]
  - Alternatives considered: [What was rejected]

## External Documentation
- Library X API: [Summary of key points]
- Best Practices: [Essential guidelines only]

## Architecture Context
[Component diagram or data flow - kept simple]

## Patterns to Follow
- Pattern 1: [Description]
- Pattern 2: [Description]

## Patterns to Avoid
- Anti-pattern 1: [Why to avoid]
```

**agent-context 적용**:

**생성 시점**:
1. `agent dev design` → 초기 llm_context.md 생성 (아키텍처 맥락)
2. `agent dev code` → 기술 결정 기록
3. `agent dev check` → context 갱신 (검증 결과)
4. `agent dev submit` → 최종 context를 MR description에 포함

**구현 위치**:
- `tools/agent/lib/context.sh`: `create_llm_context()`, `update_llm_context()`
- `tools/agent/templates/llm_context.md`: 템플릿

##### 1.2.3 Question-Driven Planning (questions.md)

**목적**: 계획 단계에서 명확화 필요 항목 추적

**파일 구조**:
```markdown
# questions.md

## Planning Questions
- [ ] Q1: What authentication method? (JWT, OAuth2, Session)
      A: JWT with RS256
      Follow-up: Key rotation strategy?

- [ ] Q2: Database choice? (PostgreSQL, MySQL, MongoDB)
      A: [Pending - need performance requirements]

## Blockers
- [ ] B1: External API rate limit unclear
      Resolution: Contact API provider for tier information

## Decisions Needed
- [ ] D1: Monolith vs Microservices
      Options: [Monolith for MVP, Microservices for scale]
      Deadline: Before Phase 2
```

**agent-context 적용**:

**워크플로우**:
```bash
# 1. 질문 생성
agent dev analyze
# → .context/TASK-123/questions.md 생성

# 2. 사용자가 답변 추가 (수동)
vim .context/TASK-123/questions.md

# 3. 설계 문서 갱신
agent dev debrief
# → questions.md 읽고 design/*.md 자동 갱신
# → llm_context.md에 결정사항 기록
```

**구현**:
- `skills/analyze/parse-requirement/SKILL.md`: questions.md 생성 로직 추가
- `tools/agent/bin/agent`: `agent dev debrief` 명령 추가
- `tools/agent/lib/context.sh`: `process_questions()` 함수

##### 1.2.4 Command Structure

vi2의 명령어 구조:

| Command | Purpose | agent-context 대응 |
|---------|---------|-------------------|
| /vi2/plan | 요구사항 분석 및 계획 생성 | agent dev analyze + design |
| /vi2/do-next | 다음 task 실행 | agent dev code |
| /vi2/test | 테스트 실행 | agent dev check --tests-only |
| /vi2/review | 코드 품질 리뷰 | agent dev check |
| /vi2/refactor | 리팩토링 | agent dev code (refactor mode) |
| /vi2/update | 계획 갱신 | agent dev debrief |
| /vi2/sync | 수동 변경 동기화 | agent dev sync (확장 필요) |
| /vi2/debrief | 질문 처리 및 계획 갱신 | **신규**: agent dev debrief |
| /vi2/done | 최종 리포트 및 정리 | agent dev submit |

**신규 명령 필요**:
- `agent dev debrief`: questions.md 처리 및 설계 갱신

#### 1.3 cursor-commands (hamzafer)

**프로젝트 개요**:
- **GitHub**: https://github.com/hamzafer/cursor-commands
- **Stars**: 515, **Forks**: 47
- **내용**: 웹 검색 결과에 디렉터리 구조만 표시됨

**분석 결과**:
- 상세 내용 없음
- 디렉터리 구조만 참고 가능 (`.cursor/commands/` 위치)

**agent-context 적용**:
- ❌ **적용 불가**: 충분한 정보 없음

### 2. 설계 철학 비교 매트릭스

#### 2.1 에이전트 제어 패러다임

| 측면 | agent-context | SDD | vi2 |
|------|---------------|-----|-----|
| **에이전트 역할** | Skill executor + CLI helper | Specification agent with explicit boundaries | Task executor with state tracking |
| **제어 방식** | Skill composition, Workflow as composition | Role Declarations + Mode Boundaries | Checklist-driven execution |
| **자율성** | User Autonomy (warnings, --force) | Plan → Approve → Execute (gate 포함) | Interactive feedback loop |
| **상태 단언** | ❌ 없음 | ✅ State Assertion (REQUIRED) | ⚠️ 부분적 (tasks.md status) |
| **오류 복구** | Git hooks, lint, test | Self-Correction Protocol | Debrief + Update cycle |
| **Human Loop** | Human intervention on conflict | Plan approval before execution | Questions → Debrief → Update |

**분석 결과**:
- **agent-context의 강점**: 최고 수준의 자율성, 유연한 Skill 조합
- **개선 필요**: 상태 단언 부재, 오류 조기 감지 약함
- **SDD 장점 흡수**: State Assertion, Self-Correction
- **vi2 장점 흡수**: Questions, Debrief 사이클

#### 2.2 Context Window 관리

| 측면 | agent-context | SDD | vi2 |
|------|---------------|-----|-----|
| **컨텍스트 크기** | Rolling Summary (계획 단계, 미구현) | Full spec → Quick PRD | llm_context.md (snapshot) |
| **정보 압축** | summary.yaml | quick-prd.md (AI-optimized) | Context caching |
| **재사용성** | Skill 단위 로드 | Shared protocols (_shared/) | Knowledge persistence |
| **임시 저장** | .context/{task-id}/ | specs/active/{task-id}/ | .vi2/ (temporary) |
| **영속성** | Issue/MR upload 후 삭제 | Spec files committed | LLM context only, deleted on done |

**분석 결과**:
- **agent-context의 강점**: 이미 `.context/` 구조 존재
- **개선 필요**: Rolling Summary 미구현, LLM 효율성 낮음
- **SDD 장점 흡수**: quick-prd.md (AI-optimized summary)
- **vi2 장점 흡수**: llm_context.md (knowledge caching)

#### 2.3 워크플로우 구조

| 측면 | agent-context | SDD | vi2 |
|------|---------------|-----|-----|
| **워크플로우 단위** | Skill composition | Command-driven phases | Checklist-driven tasks |
| **진행 추적** | Git commits + attempts | Roadmap status | tasks.md (pending/in_progress/completed) |
| **병렬 작업** | ✅ Detached Mode (worktrees) | ❌ 없음 | ❌ 없음 |
| **반복 개선** | Try mechanism | /refine, /evolve | /vi2/update, /vi2/sync |
| **재사용성** | ✅ Skills reusable | ✅ Commands reusable | ⚠️ Limited |
| **확장성** | ✅ New workflow = new composition | ✅ New command file | ⚠️ New task type |

**분석 결과**:
- **agent-context의 강점**: 가장 유연한 Skill 구조, 독창적인 Try 메커니즘
- **유지 권장**: 현재 구조 유지
- **SDD 참고**: 명령어 네이밍, 문서화 스타일
- **vi2 참고**: Debrief 사이클

### 3. 상세 구현 계획

#### 3.1 Phase 1: 핵심 패턴 도입 (1-2주)

##### Task 1: State Assertion 패턴 도입

**목표**: 에이전트가 작업 전 역할, 모드, 경계를 명시하도록 강제

**파일 변경**:

1. **`skills/_template/SKILL.md` 업데이트**:

```yaml
---
name: skill-name
category: analyze|plan|execute|validate|integrate
description: One line description
version: 1.0.0
role: developer|manager|both
mode: planning|implementation|verification|research
cursor_mode: plan|ask|agent|debug
agent_role: |
  You are a [role] agent. Your job is to [purpose].
  You WILL: [Specific actions]
  You will NOT: [Forbidden actions]
inputs:
  - Input 1
outputs:
  - Output 1
---

# Skill Name

## State Assertion (Agent Requirement)

**Before starting this skill, output:**

```
AGENT MODE: [skill-name]
Mode: [planning|implementation|verification|research]
Purpose: [Specific purpose of this execution]
Implementation: [AUTHORIZED|BLOCKED]
Boundaries: Will [actions], Will NOT [forbidden]
```

## When to Use
...
```

2. **`tools/agent/lib/executor.sh` 업데이트**:

```bash
# 기존 함수에 State Assertion 출력 추가
execute_skill() {
    local skill_path="$1"
    
    # Extract metadata from SKILL.md
    local skill_name=$(basename "$skill_path")
    local mode=$(grep "^mode:" "$skill_path/SKILL.md" | cut -d: -f2 | xargs)
    local cursor_mode=$(grep "^cursor_mode:" "$skill_path/SKILL.md" | cut -d: -f2 | xargs)
    local agent_role=$(sed -n '/^agent_role:/,/^[a-z_]*:/p' "$skill_path/SKILL.md" | sed '1d;$d')
    
    # Output State Assertion
    cat << EOF

==========================================
AGENT MODE: $skill_name
==========================================
Mode: $mode
Cursor Mode: $cursor_mode (recommended)
Purpose: Executing $skill_name
Implementation: AUTHORIZED

Agent Role:
$agent_role
==========================================

EOF
    
    # Continue with skill execution
    # ...
}
```

3. **`.cursorrules` 업데이트**:

```markdown
## Agent State Assertion

When executing any Skill, you MUST output State Assertion first:

```
AGENT MODE: [skill-name]
Mode: [planning|implementation|verification|research]
Purpose: [What you will do in this execution]
Implementation: [AUTHORIZED if allowed to proceed]
Boundaries: Will [actions], Will NOT [forbidden actions]
```

### Mode Boundaries

| Mode | Allowed | Forbidden |
|------|---------|-----------|
| planning | Analyze, Design, Document | Write code, Modify files |
| implementation | Write code, Refactor, Test | Change requirements, Skip tests |
| verification | Run tests, Check style, Review | Write new features, Change design |
| research | Read code, Explore, Ask | Modify files, Commit changes |
```

**테스트**:
```bash
agent dev code
# Expected output:
# ==========================================
# AGENT MODE: write-code
# ==========================================
# Mode: implementation
# Cursor Mode: agent (recommended)
# Purpose: Executing write-code
# Implementation: AUTHORIZED
# ...
```

**예상 효과**:
- 사용자가 에이전트 의도를 즉시 이해
- Mode 위반 시각적 감지 (예: planning 모드인데 파일 변경)

##### Task 2: Self-Correction Protocol 구현

**목표**: 에이전트가 실수를 조기 감지하고 자동 수정

**파일 변경**:

1. **`skills/validate/check-intent/SKILL.md` 업데이트**:

```markdown
# Intent Verification

## Self-Correction Protocol

### Trigger Conditions

This skill monitors for mode violations and triggers self-correction:

1. **Mode Violations**:
   - DETECT: Code changes in planning mode
   - DETECT: Requirement changes in implementation mode
   - DETECT: Skipped quality gates

2. **Workflow Violations**:
   - DETECT: Commit without tests
   - DETECT: Submit without verify
   - DETECT: Design without requirements

### Self-Correction Flow

When violation detected:

```
DETECT: [Specific violation]
STOP: Immediately halt current action
CORRECT: "I apologize - I was [mistake]. Let me return to [correct mode/workflow]."
RESUME: Continue with correct approach
```

### Examples

**Example 1: Code in Planning Mode**

```
DETECT: I attempted to write code while in planning mode
STOP: Halting file modification
CORRECT: "I apologize - I was writing code during analyze mode. 
          Let me return to requirement analysis."
RESUME: Continuing with parse-requirement skill
```

**Example 2: Skip Tests**

```
DETECT: I attempted to commit without running tests
STOP: Halting commit operation
CORRECT: "I apologize - I was skipping the test gate. 
          Let me run tests first."
RESUME: Executing run-tests skill
```

## Workflow

### 1. Monitor Current Mode

Check `.context/{task-id}/mode.txt` for current mode:

```bash
cat .context/TASK-123/mode.txt
# Expected: planning|implementation|verification|research
```

### 2. Detect Violations

```bash
# Check if git status shows changes in planning mode
current_mode=$(cat .context/*/mode.txt)
git_changes=$(git status --short | wc -l)

if [[ "$current_mode" == "planning" && "$git_changes" -gt 0 ]]; then
    echo "DETECT: Code changes in planning mode"
    # Trigger self-correction
fi
```

### 3. Trigger Correction

```bash
# Revert to last known good state
git stash
echo "CORRECT: Reverted to planning mode, code changes stashed"
```

### 4. Resume Correct Path

```bash
# Continue with correct workflow
agent dev analyze  # Return to analysis
```
```

2. **`tools/agent/lib/checks.sh` 업데이트**:

```bash
#!/bin/bash

# Self-correction functions

detect_mode_violation() {
    local task_id="$1"
    local context_dir=".context/$task_id"
    
    # Read current mode
    local current_mode=$(cat "$context_dir/mode.txt" 2>/dev/null || echo "unknown")
    
    # Check git status
    local git_changes=$(git status --short | wc -l)
    
    # Detect violations
    case "$current_mode" in
        planning)
            if [[ "$git_changes" -gt 0 ]]; then
                echo "VIOLATION: Code changes detected in planning mode"
                return 1
            fi
            ;;
        implementation)
            # Check if requirements changed
            if git diff --name-only | grep -q "design/\|plan/"; then
                echo "VIOLATION: Requirement changes in implementation mode"
                return 1
            fi
            ;;
        verification)
            # Check if new features added
            if git diff --stat | grep -qE '\+\+\+.*\.(c|py|sh).*[0-9]+ insertions'; then
                echo "VIOLATION: New code in verification mode"
                return 1
            fi
            ;;
    esac
    
    return 0
}

self_correct() {
    local violation="$1"
    
    cat << EOF

==========================================
SELF-CORRECTION TRIGGERED
==========================================
DETECT: $violation
STOP: Halting current operation
CORRECT: Reverting to safe state
==========================================

EOF
    
    # Stash changes
    git stash push -m "self-correction: $violation"
    
    echo "RESUME: Please specify correct mode and retry"
}

# Export functions
export -f detect_mode_violation
export -f self_correct
```

3. **`agent dev check` 통합**:

```bash
# tools/agent/bin/agent의 cmd_dev_check 함수 수정

cmd_dev_check() {
    local task_id=$(get_current_task)
    
    echo "[INFO] Running self-correction check..."
    
    # Detect mode violations
    if ! detect_mode_violation "$task_id"; then
        local violation=$(detect_mode_violation "$task_id" 2>&1)
        self_correct "$violation"
        return 1
    fi
    
    echo "[PASS] No mode violations detected"
    
    # Continue with other checks (lint, test, etc.)
    # ...
}
```

**테스트**:
```bash
# Scenario: Code change in planning mode
echo "mode: planning" > .context/TASK-123/mode.txt
echo "test" > test.txt
git add test.txt

agent dev check
# Expected output:
# ==========================================
# SELF-CORRECTION TRIGGERED
# ==========================================
# DETECT: Code changes detected in planning mode
# STOP: Halting current operation
# CORRECT: Reverting to safe state
# ==========================================
# RESUME: Please specify correct mode and retry
```

**예상 효과**:
- 실수 즉시 감지 및 자동 복구
- 재작업 시간 감소
- 사용자 신뢰도 증가

##### Task 3: Cursor Mode 매핑

**목표**: Workflow와 Skill에 최적 Cursor Mode 매핑

**파일 변경**:

1. **모든 Workflow 파일에 `cursor_mode` 필드 추가**:

```yaml
# workflows/developer/feature.md
---
name: feature
description: Full feature development workflow
role: developer
cursor_mode: agent  # Overall workflow mode
skills:
  - analyze/parse-requirement     # cursor_mode: ask
  - plan/design-solution          # cursor_mode: plan
  - execute/write-code            # cursor_mode: agent
  - validate/run-tests            # cursor_mode: debug
  - integrate/commit-changes      # cursor_mode: agent
---
```

2. **모든 Skill 파일에 `cursor_mode` 필드 추가**:

```yaml
# skills/analyze/parse-requirement/SKILL.md
---
name: parse-requirement
category: analyze
cursor_mode: ask  # Read-only exploration
---
```

```yaml
# skills/execute/write-code/SKILL.md
---
name: write-code
category: execute
cursor_mode: agent  # Multi-file changes
---
```

3. **`docs/cursor-modes-guide.md` 생성**:

```markdown
# Cursor Mode Integration Guide

## Overview

agent-context integrates with Cursor IDE's four modes to optimize AI assistance.

## Mode Mapping

| Cursor Mode | Purpose | agent-context Commands | When to Use |
|-------------|---------|------------------------|-------------|
| **Plan** | Create specs without code changes | agent dev design, agent dev plan | Designing solutions, breaking down work |
| **Ask** | Read-only exploration | agent dev analyze | Understanding requirements, exploring codebase |
| **Agent** | Full multi-file changes | agent dev code, agent dev submit | Writing code, refactoring |
| **Debug** | Runtime evidence + spec audit | agent dev check (extended) | Testing, debugging, verification |

## Switching Modes

Use `Cmd+.` (Mac) or `Ctrl+.` (Windows/Linux) to switch Cursor modes.

## Workflow Mode Recommendations

### Developer Workflows

| Workflow | Primary Mode | Phase-specific Modes |
|----------|--------------|----------------------|
| feature | Agent | Ask (analyze) → Plan (design) → Agent (code) → Debug (test) |
| bug-fix | Debug | Ask (logs) → Agent (fix) → Debug (verify) |
| hotfix | Agent | Agent (fast) → Debug (critical tests) |
| refactor | Agent | Plan (plan) → Agent (refactor) → Debug (regression test) |

### Manager Workflows

| Workflow | Primary Mode | Reason |
|----------|--------------|--------|
| approval | Ask | Read MR, no code changes |
| monitoring | Ask | Read status, no changes |

## Skill-Level Recommendations

### analyze/ (Ask Mode)

- **parse-requirement**: Ask - Explore requirements, ask questions
- **inspect-codebase**: Ask - Read-only code exploration
- **inspect-logs**: Ask - Read logs, no changes

### plan/ (Plan Mode)

- **design-solution**: Plan - Create design docs
- **breakdown-work**: Plan - Create task lists

### execute/ (Agent Mode)

- **write-code**: Agent - Multi-file implementation
- **refactor-code**: Agent - Large-scale changes
- **fix-defect**: Agent - Bug fixes

### validate/ (Debug Mode)

- **run-tests**: Debug - Execute tests, analyze failures
- **review-code**: Ask - Read code, suggest improvements
- **check-style**: Ask - Read and analyze

### integrate/ (Agent Mode)

- **commit-changes**: Agent - Git operations
- **create-merge-request**: Agent - MR creation

## Best Practices

1. **Start in Ask/Plan**: Understand before implementing
2. **Switch to Agent**: When ready to write code
3. **Use Debug for verification**: Test, debug, audit
4. **Return to Ask**: When stuck or need to re-understand

## Examples

### Feature Development Flow

```bash
# 1. Understand (Ask Mode)
# Press Cmd+. → Select "Ask"
agent dev analyze

# 2. Design (Plan Mode)
# Press Cmd+. → Select "Plan"
agent dev design

# 3. Implement (Agent Mode)
# Press Cmd+. → Select "Agent"
agent dev code

# 4. Verify (Debug Mode)
# Press Cmd+. → Select "Debug"
agent dev check
```

### Bug Fix Flow

```bash
# 1. Investigate (Debug Mode)
# Press Cmd+. → Select "Debug"
agent dev analyze --logs

# 2. Fix (Agent Mode)
# Press Cmd+. → Select "Agent"
agent dev code

# 3. Verify (Debug Mode)
# Press Cmd+. → Select "Debug"
agent dev check
```

## Mode-Specific Features

### Ask Mode Features
- Read-only codebase exploration
- Semantic search
- Documentation lookup
- No file modifications

### Plan Mode Features
- Create specifications
- Design documents
- Task breakdowns
- No code implementation

### Agent Mode Features
- Multi-file changes
- Refactoring
- Implementation
- Git operations

### Debug Mode Features
- Runtime analysis
- Log instrumentation
- Test execution
- Hypothesis generation

## Integration with State Assertion

When executing skills, the State Assertion will recommend Cursor Mode:

```
AGENT MODE: write-code
Mode: implementation
Cursor Mode: agent (recommended)  ← Recommendation
Purpose: Implement feature code
```

If you're in a different mode, consider switching for optimal experience.
```

**테스트**:
```bash
# Check mode recommendations
grep "cursor_mode:" workflows/**/*.md
grep "cursor_mode:" skills/**/*.md

# Verify guide
cat docs/cursor-modes-guide.md
```

**예상 효과**:
- Cursor IDE 기능 최적 활용
- 사용자 경험 향상
- 작업 효율 증가

**Phase 1 완료 기준**:
- ✅ State Assertion 출력 확인 (`agent dev code` 실행 시)
- ✅ Self-Correction 동작 확인 (mode 위반 시나리오)
- ✅ Cursor Mode 가이드 문서 완성
- ✅ 모든 Workflow/Skill에 `cursor_mode` 필드 존재

#### 3.2 Phase 2: Context 관리 개선 (2-3주)

##### Task 4: Knowledge Caching (llm_context.md)

**목표**: LLM 효율성 향상을 위한 기술 결정 및 외부 문서 캐싱

**파일 변경**:

1. **`tools/agent/templates/llm_context.md` 생성**:

```markdown
# LLM Context Cache

**Task ID**: {TASK_ID}
**Created**: {DATE}
**Last Updated**: {DATE}

---

## Task Summary

**Goal**: {Brief description of what we're building}

**Status**: {planning|implementation|verification}

---

## Technical Decisions

### Decision 1: {Title}
- **Date**: {YYYY-MM-DD}
- **Decision**: {What was decided}
- **Rationale**: {Why this approach}
- **Trade-offs**: 
  - Pros: {Benefits}
  - Cons: {Drawbacks}
- **Alternatives considered**: {What was rejected and why}

### Decision 2: {Title}
...

---

## External References

### Library/Framework: {Name}
- **Version**: {X.Y.Z}
- **Key APIs**:
  - `function1()`: {Brief description}
  - `function2()`: {Brief description}
- **Best Practices**: {Essential guidelines only}
- **Gotchas**: {Common pitfalls to avoid}

### Documentation: {Source}
- **Summary**: {Key points extracted}
- **Relevant sections**: {What to remember}

---

## Architecture Context

### Component Overview
```
[Simple ASCII diagram or bullet list]
- Component A: {Purpose}
- Component B: {Purpose}
- Relationship: {How they interact}
```

### Data Flow
```
Input → Processing → Output
{Brief description of each stage}
```

---

## Patterns to Follow

### Pattern 1: {Name}
```{language}
{Code example}
```
- **When to use**: {Scenario}
- **Benefits**: {Why}

### Pattern 2: {Name}
...

---

## Patterns to Avoid

### Anti-pattern 1: {Name}
- **Problem**: {What's wrong}
- **Instead do**: {Correct approach}

---

## Open Questions

- [ ] Q1: {Question awaiting answer}
- [ ] Q2: {Question awaiting answer}

---

## Blockers Resolved

### Blocker 1: {Description}
- **Resolution**: {How it was resolved}
- **Date resolved**: {YYYY-MM-DD}

---

## Notes

- {Any other context that doesn't fit above}
```

2. **`tools/agent/lib/context.sh` 업데이트**:

```bash
#!/bin/bash

# Existing functions...

# Create LLM context
create_llm_context() {
    local task_id="$1"
    local context_dir=".context/$task_id"
    local llm_context="$context_dir/llm_context.md"
    
    mkdir -p "$context_dir"
    
    # Copy template
    cp "$TEMPLATES_DIR/llm_context.md" "$llm_context"
    
    # Replace placeholders
    sed -i.bak "s/{TASK_ID}/$task_id/g" "$llm_context"
    sed -i.bak "s/{DATE}/$(date +%Y-%m-%d)/g" "$llm_context"
    rm "$llm_context.bak"
    
    echo "[INFO] Created llm_context.md for $task_id"
}

# Update LLM context with technical decision
add_technical_decision() {
    local task_id="$1"
    local title="$2"
    local decision="$3"
    local rationale="$4"
    
    local llm_context=".context/$task_id/llm_context.md"
    
    cat >> "$llm_context" << EOF

### Decision: $title
- **Date**: $(date +%Y-%m-%d)
- **Decision**: $decision
- **Rationale**: $rationale
- **Trade-offs**: 
  - Pros: [To be filled]
  - Cons: [To be filled]

EOF
    
    echo "[INFO] Added technical decision: $title"
}

# Update LLM context with external reference
add_external_reference() {
    local task_id="$1"
    local name="$2"
    local summary="$3"
    
    local llm_context=".context/$task_id/llm_context.md"
    
    cat >> "$llm_context" << EOF

### Library/Framework: $name
- **Summary**: $summary
- **Key APIs**: [To be filled during implementation]

EOF
    
    echo "[INFO] Added external reference: $name"
}

# Get LLM context for current task
get_llm_context() {
    local task_id="$1"
    local llm_context=".context/$task_id/llm_context.md"
    
    if [[ -f "$llm_context" ]]; then
        cat "$llm_context"
    else
        echo "[WARN] No LLM context found for $task_id"
        return 1
    fi
}

# Export functions
export -f create_llm_context
export -f add_technical_decision
export -f add_external_reference
export -f get_llm_context
```

3. **`agent dev` 명령 통합**:

```bash
# tools/agent/bin/agent

cmd_dev_start() {
    local task_id="$1"
    
    # ... existing start logic ...
    
    # Create LLM context
    create_llm_context "$task_id"
}

cmd_dev_design() {
    local task_id=$(get_current_task)
    
    # Execute design skill
    # ...
    
    # Prompt for technical decisions
    echo "=== Technical Decisions ==="
    echo "Record key technical decisions in llm_context.md"
    echo "Example: add_technical_decision \"$task_id\" \"Auth Method\" \"JWT with RS256\" \"Better security\""
}

cmd_dev_check() {
    local task_id=$(get_current_task)
    
    # ... existing check logic ...
    
    # Update LLM context with verification results
    cat >> ".context/$task_id/llm_context.md" << EOF

## Verification Results ($(date +%Y-%m-%d))
- Lint: [PASS/FAIL]
- Tests: [PASS/FAIL]
- Coverage: [X%]

EOF
}
```

4. **`skills/plan/design-solution/SKILL.md` 업데이트**:

```markdown
# Design Solution

## Workflow

### 1. Analyze Requirements

...

### 2. Make Technical Decisions

For each major decision:

```bash
# Record in llm_context.md
Decision: [What]
Rationale: [Why]
Trade-offs: [Pros/Cons]
Alternatives: [What was rejected]
```

### 3. Document Architecture

Update llm_context.md with:
- Component overview
- Data flow
- Patterns to follow

### 4. Output Design Document

Create `design/solutions/{task-id}.md` with detailed design.

**Note**: llm_context.md is a cache for LLM efficiency. 
The design document is the official specification.
```

**사용 시나리오**:

```bash
# 1. Start task
agent dev start TASK-123
# → llm_context.md created

# 2. Design phase
agent dev design
# → Agent asks: "What authentication method?"
# → User answers: "JWT with RS256"
# → Agent records in llm_context.md:
#   Decision: Use JWT with RS256
#   Rationale: Better security, key rotation support

# 3. Later in same task
agent dev code
# → Agent reads llm_context.md
# → No need to ask about auth method again
# → Implements JWT RS256 directly

# 4. Check phase
agent dev check
# → Results appended to llm_context.md

# 5. Submit
agent dev submit
# → llm_context.md included in MR description
```

**예상 효과**:
- 평균 20% 토큰 사용 감소
- 동일 질문 반복 제거
- LLM amnesia 방지

##### Task 5: Question-Driven Planning (questions.md)

**목표**: 계획 단계에서 명확화가 필요한 항목을 구조화된 질문으로 관리

**파일 변경**:

1. **`tools/agent/templates/questions.md` 생성**:

```markdown
# Planning Questions

**Task ID**: {TASK_ID}
**Created**: {DATE}

---

## Status

- Total Questions: {N}
- Answered: {N}
- Pending: {N}
- Blockers: {N}

---

## Planning Questions

### Requirements Clarification

- [ ] **Q1**: {Question about requirements}
      - Context: {Why this matters}
      - Options: {Possible answers}
      - **Answer**: [Your answer here]
      - Follow-up: {New questions from this answer}

- [ ] **Q2**: {Question about scope}
      - Context: {Why this matters}
      - **Answer**: [Pending]

### Technical Decisions

- [ ] **Q3**: {Question about tech stack}
      - Context: {Why this matters}
      - Options: {A, B, C}
      - **Answer**: [Your answer]
      - Rationale: {Why you chose this}

### Architecture

- [ ] **Q4**: {Question about architecture}
      - Context: {Why this matters}
      - **Answer**: [Your answer]

---

## Blockers

- [ ] **B1**: {Blocker description}
      - Impact: {What's blocked}
      - Resolution: {How to resolve}
      - Owner: {Who should resolve}
      - Status: [Pending/In Progress/Resolved]

- [ ] **B2**: {Another blocker}
      ...

---

## Decisions Needed

- [ ] **D1**: {Decision point}
      - Options: {List alternatives}
      - Criteria: {How to decide}
      - Deadline: {When decision is needed}
      - **Decision**: [Your decision]
      - Date: {When decided}

---

## Assumptions

- A1: {Assumption we're making}
  - Risk if wrong: {Impact}
  - Validation: {How to verify}

---

## Notes

- {Any additional context}
```

2. **`tools/agent/lib/context.sh` 업데이트**:

```bash
# Create questions.md
create_questions() {
    local task_id="$1"
    local context_dir=".context/$task_id"
    local questions="$context_dir/questions.md"
    
    mkdir -p "$context_dir"
    
    # Copy template
    cp "$TEMPLATES_DIR/questions.md" "$questions"
    
    # Replace placeholders
    sed -i.bak "s/{TASK_ID}/$task_id/g" "$questions"
    sed -i.bak "s/{DATE}/$(date +%Y-%m-%d)/g" "$questions"
    rm "$questions.bak"
    
    echo "[INFO] Created questions.md for $task_id"
}

# Add question
add_question() {
    local task_id="$1"
    local category="$2"  # requirements|technical|architecture|blocker|decision
    local question="$3"
    local context="$4"
    
    local questions=".context/$task_id/questions.md"
    
    local section=""
    case "$category" in
        requirements) section="Requirements Clarification" ;;
        technical) section="Technical Decisions" ;;
        architecture) section="Architecture" ;;
        blocker) section="Blockers" ;;
        decision) section="Decisions Needed" ;;
    esac
    
    # Find section and append
    # (Implementation details...)
    
    echo "[INFO] Added question: $question"
}

# Process answered questions
process_questions() {
    local task_id="$1"
    local questions=".context/$task_id/questions.md"
    local design_doc="design/solutions/$task_id.md"
    local llm_context=".context/$task_id/llm_context.md"
    
    echo "[INFO] Processing answered questions..."
    
    # Extract answered questions
    # For each answered question:
    #   - Update design document
    #   - Add to llm_context.md as decision
    #   - Mark as processed
    
    # (Implementation details...)
    
    echo "[INFO] Questions processed and integrated into design"
}

export -f create_questions
export -f add_question
export -f process_questions
```

3. **`agent dev debrief` 명령 추가**:

```bash
# tools/agent/bin/agent

cmd_dev_debrief() {
    local task_id=$(get_current_task)
    
    echo "=== Debrief: Processing Questions ==="
    
    # Check if questions.md exists
    if [[ ! -f ".context/$task_id/questions.md" ]]; then
        echo "[ERROR] No questions.md found. Run 'agent dev analyze' first."
        return 1
    fi
    
    # Process questions
    process_questions "$task_id"
    
    # Show summary
    echo ""
    echo "=== Debrief Complete ==="
    echo "Updated documents:"
    echo "  - design/solutions/$task_id.md"
    echo "  - .context/$task_id/llm_context.md"
    echo ""
    echo "Next step: agent dev plan"
}
```

4. **`skills/analyze/parse-requirement/SKILL.md` 업데이트**:

```markdown
# Parse Requirement

## Workflow

### 1. Read Requirements

...

### 2. Generate Clarification Questions

For unclear requirements, generate questions in questions.md:

```bash
# Categories:
# - Requirements Clarification: What/Why/Who
# - Technical Decisions: How/With what
# - Architecture: Where/Structure
# - Blockers: Dependencies/Unknowns
# - Decisions: Trade-offs/Alternatives
```

### 3. Present Questions to User

Output:

```
=== Clarification Questions ===

Requirements:
  Q1: What authentication method? (JWT, OAuth2, Session)
  Q2: What database? (PostgreSQL, MySQL, MongoDB)

Technical:
  Q3: Monolith or Microservices?

Blockers:
  B1: External API rate limits unclear

Please answer in .context/{task-id}/questions.md
Then run: agent dev debrief
```

### 4. Wait for Answers

User edits questions.md and runs `agent dev debrief`.

### 5. Generate Design Document

After debrief, create `design/requirements/{task-id}.md`.
```

**사용 시나리오**:

```bash
# 1. Analyze requirements
agent dev analyze

# Output:
# === Clarification Questions ===
# 
# Requirements:
#   Q1: What authentication method? (JWT, OAuth2, Session)
#   Q2: What are the supported user roles? (Admin, User, Guest)
# 
# Technical:
#   Q3: Monolith or Microservices for this feature?
# 
# Please answer in .context/TASK-123/questions.md
# Then run: agent dev debrief

# 2. User edits questions.md:
vim .context/TASK-123/questions.md

# - [ ] **Q1**: What authentication method?
#       **Answer**: JWT with RS256

# - [ ] **Q2**: What are the supported user roles?
#       **Answer**: Admin (full access), User (read/write own), Guest (read-only)

# - [ ] **Q3**: Monolith or Microservices?
#       **Answer**: Monolith for MVP, plan for microservices later

# 3. Process answers
agent dev debrief

# Output:
# === Debrief: Processing Questions ===
# [INFO] Processing answered questions...
# [INFO] Updated design/solutions/TASK-123.md with requirements
# [INFO] Added technical decision to llm_context.md: JWT with RS256
# [INFO] Questions processed and integrated into design
# 
# === Debrief Complete ===
# Next step: agent dev plan

# 4. Continue with design
agent dev design
# → Agent reads answers from llm_context.md
# → No need to ask again
```

**예상 효과**:
- 요구사항 오해율 15% → 5%
- 명확한 피드백 루프
- 설계 품질 향상

##### Task 6: AI-Optimized Summary (quick-summary.md)

**목표**: MR 제출 전 AI에 최적화된 간결한 요약 생성

**파일 변경**:

1. **`tools/agent/lib/markdown.sh` 업데이트**:

```bash
#!/bin/bash

# Existing functions...

# Generate quick summary (AI-optimized)
generate_quick_summary() {
    local task_id="$1"
    local context_dir=".context/$task_id"
    local quick_summary="$context_dir/quick-summary.md"
    
    echo "[INFO] Generating AI-optimized summary..."
    
    # Extract key information
    local goal=$(grep "^Goal:" "$context_dir/llm_context.md" | cut -d: -f2- | xargs)
    local decisions=$(grep -A3 "^### Decision:" "$context_dir/llm_context.md" | grep "Decision:" | cut -d: -f2- | head -3)
    local test_results=$(grep -A5 "^## Verification Results" "$context_dir/llm_context.md" | tail -3)
    
    # Generate summary
    cat > "$quick_summary" << EOF
# Quick Summary: $task_id

**AI-Optimized Context Snapshot**

---

## Goal
$goal

---

## Key Changes
$(generate_key_changes "$task_id")

---

## Technical Decisions
$decisions

---

## Verification
$test_results

---

## Impact
- Files changed: $(git diff --name-only origin/main | wc -l)
- Insertions: $(git diff --stat origin/main | tail -1 | awk '{print $4}')
- Deletions: $(git diff --stat origin/main | tail -1 | awk '{print $6}')

---

## Next Steps
$(generate_next_steps "$task_id")

---

*Generated: $(date +%Y-%m-%d\ %H:%M:%S)*
*Token-optimized for LLM consumption*
EOF
    
    echo "[INFO] Quick summary created: $quick_summary"
}

# Generate key changes (bullet points)
generate_key_changes() {
    local task_id="$1"
    
    # Analyze git diff and extract key changes
    git diff --stat origin/main | head -10 | while read line; do
        echo "- $line"
    done
}

# Generate next steps
generate_next_steps() {
    local task_id="$1"
    
    # Check if all requirements met
    if [[ -f ".context/$task_id/verify-report.md" ]]; then
        echo "- ✅ All requirements verified"
        echo "- Ready for MR review"
    else
        echo "- Run verification: agent dev verify"
    fi
}

export -f generate_quick_summary
export -f generate_key_changes
export -f generate_next_steps
```

2. **`agent dev verify`, `agent dev submit` 통합**:

```bash
# tools/agent/bin/agent

cmd_dev_verify() {
    local task_id=$(get_current_task)
    
    # ... existing verify logic ...
    
    # Generate quick summary
    generate_quick_summary "$task_id"
    
    echo ""
    echo "=== Quick Summary Generated ==="
    echo "Location: .context/$task_id/quick-summary.md"
    echo "This will be included in MR description"
}

cmd_dev_submit() {
    local task_id=$(get_current_task)
    
    # ... existing submit logic ...
    
    # Include quick summary in MR description
    local quick_summary=$(cat ".context/$task_id/quick-summary.md" 2>/dev/null || echo "No summary")
    
    # Create MR with summary
    pm mr create \
        --title "feat: $task_id implementation" \
        --description "$quick_summary" \
        --source-branch "$(git branch --show-current)" \
        --target-branch main
    
    echo "[INFO] MR created with AI-optimized summary"
}
```

**사용 시나리오**:

```bash
# 1. Complete development
agent dev code
agent dev check

# 2. Verify requirements
agent dev verify

# Output:
# [INFO] Generating AI-optimized summary...
# [INFO] Quick summary created: .context/TASK-123/quick-summary.md
# 
# === Quick Summary Generated ===
# Location: .context/TASK-123/quick-summary.md

# 3. Review summary
cat .context/TASK-123/quick-summary.md

# Output:
# # Quick Summary: TASK-123
# 
# **AI-Optimized Context Snapshot**
# 
# ## Goal
# Implement JWT authentication with RS256
# 
# ## Key Changes
# - src/auth/jwt.c (120 insertions)
# - tests/test_auth.c (80 insertions)
# - include/auth.h (15 insertions)
# 
# ## Technical Decisions
# - Decision: Use JWT with RS256
# - Decision: 15-minute access token, 7-day refresh token
# - Decision: Redis for token blacklist
# 
# ## Verification
# - Lint: PASS
# - Tests: PASS (100% coverage)
# - Requirements: Met (3/3)
# 
# ## Impact
# - Files changed: 3
# - Insertions: 215
# - Deletions: 10

# 4. Submit with summary
agent dev submit

# → MR created with quick-summary.md as description
# → Reviewer sees concise, AI-optimized summary
```

**예상 효과**:
- MR description 간결화 (3-5 bullet points)
- 리뷰어 이해도 향상
- 리뷰 시간 평균 30% 단축
- Context Window 최적화

**Phase 2 완료 기준**:
- ✅ llm_context.md 생성 확인 (`agent dev start` 실행 시)
- ✅ questions.md + debrief 워크플로우 동작 확인
- ✅ quick-summary.md 생성 확인 (`agent dev verify` 실행 시)
- ✅ MR description에 quick-summary 포함 확인

#### 3.3 Phase 3: 선택적 기능 추가 (장기 검토)

##### Task 7: Automated Execution (--auto-submit)

**목표**: 전체 워크플로우 자동 실행 (선택적 기능)

**철학적 고려사항**:
- ⚠️ User Autonomy와 충돌 가능
- ✅ 선택적 기능으로 제공
- ✅ 기본값은 단계별 승인 유지

**구현 계획**:

```bash
# tools/agent/bin/agent

cmd_dev_start() {
    local task_id="$1"
    local auto_submit=false
    
    # Parse flags
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto-submit)
                auto_submit=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    # ... existing start logic ...
    
    # If auto-submit, run workflow automatically
    if [[ "$auto_submit" == "true" ]]; then
        echo "[INFO] Auto-submit mode enabled"
        echo "[INFO] Will execute: check → commit → verify → submit"
        
        auto_execute_workflow "$task_id"
    fi
}

auto_execute_workflow() {
    local task_id="$1"
    
    echo "=== Auto-Execution Mode ==="
    
    # Step 1: Check
    echo "[Step 1/4] Running checks..."
    if ! cmd_dev_check; then
        echo "[ERROR] Checks failed. Stopping auto-execution."
        return 1
    fi
    
    # Step 2: Commit
    echo "[Step 2/4] Committing changes..."
    if ! cmd_dev_commit "feat: auto-commit for $task_id"; then
        echo "[ERROR] Commit failed. Stopping auto-execution."
        return 1
    fi
    
    # Step 3: Verify
    echo "[Step 3/4] Verifying requirements..."
    if ! cmd_dev_verify; then
        echo "[ERROR] Verification failed. Stopping auto-execution."
        return 1
    fi
    
    # Step 4: Submit
    echo "[Step 4/4] Submitting MR..."
    if ! cmd_dev_submit; then
        echo "[ERROR] Submit failed."
        return 1
    fi
    
    echo "=== Auto-Execution Complete ==="
    echo "MR created successfully"
}
```

**사용 시나리오**:

```bash
# Manual mode (default)
agent dev start TASK-123
agent dev code
agent dev check
agent dev commit "feat: ..."
agent dev verify
agent dev submit

# Auto mode (optional)
agent dev start TASK-123 --auto-submit
agent dev code
# → Auto-executes: check → commit → verify → submit
# → On error: stops and notifies
```

**리스크**:
- 중간 단계 검토 불가 → 품질 저하 가능
- 완화: 에러 발생 시 즉시 중단

**권장사항**:
- ⚠️ Phase 3로 분류 (선택적 도입)
- 사용자 피드백 수집 후 결정

##### Task 8: Manual Change Sync 확장

**목표**: 수동 코드 변경을 프레임워크 상태에 자동 동기화

**현재 상태**:
- `agent dev sync`는 rebase만 수행
- 수동 변경 시 상태 불일치 가능

**vi2 참고**:
- `/vi2/sync`: 수동 변경 감지 → tasks.md 자동 갱신

**구현 계획**:

```bash
# tools/agent/lib/git-strategy.sh

sync_manual_changes() {
    local task_id="$1"
    
    echo "[INFO] Detecting manual changes..."
    
    # Check uncommitted changes
    if git diff --quiet; then
        echo "[INFO] No manual changes detected"
        return 0
    fi
    
    # Analyze changes
    local changed_files=$(git diff --name-only)
    
    echo "[INFO] Manual changes detected:"
    echo "$changed_files" | while read file; do
        echo "  - $file"
    done
    
    # Update llm_context.md
    cat >> ".context/$task_id/llm_context.md" << EOF

## Manual Changes ($(date +%Y-%m-%d))
$changed_files

**Note**: These changes were made manually outside agent workflow.
Review and ensure they align with design.
EOF
    
    # Suggest commit
    echo ""
    echo "[SUGGEST] Commit manual changes:"
    echo "  git add -A"
    echo "  agent dev commit \"manual: <description>\""
}
```

**사용 시나리오**:

```bash
# 1. Manual edit
vim src/auth.c
# (User makes changes)

# 2. Sync
agent dev sync

# Output:
# [INFO] Detecting manual changes...
# [INFO] Manual changes detected:
#   - src/auth.c
# 
# [SUGGEST] Commit manual changes:
#   git add -A
#   agent dev commit "manual: fix auth bug"
```

**리스크**:
- 복잡도 증가
- Git diff 분석 정확도

**권장사항**:
- ⚠️ Phase 3로 분류 (복잡도 대비 효과 검증 필요)
- 단순한 감지 + 알림으로 시작

### 4. 철학적 통합: "명확한 자율성"

#### 4.1 핵심 개념

agent-context의 기존 철학을 유지하되, 레퍼런스 프로젝트의 장점을 통합하여 **"명확한 자율성(Clear Autonomy)"** 패러다임을 제안합니다.

**정의**:
> 에이전트가 자율적으로 작동하되, 그 의도와 경계를 명확히 표현하여 사용자가 신뢰하고 제어할 수 있는 시스템

#### 4.2 원칙 재정의

##### 원칙 1: Simplicity Over Completeness (유지)

**기존**: Simple solutions that work > Complex solutions that might work better

**통합 후**:
- SDD의 State Assertion은 "가시성 도구"로만 사용 (강제 아님)
- vi2의 체크리스트는 참고용, 필수 아님
- 복잡도 예산 유지: Skill 200 lines, Workflow 100 lines

**실천**:
- State Assertion 출력 = 정보 제공, 차단 없음
- Self-Correction = 제안, 강제 아님 (사용자가 override 가능)

##### 원칙 2: User Autonomy (유지 + 강화)

**기존**: Warnings > Blocking, --force escape hatches

**통합 후**:
- SDD의 Plan approval은 선택적 기능 (--auto-submit)
- 기본값은 여전히 warnings + --force
- State Assertion으로 의도 명확화 → 더 나은 자율적 판단 가능

**실천**:
- Mode Boundaries 표시하되, 위반 시 경고만 (차단 없음)
- --force 플래그 유지
- 사용자가 모든 단계에서 개입 가능

##### 원칙 3: Feedback Over Enforcement (강화)

**기존**: Clear feedback teaches better than hard blocks

**통합 후**:
- **SDD의 Self-Correction**: 강제가 아닌 "피드백 루프"
- **vi2의 Questions**: 명령이 아닌 "대화 도구"
- State Assertion = "에이전트가 지금 무엇을 하는지" 피드백

**실천**:
- Self-Correction DETECT → STOP → CORRECT → RESUME = 투명한 피드백
- questions.md = 사용자-에이전트 대화 기록
- 모든 상태 변화를 사용자에게 알림

##### 원칙 4: Composability (유지)

**기존**: Small, focused skills > Large, monolithic workflows

**통합 후**:
- Skills 기반 구조 유지 (가장 유연함)
- SDD/vi2의 Command는 Skills의 wrapper로 볼 수 있음
- Workflow = Skill composition (변경 없음)

**실천**:
- 새 기능 추가 시 Skill 단위로 구현
- SDD 패턴은 Skill 템플릿에 통합
- vi2 패턴은 Context 관리에 통합

##### 원칙 5: State Through Artifacts (확장)

**기존**: Git is truth, Files > Databases, Human-readable

**통합 후**:
- **기존 유지**: Git + .context/
- **추가**: llm_context.md (LLM 효율성)
- **추가**: questions.md (요구사항 명확화)
- **유지**: Issue/MR이 진실의 원천

**실천**:
- llm_context.md = 임시 LLM 캐시
- quick-summary.md = AI-optimized MR description
- 영속 데이터는 여전히 Git + Issue

#### 4.3 Triple-Layer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: State Visibility (SDD 영감)                        │
│ - State Assertion (에이전트 의도 명시)                       │
│ - Mode Boundaries (작업 범위 명시)                           │
│ - Cursor Mode Integration (IDE 최적화)                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 2: Feedback Loops (vi2 영감)                          │
│ - Knowledge Caching (llm_context.md)                        │
│ - Question-Driven Planning (questions.md)                   │
│ - Self-Correction Protocol (오류 조기 감지)                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 3: Flexible Execution (agent-context 기존)            │
│ - Skill Composition (재사용성)                               │
│ - Warnings + --force (자율성)                                │
│ - Git + Issue as Truth (단순성)                              │
└─────────────────────────────────────────────────────────────┘
```

**설명**:
1. **Layer 1 (가시성)**: 에이전트가 무엇을 하는지 명확히 표현
2. **Layer 2 (피드백)**: 에이전트와 사용자 간 대화 루프
3. **Layer 3 (실행)**: 유연하고 자율적인 실행 모델

#### 4.4 철학 비교 테이블

| 측면 | agent-context | SDD | vi2 | 통합 후 (Clear Autonomy) |
|------|---------------|-----|-----|--------------------------|
| **통제 vs 자율성** | 자율성 우선 | 통제 우선 (Plan approval) | 중간 (Interactive) | 명확한 자율성 |
| **상태 가시성** | 낮음 (암묵적) | 높음 (State Assertion) | 중간 (tasks.md) | 높음 (투명한 자율성) |
| **오류 처리** | 사후 검증 | 사전 방지 (Self-Correction) | 대화형 (Debrief) | 조기 감지 + 제안 |
| **Context 관리** | 단순 (summary.yaml) | 명세 중심 (specs/) | LLM 최적화 (llm_context.md) | LLM 효율 + 단순성 |
| **워크플로우** | Skill composition | Command-driven | Checklist-driven | Skill composition (유지) |
| **사용자 개입** | 항상 가능 | Plan 단계만 | Questions 단계 | 모든 단계에서 가능 |

### 5. 예상 효과 및 성공 지표

#### 5.1 정량적 효과

| 지표 | 측정 방법 | 현재 (추정) | 목표 | 개선율 |
|------|-----------|------------|------|--------|
| **에이전트 의도 명확성** | 사용자 설문 (5점 척도) | 3.0/5.0 | 4.7/5.0 | +58% |
| **Mode 위반 조기 감지** | 월 감지 횟수 | 0회 (사후 발견) | 5회 이상 | - |
| **Context Window 토큰 절감** | 평균 토큰 사용 | 기준선 | -20% | 20% 절감 |
| **MR 리뷰 시간** | 평균 리뷰 시간 (분) | 기준선 | -30% | 30% 단축 |
| **요구사항 오해율** | 재작업 발생 비율 | 15% | 5% | -67% |
| **Self-Correction 발동** | 월 발동 횟수 | 0회 | 5회 이상 | - |
| **사용자 만족도** | 설문 조사 (5점 척도) | 3.5/5.0 | 4.0/5.0 | +14% |

#### 5.2 정성적 효과

##### 사용자 경험
- ✅ 에이전트 의도가 명확하여 안심하고 사용
- ✅ 실수를 조기 발견하여 재작업 감소
- ✅ Cursor Mode 매핑으로 IDE 기능 최적 활용

##### 개발 품질
- ✅ 명세 중심 개발로 일관성 유지
- ✅ 기술 결정 기록으로 추적 가능성 향상
- ✅ 질문 기반 계획으로 요구사항 명확화

##### 협업 효율
- ✅ MR 리뷰 품질 향상으로 팀 생산성 증가
- ✅ 간결한 summary로 리뷰어 부담 감소
- ✅ Context Window 최적화로 LLM 비용 절감

##### LLM 효율성
- ✅ llm_context.md로 반복 설명 제거
- ✅ quick-summary로 핵심만 전달
- ✅ 평균 20% 토큰 절감

#### 5.3 리스크 및 완화 방안

| 리스크 | 확률 | 영향 | 완화 방안 | 담당 |
|--------|------|------|-----------|------|
| **복잡도 증가** | 중간 | 중간 | Progressive rollout, 기본값 유지, 문서화 강화 | Dev Team |
| **철학 충돌** (Autonomy vs Gate) | 낮음 | 중간 | State Assertion은 "가시성" 도구로만, 강제 없음 | Architect |
| **Context 관리 오버헤드** | 낮음 | 낮음 | 자동화, 선택적 기능, 성능 모니터링 | Dev Team |
| **사용자 혼란** | 중간 | 낮음 | 문서화, 점진적 도입, 튜토리얼 제공 | Doc Team |
| **LLM 호환성 문제** | 낮음 | 중간 | 다양한 LLM에서 테스트, 템플릿 조정 | QA Team |
| **Phase 3 기능 오남용** | 중간 | 중간 | 기본값 비활성화, 명확한 경고 메시지 | Product Owner |

#### 5.4 성공 지표 측정 계획

##### Phase 1 (1-2주 후)
- State Assertion 활용률: 80% 이상의 Skill 실행 시 출력 확인
- Self-Correction 발동: 월 5회 이상 Mode 위반 감지 로그 확인
- 사용자 설문: 에이전트 의도 명확성 평가

##### Phase 2 (4-6주 후)
- Context Window 토큰 사용: 이전 대비 20% 절감 확인 (로그 분석)
- MR 리뷰 시간: 평균 30% 단축 확인 (GitLab/JIRA 메트릭)
- 요구사항 오해율: 재작업 발생 비율 확인 (JIRA 이슈 추적)

##### Phase 3 (12주 후, 선택적)
- --auto-submit 사용률: 전체 작업 중 사용 비율
- 오류 발생률: 자동 실행 시 오류 중단 비율
- 사용자 피드백: Phase 3 기능 만족도 조사

### 6. 구현 로드맵

#### Timeline

```
Week 1-2: Phase 1
├── Task 1: State Assertion (3-4일)
├── Task 2: Self-Correction (3-4일)
└── Task 3: Cursor Mode (2-3일)

Week 3-5: Phase 2
├── Task 4: Knowledge Caching (4-5일)
├── Task 5: Question Planning (4-5일)
└── Task 6: Quick Summary (3-4일)

Week 6-12: Phase 3 (선택적)
├── Task 7: Auto-Submit (5-7일)
├── Task 8: Manual Sync (5-7일)
└── Buffer: 테스트 및 조정
```

#### Milestones

| Milestone | Date (예상) | Deliverables | Success Criteria |
|-----------|------------|--------------|------------------|
| **M1: Phase 1 Complete** | Week 2 | State Assertion, Self-Correction, Cursor Mode | 80% Skill 적용, 5회 Self-Correction |
| **M2: Phase 2 Complete** | Week 5 | Knowledge Cache, Questions, Summary | 20% 토큰 절감, 30% 리뷰 단축 |
| **M3: User Validation** | Week 6 | 사용자 피드백 수집 | 4.0/5.0 만족도 |
| **M4: Phase 3 Decision** | Week 7 | Phase 3 구현 여부 결정 | 피드백 기반 Go/No-Go |
| **M5: Full Rollout** | Week 12 | 전체 기능 안정화 | 모든 지표 달성 |

### 7. 결론

#### 7.1 핵심 요약

1. **벤치마킹 결과**: SDD의 Agentic-First Architecture와 vi2의 LLM State Management는 검증된 패턴이며, agent-context에 적용 가능합니다.

2. **철학 통합**: agent-context의 "User Autonomy" 철학을 유지하되, "State Visibility"와 "Feedback Loops"를 추가하여 **"명확한 자율성(Clear Autonomy)"**으로 진화합니다.

3. **ROI 분석**: Phase 1 (State Assertion, Self-Correction, Cursor Mode)의 ROI가 가장 높으며, Phase 2 (Knowledge Cache, Questions, Summary)가 LLM 효율성 향상에 핵심입니다.

4. **리스크 관리**: Progressive rollout과 기본값 유지로 복잡도 증가를 완화하며, 철학 충돌은 "가시성 도구"로 해결합니다.

#### 7.2 권장 실행 계획

**즉시 실행** (Week 1-2):
- ✅ Task 1: State Assertion 패턴 도입
- ✅ Task 2: Self-Correction Protocol 구현
- ✅ Task 3: Cursor Mode 매핑 추가

**단기 실행** (Week 3-5):
- ✅ Task 4: Knowledge Caching 시스템 구축
- ✅ Task 5: Question-Driven Planning 구현
- ✅ Task 6: AI-Optimized Summary 생성

**장기 검토** (Week 6-12):
- ⚠️ Task 7: Automated Execution (사용자 피드백 후 결정)
- ⚠️ Task 8: Manual Change Sync (효과 검증 후 결정)

#### 7.3 예상 성과

| 목표 | 측정 지표 | 개선 목표 |
|------|-----------|-----------|
| **에이전트 신뢰성 향상** | 의도 명확성, Self-Correction 발동 | +58%, 월 5회 이상 |
| **LLM 효율성 향상** | 토큰 사용, Context Window 최적화 | -20% |
| **협업 효율 향상** | MR 리뷰 시간, 요구사항 오해율 | -30%, -67% |
| **사용자 만족도** | 설문 조사 | 4.0/5.0 이상 |

#### 7.4 다음 단계

1. **경영진 승인**: Part I 제안서 기반 의사결정
2. **개발팀 리뷰**: Part II 기술 제안서 검토 및 피드백
3. **Phase 1 착수**: Week 1부터 Task 1, 2, 3 병렬 진행
4. **중간 검토**: Week 2 말 M1 마일스톤 평가
5. **Phase 2 진행**: M1 성공 시 Week 3부터 Task 4, 5, 6 진행

---

**End of Technical Proposal**

---

## 부록

### A. 레퍼런스 프로젝트 링크

- [spec-kit-command-cursor (SDD v3.0)](https://github.com/madebyaris/spec-kit-command-cursor)
- [vibe-coding-v2 (vi2)](https://github.com/paslavsky/vibe-coding-v2)
- [cursor-commands](https://github.com/hamzafer/cursor-commands)

### B. 관련 문서

- [agent-context/why.md](../why.md): 설계 철학
- [agent-context/plan/agent-workflow-system-plan.md](../plan/agent-workflow-system-plan.md): 시스템 계획
- [agent-context/skills/](../skills/): Atomic Skills
- [agent-context/workflows/](../workflows/): Workflow 정의

### C. 용어 정리

| 용어 | 정의 |
|------|------|
| **Agentic-First** | 에이전트가 명시적 역할과 경계를 선언하는 아키텍처 |
| **State Assertion** | 에이전트가 작업 전 자신의 모드와 의도를 출력하는 프로토콜 |
| **Self-Correction** | 에이전트가 실수를 스스로 감지하고 수정하는 프로세스 |
| **Knowledge Caching** | LLM이 기술 결정과 외부 문서를 캐싱하여 재사용하는 기법 |
| **Question-Driven Planning** | 계획 단계에서 질문을 생성하고 답변 후 설계를 갱신하는 방법 |
| **Quick Summary** | AI에 최적화된 간결한 요약 문서 |
| **Clear Autonomy** | 명확한 의도 표현과 자율적 실행을 결합한 패러다임 |
| **Triple-Layer Architecture** | State Visibility, Feedback Loops, Flexible Execution 3계층 구조 |

### D. FAQ

**Q1: State Assertion이 User Autonomy와 충돌하지 않나요?**

A1: State Assertion은 "가시성 도구"로만 사용하며, 에이전트의 의도를 명시할 뿐 사용자를 차단하지 않습니다. 사용자는 여전히 모든 단계에서 개입하고 --force로 오버라이드할 수 있습니다.

**Q2: llm_context.md가 git에 커밋되나요?**

A2: 아니요. llm_context.md는 .gitignore에 포함되며, 작업 완료 후 MR description에 포함되거나 삭제됩니다. 영속 데이터는 여전히 Git commits와 Issue/MR에만 저장됩니다.

**Q3: Phase 3 기능은 필수인가요?**

A3: 아니요. Phase 3 (--auto-submit, Manual Sync)는 선택적 기능이며, 사용자 피드백을 수집한 후 도입 여부를 결정합니다. Phase 1과 2만으로도 충분한 효과를 얻을 수 있습니다.

**Q4: 기존 프로젝트에 어떻게 적용하나요?**

A4: Progressive rollout으로 점진적 도입합니다. 먼저 새 프로젝트에 Phase 1을 적용하고, 안정화 후 기존 프로젝트에 확산합니다. 기존 Skill과 Workflow는 호환성을 유지합니다.

**Q5: 어떤 LLM에서 테스트되었나요?**

A5: SDD와 vi2는 주로 Claude와 GPT-4에서 검증되었습니다. agent-context도 동일 환경에서 테스트할 예정이며, Gemini 등 다른 LLM 호환성도 검토합니다.

---

**문서 메타데이터**:
- 제안일: 2026-01-24
- 작성자: Agent Context Team
- 리뷰어: [Pending]
- 승인자: [Pending]
- 버전: 1.0
- 상태: Draft
- 다음 리뷰: [To be scheduled]

---

**End of Proposal**
