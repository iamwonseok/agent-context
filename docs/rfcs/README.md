# RFCs (Request for Comments)

Design proposals and implementation plans for agent-context framework.

## Active RFCs

**Last Updated**: 2026-01-27

| # | Title | File | Status | Progress | Priority |
|---|-------|------|--------|----------|----------|
| 002 | Proposal v2.0 | [002-proposal.md](002-proposal.md) | Active | 0% (Meta RFC) | Low |
| 004 | Agent Workflow System v2.0 | [004-agent-workflow-system.md](004-agent-workflow-system.md) | Active | **0%** | **Critical** |
| 005 | Manual Fallback Improvement | [005-manual-fallback-improvement.md](005-manual-fallback-improvement.md) | Active | 20% | High |
| 006 | Unified Platform Abstraction | [006-unified-platform-abstraction.md](006-unified-platform-abstraction.md) | Active | 30% | Medium |
| 007 | Architecture Pattern Improvements | [007-architecture-improvements.md](007-architecture-improvements.md) | Active | 70% | Medium |
| 008 | Domain Extension & Installation | [008-domain-extension.md](008-domain-extension.md) | Active | 30% | Medium |
| 009 | CLI Documentation Policy | [009-cli-documentation-policy.md](009-cli-documentation-policy.md) | Active | 50% | Medium |
| 010 | Agent Efficiency & Best Practices | [010-agent-efficiency-best-practices.md](010-agent-efficiency-best-practices.md) | Active | 60% | High |
| 011 | Language Policy & Internationalization | [011-language-policy.md](011-language-policy.md) | **Complete** | **100%** | Done |
| 012 | Test Planning Framework | [012-test-planning-framework.md](012-test-planning-framework.md) | Active | 40% | High |

### Implementation Summary

**Overall**: 1/10 RFCs fully implemented (10%)

**Breakdown by Status**:
- ✅ Complete: 1 RFC (011)
- 🔄 In Progress: 6 RFCs (005-010, 012)
- ❌ Not Started: 2 RFCs (002, 004)
- 📋 Reference: 1 RFC (002 - meta document)

**Priority Distribution**:
- Critical: 1 RFC (004) - **0% - Needs immediate attention**
- High: 3 RFCs (005, 010, 012)
- Medium: 5 RFCs (006-009)
- Low: 1 RFC (002)

### Next Steps (Priority Order)

1. **P1: Testing Infrastructure** (1-2 weeks)
   - E2E tests implementation
   - Scenario automation
   - Error handling tests
   - See [docs/internal/handoff.md](../internal/handoff.md)

2. **P2: RFC-004 Implementation** (4-6 weeks) **CRITICAL**
   - Phase 1: State Visibility Layer (1-2 weeks)
   - Phase 2: Feedback Loops Layer (1-2 weeks)
   - Most important RFC - core workflow system

3. **P2: RFC-012 Completion** (1 week)
   - Backfill test plans in RFCs 002-009
   - Foundation already complete (40%)

4. **P2: Other RFCs** (As capacity allows)
   - RFC-005: Manual Fallback CLI extensions
   - RFC-006: Platform abstraction completion
   - RFC-008: Installation flow improvements

### Reference Materials

- [Implementation Handoff](../internal/handoff.md) - Detailed task breakdown
- [Feedback Analysis](../../.context/claude-opus-feedback-implementation.md) - Current assessment
- [Future Work](future-work.md) - Long-term enhancements

## Future Work

| Title | File | Description |
|-------|------|-------------|
| Future Work | [future-work.md](future-work.md) | 장기 발전 방향 (Phase 2 완료 후 리뷰) |

## Archived RFCs

See [archive/](archive/) for superseded documents.

## RFC Process

1. Create new RFC file: `NNN-title.md`
2. Write proposal with motivation, design, and implementation plan
3. Review with team
4. Update status as work progresses
5. Move to `archive/` when superseded or completed

## File Naming

- Format: `NNN-descriptive-title.md`
- Use sequential numbers (001, 002, ...)
- Keep titles short but descriptive

## Status Values

| Status | Meaning |
|--------|---------|
| Draft | Work in progress |
| Active | Accepted and being implemented |
| Superseded | Replaced by newer RFC |
| Completed | Fully implemented |
| Rejected | Not accepted |
