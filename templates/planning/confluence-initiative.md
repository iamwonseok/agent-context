# Confluence Initiative Page Template

Confluence에서 Initiative 페이지를 작성할 때 사용하는 표준 템플릿입니다.

## Page Title Format

```
[Initiative] <Initiative Name>
```

**Example**: `[Initiative] Q1 2026 Performance Optimization`

---

## Template Sections

아래 섹션들을 복사하여 Confluence 페이지에 붙여넣기 하세요.

---

### Overview

| Field | Value |
|-------|-------|
| **Owner** | @mention |
| **Start Date** | YYYY-MM-DD |
| **Target Date** | YYYY-MM-DD |
| **Status** | Planning / In Progress / Completed / On Hold |
| **JIRA Link** | [JIRA Initiative/Epic URL] |

### Goals

이 Initiative가 달성하고자 하는 목표를 명확하게 기술합니다.

- Goal 1: ...
- Goal 2: ...
- Goal 3: ...

### Success Criteria

성공 여부를 판단할 수 있는 측정 가능한 기준을 정의합니다.

| Criteria | Target | Current |
|----------|--------|---------|
| Metric 1 | value | value |
| Metric 2 | value | value |

### Scope

#### In Scope

- Item 1
- Item 2

#### Out of Scope

- Item 1
- Item 2

### Related Epics

| Epic | Status | Progress | Owner |
|------|--------|----------|-------|
| [EPIC-XXX: Name](JIRA URL) | In Progress | 60% | @mention |
| [EPIC-YYY: Name](JIRA URL) | Planning | 0% | @mention |

> [NOTE] 개별 Work item(Story/Task/Bug) 목록은 여기에 나열하지 않습니다.  
> JIRA Epic 링크를 통해 확인하세요.

### Key Decisions

| Date | Decision | Rationale | Decided By |
|------|----------|-----------|------------|
| YYYY-MM-DD | Decision 1 | Reason | @mention |

### Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation | Owner |
|------|--------|------------|------------|-------|
| Risk 1 | High/Med/Low | High/Med/Low | Action | @mention |

### Timeline

```
Phase 1: [Start] -------- [End]
  |-- Epic A
  |-- Epic B

Phase 2: [Start] -------- [End]
  |-- Epic C
```

또는 Confluence Roadmap Macro 사용을 권장합니다.

### Resources

| Role | Name | Allocation |
|------|------|------------|
| Lead | @mention | 100% |
| Developer | @mention | 50% |

### References

- [Related Confluence Page](URL)
- [GitLab Wiki Runbook](URL) (운영 문서가 있는 경우)
- [External Document](URL)

---

## Usage Notes

1. **Epic 진행률만 요약**: 개별 이슈 나열 금지
2. **JIRA 링크 필수**: Initiative/Epic은 반드시 JIRA 링크 포함
3. **정기 업데이트**: 최소 2주 간격으로 Status 및 Progress 업데이트
4. **결정 사항 기록**: Key Decisions 섹션에 중요 의사결정 추적

## Related

- [PM Hierarchy Sync Guide](../../docs/guides/pm-hierarchy-sync.md)
- [Confluence Epic Template](./confluence-epic.md)
