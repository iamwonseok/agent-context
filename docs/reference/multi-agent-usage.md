# Multi-agent Usage

## Background

멀티에이전트/멀티워크트리 환경에서 여러 AI 에이전트가 동시에 작업할 때 발생하는 문제와 해결 방안.

## Problem

여러 에이전트가 같은 레포에서 동시에 작업하면:

1. **로컬 상태 충돌**: 로그/세션/임시파일 같은 로컬 상태 파일에 동시 쓰기 발생
2. **레이스 컨디션**: 같은 파일을 동시에 수정하면 데이터 손실 가능
3. **디버깅 어려움**: 어떤 에이전트가 어떤 변경을 했는지 추적 어려움

## Solution: 1 Clone = 1 Agent

**핵심 아이디어:** 레포를 여러 개 클론하고, 각 클론에서 하나의 에이전트만 동작하게 강제.

### Advantages

- **로컬 상태 충돌 제거**: 각 클론은 디스크 경로가 달라 로그/임시파일이 섞이지 않음
- **실행 격리**: 하나의 에이전트가 이상 행동해도 다른 클론에 영향 없음
- **디버깅 단순**: "어떤 에이전트가 어떤 파일을 만들었는지"가 경로로 분리됨

### Trade-offs

- **코드 머지 충돌은 동일**: 여러 에이전트가 같은 소스 파일을 바꾸면 PR/merge 단계에서 충돌
- **운영비 증가**: 의존성 설치/캐시/빌드 아티팩트가 클론 수만큼 늘어남
- **동기화 비용**: 공통 브랜치/리베이스/테스트를 각 클론에서 반복

## Option: Worktree-based Isolation

`git worktree`를 사용하면 하나의 `.git` 저장소를 공유하면서도 물리적으로 분리된 작업 경로를 만들 수 있다.
클론을 여러 개 만드는 방식보다 디스크 사용량이 줄어드는 장점이 있다.

### Advantages

- **디스크 절약**: 저장소 데이터는 공유하고 워크트리만 분리
- **빠른 전환**: worktree 추가/삭제가 빠르고 가볍다
- **물리적 격리 유지**: 경로가 분리되어 `.context` 충돌을 줄일 수 있다

### Trade-offs

- **브랜치 중복 체크아웃 제한**: 같은 브랜치를 여러 worktree에서 동시에 사용할 수 없다
- **논리적 충돌은 동일**: 머지/리뷰 단계의 충돌은 여전히 남는다

## Recommended Operation (Clone or Worktree)

1. **Sandbox 분리**: 에이전트별로 clone 또는 worktree를 분리한다
2. **Orchestrator 통합**: PR 단위로 병합하고 충돌을 관리한다
3. **Shared Knowledge 분리**: 공용 문서는 큐레이터만 수정하고, 에이전트는 제안만 만든다

### When to choose clone

- 에이전트별로 의존성/환경이 다르거나, 완전한 격리가 필요한 경우
- 대용량 레포에서 캐시 충돌이 잦은 경우

### When to choose worktree

- 디스크 사용량을 줄여야 하는 경우
- 같은 레포의 여러 브랜치를 동시에 다뤄야 하는 경우

## Recommended Operation

1. **에이전트별 클론 + PR 단위 통합**: 각 클론은 자기 브랜치만 건드리고, 통합은 PR로
2. **충돌이 잦은 파일은 append-only/섹션 분리**: 그래도 충돌을 작게 유지
3. **공유 문서는 "큐레이터"만 수정**: 다른 에이전트는 제안(패치/노트)만 만들고 최종 반영은 1명이 수행

## Conclusion

"클론 분산"은 로컬 상태 충돌을 줄이는 데 매우 효과적이고, 멀티모델의 핵심 문제인 동시 쓰기 레이스를 상당 부분 구조적으로 제거한다.

단, 최종 머지에서의 논리적 충돌(같은 파일 수정)은 남기 때문에, 문서/지식 파일은 큐레이션 정책까지 같이 가져가는 게 가장 안정적이다.

## References

- Git worktree documentation: https://git-scm.com/docs/git-worktree
- Multi-agent reference architecture: https://microsoft.github.io/multi-agent-reference-architecture/docs/Introduction.html
