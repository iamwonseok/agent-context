# RFCs (Request for Comments)

Design proposals and implementation plans for agent-context framework.

## Active RFCs

**Last Updated**: 2026-01-29

| # | Title | Status | Priority | Notes |
|---|-------|--------|----------|-------|
| 006 | Unified Platform Abstraction | Active | **High** | JIRA/GitLab/Confluence 통합 |
| 008 | Domain Extension & Installation | Active | Medium | 설치 개선 (RFC-013으로 확장) |
| 010 | Agent Efficiency Best Practices | Active | High | 효율성 패턴 |
| 011 | Language Policy | **Complete** | Done | 언어 정책 |
| **013** | **Simplified Installation** | **Draft** | **High** | Tools 전역 설치 + Minimal Core |

## Simplified RFCs (축소)

이전에 과도하게 복잡했던 RFC들을 핵심만 유지:

| # | Title | Status | Notes |
|---|-------|--------|-------|
| 005 | Manual Fallback | Simplified | 핵심: `--skip` 옵션 |
| 007 | Architecture Improvements | Simplified | 핵심: IR (intermediate.yaml) |
| 009 | CLI Documentation Policy | Deferred | 낮은 우선순위 |
| 012 | Test Planning Framework | Simplified | 핵심: E2E Docker 테스트 |

## Priority Order

1. **P1: RFC-013** - Simplified Installation (1주)
   - Tools 전역 설치
   - Minimal core 분리
   - Docker E2E 테스트

2. **P2: RFC-006** - Platform Abstraction 완성
   - JIRA ↔ GitLab ↔ Confluence 동기화

3. **P3: 나머지** - 필요 시

## Archived RFCs

과도하게 복잡하거나 현재 방향과 맞지 않는 RFC:

| # | Title | Archive Reason |
|---|-------|---------------|
| 002 | Proposal v2.0 | 메타 문서, 1100줄 과도 |
| 004 | Agent Workflow System v2.0 | 1100줄 과도, 복잡한 설계 |

See [archive/](archive/) for full documents.

## RFC Process

1. 새 RFC: `NNN-title.md` 생성
2. 핵심만 작성 (200줄 이내 권장)
3. 구현 시작 전 리뷰
4. 완료 시 Status를 Complete로 변경
5. 더 이상 유효하지 않으면 archive/로 이동

## Design Philosophy

From [ARCHITECTURE.md](../../ARCHITECTURE.md):

- **Simplicity Over Completeness**: 단순한 솔루션 우선
- **200줄 예산**: 단일 RFC도 과도하면 분리
- **구현 가능한 범위**: 1-2주 내 구현 가능한 크기
