# Handoff: agent-context Framework Development

**Date**: 2026-01-26  
**Previous Agent**: Claude Opus 4.5

---

## Completed Work

### RFC-009: CLI Documentation Policy (Phase 0 Complete)

- [x] `docs/cli/pm.md` 생성 (NAME/SYNOPSIS/QUICK START/COMMANDS/EXAMPLES/SEE ALSO)
- [x] `docs/cli/README.md`의 Tools 표에 `pm` 추가
- [x] `tools/pm/README.md` 상단에 "User manual: `docs/cli/pm.md`" 링크 추가

**결과**: 사용자용 CLI 문서의 정본을 `docs/cli/`로 통일하는 Phase 0 완료

---

## Remaining Work (Priority Order)

### 1. RFC-009: Phase 1-2 (CLI Documentation Policy)

**Phase 1: Content Split**
- [ ] `tools/pm/README.md`에서 사용자용 섹션을 `docs/cli/pm.md`로 이동
- [ ] `tools/lint/README.md`와 `docs/cli/lint.md` 역할 분리

**Phase 2: Consistency Polish**
- [ ] `docs/cli/*` 문서의 섹션 템플릿 통일 (NAME/SYNOPSIS/QUICK START/COMMANDS/CONFIG/EXAMPLES/SEE ALSO)
- [ ] 상호 링크 정책 확립

---

### 2. RFC-005: Manual Fallback Improvement (Active)

**Phase 0: 문서 정비 (코드 변경 없음)**
| Task | 내용 | 상태 |
|------|------|------|
| 0-1 | `docs/manual-fallback-guide.md` 작성 | [ ] |
| 0-2 | 시나리오 템플릿 표준화 (6개 시나리오에 Manual Flow 추가) | [ ] |
| 0-3 | 워크플로우 Implementation Status 표기 | [ ] |

**Phase 1: 최소 CLI 확장 (~170 LOC)**
| Task | 내용 | 상태 |
|------|------|------|
| 1-1 | `agent dev submit --only/--skip` 옵션 확장 | [ ] |
| 1-2 | Pre-commit Hook 관리 (`--install-hook`) | [ ] |
| 1-3 | 짧은 Alias 추가 (`agent sync`, `agent check`) | [ ] |
| 1-4 | Jira Assignee 할당 + CSV 일괄 생성 | [ ] |

**Phase 2: 검증 테스트**
| Task | 내용 | 상태 |
|------|------|------|
| 2-1 | Manual only 테스트 | [ ] |
| 2-2 | P1 회귀 테스트 | [ ] |

---

### 3. RFC-004: Agent Workflow System v2.0 (Active)

**Phase 1: State Visibility Layer**
| Task | 내용 | 예상 소요 | 상태 |
|------|------|----------|------|
| 1.1 | State Assertion 패턴 구현 | 3-4일 | [ ] |
| 1.2 | Self-Correction Protocol 구현 | 3-4일 | [ ] |
| 1.3 | Cursor Mode Integration | 2-3일 | [ ] |

**Phase 2: Feedback Loops Layer**
| Task | 내용 | 예상 소요 | 상태 |
|------|------|----------|------|
| 2.1 | Knowledge Caching (llm_context.md) | 4-5일 | [ ] |
| 2.2 | Question-Driven Planning (questions.md) | 4-5일 | [ ] |
| 2.3 | AI-Optimized Summary (quick-summary.md) | 3-4일 | [ ] |

**Phase 3**: 조건부 (Phase 2 완료 후 Go/No-Go 결정)

---

### 4. Draft RFCs (미착수)

| RFC | 제목 | 상태 | 비고 |
|-----|------|------|------|
| 006 | Unified Platform Abstraction | Draft | GitLab/GitHub/Jira 추상화 |
| 007 | Architecture Pattern Improvements | Draft | VCS 추상화, Skill Executor 등 |
| 008 | Domain Extension & Installation | Draft | 도메인별 확장 패키지 |

---

### 5. Future Work (Phase 2 완료 후 검토)

| ID | 제목 | 우선순위 | 관련 RFC |
|----|------|----------|----------|
| FW-1 | Autonomous Loop Mode (--loop) | 중 | RFC-004 |
| FW-2 | LSP-based Validation | 중 | RFC-004 |
| FW-3 | Automated Execution (--auto-submit) | 낮 | RFC-004 |
| FW-4 | MCP Server 통합 | 낮 | - |
| FW-5 | Multi-Agent Coordination | 최하위 | - |
| FW-6 | VCS Abstraction Layer | 낮 | RFC-007 |
| FW-7 | Skill Executor Abstraction | 낮 | RFC-007 |
| FW-8 | AOP-style Aspects | 중 | RFC-007 |
| FW-9 | Domain Extension Ecosystem | RFC-008 후 | RFC-008 |
| FW-10 | Retrospective Skill | RFC-008 후 | RFC-008 |

---

## Recommended Work Order

```
1. RFC-004 Phase 1 (State Visibility Layer)
   └── Agent 워크플로우의 핵심 패턴 구현
   └── State Assertion, Self-Correction, Cursor Mode Integration

2. RFC-004 Phase 2 (Feedback Loops Layer)
   └── Knowledge Caching, Question-Driven Planning, Quick Summary

3. RFC-005 (Manual Fallback)
   └── RFC-004 완료 후 agent 워크플로우 기반으로 Manual 버전 문서화
   └── Agent가 하는 일이 명확해야 Manual 대안을 정리 가능

4. RFC-009 Phase 1-2 (CLI Documentation)
   └── Content Split + Consistency Polish
   └── 급하지 않음 (Phase 0 Stub으로 충분)

5. Draft RFCs 검토 (006, 007, 008)
   └── 필요성 재평가 후 Active 전환

6. Future Work 리뷰
   └── Phase 2 완료 후 일괄 검토
```

### 순서 변경 이유

RFC-005 (Manual Fallback)는 "agent가 하는 일의 수동 버전"을 문서화하는 것이므로,
**먼저 RFC-004로 agent 워크플로우가 완성되어야** 그에 대응하는 Manual 방법을 정리할 수 있음.

---

## Key Context

### RFC 상태 요약

| RFC | 제목 | 상태 | 진행률 |
|-----|------|------|--------|
| 002 | Proposal v2.0 | Active | 기준 문서 |
| 004 | Agent Workflow System v2.0 | Active | 0% (Phase 1 미착수) |
| 005 | Manual Fallback Improvement | Active | 0% (Phase 0 미착수) |
| 006 | Unified Platform Abstraction | Draft | 0% |
| 007 | Architecture Improvements | Draft | 0% |
| 008 | Domain Extension | Draft | 0% |
| 009 | CLI Documentation Policy | Draft | **Phase 0 완료** |

### 설계 원칙 (ARCHITECTURE.md)

- **Simplicity Over Completeness**: 단순한 솔루션 우선
- **User Autonomy**: 경고 + --force로 사용자 선택권 보장
- **Feedback Over Enforcement**: 강제보다 피드백
- **Composability**: 작은 Skill의 조합
- **State Through Artifacts**: Git + 파일 기반 상태 관리

### Complexity Budget (라인 제한)

| 컴포넌트 | 제한 |
|----------|------|
| Single Skill | 200 lines |
| Workflow | 100 lines |
| CLI command | 100 lines |
| Helper library | 300 lines |

---

## Notes for Next Agent

1. **RFC-004가 최우선**: Agent 워크플로우 구현이 먼저 (Phase 1 약 1주일 소요)
2. **RFC-005는 RFC-004 이후**: Agent가 하는 일이 명확해야 Manual 버전 문서화 가능
3. **RFC-009 Phase 1은 선택적**: 현재 pm.md Stub이 충분하면 지연 가능
4. **Draft RFC들은 급하지 않음**: Active RFC 진행 중 필요성 확인 후 전환

---

**Delete this handoff after taking over and understanding context.**
