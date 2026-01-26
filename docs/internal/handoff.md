# Handoff: RFC-009 CLI Documentation Policy

**Date**: 2026-01-26  
**Branch**: `chore/cli-docs-structure-plan`  
**Previous Agent**: Claude Opus 4.5

---

## Completed Work

### 1. RFC-009 작성 및 검토

- RFC 초안 생성 (Gemini 피드백 기반)
- ARCHITECTURE.md 및 .cursorrules 기준으로 검토 완료
- 최종 수정 반영

### 2. RFC-009 수정 사항

| 항목 | 변경 내용 |
|------|----------|
| 파일명 | `009-cli-documentation-unification.md` → `009-cli-documentation-policy.md` |
| 제목 | "CLI Documentation Unification" → "CLI Documentation Policy" |
| Related | `ARCHITECTURE.md` 추가 |
| Section 2.3 | "설계 원칙과의 정합" 신규 추가 |
| 용어 통일 | "구현/유지보수 문서" → "구현/내부 문서 (Implementation Notes)" |

### 3. 파일 변경 목록

```
 M docs/rfcs/README.md                      # 009 제목/링크 업데이트
 A docs/rfcs/009-cli-documentation-policy.md # RFC 신규 생성
```

---

## Remaining Work

### Phase 0 (RFC-009 구현)

RFC-009 Section 5의 Phase 0 작업:

- [ ] `docs/cli/pm.md` 생성 (Stub)
  - NAME/SYNOPSIS/대표 예제 + 상세는 `tools/pm/README.md` 링크
- [ ] `docs/cli/README.md`의 Tools 표에 `pm` 추가
- [ ] `tools/pm/README.md` 상단에 "User manual: `docs/cli/pm.md`" 링크 추가

### 커밋 및 MR

- [ ] 현재 변경사항 커밋
- [ ] Phase 0 구현 후 MR 생성

---

## Key Context

### RFC-009 핵심 정책

| 구분 | 위치 |
|------|------|
| 사용자용 매뉴얼 (User Manual) | `docs/cli/<command>.md` |
| 구현/내부 문서 (Implementation Notes) | `tools/<tool>/README.md` |

### 설계 원칙 연결 (ARCHITECTURE.md)

- **Human-readable > Machine-optimized**: Markdown 유지
- **Simplicity Over Completeness**: Phase 분리, 대규모 리라이트 지양
- **Composability**: 역할별 분리

### Non-goals (범위 밖)

- CLI 기능/옵션/출력 포맷 변경 없음
- 문서 전면 리라이트 아님

---

## Notes for Next Agent

1. **Phase 0부터 시작**: Stub 전략으로 최소 실행 가능 상태 먼저 만들기
2. **Simplicity 원칙**: Phase 0은 stub, Phase 1에서 content split
3. **docs/cli/README.md Related 섹션**: pm 링크가 중복될 수 있음 → Phase 1에서 정리 대상

---

**Delete this handoff after taking over and understanding context.**
