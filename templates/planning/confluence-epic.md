# Confluence Epic Page Template

Confluence에서 Epic 페이지를 작성할 때 사용하는 표준 템플릿입니다.

## Page Title Format

```
[Epic] <Epic Name>
```

**Example**: `[Epic] User Authentication System`

---

## Template Sections

아래 섹션들을 복사하여 Confluence 페이지에 붙여넣기 하세요.

---

### Overview

| Field | Value |
|-------|-------|
| **Owner** | @mention |
| **Initiative** | [Initiative Page Link] |
| **JIRA Epic** | [JIRA Epic URL] |
| **Start Date** | YYYY-MM-DD |
| **Target Date** | YYYY-MM-DD |
| **Status** | Planning / In Progress / Completed / On Hold |

### Objective

이 Epic이 달성하고자 하는 목표를 1-2문장으로 명확하게 기술합니다.

### Acceptance Criteria

Epic 완료 조건을 정의합니다.

- [ ] Criteria 1
- [ ] Criteria 2
- [ ] Criteria 3

### Technical Approach

기술적 접근 방식을 요약합니다.

- Architecture decisions
- Key technologies
- Integration points

### Progress Summary

| Metric | Value |
|--------|-------|
| Total Work Items | N |
| Completed | N |
| In Progress | N |
| Progress | XX% |

> [NOTE] 개별 Work item 목록은 JIRA Epic 링크에서 확인하세요.

### Key Decisions

| Date | Decision | Rationale |
|------|----------|-----------|
| YYYY-MM-DD | Decision 1 | Reason |

### Risks & Dependencies

#### Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Risk 1 | High/Med/Low | Action |

#### Dependencies

| Dependency | Type | Status |
|------------|------|--------|
| [EPIC-XXX](URL) | Blocks | Resolved |
| External API | Waits on | Pending |

### Timeline

```
Week 1-2: Phase 1 - Foundation
Week 3-4: Phase 2 - Implementation
Week 5:   Phase 3 - Testing & Integration
```

### Team

| Role | Name |
|------|------|
| Tech Lead | @mention |
| Developer | @mention |
| QA | @mention |

### References

- [Parent Initiative](URL)
- [Design Document](URL)
- [GitLab MRs](GitLab URL with label/milestone filter)

---

## Usage Notes

1. **JIRA Epic 링크 필수**: 반드시 JIRA Epic URL 포함
2. **Progress Summary만**: 개별 Story/Task 목록은 JIRA에서 확인
3. **정기 업데이트**: 스프린트마다 Progress Summary 업데이트
4. **결정 사항 기록**: 기술적 의사결정을 Key Decisions에 추적

## Related

- [PM Hierarchy Sync Guide](../../docs/guides/pm-hierarchy-sync.md)
- [Confluence Initiative Template](./confluence-initiative.md)
