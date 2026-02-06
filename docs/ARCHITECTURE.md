# 설계 철학

이 시스템을 이렇게 설계한 이유와 원칙.

## 핵심 원칙

### 1. 완전성보다 단순성

> "Avoid over-engineering. Only make changes that are directly requested or clearly necessary."
> -- Cursor Best Practices

**우리가 믿는 것:**
- 단순하게 동작하는 해법 > 복잡하지만 더 좋아 보이는 해법
- 모두가 이해하는 100줄 > 작성자만 이해하는 1000줄
- 사용자 경고 > 사용자 차단
- 점진적 강화 > 한 번에 전체 적용

**실천 방식:**
- 경고부터 시작하고, 필요 시에만 강제
- 최소 기능부터 구현
- 실제로 문제가 반복될 때만 복잡도 추가

### 2. 사용자 자율성

> "Let the agent find context. Keep it simple: if you know the exact file, tag it. If not, the agent will find it."
> -- Cursor Best Practices

**우리가 믿는 것:**
- 사용자와 에이전트는 의사결정의 자유가 있어야 한다
- 하드 차단은 정말 치명적인 경우에만 사용한다
- 예외 상황을 위한 `--force` 옵션을 제공한다
- 경고를 통해 사용자가 학습하도록 신뢰한다

**실천 방식:**
- 하드 차단 대신 `[!]` 경고를 우선 사용한다
- 소프트 강제에는 `--force`를 제공한다
- 권장 사항을 보여주되 강제하지 않는다
- 긴급 상황(hotfix)에서는 단계 생략을 허용한다

### 3. 강제보다 피드백

> "After completing a task that involves tool use, provide a quick summary of the work you've done."
> -- Claude 4.x Best Practices

**우리가 믿는 것:**
- 하드 차단보다 명확한 피드백이 더 잘 가르친다
- 사용자는 WHY(왜 필요한가)를 이해해야 한다
- 진행 상황과 상태를 보여주고 다음 행동은 사용자가 결정한다

**실천 방식:**
```bash
# Good: Informative warning
[!] No verification found
[i] Run 'agent dev verify' to check requirements
Continue anyway? [y/N]

# Avoid: Hard block without context
[X] Cannot submit. Run verify first.
```

### 4. 조합 가능성

> "Ralph is an autonomous AI agent loop that runs repeatedly until all PRD items are complete. Each iteration is a fresh instance with clean context."
> -- Ralph Project

**우리가 믿는 것:**
- 작은 스킬 조합 > 거대한 단일 워크플로
- 스킬은 독립적으로 사용 가능해야 한다
- 워크플로는 스킬 조합이다
- 각 스킬은 입력/출력이 명확해야 한다

**실천 방식:**
- 스킬은 자기완결적이어야 한다 (`{skill}.md` 하나로 충분)
- 워크플로는 스킬을 참조하고 중복 작성하지 않는다
- 새 워크플로는 새 스킬 조합이다

### 5. 상태는 데이터베이스가 아니라 산출물로

> "Memory persists via git history, progress.txt, and prd.json."
> -- Ralph Project

**우리가 믿는 것:**
- Git이 단일 진실 소스이다
- 복잡한 상태 머신보다 파일(YAML, Markdown)이 낫다
- 기계 최적화보다 사람이 읽기 쉬워야 한다
- 커밋이 감사 추적을 제공한다

**실천 방식:**
- 작업 중 상태는 레포 외부(개인 작업 공간) 또는 Issue Tracker에 둔다
- 데이터베이스 대신 `summary.yaml`을 사용한다
- Git 커밋을 상태 전환으로 본다
- 모든 것은 파일 기반으로 확인 가능해야 한다

---

## 아키텍처 패턴

### Engineering Coordinate System

> **"Skill은 멍청할수록(Generic) 좋고, Workflow는 친절할수록(Context-Aware) 좋다"**

일은 두 개의 축으로 정리한다:

```
Y-Axis (Layer)              X-Axis (Timeline)
---------------------------------------------------------
PROJECT (Org)               Plan --> Execute --> Review
    |
TEAM (Squad)                Plan --> Execute --> Review
    |
SOLO (Dev)                  Plan --> Execute --> Review
```

**Layer (Y-axis):** 누가 일을 하는가
- **Solo**: 개인 개발 (feature, bugfix, hotfix)
- **Team**: 팀 단위 조정 (sprint, release)
- **Project**: 조직 단위 계획 (quarter, roadmap)

**Timeline (X-axis):** 각 레이어의 Plan-Execute-Review 루프

### Thin Skill / Thick Workflow 패턴

| 개념 | 역할 | 개발자 비유 |
|---------|------|-------------------|
| **Skill** | 인터페이스/템플릿 | 함수 시그니처, 추상 클래스 |
| **Workflow** | 컨텍스트 주입 | DI 컨테이너, 구현체 |

**Skills (Thin):**
- 입력 중심 템플릿 (빈칸 채우기)
- HOW에 집중: 방법, 체크리스트, 원칙
- 컨텍스트 없음: 티켓 ID, 프로젝트명 배제
- 범용/재사용 가능

**Workflows (Thick):**
- 현재 컨텍스트를 스킬 입력으로 매핑
- WHAT에 집중: 무엇을 어디에 넣는가
- 컨텍스트 인지: 티켓, 도구, 데드라인
- 상황 특화

### 컨텍스트 주입 흐름 (Context Injection Flow)

```
컨텍스트 (Jira, Logs, Code)
       |
       | 읽기
       v
워크플로 (오케스트레이터)
  - 컨텍스트 매핑: 스킬 입력 <-- 소스
  - 도구 규칙: Git branch, commit format
       |
       | 주입
       v
스킬 (템플릿)
  - 입력: problem, scope, constraints
  - 출력: 산출물
       |
       | 생성
       v
산출물 (PR, Doc, Report)
```

### 구조

```
skills/                     # Thin 템플릿 (5)
    analyze.md              # 문제 이해
    design.md               # 해결안 정의
    implement.md            # 구현
    test.md                 # 검증
    review.md               # 품질 확인

workflows/                  # Thick 컨텍스트 주입
    solo/                   # 개인 PER 루프
        feature.md
        bugfix.md
        hotfix.md
    team/                   # 팀 PER 루프
        sprint.md
        release.md
    project/                # 조직 PER 루프
        quarter.md
        roadmap.md
```

### 플랫폼 추상화

추상 인터페이스로 구현 상세를 숨긴다:

```
        통합 인터페이스 (pm CLI)
               |
        Provider 레이어 (provider.sh)
               |
    +----------+----------+----------+
    |          |          |          |
  JIRA      GitLab     GitHub   Confluence
```

**이 프로젝트에서:**
- `tools/pm/lib/provider.sh` - Provider 선택 로직
- `tools/pm/lib/jira.sh` - JIRA 구현
- `tools/pm/lib/gitlab.sh` - GitLab 구현
- `tools/pm/lib/github.sh` - GitHub 구현

---

## 피하는 것

### 과도한 설계 패턴

| 패턴 | 문제 | 접근 방식 |
|---------|---------|--------------|
| 복잡한 상태 머신 | 디버깅/유지보수 어려움 | 단순 플래그 + 경고 |
| 하드 차단 | 사용자 불만, 긴급 대응 불가 | 소프트 강제 + `--force` |
| 깊은 중첩 | 인지 부하 증가 | 2단계 이하의 평면 구조 |
| 커스텀 DSL | 학습 비용 | 표준 YAML + Markdown |
| 암묵적 의존성 | 실패 원인 추적 어려움 | 스킬 참조를 명시 |

### 12-State 함정

12단계 유한 상태 머신을 고려했다:
```
NOT_STARTED -> IN_PROGRESS -> CHECKING -> CHECK_FAILED -> 
CHECK_PASSED -> COMMITTED -> VERIFYING -> VERIFY_FAILED -> 
VERIFIED -> RETRO_PENDING -> RETRO_DONE -> SUBMITTED
```

**왜 거부했는가:**
1. 유지보수 코드가 약 800줄 이상
2. 모든 명령에 상태 검증 래퍼 필요
3. 상태 전환 디버깅이 고통스러움
4. 예외 상황을 사용자가 우회하기 어려움
5. 자율성 원칙에 위배

**대신 하는 일:**
- 핵심 지점에서의 간단한 상태 체크
- 권장 행동을 포함한 경고
- 점진적 강제 (Phase 1: warn, Phase 2: soft, Phase 3: hard)
- `--force` 우회 경로 제공

### 게이트 함정

강제 게이트를 고려했다:
```bash
$ agent dev commit "feat: add feature"
[X] Must run 'agent dev check' first
```

**왜 완화했는가:**
1. 숙련자는 언제 건너뛰어야 하는지 알고 있다
2. 긴급 상황(hotfix)에는 유연성이 필요하다
3. 강제보다 신뢰가 더 좋은 습관을 만든다
4. pre-commit 훅이 이미 대부분을 잡는다

**대신 하는 일:**
```bash
$ agent dev commit "feat: add feature"
[!] 'agent dev check' not run yet
[i] Run check to verify quality
Continue anyway? [y/N]
```

---

## 구현 가이드

### 신규 기능 추가

1. **문서부터 시작** - 스킬 템플릿을 먼저 작성
2. **최소 버전 구현** - 경고만, 차단은 하지 않음
3. **피드백 수집** - 실제 프로젝트에서 사용
4. **점진적 강제** - Phase 1 -> 2 -> 3
5. **우회 경로 유지** - 항상 `--force` 옵션 유지

### 코드 복잡도 예산

| 컴포넌트 | 최대 라인 | 최대 파일 수 |
|-----------|-----------|-----------|
| 단일 스킬 | 200 | 1 ({skill}.md) |
| 워크플로 | 100 | 1 ({workflow}.md) |
| CLI 명령 | 100 | 1 (lib/ 내 함수) |
| 헬퍼 라이브러리 | 300 | 1 |

한도를 넘으면 더 작은 컴포넌트로 분리한다.

### 복잡도를 추가할 때

아래 조건을 만족할 때만 복잡도를 추가한다:
- [ ] 단순한 해법이 여러 번 실패했다
- [ ] 사용자가 동일한 실수를 반복한다
- [ ] 실제 사례로 문제가 문서화되었다
- [ ] 더 단순한 대안이 이미 검토되었다

아래의 이유로는 복잡도를 추가하지 않는다:
- 이론적 엣지 케이스
- "만약에" 시나리오
- 과도한 최적화
- 기능 완결성만을 위한 추가

---

## 참고 자료

### 업계 베스트 프랙티스

1. **Cursor Agent Best Practices**
   - "Start simple. Add rules only when you notice the agent making the same mistake repeatedly."
   - "Let the agent find context"
   - https://cursor.com/blog/agent-best-practices

2. **Claude 4.x Prompting Best Practices**
   - "Avoid over-engineering"
   - "Please write a high-quality, general-purpose solution"
   - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-4-best-practices

3. **Gemini Prompting Strategies**
   - "Be explicit with your instructions"
   - "Provide context to improve performance"
   - https://ai.google.dev/gemini-api/docs/prompting-strategies

4. **Ralph Project**
   - Autonomous agent loop with simple bash + JSON
   - No complex state machine, just files
   - https://github.com/snarktank/ralph

5. **OpenCode**
   - "Free models included or connect any model"
   - Simplicity in design
   - https://opencode.ai/

6. **Unicode Technical Standard #51**
   - Emoji 표준, ZWJ 시퀀스, 플랫폼별 표시 차이
   - "Emoji are not typically typed on a keyboard"
   - https://unicode.org/reports/tr51/

7. **Apple Support - Use emoji and symbols on Mac**
   - macOS에서 Character Viewer를 통한 이모지 입력 방법
   - https://support.apple.com/guide/mac-help/use-emoji-and-symbols-on-mac-mchlp1560/mac

8. **Microsoft Learn - Emoji**
   - Windows에서 `Win + .`을 통한 이모지 입력 방법
   - https://learn.microsoft.com/en-us/globalization/fonts-layout/emoji

### 핵심 인용

> "The developers who get the most from agents share a few traits: They write specific prompts. They iterate on their setup. They review carefully."
> -- Cursor Team

> "Avoid creating helper scripts or workarounds. Keep solutions simple and focused."
> -- Claude 4.x Best Practices

> "Each iteration is a fresh instance with clean context. Memory persists via git history."
> -- Ralph Project

> "Emoji are not typically typed on a keyboard. Instead, they are generally picked from a palette."
> -- Unicode UTS #51

---

## 결정 사항 로그

### 2026-01-23: 의도 검증 단순화

**배경:** 의도 검증을 위해 800줄 이상인 12단계 FSM을 계획했다.

**결정:** 단순 경고 시스템으로 대체 (~200줄).

**근거:**
1. 베스트 프랙티스는 단순성을 권장한다
2. Ralph는 단순한 bash 루프가 충분함을 증명한다
3. 사용자는 강제보다 유연성이 필요하다
4. 점진적 롤아웃이 학습을 가능하게 한다

**트레이드오프:**
- 강제력이 약해짐 (수용 가능)
- 사용자 규율에 의존 (경고로 보완)
- 추후 강화 필요 가능성 (점진적 추가)

### 2026-01-23: 레포 구조 변경

**배경:** `.agent/`를 서브모듈로 사용하려는 구조였다.

**문제:**
1. 서브모듈 방식으로 `.agent/`가 사용자 프로젝트에서 읽기 전용이 됨
2. 포크 없이 버그 수정이나 커스터마이징이 어려움
3. 개발 문서(plan/, design/)가 배포 코드와 섞임
4. 파일 위치에 대한 혼란

**결정:** 구조를 평탄화하고 레포 루트를 배포 단위로 사용.

**새 구조:**
```
agent-context/              # This repo = what gets deployed
|-- skills/                 # Generic skill templates
|-- workflows/              # Context-aware workflow definitions
|-- tools/                  # CLI tools (agent, lint, pm, worktree)
|-- docs/                   # Documentation and style guides
`-- (removed) tests/         # Workflow integration tests (removed)
```

**배포 모델 (Hybrid):**
```
# Priority order for agent context resolution:
1. .agent/                  # Project local (highest priority)
2. .project.yaml            # Config file setting
3. $AGENT_CONTEXT_PATH      # Environment variable
4. ~/.agent                 # Global default
```

**근거:**
1. 글로벌 설치(`~/.agent`)는 수정 가능
2. 로컬 설치(`.agent/`)는 프로젝트별 버전 관리 가능
3. Docker 기반 테스트로 격리 가능
4. 간단한 멘탈 모델: 레포 = 배포 단위

**트레이드오프:**
- 1회성 마이그레이션 필요
- 유연하지만 경로 해석이 약간 복잡해짐

---

## 언어 정책

### 정책 매트릭스

| 파일 유형 | 언어 | 이모지 | 유니코드 | 이유 |
|-----------|----------|:-----:|:-------:|-----------|
| 실행 파일 (`*.sh`, `*.py`) | English only | Forbidden | Forbidden | 코드는 보편적으로 읽혀야 한다 |
| 코드 주석 | English only | Forbidden | Forbidden | 주석은 코드의 일부이다 |
| Markdown (`*.md`) | Korean-first (except `skills/`, `workflows/`) | Forbidden | Restricted | 문서는 사람이 읽는 대상이다 |

### 왜 이모지/장식 유니코드를 하드 차단하는가

이모지와 장식 유니코드는 일반 텍스트와 달리 **재현성과 호환성 문제**가 있어 하드 차단한다.

**1. 플랫폼마다 표시가 다름**

> "Emoji are pictographs ... typically presented in a colorful cartoon form."
> "The shape of the character can vary significantly."
> -- Unicode UTS #51, Section 2 Design Guidelines

이모지는 단일 코드포인트가 아니라 ZWJ(Zero Width Joiner)와 Variation Selector를 포함하는 시퀀스일 수 있다.
구현체가 해당 시퀀스를 지원하지 않으면 fallback으로 분해되어 표시된다.
같은 이모지가 macOS, Windows, Linux, 브라우저, 터미널에서 각각 다르게 보일 수 있어 문서의 재현성을 해친다.

**2. 키보드로 쉽게 입력할 수 없음**

> "Emoji are not typically typed on a keyboard. Instead, they are generally picked from a palette."
> -- Unicode UTS #51, Section 6 Input

이모지는 일반 키보드로 타이핑하지 않고 OS별 팔레트/뷰어를 통해 입력한다:
- **macOS**: `Fn-E` 또는 `Ctrl-Cmd-Space`로 Character Viewer 호출
- **Windows**: `Win + .` (period)로 Emoji Picker 호출

입력 방법이 OS마다 다르므로, 문서 예시나 템플릿을 작성할 때 **재현 가능한 키보드 입력만으로 작성할 수 없다**.
기여자가 다양한 환경에서 동일하게 문서를 편집/검토하려면 ASCII + 표준 Markdown만 사용하는 것이 안전하다.

**3. 검색/grep/diff 도구와의 호환성**

이모지 시퀀스는 여러 코드포인트로 구성되어 일반 텍스트 검색 도구에서 예상치 못한 결과를 낼 수 있다.
`grep`, `diff`, `git diff` 등에서 일관된 동작을 보장하려면 이모지를 배제하는 것이 실용적이다.

**결론:** 이모지/장식 유니코드는 pre-commit에서 하드 차단(`[X]`)하며, 우회 경로를 제공하지 않는다.
이 정책은 "경고 우선" 원칙의 예외이며, 재현성과 도구 호환성이라는 운영상 요구 때문이다.

### Markdown 내 Unicode

**Allowed:**
- Arrows: `->`, `-->`, `<--`
- Box drawing: `|`, `+`, `-`
- Tables: Standard markdown tables

**Forbidden:**
- Emoji icons: No decorative emoji
- Checkmark symbols: Use `[x]` instead of checkmarks
- Star symbols: Use numbers or `-` instead

### 강제

`pre-commit` 훅에서 이모지/장식 유니코드를 자동 검증한다:
- `tools/lint/check_no_emoji_text.py`: 모든 텍스트 파일에서 이모지/장식 유니코드 검출 시 실패
- 위반 시 `[X]` 출력과 함께 커밋 차단

워크플로-스킬 정합성 검증은 필요 시 이슈 기반으로 테스트를 추가하여 보강한다.

---

*Last updated: 2026-01-26*
*Maintainer: Agent Context Team*
