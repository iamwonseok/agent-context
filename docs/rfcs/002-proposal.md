# agent-context v2.0 통합 제안서

**제안일**: 2026-01-24  
**작성자**: Agent Context Team  
**문서 버전**: 2.0  
**기반 분석**: Notebook LM Analysis + SDD v3.0 + vi2 framework

---

## Executive Summary

본 제안서는 agent-context 프레임워크를 v2.0으로 진화시키기 위한 통합 계획입니다.

**핵심 패러다임**: "명확한 자율성(Clear Autonomy)"
> 에이전트가 자율적으로 작동하되, 그 의도와 경계를 명확히 표현하여 사용자가 신뢰하고 제어할 수 있는 시스템

**레퍼런스 프로젝트**:
- [spec-kit-command-cursor (SDD v3.0)](https://github.com/madebyaris/spec-kit-command-cursor): Agentic-First Architecture
- [vibe-coding-v2 (vi2)](https://github.com/paslavsky/vibe-coding-v2): LLM State Management
- Ralph Project: Fresh Context Loop (선택적 참고)

**why.md 설계 철학 준수**: ✅ 모든 제안 항목은 5대 원칙과 양립 가능

**예상 효과**:
- 에이전트 의도 명확성: +58% (3.0 → 4.7/5.0)
- Context Window 토큰 절감: 20%
- MR 리뷰 시간 단축: 30%
- 요구사항 오해율 감소: 67% (15% → 5%)

---

## Part I: 현행 시스템 평가 및 개선 방향

### 1. 현행 agent-workflow-system 평가

#### 1.1 강점 분석

**vs Industry Best Practices (Ralph, Cursor Team, SDD, vi2)**

✅ **하이브리드 Git 전략** (최대 강점)
- Interactive Mode (Branch) + Detached Mode (Worktree)
- 백그라운드 병렬 작업 지원 (A/B 테스팅)
- 업계에서 유일무이한 차별화 포인트

✅ **Atomic Skills 구조**
- 5개 카테고리 (analyze, plan, execute, validate, integrate)
- Ralph의 "작은 작업 단위", vi2의 "Curated Agents" 포괄 가능
- 높은 재사용성 및 확장성

✅ **역할 분리**
- Manager vs Developer 워크플로우 분리
- Spec-Kit의 SDD 철학 수용 가능한 구조

✅ **설계 철학 우수성**
- Simplicity Over Completeness
- User Autonomy (warnings + --force)
- Artifacts as State (Git + Files)
- Manual Fallback 지원

#### 1.2 개선 필요 영역

⚠️ **Context Window 관리 부재**
- Rolling Summary 계획만 존재, 미구현
- 동일 설명 반복으로 토큰 낭비
- LLM amnesia 문제 (기술 결정 망각)

⚠️ **에이전트 의도 불명확**
- 암묵적 상태 관리
- 사용자가 에이전트가 무엇을 하는지 추측해야 함
- Mode 위반 사후 발견 (조기 감지 불가)

⚠️ **요구사항 명확화 프로세스 부족**
- parse-requirement 스킬만 존재
- 질문-답변 피드백 루프 부재
- 요구사항 오해로 인한 재작업 발생

⚠️ **Self-Correction 메커니즘 부재**
- 에이전트 실수를 사후에만 발견
- 자율적 오류 감지 및 수정 불가
- Quality gate 효과성 제한적

### 2. 레퍼런스 프로젝트 분석

#### 2.1 spec-kit-command-cursor (SDD v3.0)

**핵심 강점**: Agentic-First Architecture

**주요 패턴**:

1. **State Assertion** (상태 선언)
```
SDD MODE: execute/write-code
Mode: implementation
Purpose: Implement feature code with TDD
Implementation: AUTHORIZED
Boundaries: Will NOT modify requirements, Will NOT skip tests
```

2. **Self-Correction Protocol**
```
DETECT → STOP → CORRECT → RESUME
```

3. **Cursor Mode Integration**
- /brief → Plan Mode
- /research → Ask Mode
- /implement → Agent Mode
- /audit → Debug Mode

4. **AI-Optimized Summary** (quick-prd.md)

**agent-context 적용성**: ✅ 즉시 적용 가능 (구조적으로 호환)

#### 2.2 vibe-coding-v2 (vi2 framework)

**핵심 강점**: LLM State Management

**주요 패턴**:

1. **Knowledge Caching** (llm_context.md)
- 기술 결정 기록
- 외부 문서 요약
- 아키텍처 맥락 저장

2. **Question-Driven Planning** (questions.md)
- 계획 단계에서 질문 생성
- 사용자 답변 수집
- Debrief 사이클로 설계 갱신

3. **Temporary State Directory** (.vi2/)
- 작업 완료 후 삭제
- Issue/MR에 최종 리포트만 업로드

**agent-context 적용성**: ✅ 즉시 적용 가능 (.context/ 구조와 유사)

#### 2.3 Ralph Project

**핵심 강점**: Fresh Context Loop

**주요 패턴**:
- 반복마다 메모리 리셋
- progress.txt와 Git만 기억
- learnings.md 누적
- 무한 재시도

**agent-context 적용성**: ⚠️ Phase 3 검토 (복잡도 증가 우려)

### 3. 통합 방향성

#### 3.1 Triple-Layer Architecture

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

#### 3.2 why.md 철학 준수 검증

| 원칙 | 준수 방법 | 위반 리스크 | 완화 방안 |
|------|----------|------------|----------|
| **Simplicity Over Completeness** | Progressive rollout, 기본값 유지 | Phase 2-3 복잡도 증가 | 옵트인, Complexity Budget 준수 (Skill 200 lines) |
| **User Autonomy** | State Assertion = 가시성만, --force 유지 | Self-Correction 자동 revert | 제안으로만, 강제 없음 |
| **Feedback Over Enforcement** | DETECT→STOP→CORRECT→RESUME 투명화 | 없음 | - |
| **Composability** | Skill 구조 유지 | 없음 | - |
| **Artifacts as State** | llm_context.md (임시), Git은 SSOT | .context/ 증가 | MR 후 삭제, .gitignore |

**결론**: ✅ 모든 Phase 1-2 제안은 철학과 충돌 없음. Phase 3는 신중한 검토 필요.

---

## Part II: 기술 제안서

### Phase 1: 핵심 패턴 도입 (1-2주, ROI ★★★★★)

#### Task 1: State Assertion 패턴 도입

**목표**: 에이전트가 작업 전 역할, 모드, 경계를 명시하도록 강제

**구현 파일**:

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
- Mode 위반 시각적 감지
- 에이전트 신뢰도 향상

#### Task 2: Self-Correction Protocol 구현

**목표**: 에이전트가 실수를 조기 감지하고 자동 수정

**구현 파일**:

1. **`skills/validate/check-intent/SKILL.md` 업데이트**:

```markdown
# Intent Verification

## Self-Correction Protocol

### Trigger Conditions

1. **Mode Violations**:
   - DETECT: Code changes in planning mode
   - DETECT: Requirement changes in implementation mode
   - DETECT: Skipped quality gates

2. **Workflow Violations**:
   - DETECT: Commit without tests
   - DETECT: Submit without verify
   - DETECT: Design without requirements

### Self-Correction Flow

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
```

2. **`tools/agent/lib/checks.sh` 업데이트**:

```bash
#!/bin/bash

detect_mode_violation() {
    local task_id="$1"
    local context_dir=".context/$task_id"
    
    local current_mode=$(cat "$context_dir/mode.txt" 2>/dev/null || echo "unknown")
    local git_changes=$(git status --short | wc -l)
    
    case "$current_mode" in
        planning)
            if [[ "$git_changes" -gt 0 ]]; then
                echo "VIOLATION: Code changes detected in planning mode"
                return 1
            fi
            ;;
        implementation)
            if git diff --name-only | grep -q "design/\|plan/"; then
                echo "VIOLATION: Requirement changes in implementation mode"
                return 1
            fi
            ;;
        verification)
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
    
    git stash push -m "self-correction: $violation"
    echo "RESUME: Please specify correct mode and retry"
}

export -f detect_mode_violation
export -f self_correct
```

**예상 효과**:
- 실수 즉시 감지 및 자동 복구
- 재작업 시간 감소
- Quality gate 효과성 향상

#### Task 3: Cursor Mode 매핑

**목표**: Workflow와 Skill에 최적 Cursor Mode 매핑

**구현**:

1. **모든 Workflow/Skill에 `cursor_mode` 필드 추가**

```yaml
# workflows/developer/feature.md
---
cursor_mode: agent  # Overall workflow mode
skills:
  - analyze/parse-requirement     # cursor_mode: ask
  - plan/design-solution          # cursor_mode: plan
  - execute/write-code            # cursor_mode: agent
  - validate/run-tests            # cursor_mode: debug
---
```

2. **`docs/cursor-modes-guide.md` 생성**:

```markdown
# Cursor Mode Integration Guide

## Mode Mapping

| Cursor Mode | Purpose | agent-context Commands | When to Use |
|-------------|---------|------------------------|-------------|
| **Plan** | Create specs without code changes | agent dev design, agent dev plan | Designing solutions |
| **Ask** | Read-only exploration | agent dev analyze | Understanding requirements |
| **Agent** | Full multi-file changes | agent dev code, agent dev submit | Writing code |
| **Debug** | Runtime evidence + spec audit | agent dev check (extended) | Testing, debugging |

## Workflow Mode Recommendations

| Workflow | Primary Mode | Phase-specific Modes |
|----------|--------------|----------------------|
| feature | Agent | Ask (analyze) → Plan (design) → Agent (code) → Debug (test) |
| bug-fix | Debug | Ask (logs) → Agent (fix) → Debug (verify) |
| hotfix | Agent | Agent (fast) → Debug (critical tests) |
| refactor | Agent | Plan (plan) → Agent (refactor) → Debug (regression test) |
```

**예상 효과**:
- Cursor IDE 기능 최적 활용
- 사용자 경험 향상
- 작업 효율 증가

**Phase 1 완료 기준**:
- ✅ State Assertion 출력 확인
- ✅ Self-Correction 동작 확인
- ✅ Cursor Mode 가이드 문서 완성
- ✅ 모든 Workflow/Skill에 `cursor_mode` 필드 존재

---

### Phase 2: Context 관리 개선 (2-3주, ROI ★★★★☆)

#### Task 4: Knowledge Caching (llm_context.md)

**목표**: LLM 효율성 향상을 위한 기술 결정 및 외부 문서 캐싱

**파일 구조**:

```markdown
# llm_context.md

## Technical Decisions
- Decision 1: {What, Why, Trade-offs, Alternatives}
- Decision 2: ...

## External References
- Library X: {Key APIs, Best Practices, Gotchas}

## Architecture Context
- Component overview
- Data flow

## Patterns to Follow
- Pattern 1: {Code example, When to use}

## Patterns to Avoid
- Anti-pattern 1: {Problem, Instead do}
```

**구현**:

1. **`tools/agent/lib/context.sh` 업데이트**:

```bash
create_llm_context() {
    local task_id="$1"
    local context_dir=".context/$task_id"
    local llm_context="$context_dir/llm_context.md"
    
    mkdir -p "$context_dir"
    cp "$TEMPLATES_DIR/llm_context.md" "$llm_context"
    
    sed -i.bak "s/{TASK_ID}/$task_id/g" "$llm_context"
    sed -i.bak "s/{DATE}/$(date +%Y-%m-%d)/g" "$llm_context"
    rm "$llm_context.bak"
    
    echo "[INFO] Created llm_context.md for $task_id"
}

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

EOF
}
```

**사용 시나리오**:

```bash
# 1. Start task
agent dev start TASK-123
# → llm_context.md created

# 2. Design phase - Agent asks technical questions
agent dev design
# → Agent records decisions in llm_context.md

# 3. Later in same task - No need to re-ask
agent dev code
# → Agent reads llm_context.md
# → Implements based on recorded decisions
```

**예상 효과**:
- 평균 20% 토큰 사용 감소
- 동일 질문 반복 제거
- LLM amnesia 방지

#### Task 5: Question-Driven Planning (questions.md)

**목표**: 계획 단계에서 명확화가 필요한 항목을 구조화된 질문으로 관리

**파일 구조**:

```markdown
# questions.md

## Planning Questions

### Requirements Clarification
- [ ] Q1: {Question about requirements}
      Context: {Why this matters}
      Answer: [Your answer here]

### Technical Decisions
- [ ] Q2: {Question about tech stack}
      Options: {A, B, C}
      Answer: [Your answer]

## Blockers
- [ ] B1: {Blocker description}
      Resolution: {How to resolve}
```

**워크플로우**:

```bash
# 1. Analyze - Agent generates questions
agent dev analyze
# → questions.md created

# 2. User answers questions
vim .context/TASK-123/questions.md

# 3. Debrief - Agent updates design based on answers
agent dev debrief
# → design/*.md updated
# → llm_context.md updated with decisions
```

**예상 효과**:
- 요구사항 오해율 15% → 5%
- 명확한 피드백 루프
- 설계 품질 향상

#### Task 6: AI-Optimized Summary (quick-summary.md)

**목표**: MR 제출 전 AI에 최적화된 간결한 요약 생성

**파일 구조**:

```markdown
# Quick Summary: TASK-123

## Goal
{Brief description}

## Key Changes
- File 1 (120 insertions)
- File 2 (80 insertions)

## Technical Decisions
- Decision 1
- Decision 2

## Verification
- Lint: PASS
- Tests: PASS (100% coverage)
- Requirements: Met (3/3)

## Impact
- Files changed: 3
- Insertions: 215
- Deletions: 10
```

**구현**:

```bash
generate_quick_summary() {
    local task_id="$1"
    local context_dir=".context/$task_id"
    local quick_summary="$context_dir/quick-summary.md"
    
    # Extract key information from llm_context.md
    local goal=$(grep "^Goal:" "$context_dir/llm_context.md" | cut -d: -f2- | xargs)
    local decisions=$(grep -A3 "^### Decision:" "$context_dir/llm_context.md" | grep "Decision:" | cut -d: -f2- | head -3)
    
    # Generate concise summary
    # ...
}
```

**예상 효과**:
- MR description 간결화
- 리뷰어 이해도 향상
- 리뷰 시간 평균 30% 단축

**Phase 2 완료 기준**:
- ✅ llm_context.md 생성 확인
- ✅ questions.md + debrief 워크플로우 동작
- ✅ quick-summary.md 생성 확인
- ✅ MR description에 quick-summary 포함

---

### Phase 3: 선택적 기능 추가 (장기 검토, ROI ★★★☆☆)

> **Note**: Phase 3 상세 내용은 [future-work.md](future-work.md)로 이동되었습니다.
> Phase 2 완료 후 일괄 리뷰 예정입니다.

#### Task 7: Automated Execution (--auto-submit)

**철학적 고려사항**:
- ⚠️ User Autonomy와 충돌 가능
- ✅ 선택적 기능으로 제공
- ✅ 기본값은 단계별 승인 유지

**구현**:

```bash
cmd_dev_start() {
    local task_id="$1"
    local auto_submit=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto-submit)
                auto_submit=true
                shift
                ;;
        esac
    done
    
    if [[ "$auto_submit" == "true" ]]; then
        echo "[INFO] Auto-submit mode enabled"
        auto_execute_workflow "$task_id"
    fi
}
```

**리스크**:
- 중간 단계 검토 불가 → 품질 저하 가능
- 완화: 에러 발생 시 즉시 중단

**권장사항**: ⚠️ 사용자 피드백 수집 후 결정

#### Task 8: Fresh Context Loop (Ralph-inspired)

**목표**: Detached Mode에서 무한 재시도 구현

**철학적 고려사항**:
- ⚠️ Simplicity 충돌 (복잡도 증가)
- ✅ Detached Mode 전용으로 제한
- ✅ 옵트인 방식 (--loop 플래그)

**권장사항**: ⚠️ Complexity Budget 검증 후 결정

---

## Part III: 통합 분석 및 철학적 검증

### 1. why.md 설계 철학 vs 제안서 충돌 분석

| 원칙 | Notebook LM 제안 | docs/proposal.md | 충돌 여부 | 통합 방안 |
|------|------------------|------------------|----------|----------|
| **Simplicity Over Completeness** | Ralph 루프 (복잡도 증가) | Triple-Layer (점진적 추가) | ⚠️ Phase 3 주의 | 옵트인, Phase 분리 |
| **User Autonomy** | SDD Plan-Approve (강제) | State Assertion (가시성만) | ✅ proposal 우수 | Soft enforcement, --force 유지 |
| **Feedback Over Enforcement** | 감사 강화 | Self-Correction (제안) | ✅ 양립 가능 | 피드백 루프로 구현 |
| **Composability** | 유지 | Skill 기반 유지 | ✅ 충돌 없음 | 현행 구조 유지 |
| **Artifacts as State** | learnings.md 추가 | llm_context.md 추가 | ✅ 충돌 없음 | 임시 파일, .gitignore |

**결론**: ✅ Phase 1-2는 철학과 완전 양립. Phase 3는 신중한 검토 필요.

### 2. Manual Fallback 유지성 검증

모든 Agent 기능은 Manual 대안 제공:

| Agent 기능 | Manual 대안 | Agent 추가 가치 |
|-----------|------------|----------------|
| State Assertion 출력 | Skill YAML 직접 읽기 | 자동 출력, 시각적 표시 |
| llm_context.md | 수동 작성 가능 | AI 자동 생성 |
| questions.md | vim으로 작성 | AI 질문 생성 |
| agent dev debrief | 수동으로 design/*.md 갱신 | AI 자동 갱신 |
| Self-Correction | 수동 git stash | 자동 감지 및 제안 |

**Hybrid 접근 권장**: `git checkout -b` → `agent dev check` → `agent dev submit`

### 3. Complexity Budget 검증

| 구성요소 | 예산 (why.md) | Phase 1-2 예상 | 초과 시 조치 |
|---------|--------------|---------------|------------|
| Skill | 200 lines | 150-180 | 분리 |
| Workflow | 100 lines | 80-100 | 유지 |
| CLI command | 100 lines | 120 | ⚠️ 리팩토링 필요 |
| context.sh | 300 lines | 280 | 유지 |

**결론**: Phase 1-2는 예산 내. CLI command만 경계선 → 모듈화 권장.

### 4. 제안서 비교 분석

**공통점**:
- SDD (Spec-Kit)의 State Assertion 도입
- vi2의 Knowledge Caching 도입
- Context Window 관리 강화
- 요구사항 명확화 중요성

**차이점**:

| 측면 | Notebook LM | docs/proposal.md | 통합 방안 |
|------|-------------|------------------|----------|
| **깊이** | 개념적, 방향성 제시 | 구체적 구현 계획 + 코드 | proposal.md를 실행 기반으로 |
| **범위** | 더 넓음 (Ralph, OpenCode) | SDD, vi2 집중 | Ralph/OpenCode는 Phase 3 |
| **실행성** | 컨셉 단계 | 즉시 실행 가능 | proposal.md 우선 실행 |
| **철학 통합** | Gap 언급만 | "Clear Autonomy" 제시 | 패러다임 채택 |
| **로드맵** | Phase 구분만 | 12주 타임라인 | 구체적 일정 사용 |

**통합 결론**: 
- Notebook LM → 방향성 및 아이디어 제공
- docs/proposal.md → 실행 계획 및 코드
- 두 제안서는 **보완 관계**, 충돌 없음

---

## Part IV: 최종 권고사항

### 1. 즉시 실행 (Week 1-2)

**Phase 1: 핵심 패턴 도입**

✅ **Task 1**: State Assertion 패턴
- Skill 템플릿 업데이트
- executor.sh 수정
- .cursorrules 추가

✅ **Task 2**: Self-Correction Protocol
- check-intent SKILL.md 업데이트
- checks.sh 구현
- agent dev check 통합

✅ **Task 3**: Cursor Mode 매핑
- Workflow/Skill에 cursor_mode 필드
- cursor-modes-guide.md 생성

**성공 지표**:
- State Assertion 활용률 80% 이상
- Self-Correction 월 5회 이상 발동
- 사용자 설문: 에이전트 의도 명확성 평가

### 2. 단기 실행 (Week 3-5)

**Phase 2: Context 관리 개선**

✅ **Task 4**: Knowledge Caching
- llm_context.md 템플릿 생성
- context.sh 함수 추가
- agent dev start/design/check 통합

✅ **Task 5**: Question-Driven Planning
- questions.md 템플릿 생성
- agent dev debrief 명령 추가
- parse-requirement 스킬 업데이트

✅ **Task 6**: AI-Optimized Summary
- quick-summary.md 생성 함수
- agent dev verify/submit 통합

**성공 지표**:
- Context Window 토큰 20% 절감
- MR 리뷰 시간 30% 단축
- 요구사항 오해율 67% 감소 (15% → 5%)

### 3. 장기 검토 (Week 6-12, 선택적)

**Phase 3: 선택적 기능 추가**

⚠️ **Task 7**: Automated Execution (--auto-submit)
- **철학 충돌**: User Autonomy
- **완화 방안**: 기본값 비활성화, 명시적 플래그
- **결정 시점**: Phase 2 완료 후 사용자 피드백 수집

⚠️ **Task 8**: Fresh Context Loop (Ralph)
- **철학 충돌**: Simplicity (복잡도 증가)
- **완화 방안**: Detached Mode 전용, 옵트인
- **결정 시점**: Complexity Budget 검증 후

⚠️ **Task 9**: LSP-based Validation (OpenCode)
- **철학 충돌**: Simplicity (새 도구 의존성)
- **완화 방안**: 선택적 도입, 기존 lint 우선
- **결정 시점**: Phase 2 효과 검증 후

**Phase 3 Go/No-Go 기준**:
- Phase 2 성공 지표 달성
- 사용자 만족도 4.0/5.0 이상
- Complexity Budget 여유 확인

### 4. 구현 로드맵

```
Week 1-2: Phase 1 (병렬 진행)
├── Task 1: State Assertion (3-4일)
├── Task 2: Self-Correction (3-4일)
└── Task 3: Cursor Mode (2-3일)
Milestone M1: Phase 1 Complete

Week 3-5: Phase 2 (순차 진행)
├── Task 4: Knowledge Caching (4-5일)
├── Task 5: Question Planning (4-5일)
└── Task 6: Quick Summary (3-4일)
Milestone M2: Phase 2 Complete

Week 6: User Validation
└── 피드백 수집, Phase 3 Go/No-Go 결정
Milestone M3: User Validation

Week 7-12: Phase 3 (선택적, Go 시)
├── Task 7: Auto-Submit (5-7일)
├── Task 8: Fresh Context Loop (5-7일)
└── Buffer: 테스트 및 조정
Milestone M4: Full Rollout (조건부)
```

### 5. 리스크 관리

| 리스크 | 확률 | 영향 | 완화 방안 | 담당 |
|--------|------|------|-----------|------|
| Phase 2 복잡도 증가 | 중간 | 중간 | Progressive rollout, 선택적 기능 | Dev Team |
| Phase 3 Autonomy 충돌 | 낮음 | 높음 | 기본값 비활성화, 사용자 피드백 | Architect |
| Context 파일 증가 | 중간 | 낮음 | MR 후 정리, .gitignore | Dev Team |
| 사용자 학습 부담 | 중간 | 낮음 | Manual 대안 제공, Hybrid 권장 | Doc Team |
| LLM 호환성 문제 | 낮음 | 중간 | Claude, GPT-4, Gemini 테스트 | QA Team |

### 6. 성공 지표 측정 계획

**Phase 1 (Week 2)**:
- State Assertion 활용률: 80% 이상
- Self-Correction 발동: 월 5회 이상
- 사용자 설문: 의도 명확성 4.7/5.0

**Phase 2 (Week 5)**:
- 토큰 절감: 평균 20%
- 리뷰 시간 단축: 평균 30%
- 요구사항 오해율: 5% 이하

**Phase 3 (Week 12, 조건부)**:
- --auto-submit 사용률: 전체 작업 중 20% 이상
- 사용자 만족도: 4.0/5.0 이상

---

## 결론

### 핵심 요약

1. **레퍼런스 프로젝트 분석**: SDD와 vi2는 검증된 패턴이며, agent-context에 즉시 적용 가능

2. **철학 통합**: why.md의 5대 원칙을 유지하며 "명확한 자율성(Clear Autonomy)"으로 진화

3. **ROI 분석**: Phase 1-2의 ROI가 가장 높으며, Phase 3는 선택적 검토

4. **리스크 관리**: Progressive rollout과 기본값 유지로 복잡도 증가 완화

5. **Manual Fallback 유지**: 모든 Agent 기능은 Manual 대안 제공

### 권장 실행 계획

**즉시 착수** (Week 1):
- Phase 1 Task 1-3 병렬 진행
- State Assertion, Self-Correction, Cursor Mode

**중간 검토** (Week 2):
- M1 마일스톤 평가
- Phase 2 진행 여부 결정

**단기 실행** (Week 3-5):
- Phase 2 Task 4-6 순차 진행
- Knowledge Caching, Questions, Summary

**사용자 검증** (Week 6):
- 피드백 수집
- Phase 3 Go/No-Go 결정

**장기 검토** (Week 7-12, 조건부):
- Phase 3 Task 7-8 진행 (Go 시)
- Automated Execution, Fresh Context Loop

### 예상 성과

| 목표 | 측정 지표 | 개선 목표 |
|------|-----------|-----------|
| **에이전트 신뢰성 향상** | 의도 명확성, Self-Correction 발동 | +58%, 월 5회 이상 |
| **LLM 효율성 향상** | 토큰 사용, Context Window 최적화 | -20% |
| **협업 효율 향상** | MR 리뷰 시간, 요구사항 오해율 | -30%, -67% |
| **사용자 만족도** | 설문 조사 | 4.0/5.0 이상 |

### 다음 단계

1. ✅ **경영진 승인**: 본 제안서 검토 및 의사결정
2. ✅ **개발팀 리뷰**: 기술 제안서 검토 및 피드백
3. ✅ **Phase 1 착수**: Week 1부터 Task 1-3 병렬 진행
4. ✅ **중간 검토**: Week 2 말 M1 마일스톤 평가
5. ✅ **Phase 2 진행**: M1 성공 시 Week 3부터 진행

---

## 부록

### A. 레퍼런스 프로젝트 링크

- [spec-kit-command-cursor (SDD v3.0)](https://github.com/madebyaris/spec-kit-command-cursor)
- [vibe-coding-v2 (vi2)](https://github.com/paslavsky/vibe-coding-v2)
- [Ralph Project](https://github.com/snarktank/ralph)
- [cursor-commands](https://github.com/hamzafer/cursor-commands)

### B. 관련 문서

- [why.md](../why.md): 설계 철학
- [plan/agent-workflow-system-plan.md](../plan/agent-workflow-system-plan.md): 현행 시스템 계획
- [docs/manual-fallback-guide.md](manual-fallback-guide.md): Manual Fallback 가이드
- [skills/](../skills/): Atomic Skills
- [workflows/](../workflows/): Workflow 정의

### C. 용어 정리

| 용어 | 정의 |
|------|------|
| **Clear Autonomy** | 명확한 의도 표현과 자율적 실행을 결합한 패러다임 |
| **State Assertion** | 에이전트가 작업 전 자신의 모드와 의도를 출력하는 프로토콜 |
| **Self-Correction** | 에이전트가 실수를 스스로 감지하고 수정하는 프로세스 |
| **Knowledge Caching** | LLM이 기술 결정과 외부 문서를 캐싱하여 재사용하는 기법 |
| **Question-Driven Planning** | 계획 단계에서 질문을 생성하고 답변 후 설계를 갱신하는 방법 |
| **Triple-Layer Architecture** | State Visibility, Feedback Loops, Flexible Execution 3계층 구조 |

### D. FAQ

**Q1: State Assertion이 User Autonomy와 충돌하지 않나요?**

A1: State Assertion은 "가시성 도구"로만 사용하며, 에이전트의 의도를 명시할 뿐 사용자를 차단하지 않습니다. 사용자는 여전히 --force로 오버라이드할 수 있습니다.

**Q2: llm_context.md가 git에 커밋되나요?**

A2: 아니요. llm_context.md는 .gitignore에 포함되며, 작업 완료 후 MR description에 포함되거나 삭제됩니다.

**Q3: Phase 3 기능은 필수인가요?**

A3: 아니요. Phase 3는 선택적이며, 사용자 피드백을 수집한 후 도입 여부를 결정합니다.

**Q4: 기존 프로젝트에 어떻게 적용하나요?**

A4: Progressive rollout으로 점진적 도입합니다. 먼저 새 프로젝트에 Phase 1을 적용하고, 안정화 후 기존 프로젝트에 확산합니다.

**Q5: Manual Fallback은 계속 유지되나요?**

A5: 예. 모든 Agent 기능은 Manual 대안을 제공하며, Hybrid 접근 (Manual + Agent 조합)을 권장합니다.

---

---

## Test Plan

### Test Strategy

**Scope:**
- Phase 1: State Assertion, Self-Correction, Cursor Mode Integration
- Phase 2: Knowledge Caching, Question-Driven Planning
- Phase 3: Automated Execution (optional)

**Levels:**
- Unit: Individual function tests (executor.sh, checks.sh, context.sh)
- Integration: Full workflow tests (agent dev start → submit)
- E2E: Scenario-based validation

### Test Cases

| ID | Phase | Component | Test Case | Expected |
|----|-------|-----------|-----------|----------|
| UT-1 | 1 | State Assertion | Skill outputs mode info | Mode/Purpose/Boundaries displayed |
| UT-2 | 1 | Self-Correction | detect_mode_violation() | Returns error on planning mode with code changes |
| UT-3 | 2 | Knowledge Caching | create_llm_context() | llm_context.md created |
| UT-4 | 2 | Questions | create_questions() | questions.md created |
| IT-1 | 1 | Workflow | feature workflow with State Assertion | All skills output state info |
| IT-2 | 2 | Workflow | debrief command | design/*.md updated from answers |

### Success Criteria

**Must Have:**
- [ ] State Assertion output on all skill executions
- [ ] Self-Correction detects mode violations
- [ ] Knowledge caching reduces token usage

**Should Have:**
- [ ] User satisfaction score >= 4.0/5.0
- [ ] Token reduction >= 20%

### Validation Checklist

- [ ] Phase 1 tests pass
- [ ] Phase 2 tests pass
- [ ] Philosophy compliance verified
- [ ] Manual fallback documented

---

## Implementation Status

> Quick reference for next session. See each Phase section for details.

| Phase | Status | Priority Tasks |
|-------|--------|----------------|
| Phase 1 | Pending | State Assertion, Self-Correction, Cursor Mode Integration |
| Phase 2 | Pending | Knowledge Caching, Question-Driven Planning |
| Phase 3 | Roadmap | Agentic CI/CD (optional) |

**Related RFC**: [005-manual-fallback-improvement.md](005-manual-fallback-improvement.md) for CLI enhancements

---

**문서 메타데이터**:
- 제안일: 2026-01-24
- 작성자: Agent Context Team
- 버전: 2.0
- 상태: Draft
- 기반 분석: Notebook LM + SDD v3.0 + vi2 framework + why.md 철학 검증

---

**End of Proposal v2.0**
