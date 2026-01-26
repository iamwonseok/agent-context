# Handoff: RFC Implementation & Workflow Refactoring

## Status: Ready for Merge (Task 0, 1 완료)
## Created: 2026-01-27
## Last Updated: 2026-01-27

---

## Merge Policy

**READY TO MERGE:**
- [x] Task 0 완료 (RFC 상태 업데이트)
- [x] Task 1 완료 (Workflow 리팩토링 계획)
- [x] All tests passing (413/413 unit, meta-validation pass)

**선택적 추가 작업** (별도 브랜치 권장):
- Task 2: Workflow 리팩토링 실행
- Task 3: RFC-011 Language Policy 구현
- Task 4: RFC-007 IR 도입

---

## Completed Work

### 현재 세션 (2026-01-27 - Session 2)
- [x] Task 0: RFC-010, 012 상태 Draft → Active
- [x] Task 1: Workflow 리팩토링 계획 문서 작성
  - `docs/internal/workflow-refactor-plan.md` 생성
  - 전략 분석 및 권장안 제시
- [x] Tests: 413/413 unit tests passed
- [x] Meta-validation: All 3 levels passed

### 이전 세션 (2026-01-27 - Session 1)
- [x] RFC-012 Test Planning Framework 구현
- [x] RFC-010 Agent Efficiency Best Practices 구현
- [x] Meta-validation suite 생성 (tests/meta/)
- [x] Efficiency test scenarios 생성 (tests/efficiency/)
- [x] 모든 RFC에 Test Plan 섹션 추가

---

## Task 0: RFC 상태 업데이트 [URGENT]

### 목표
구현 완료된 RFC들의 상태를 Draft → Active로 변경

### 대상 파일
| RFC | 현재 상태 | 변경 후 |
|-----|-----------|---------|
| `docs/rfcs/010-agent-efficiency-best-practices.md` | Draft | **Active** |
| `docs/rfcs/012-test-planning-framework.md` | Draft | **Active** |

### 작업
1. 각 RFC 파일의 `## Status: Draft` → `## Status: Active` 변경
2. Changelog 섹션에 상태 변경 기록 추가

### 검증
```bash
grep "Status:" docs/rfcs/010*.md docs/rfcs/012*.md
```

---

## Task 1: Workflow 복잡도 분석 및 리팩토링 계획

### 배경
`.cursorrules`의 Complexity Budget에 따르면 Workflow는 100줄 이하여야 함.
현재 9개 workflow 중 8개가 예산 초과.

### 현재 상태
| Workflow | 줄 수 | 초과량 | 우선순위 |
|----------|-------|--------|----------|
| developer/refactor.md | 158 | +58 | High |
| developer/feature.md | 143 | +43 | High |
| manager/initiative.md | 135 | +35 | Medium |
| manager/monitoring.md | 123 | +23 | Medium |
| manager/approval.md | 123 | +23 | Medium |
| manager/epic.md | 120 | +20 | Medium |
| manager/task-assignment.md | 115 | +15 | Low |
| developer/bug-fix.md | 113 | +13 | Low |
| developer/hotfix.md | 95 | -5 | OK |

### 작업
1. 각 workflow 분석하여 분할 가능한 섹션 식별
2. 리팩토링 계획 문서 작성: `docs/internal/workflow-refactor-plan.md`
3. 공통 패턴을 별도 파일로 추출 가능한지 검토

### 리팩토링 전략 옵션
| 전략 | 설명 | 장점 | 단점 |
|------|------|------|------|
| A. 섹션 분리 | 긴 섹션을 별도 파일로 분리 | 단순 | 참조 복잡 |
| B. 공통 추출 | 공통 패턴을 include로 분리 | 재사용 | 구현 필요 |
| C. 예산 조정 | 100 → 150으로 상향 | 최소 변경 | 원칙 훼손 |

### 산출물
- `docs/internal/workflow-refactor-plan.md`

---

## Task 2: Workflow 리팩토링 실행 [선택적]

### 전제조건
- Task 1의 계획 문서 완료
- 리팩토링 전략 결정

### 우선순위
1. developer/refactor.md (158줄)
2. developer/feature.md (143줄)

### 작업
1. 계획에 따라 workflow 파일 분할/수정
2. 참조 업데이트 (.cursorrules, README 등)
3. 테스트 실행

### 검증
```bash
# 복잡도 재확인
for wf in workflows/*/*.md; do
  lines=$(wc -l < "$wf")
  if [ "$lines" -gt 100 ]; then
    echo "[WARN] $wf: $lines lines"
  fi
done

# 테스트
bash tests/meta/run-all-meta-tests.sh
```

---

## Task 3: RFC-011 Language Policy 구현 [선택적]

### 개요
RFC-011에 정의된 언어 정책 자동 검증 도구 강화

### 현재 상태
- 기본 검증: tests/unit/skills/test_skills.sh (Korean 검출)
- 추가 필요: batch cleanup 도구, CI 강화

### 작업
1. `tools/lint/check-language.sh` 스크립트 생성
2. CI pipeline에 language check 추가
3. 문서에 cleanup 가이드 추가

### 우선순위
Task 0, 1 완료 후 진행

---

## Task 4: RFC-007 Architecture Improvements [선택적]

### 개요
IR (Intermediate Representation) 도입으로 skill 간 데이터 흐름 명시화

### 범위
- `.context/{task}/intermediate.yaml` 형식 정의
- Provider interface 계약 정의

### 복잡도
High - 여러 세션에 걸쳐 진행 필요

### 전제조건
Task 0, 1 완료 권장

---

## Notes

### 작업 순서 권장
```
Task 0 (5분) → Task 1 (30분) → [Commit] → Task 2 또는 Task 3
```

### 테스트 명령어
```bash
# Meta-validation
bash tests/meta/run-all-meta-tests.sh

# Unit tests
bash tests/unit/run-all-unit-tests.sh

# Specific workflow check
bash tests/meta/test_workflows_structure.sh
```

### 참고 문서
- RFC-010: `docs/rfcs/010-agent-efficiency-best-practices.md`
- RFC-012: `docs/rfcs/012-test-planning-framework.md`
- Complexity Budget: `.cursorrules` → "Complexity Budget" 섹션

---

## Checkpoint Checklist

- [x] **Checkpoint 1**: Task 0 완료 (RFC 상태 업데이트)
- [x] **Checkpoint 2**: Task 1 완료 (리팩토링 계획)
- [ ] **Checkpoint 3**: Task 2 완료 (리팩토링 실행) - 선택적
- [x] **Checkpoint 4**: Commit & Push

---

## 다음 작업 방향

### 즉시 가능 (선택적)
1. **Task 2: Workflow 리팩토링 실행**
   - 계획: `docs/internal/workflow-refactor-plan.md`
   - 우선순위: developer/refactor.md → developer/feature.md
   - 예상 시간: 2-3시간

2. **Task 3: RFC-011 Language Policy 도구 강화**
   - `tools/lint/check-language.sh` 생성
   - CI pipeline 강화

### 중장기 (별도 RFC)
3. **Task 4: RFC-007 IR 도입**
   - 대규모 변경, 여러 세션 필요
   - `.context/{task}/intermediate.yaml` 형식 정의

### 권장 순서
```
현재 브랜치 Merge → Task 2 (새 브랜치) → Task 3 → Task 4
```

---

## 완료 조건

이 handoff 삭제 조건:
1. ✅ Task 0, Task 1 완료
2. ✅ 테스트 통과 (413/413)
3. ✅ Commit 완료
4. [ ] 다음 세션에서 인수 확인 후 삭제

---

## 참고 파일

- **리팩토링 계획**: `docs/internal/workflow-refactor-plan.md`
- **RFC-010 (Active)**: `docs/rfcs/010-agent-efficiency-best-practices.md`
- **RFC-012 (Active)**: `docs/rfcs/012-test-planning-framework.md`

---

*Last updated: 2026-01-27*
