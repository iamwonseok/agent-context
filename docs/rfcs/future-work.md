# Future Work: agent-context 장기 발전 방향

**작성일**: 2026-01-25  
**상태**: Draft (리뷰 대기)  
**목적**: Phase 1-2 완료 후 검토할 장기적 개선 아이디어 수집

---

## 배경: 현재 위치 평가

### NotebookLM 경쟁력 분석 (2026-01-25)

| 항목 | 평가 | 비고 |
|------|------|------|
| **안정성** | ★★★★★ | Git Worktree + Artifact 기반 관리 |
| **자율성** | ★★★☆☆ | Ralph/OpenCode 대비 사용자 개입 필요 |
| **확장성** | ★★★★☆ | Atomic Skill 구조로 유지보수 용이 |

### 핵심 차별점

```
agent-context의 설계 철학: "Bounded Autonomy" (제한된 자율성)

| 특성 | Ralph/OpenCode | agent-context |
|------|---------------|---------------|
| 기본 모드 | 자율 루프 | 단계별 승인 |
| 실패 처리 | 무한 재시도 | 사용자 개입 |
| 적합 환경 | 개인 프로젝트 | 팀 협업 (Git Flow, JIRA) |
```

**의도적 선택**: 팀 환경에서는 예측 가능성과 감사 추적이 자율성보다 중요

---

## Future Work 목록

### FW-1: Autonomous Loop Mode (Ralph 영감)

**목표**: Detached Mode에서 자율 반복 루프 옵션 제공

**제안 CLI**:
```bash
agent dev start TASK-123 --detached --loop [OPTIONS]

# 옵션
--max-iterations=N      # 최대 반복 횟수 (기본값: 5)
--max-duration=TIME     # 최대 실행 시간 (기본값: 30m)
--stop-condition=COND   # 탈출 조건
```

**탈출 조건 (--stop-condition)**:
- `test-pass`: 모든 테스트 통과 시 종료
- `lint-pass`: Lint 통과 시 종료
- `all-pass`: Lint + Test 모두 통과 시 종료
- `manual`: 사용자가 수동으로 종료 (기본값)

**안전장치**:
- Detached Mode 전용 (Interactive Mode에서 `--loop` 거부)
- 각 iteration마다 `.context/{task}/progress.txt` 업데이트
- 실패 시 자동 `git stash` + 알림
- `--max-iterations` 초과 시 경고 후 종료

**구현 위치**:
- `tools/agent/lib/git-strategy.sh`: loop 로직
- `tools/agent/bin/agent`: `--loop` 파싱

**철학 검증**:
- ⚠️ Simplicity 충돌 가능 (복잡도 증가)
- ✅ User Autonomy 유지 (옵트인, Detached 전용)
- ✅ Artifacts as State 유지 (progress.txt)

**예상 LOC**: ~150-200

**Go/No-Go 조건**:
- Phase 2 완료 후 사용자 피드백
- Detached Mode 사용률 확인
- Complexity Budget 여유 확인

---

### FW-2: LSP-based Validation (OpenCode 영감)

**목표**: Language Server Protocol을 활용한 코드 검증 강화

**구현 방식 검토**:

| 방식 | 장점 | 단점 | 권장 |
|------|------|------|------|
| **A: Skill 내부 통합** | 간결한 워크플로우 | Skill 복잡도 증가 | ❌ |
| **B: 별도 Validation Skill** | Composability 유지 | 추가 호출 필요 | ✅ |

**권장 구현 (Option B)**:
```
skills/validate/lsp-check/
├── SKILL.md
└── scripts/
    └── lsp-runner.sh
```

**SKILL.md 구조**:
```yaml
---
name: lsp-check
category: validate
mode: verification
cursor_mode: debug
description: LSP를 활용한 코드 정적 분석
optional_dependency: true
---

# LSP Check

## Supported Languages

| 언어 | LSP Server | 설치 확인 |
|------|------------|----------|
| Python | pylsp | `which pylsp` |
| TypeScript | tsserver | `which tsserver` |
| C/C++ | clangd | `which clangd` |
| Go | gopls | `which gopls` |

## Usage

```bash
# 활성화 (LSP 설치된 경우만)
agent dev check --with-lsp

# 특정 언어만
agent dev check --with-lsp=python,typescript
```

## Fallback

LSP 서버가 없으면 기존 lint로 fallback (경고 출력)
```

**철학 검증**:
- ⚠️ Simplicity 충돌 (새 도구 의존성)
- ✅ Composability 유지 (별도 Skill)
- ✅ User Autonomy 유지 (`--with-lsp`로 옵트인)

**예상 LOC**: ~100-150 (스킬) + ~50 (러너 스크립트)

**Go/No-Go 조건**:
- Phase 2 효과 검증 후
- 팀 내 LSP 도구 보급률 확인
- 기존 lint 대비 실질적 개선 확인

---

### FW-3: Automated Execution (기존 Phase 3 Task 7)

**목표**: 단계별 승인 없이 자동 실행

**제안 CLI**:
```bash
agent dev start TASK-123 --auto-submit
```

**동작**:
1. Start → Analyze → Design → Code → Check → Verify → Submit
2. 모든 단계 자동 실행
3. 에러 발생 시 즉시 중단 + 알림

**철학 검증**:
- ⚠️ User Autonomy 충돌 (중간 검토 불가)
- ✅ 옵트인 방식으로 완화

**리스크**:
- 중간 단계 품질 저하 가능
- 요구사항 오해 시 대규모 재작업

**완화 방안**:
- 기본값 비활성화
- 실패 시 즉시 중단
- Check 단계 실패 시 사용자 개입 요청

**Go/No-Go 조건**:
- Phase 2 성공 지표 달성
- 사용자 만족도 4.0/5.0 이상

---

### FW-4: MCP Server 통합

**목표**: Model Context Protocol을 활용한 외부 도구 연동

**잠재적 활용**:
- IDE 브라우저 자동화 (테스트 검증)
- 외부 API 호출 (Slack, Email 알림)
- 데이터베이스 조회 (이슈 메타데이터)

**구현 고려사항**:
- 현재 Cursor IDE에서 MCP 지원
- agent CLI에서 직접 MCP 호출은 복잡도 증가
- 우선 Cursor의 MCP 기능을 문서화하고, CLI 통합은 후순위

**Go/No-Go 조건**:
- MCP 표준 안정화
- Cursor 외 환경에서의 필요성 확인

---

### FW-5: Multi-Agent Coordination (Low Priority - 철학 충돌 위험)

**목표**: 여러 에이전트가 협업하는 시나리오 지원

**잠재적 시나리오**:
- Agent A: 코드 작성 (Developer)
- Agent B: 리뷰 (Reviewer)
- Agent C: 테스트 작성 (QA)

**구현 고려사항**:
- 현재 구조에서는 Role(Developer/Manager)로 구분
- Multi-Agent는 복잡도 대폭 증가
- 단일 Agent + 여러 Skill 조합으로 대부분 해결 가능

**철학 검증**:
- **Simplicity 충돌**: 복잡도 예산 초과 위험 높음
- **권장**: 단일 Agent + Skill 조합으로 먼저 시도
- **우선순위**: 최하위 (다른 모든 FW 완료 후 재검토)

**Go/No-Go 조건** (엄격):
- 단일 Agent로 해결 불가능한 실제 사례 3건 이상 수집
- 복잡도 예산 내 구현 방안 확보
- 팀 합의 필수

---

### FW-6: VCS Abstraction Layer (Architecture Feedback)

**목표**: Git 의존성 제거, Vertical 추상화 레이어 도입

**배경**: Architecture feedback에서 agent CLI가 Git에 하드코딩되어 있다는 지적

**제안 구조**:
```
tools/agent/lib/vcs/
├── provider.sh   # VCS 추상화 인터페이스
├── git.sh        # Git 구현체
└── (hg.sh)       # 미래: Mercurial
```

**인터페이스 예시**:
```bash
# provider.sh
vcs_init()           # Initialize repository
vcs_commit()         # Create commit
vcs_branch()         # Branch operations
vcs_push()           # Push to remote
vcs_status()         # Get status
vcs_diff()           # Show differences
```

**철학 검증**:
- ✅ Composability 유지 (플러그인 구조)
- ✅ Simplicity 유지 (기존 코드 분리만)
- ⚠️ 당장 필요성 낮음 (Git이 사실상 표준)

**Go/No-Go 조건**:
- 다른 VCS 지원 요청 발생 시
- 기존 git-strategy.sh 복잡도 증가 시

---

### FW-7: Skill Executor Abstraction (Architecture Feedback)

**목표**: bash 외 다른 언어로 Skill 구현 지원 (Vertical 확장)

**배경**: Architecture feedback에서 Skill 실행 엔진이 bash로 고정되어 있다는 지적

**제안 방식**:
```yaml
# SKILL.md frontmatter
---
name: complex-analysis
executor: python  # bash | python | cli
script: run.py
---
```

**구현 위치**:
```bash
# tools/agent/lib/skill-executor.sh
execute_skill() {
    local skill_path=$1
    local executor=$(get_skill_executor "$skill_path")
    
    case $executor in
        bash) bash "$skill_path/run.sh" ;;
        python) python3 "$skill_path/run.py" ;;
        cli) "$skill_path/run-cli.sh" ;;
    esac
}
```

**철학 검증**:
- ✅ Composability 유지 (실행 방식만 다름)
- ⚠️ Simplicity 충돌 (복잡도 증가)
- ✅ User Autonomy 유지 (선택적 사용)

**Go/No-Go 조건**:
- 복잡한 로직 처리 필요 시
- 외부 도구 연동 증가 시

---

### FW-8: AOP-style Aspects (Architecture Feedback)

**목표**: Cross-cutting concerns를 Aspect로 분리 (Horizontal + Vertical 조합)

**배경**: Architecture feedback에서 Layer 1, 2 (State Visibility, Feedback Loops)를 
AOP 스타일로 분리하면 코드 중복이 줄어든다는 제안

**제안 구조**:
```bash
# tools/agent/lib/aspects.sh

# Before advice - Skill 실행 전
aspect_state_before() {
    local skill_name="$1"
    echo "AGENT MODE: $skill_name"
    echo "Mode: $(get_skill_mode "$skill_name")"
    echo "Cursor Mode: $(get_skill_cursor_mode "$skill_name")"
}

# After advice - Skill 실행 후
aspect_feedback_after() {
    local skill_name="$1"
    local exit_code="$2"
    if [[ "$exit_code" -eq 0 ]]; then
        echo "[PASS] $skill_name completed"
    else
        echo "[FAIL] $skill_name failed (exit: $exit_code)"
    fi
}

# Around advice - 모드 위반 감지
aspect_self_correction() {
    local skill_name="$1"
    local mode=$(get_current_mode)
    if detect_mode_violation "$mode"; then
        trigger_self_correction
    fi
}
```

**관계**: RFC-004 Phase 2 (Self-Correction Protocol)와 연계

**철학 검증**:
- ✅ Feedback Over Enforcement 유지 (가시성 레이어)
- ✅ Composability 유지 (관심사 분리)
- ⚠️ Simplicity 충돌 가능 (추상화 레이어 추가)

**Go/No-Go 조건**:
- RFC-004 Phase 2 완료 후
- 코드 중복이 실제로 문제가 될 때

---

### FW-9: Domain Extension Ecosystem (RFC-008 관련)

**목표**: 커뮤니티가 도메인별 확장을 공유하는 생태계 구축

**제안 CLI**:
```bash
agent extension search opentitan
agent extension install opentitan-hw
agent extension list
```

**구현 고려사항**:
- 확장 레지스트리 서버 필요 (복잡도 높음)
- 초기에는 GitHub Topics로 대체 가능
- RFC-008 Phase 1-3 완료 후 필요성 재검토

**철학 검증**:
- ⚠️ Simplicity 충돌 (레지스트리 서버)
- ✅ User Autonomy 유지 (opt-in 설치)
- ✅ Composability 유지 (독립 패키지)

**Go/No-Go 조건**:
- RFC-008 구현 완료
- 3개 이상 도메인 팩 존재
- 사용자 요청 발생

---

### FW-10: Retrospective Skill (RFC-008 관련)

**목표**: 버그 수정 후 회고록 자동 생성 및 지식 베이스 축적

**스킬 구조**:
```
skills/integrate/create-retrospective/
├── SKILL.md
└── templates/
    └── retrospective.md
```

**워크플로우**:
1. 버그 수정 완료
2. `agent dev retro` 실행
3. `docs/retrospectives/{task-id}.md` 생성
4. MR에 포함하여 팀 리뷰
5. 승인 후 병합 -> policies/에 반영 검토

**제안 CLI**:
```bash
agent dev retro              # 회고록 생성
agent dev retro --to-policy  # 정책 후보 추출
```

**철학 검증**:
- ✅ Simplicity 유지 (문서 생성만)
- ✅ User Autonomy 유지 (수동 병합)
- ✅ Artifacts as State 유지 (파일 기반)

**Go/No-Go 조건**:
- RFC-008 Phase 2 완료
- 회고록 수요 확인

---

## 자율성 향상 로드맵

현재 Phase 1-2 완료 시 자율성 개선 경로:

```
현재: ★★★☆☆

Phase 1 (State Visibility):
└── Self-Correction → 오류 자동 감지 → 사용자 개입 감소

Phase 2 (Feedback Loops):
├── Knowledge Caching → LLM amnesia 방지 → 더 긴 자율 실행
└── Question-Driven Planning → 사전 명확화 → 재작업 감소

예상: ★★★★☆

Future Work (선택적):
├── FW-1 (--loop) → 완전 자율 모드 (Detached)
└── FW-2 (LSP) → 자동 검증 강화

잠재적: ★★★★★ (옵트인 시)
```

---

## 리뷰 체크리스트

### Phase 2 완료 후 검토 항목

- [ ] Phase 2 성공 지표 달성 여부
  - [ ] 토큰 절감 20% 이상
  - [ ] MR 리뷰 시간 30% 단축
  - [ ] 요구사항 오해율 5% 이하
- [ ] 사용자 만족도 설문
- [ ] Complexity Budget 현황
- [ ] Detached Mode 사용률

### 각 Future Work 검토 기준

| FW | 필요성 | 복잡도 | 리스크 | 우선순위 |
|----|--------|--------|--------|----------|
| FW-1 (Loop) | 중 | 중 | 중 | TBD |
| FW-2 (LSP) | 중 | 낮 | 낮 | TBD |
| FW-3 (Auto) | 낮 | 낮 | 높 | TBD |
| FW-4 (MCP) | 낮 | 높 | 중 | TBD |
| FW-5 (Multi) | 낮 | 높 | 높 | **최하위** |
| FW-6 (VCS) | 낮 | 중 | 낮 | TBD |
| FW-7 (Executor) | 낮 | 중 | 중 | TBD |
| FW-8 (AOP) | 중 | 중 | 중 | TBD |
| FW-9 (Domain Ext) | 낮 | 높 | 중 | RFC-008 후 |
| FW-10 (Retro) | 중 | 낮 | 낮 | RFC-008 후 |

---

## 참고 자료

### 레퍼런스 프로젝트

- [Ralph Project](https://github.com/snarktank/ralph): Fresh Context Loop
- [Oh My OpenCode](https://github.com/opencode/oh-my-opencode): LSP 통합
- [spec-kit-command-cursor](https://github.com/madebyaris/spec-kit-command-cursor): SDD v3.0
- [vibe-coding-v2](https://github.com/paslavsky/vibe-coding-v2): LLM State Management

### 관련 RFC

- [002-proposal.md](002-proposal.md): v2.0 통합 제안서
- [004-agent-workflow-system.md](004-agent-workflow-system.md): v2.0 구현 계획
- [005-manual-fallback-improvement.md](005-manual-fallback-improvement.md): Manual Fallback 개선
- [007-architecture-improvements.md](007-architecture-improvements.md): Architecture Pattern Improvements (FW-6,7,8 관련)
- [008-domain-extension.md](008-domain-extension.md): Domain Extension & Installation (FW-9,10 관련)

---

## 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|------|----------|--------|
| 2026-01-25 | 초안 작성 (NotebookLM 분석 기반) | AI Agent |
| 2026-01-25 | FW-6,7,8 추가 (Architecture Feedback 반영) | AI Agent |
| 2026-01-25 | FW-9,10 추가 (RFC-008 Domain Extension 관련) | AI Agent |

---

### FW-11: RFC-006 Unified Platform Abstraction (Deferred)

**목표**: pm CLI의 플랫폼 추상화 레이어 확장

**배경**: RFC-006에서 제안된 pm milestone/label/wiki 통합 기능

**제안 기능**:
```bash
pm milestone list [--state <active|closed|all>]
pm milestone create <TITLE> [--due <DATE>]
pm label list
pm label create <NAME> [--color <HEX>]
pm wiki list
pm wiki create <TITLE> --content <TEXT|FILE>
```

**플랫폼 매핑**:
| Unified Command | JIRA | GitLab | GitHub |
|-----------------|------|--------|--------|
| milestone list | Sprint | Milestone | Milestone |
| label create | Label | Label | Label |
| wiki list | - | Wiki | Wiki* |

*GitHub Wiki는 Git repo 기반 (복잡)

**구현 파일**:
- `tools/pm/lib/milestone.sh` (신규)
- `tools/pm/lib/label.sh` (신규)
- `tools/pm/lib/wiki.sh` (신규)
- `tools/pm/bin/pm` (수정)

**철학 검증**:
- ✅ Composability 유지 (Unified command 패턴)
- ⚠️ Simplicity 충돌 (API 구현 복잡도)
- ✅ User Autonomy 유지 (플랫폼별 선택)

**Go/No-Go 조건**:
- RFC-005 완료 후
- 실제 사용 요청 발생 시
- API 연동 테스트 환경 확보

**참조**: [RFC-006](006-unified-platform-abstraction.md)

---

## 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|------|----------|--------|
| 2026-01-25 | 초안 작성 (NotebookLM 분석 기반) | AI Agent |
| 2026-01-25 | FW-6,7,8 추가 (Architecture Feedback 반영) | AI Agent |
| 2026-01-25 | FW-9,10 추가 (RFC-008 Domain Extension 관련) | AI Agent |
| 2026-01-28 | FW-11 추가 (RFC-006 Deferred) | AI Agent |

---

**다음 리뷰 예정**: Phase 2 완료 후 (약 Week 5-6)
