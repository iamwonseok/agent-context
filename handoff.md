# Handoff: Manual Fallback 개선 작업

## 완료된 작업 (P0 - 2026-01-24)

### 계획 문서
- ✅ `plan/manual-fallback-improvement-plan.md` 생성
  - 3개 AI 모델(Claude, GPT, Gemini)의 독립 분석 통합
  - 설계 철학(why.md) 부합성 검증
  - P0/P1/P2 우선순위 정의
  - 복잡도 예산 분석 (+20% vs 원안 +100%)

### 문서 작업
- ✅ `docs/manual-fallback-guide.md` 작성 (~500줄)
  - Feature/Bug/Hotfix/Refactor 4개 코어 워크플로우 Manual 버전
  - Context 수동 관리 (생성/업데이트/정리)
  - Worktree 수동 관리 (병렬 작업, A/B 테스팅)
  - Agent ↔ Manual 명령어 매핑 테이블
  - When to Use Manual vs Agent 가이드

- ✅ 시나리오 템플릿 표준화 (6개 파일)
  - `tests/scenario/001-dev-standard-loop.md`
  - `tests/scenario/002-incident-idle-available.md`
  - `tests/scenario/003-incident-idle-unavailable-replan.md`
  - `tests/scenario/004-parallel-work-detached-mode.md`
  - `tests/scenario/005-rebase-conflict-resolution.md`
  - `tests/scenario/006-draft-mr-iterative-review.md`
  - 모든 파일에 `## Manual Flow (Without Agent)` 추가
  - 모든 파일에 `## Responsibility Boundary` 추가

- ✅ 워크플로우 구현 상태 표기 (9개 파일)
  - Developer workflows (4개): feature, bug-fix, hotfix, refactor
  - Manager workflows (5개): approval, initiative, epic, task-assignment, monitoring
  - 모든 파일에 `## Implementation Status` 섹션 추가
  - Implemented/Partial/Roadmap 상태 명시
  - Manual Alternative 링크 추가

## 남은 작업 (P1 - CLI 코드 변경 필요)

### 1. agent dev submit 옵션 확장

**위치**: `tools/agent/lib/dev.sh`

**작업 내용**:
- `--only=<step>[,<step>,...]` 옵션 추가
- `--skip=<step>[,<step>,...]` 옵션 추가
- 허용 값: `sync`, `push`, `pr`, `jira`
- 전제 조건 검증 로직 (예: pr 단계에서 원격 브랜치 필요)
- 에러 메시지 개선 (actionable guidance)

**예상 LOC**: ~100 줄

**구현 스펙**:
```bash
# 기본 동작 (변경 없음)
agent dev submit  # sync + push + pr + jira

# 새 옵션
agent dev submit --only=sync      # rebase만
agent dev submit --only=push      # push만
agent dev submit --only=pr        # MR 생성만
agent dev submit --only=push,pr   # push + MR
agent dev submit --skip=jira      # Jira 제외
agent dev submit --skip=sync      # sync 제외

# 실행 순서 (--only)
1. sync  (git fetch + git rebase)
2. push  (git push)
3. pr    (MR/PR 생성)
4. jira  (Jira 상태 전환)

# 전제 조건
- pr 단계: 원격 브랜치 존재 필요
  → 없으면 에러 + 가이드: "Run 'agent dev submit --only=push' first or use '--only=push,pr'"
- 중간 실패 시 즉시 종료 + 부분 성공 상태 출력
```

**테스트 필요**:
- [ ] 모든 옵션 조합 동작 확인
- [ ] 전제 조건 위배 시 명확한 에러
- [ ] 하위 호환성 100% (기본 동작 변경 없음)

### 2. Pre-commit Hook 관리

**위치**: 
- `tools/agent/lib/check.sh` (수정)
- `tools/agent/templates/pre-commit.hook.sh` (신규)

**작업 내용**:
- `agent dev check --install-hook` 구현
- `agent dev check --uninstall-hook` 구현
- `agent dev check --status` 구현
- Hook 템플릿 작성 (lint + test)

**예상 LOC**: ~50 줄

**Hook 템플릿**:
```bash
#!/bin/bash
# Pre-commit hook installed by 'agent dev check --install-hook'

echo "[PRE-COMMIT] Running quality checks..."

if [ -f "Makefile" ] && grep -q "^lint:" Makefile; then
    make lint || exit 1
fi

if [ -f "Makefile" ] && grep -q "^test:" Makefile; then
    make test || exit 1
fi

echo "[PRE-COMMIT] All checks passed"
exit 0
```

**구현 요구사항**:
- Agent가 생성한 hook만 관리 (수동 hook 보존)
- Hook 실패 시 커밋 차단
- `git commit --no-verify`로 우회 가능
- Hook 존재 여부 검증

**테스트 필요**:
- [ ] Hook 설치/제거 동작
- [ ] Lint/Test 실패 시 커밋 차단
- [ ] `--no-verify`로 우회 확인

### 3. 짧은 Alias 추가 (선택사항)

**위치**: 
- `tools/agent/lib/aliases.sh` (신규)
- `tools/agent/bin/agent` (수정)

**작업 내용**:
```bash
# Alias 정의
agent sync    # = agent dev sync
agent check   # = agent dev check
agent submit  # = agent dev submit
```

**예상 LOC**: ~20 줄

**주의**: 기존 `agent dev <cmd>` 명령어는 그대로 유지 (alias는 편의 기능)

### 4. 검증 테스트

**Manual Only 시나리오 완주**:
- [ ] Agent 없는 환경 구성 (Docker 또는 clean VM)
- [ ] 시나리오 001-006 Manual Flow만으로 완주
- [ ] 막히는 구간 없음 확인
- [ ] CLI vs UI 경계 명확함 확인

**P1 회귀 테스트**:
- [ ] 기존 `agent dev submit` 동작 변경 없음 확인
- [ ] 모든 옵션 조합 테스트
- [ ] 전제 조건 위배 시 에러 메시지 확인
- [ ] Hook 설치/제거/재설치 테스트

## 구현 우선순위

**즉시 진행 가능** (문서 완료):
1. Submit 옵션 확장 (가장 높은 가치)
2. Hook 관리 (opt-in 품질 게이트)
3. Alias (편의 기능)
4. 검증 테스트

**예상 총 LOC**: ~170 줄

## 참고 자료

**분석 기반 문서** (참고용, 커밋 불필요):
- `claude-proposal-14adcf4.md` (2,855줄) - Claude 상세 분석
- `gpt-proposal-14adcf4.md` (159줄) - GPT 실행 가능성 검토
- `unified-proposal-14adcf4.md` (1,059줄) - Sonnet 통합 제안
- `gpt-unified-proposal-14adcf4.md` (159줄) - GPT 통합안 보완
- `gemini-unified-14adcf4.md` (124줄) - Gemini 최종 검토

이 파일들은 분석 과정에서 생성된 중간 산출물이므로:
- 보관이 필요하면 `.archive/analysis-2026-01-24/` 로 이동
- 불필요하면 삭제

## 철학 부합성 검증 결과

| 원칙 | Before | After P0 | After P1 (예상) |
|------|--------|----------|----------------|
| Simplicity | 4/5 | 4/5 | 4/5 |
| User Autonomy | 3/5 | **5/5** | **5/5** |
| Feedback | 4/5 | 4/5 | 5/5 |
| Composability | 2/5 | 2/5 | 4/5 |
| Artifacts | 5/5 | 5/5 | 5/5 |
| **총점** | 3.6/5 | **4.0/5** | 4.6/5 |

**P0 성과**: 철학 점수 3.6 → 4.0 (코드 0 LOC로 달성)

## 다음 세션 시작 시

1. **P1 구현 결정**:
   - P1 진행 여부 확인
   - 진행 시: `tools/agent/lib/dev.sh` 수정부터 시작

2. **분석 문서 정리**:
   - `*-proposal-14adcf4.md` 파일들 보관/삭제 결정

3. **테스트 계획**:
   - Manual only 환경 구성
   - 시나리오 001-006 완주 테스트

## 참고 링크

**생성된 문서**:
- [Manual Fallback Guide](docs/manual-fallback-guide.md)
- [Manual Fallback Improvement Plan](plan/manual-fallback-improvement-plan.md)
- [Scenario 001-006](tests/scenario/)
- [Workflows](workflows/)

**관련 철학**:
- [Design Philosophy (why.md)](why.md)
- [README](README.md)

---

**작성일**: 2026-01-24  
**작성자**: AI Agent (Claude Sonnet 4.5)  
**다음 작업**: P1 구현 또는 P0 검증 테스트
