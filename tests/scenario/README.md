# Scenario Tests

이 디렉터리는 `agent` / `pm` CLI 조합으로 **운영 시나리오를 실제로 따라 실행**할 수 있도록 정리한 문서 모음입니다.

## 공통 전제

- 이 시나리오 문서는 “명령어 흐름 검증” 목적입니다.
- 실제 GitLab/JIRA 연동은 토큰/프로젝트 설정이 필요합니다.

### PATH 설정(예시)

```bash
export PATH="$PATH:$(pwd)/tools/agent/bin:$(pwd)/tools/pm/bin"
```

### 설정 확인

```bash
pm config show
agent status
```

## 시나리오 목록

### 기본 플로우

- `001-dev-standard-loop.md`
  - 브레인스토밍 → 계획 → task assign 이후 개발-테스트-머지 루프(Dev)

### 긴급/인시던트 대응

- `002-incident-idle-available.md`
  - 문제 발생 → 새 task 생성 → 현재 task 없는 사람 찾기(성공) → assign → 개발-테스트-머지 루프
- `003-incident-idle-unavailable-replan.md`
  - 문제 발생 → 새 task 생성 → 현재 task 없는 사람 찾기(실패) → 강제 재할당/일정 변경 → 개발-테스트-머지 루프(PM)

### Git 워크플로우 심화

- `004-parallel-work-detached-mode.md`
  - 병렬 작업/A-B 테스팅: Detached Mode + Worktree를 활용한 여러 접근법 동시 실험
- `005-rebase-conflict-resolution.md`
  - 리베이스 충돌 해결: `agent dev sync` 중 충돌 발생 → 해결 → `--continue`/`--abort`
- `006-draft-mr-iterative-review.md`
  - Draft MR 반복 리뷰: 초안 MR → 피드백 → 수정 → 재요청 → 최종 승인 사이클

## 실행 팁

- Stage 1-2(토큰 불필요): `./tests/run-tests.sh`
- 실제 연동(E2E)은 `tests/README.md`의 Stage 3 가이드를 따르세요.

