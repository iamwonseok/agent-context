# PM Hierarchy Sync Guide

PM(Project Management) 계층을 JIRA+Confluence+GitLab 환경에서 일관되게 운영하기 위한 최소 규칙입니다.

## Goals

- **PM 계층은 JIRA 기준으로 안정화**: Work item(Story/Task/Bug)은 JIRA에서만 운영
- **개발 실행은 GitLab에 집중**: 코드/브랜치/MR은 GitLab, JIRA에는 참조 링크만
- **Confluence vs GitLab Wiki 역할 분리**: 문서 용도에 따라 명확히 구분

## Source of Truth (SoT)

| Entity | SoT Location | Notes |
|--------|--------------|-------|
| Initiative | Confluence 페이지 + JIRA Initiative/Epic | 요약/결정/지표 |
| Epic | JIRA Epic | 계층 관리의 기준점 |
| Work Item (Story/Task/Bug) | JIRA Issue | Issue Type으로 구분 |
| Code Review | GitLab MR | 브랜치/커밋/MR |
| Dev Runbook | GitLab Wiki (선택) | 운영 절차/트러블슈팅 |

### Platform Responsibilities

**JIRA**
- Work item의 **Issue Type으로 타입 구분** (라벨로 타입 표현 금지)
- Epic Link/Parent 필드로 **진짜 계층 유지**
- GitLab Issue로 Work item 복제 금지

**GitLab**
- Work item은 만들지 않음 (원칙)
- 브랜치/커밋/MR에 **JIRA Key를 강제 포함**해 추적 가능하게 함
- Milestone/Label은 릴리즈/스프린트 운영이 필요할 때만 사용

**Confluence**
- Initiative/Epic 페이지 템플릿을 고정 (섹션만 표준화)
- 하위 Work item은 링크로만 참조
- "왜/무엇" (목표, 범위, 의사결정, 리스크, 합의)

**GitLab Wiki** (선택)
- "어떻게" (런북, 운영 절차, 트러블슈팅)
- 팀 공용 런북만 유지 (이슈별 페이지 남발 금지)

## Linking Conventions

### Global Key

**JIRA Key를 단일 식별자로 사용**: 예) `G6SOCTC-123`

### Branch Naming

```
<type>/<JIRA-KEY>-<short-title>
```

| Type | Usage |
|------|-------|
| `feat/` | 새 기능 |
| `fix/` | 버그 수정 |
| `refactor/` | 리팩토링 |
| `docs/` | 문서 |
| `chore/` | 기타 |

**Examples**:
- `feat/G6SOCTC-123-user-auth`
- `fix/G6SOCTC-456-login-error`

### MR Title

```
[<JIRA-KEY>] <summary>
```

**Examples**:
- `[G6SOCTC-123] Add user authentication module`
- `[G6SOCTC-456] Fix login timeout issue`

### MR Body (Minimum)

```markdown
## JIRA

<JIRA Issue URL>

## Summary

<2-3줄 변경 요약>
```

### JIRA Issue Link

- 통합 설정이 있으면 자동 노출
- 없으면 수동으로 MR 링크 1개만 첨부

## Operational Checklist

### New Work Start

- [ ] JIRA 이슈 생성 (또는 기존 이슈 확인)
- [ ] 브랜치명에 JIRA Key 포함
- [ ] MR 제목/본문에 JIRA Key 및 URL 포함

### Review/Merge

- [ ] MR 링크를 JIRA에 남김 (자동 연동 없으면 수동)
- [ ] 코드 리뷰 완료 확인
- [ ] JIRA 이슈 상태 업데이트

### Retrospective/Reporting

- [ ] Confluence Initiative 페이지에 Epic 진행률만 요약
- [ ] 개별 이슈 나열 금지 (링크만)
- [ ] GitLab Wiki에는 운영/런북만 업데이트

## Tool Usage Scope

### Allowed

| Command | Platform | Purpose |
|---------|----------|---------|
| `pm issue` | JIRA | 이슈 조회/생성/업데이트 |
| `pm review` | GitLab | MR 관리 |
| `pm wiki` | GitLab | 런북 관리 (필요시) |
| `pm doc` | Confluence | 문서 관리 (Space Key 설정 후) |

### Prohibited (For Now)

- 보드/이니셔티브/에픽을 `pm`으로 전부 만들기 (문서/웹 UI로 충분)
- GitLab에 Work item 복제 동기화
- 자동 상태 동기화 봇

## Anti-Patterns

| Pattern | Problem | Alternative |
|---------|---------|-------------|
| GitLab Issue로 Work item 관리 | 이중 관리, 불일치 | JIRA만 사용 |
| MR에 JIRA Key 누락 | 추적 불가 | 컨벤션 강제 |
| Confluence에 이슈 목록 나열 | 유지보수 불가 | 링크만 |
| GitLab Wiki에 이슈별 페이지 | 난립 | 공용 런북만 |
| Label로 Issue Type 표현 | JIRA 기능 미활용 | Issue Type 사용 |

## Future Considerations

JIRA-GitLab 자동 동기화(웹훅/봇)는 **연 2회 이상 반복되는 고통**이 확인될 때만 검토합니다.

현 단계에서는 링크 기반 참조만으로 충분합니다.

## Related Documents

- [Initiative Workflow](../../workflows/manager/initiative.md)
- [Epic Workflow](../../workflows/manager/epic.md)
- [Confluence Initiative Template](../../templates/planning/confluence-initiative.md)
- [Confluence Epic Template](../../templates/planning/confluence-epic.md)
