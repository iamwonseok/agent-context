# RFC-009: CLI Documentation Policy

**Status**: Draft  
**Author**: wonseok  
**Created**: 2026-01-26  
**Related**: `ARCHITECTURE.md`, `docs/cli/README.md`, `tools/*/README.md`
 
---
 
## 1. Summary
 
현재 CLI 문서가 `docs/cli/`와 `tools/*/README.md`에 혼재되어 있어(특히 `pm`) 사용자가 "어디서부터 읽어야 하는지"를 매번 다시 학습해야 합니다. 본 RFC는 **사용자용 CLI 매뉴얼의 정본(canonical) 위치를 `docs/cli/`로 통일**하고, `tools/*/README.md`는 **도구 구현/유지보수 문서(개발자용)**로 역할을 명확히 분리하는 것을 제안합니다.
 
---
 
## 2. Motivation (Problem)
 
### 2.1 사용자 관점 문제
 
- 커맨드별로 문서 시작점이 달라 탐색 비용이 증가합니다.
  - 예: `agent`/`lint`는 `docs/cli/`에 있으나, `pm`은 `tools/pm/README.md`에만 존재
- 문서 depth가 달라(예: `docs/cli/*` vs `tools/*`) "CLI 문서는 여기" 같은 단순 규칙이 깨집니다.
- 동일 내용이 중복될 때(예: `lint`는 `docs/cli/lint.md`와 `tools/lint/README.md`) 정본이 불명확해집니다.
 
### 2.2 유지보수 관점 문제

- 사용자용 안내(설치/사용법/예제)와 개발자용 내용(디렉터리 구조/테스트/내부 설계)이 한 문서에 섞이면 수정 시 충돌이 잦아집니다.
- 링크 정책이 없으면 문서가 점점 흩어집니다.

### 2.3 설계 원칙과의 정합

`ARCHITECTURE.md`의 핵심 원칙을 따릅니다:

- **Human-readable > Machine-optimized**: 문서는 Markdown으로 유지, `cat`과 `grep`으로 탐색 가능
- **Simplicity Over Completeness**: 점진적 개선(Phase 분리), 대규모 리라이트 지양
- **Composability**: 문서도 역할별로 분리하여 독립적으로 관리 가능하게

---
 
## 3. Goals / Non-goals
 
### Goals
 
- **사용자용 CLI 문서의 정본을 `docs/cli/`로 통일**합니다.
- `docs/cli/README.md`가 **모든 CLI의 허브(목차)**가 되도록 합니다.
- `tools/*/README.md`는 **구현/내부 문서(Implementation Notes)**로 한정하고, 사용자용 문서로의 링크를 제공합니다.
- 중복되는 내용은 점진적으로 정리하되, 당장 큰 이동 없이도 탐색성이 개선되도록 합니다(Stub 전략).
 
### Non-goals
 
- CLI 기능/옵션/출력 포맷 자체를 변경하지 않습니다.
- 문서 전면 리라이트(대규모 재작성)를 1차 목표로 두지 않습니다.
 
---
 
## 4. Proposed Information Architecture
 
### 4.1 Canonical rule

- **사용자용 매뉴얼 (User Manual)**: `docs/cli/<command>.md`
- **구현/내부 문서 (Implementation Notes)**: `tools/<tool>/README.md`
 
### 4.2 File layout (target)
 
```
docs/
  cli/
    README.md        # CLI hub: list of all commands + quick links
    agent.md
    agent-dev.md
    agent-mgr.md
    agent-init.md
    lint.md
    pm.md            # [NEW] user manual entrypoint for pm
tools/
  agent/README.md    # implementation/developer notes (+ link to docs/cli/agent.md)
  lint/README.md     # implementation/developer notes (+ link to docs/cli/lint.md)
  pm/README.md       # implementation/developer notes (+ link to docs/cli/pm.md)
```
 
---
 
## 5. Migration Plan (Incremental)
 
### Phase 0 (low-risk, immediate usability)
 
- [ ] `docs/cli/pm.md` 생성 (초기에는 Stub 가능)
  - 목적: "pm 문서는 `docs/cli`에서 시작"이라는 규칙을 즉시 성립시키기
  - 내용: NAME/SYNOPSIS/설치/설정/대표 예제 + 상세는 `tools/pm/README.md` 링크
- [ ] `docs/cli/README.md`의 Tools 표에 `pm` 추가
- [ ] `tools/pm/README.md` 상단에 "User manual: `docs/cli/pm.md`" 링크 추가
 
### Phase 1 (content split, remove ambiguity)
 
- [ ] `tools/pm/README.md`에서 사용자용 섹션을 `docs/cli/pm.md`로 이동
  - 사용자용: 설치/설정/명령 사용 예제/트러블슈팅
  - 개발자용: 내부 구조/라이브러리 레이아웃/개발 테스트/기여 가이드
- [ ] `tools/lint/README.md`와 `docs/cli/lint.md`의 역할을 명확히 분리
  - `docs/cli/lint.md`를 사용자용 정본으로 선언
  - `tools/lint/README.md`는 구조/테스트/내부 규칙 디렉터리 설명 중심으로 정리
 
### Phase 2 (consistency polish)
 
- [ ] `docs/cli/*` 문서의 섹션 템플릿을 최소한으로 통일
  - 권장: NAME / SYNOPSIS / QUICK START / COMMANDS / CONFIG / EXAMPLES / SEE ALSO
- [ ] 상호 링크 정책 확립
  - `docs/cli/<cmd>.md`는 필요 시 `tools/<tool>/README.md`를 "Implementation details"로 링크
  - `tools/<tool>/README.md`는 항상 `docs/cli/<cmd>.md`를 "User manual"로 링크
 
---
 
## 6. Acceptance Criteria
 
- `docs/cli/README.md`에서 모든 CLI(`agent`, `lint`, `pm`)로 1-hop 이동 가능
- 각 `tools/*/README.md`에서 해당 CLI 사용자 매뉴얼로 1-hop 이동 가능
- "pm 문서는 어디 있나요?" 질문에 답이 항상 `docs/cli/pm.md`가 됨
 
---
 
## 7. Notes / Open Questions
 
- `docs/cli/README.md`의 "Related" 섹션은 유지하되, 사용자 입장에서는 Tools 표가 우선 진입점이 되도록 구성합니다.
- 향후 `man` 페이지(예: `docs/man/`)가 필요해지면, `docs/cli/*`를 원본으로 하여 생성하는 방향이 자연스럽습니다(본 RFC 범위 밖).

