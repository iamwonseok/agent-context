# agent-context

에이전트 기반 개발을 위한 워크플로 템플릿.

**설계 철학**: Thin Skill / Thick Workflow 패턴은 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)를 참고.

## 왜 이 프로젝트인가?

**문제**:
- 새 프로젝트마다 워크플로를 처음부터 구성
- 반복 작업과 구조의 비일관성
- AI 에이전트 협업에 대한 표준 부재

**해결**:
| 구성요소 | 목적 | 위치 |
|-----------|---------|----------|
| Skills | 범용 템플릿 | `skills/` |
| Workflows | 컨텍스트 기반 오케스트레이션 | `workflows/` |
| CLI Tools | JIRA/Confluence 인터페이스 | `tools/pm/` |

**목표**: AI 에이전트가 CLI(`git`, `gh`, `glab`, `pm`)로 모든 작업을 수행하며 브라우저 전환을 최소화.

## 빠른 시작

```bash
# 1. 레포 클론
git clone https://github.com/your-org/agent-context.git
cd agent-context

# 2. 의존성 설치
pip install pre-commit
brew install gh glab jq yq

# 3. 도구 설정
gh auth login      # GitHub authentication
glab auth login    # GitLab authentication

# 4. pm CLI 설정 (JIRA/Confluence)
export PATH="$PATH:$(pwd)/tools/pm/bin"
pm config init     # Initialize project configuration

# 5. pre-commit 훅 설정
pre-commit install

# 6. 작업 시작
git checkout -b feat/TASK-123
# ... make changes ...
pre-commit run --all-files
git commit -m "feat: add new feature"
git push origin feat/TASK-123
gh pr create --title "TASK-123: description"
```

## 프로젝트 구조

```
agent-context/
├── docs/                # 문서
│   ├── ARCHITECTURE.md  # 설계 철학
│   ├── convention/      # 코딩 컨벤션
│   └── rfc/             # 설계 제안(RFC)
├── skills/              # 범용 스킬 템플릿(Thin)
│   ├── analyze.md       # 상황 이해
│   ├── design.md        # 설계 접근
│   ├── implement.md     # 구현
│   ├── test.md          # 품질 검증
│   └── review.md        # 결과 확인
├── workflows/           # 컨텍스트 기반 워크플로(Thick)
│   ├── solo/            # 개인 개발
│   │   ├── feature.md
│   │   ├── bugfix.md
│   │   └── hotfix.md
│   ├── team/            # 팀 협업
│   │   ├── sprint.md
│   │   └── release.md
│   └── project/         # 조직 레벨
│       ├── quarter.md
│       └── roadmap.md
├── tools/               # CLI 도구
│   └── pm/              # JIRA/Confluence API
└── tests/               # 테스트
    ├── skills/          # 스킬 검증 테스트
    └── workflows/       # 워크플로 통합 테스트
```

## 핵심 개념

### Engineering Coordinate System

```
Y-Axis (Layer)              X-Axis (Timeline)
---------------------------------------------------------
PROJECT (Org)               Plan --> Execute --> Review
    |
TEAM (Squad)                Plan --> Execute --> Review
    |
SOLO (Dev)                  Plan --> Execute --> Review
```

### Thin Skill / Thick Workflow

| 개념 | 역할 | 비유 |
|---------|------|---------|
| **Skill** | 범용 템플릿 | Interface, Abstract class |
| **Workflow** | 컨텍스트 주입 | DI Container, Implementation |

**Skills (Thin)**: 5개 범용 템플릿
- 입력 중심(빈칸 채우기)
- HOW에 집중: 방법, 체크리스트
- 컨텍스트 없음: 티켓 ID, 프로젝트명 배제

**Workflows (Thick)**: 컨텍스트 기반 오케스트레이션
- 현재 컨텍스트를 스킬 입력으로 매핑
- WHAT에 집중: 무엇을 어디에 넣는가
- 컨텍스트 인지: 티켓, 도구, 데드라인

## CLI 도구

### Git Operations

버전 관리는 표준 `git` 명령을 사용:

```bash
git checkout -b feat/TASK-123   # Create feature branch
git add .                       # Stage changes
git commit -m "feat: message"   # Commit changes
git push origin feat/TASK-123   # Push to remote
```

### GitHub CLI (gh)

```bash
gh auth login                   # Authenticate
gh pr create                    # Create pull request
gh pr list                      # List pull requests
gh pr view 123                  # View PR details
gh pr merge 123                 # Merge PR
```

### GitLab CLI (glab)

```bash
glab auth login                 # Authenticate
glab mr create                  # Create merge request
glab mr list                    # List merge requests
glab mr view 123                # View MR details
glab mr merge 123               # Merge MR
```

### pm (JIRA/Confluence)

```bash
pm config init                  # Initialize configuration
pm jira issue list              # List JIRA issues
pm jira issue view TASK-123     # View issue details
pm jira issue create "Title"    # Create new issue
pm jira issue transition        # Change issue status
pm confluence page list         # List Confluence pages
```

## 필수 도구

| 도구 | 목적 | 설치 |
|------|---------|---------|
| `git` | 버전 관리 | 대부분 사전 설치 |
| `gh` | GitHub CLI | `brew install gh` |
| `glab` | GitLab CLI | `brew install glab` |
| `pre-commit` | 린팅/포맷팅 | `pip install pre-commit` |
| `jq` | JSON 처리 | `brew install jq` |
| `yq` | YAML 처리 | `brew install yq` |

## 문서

| 문서 | 설명 |
|----------|-------------|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | 설계 철학 |
| [docs/convention/](docs/convention/) | 코딩 컨벤션 |
| [docs/rfc/](docs/rfc/) | 설계 제안(RFC) |
| [docs/reference/](docs/reference/) | 외부 레퍼런스와 인용 |
| [skills/](skills/) | 범용 스킬 템플릿 |
| [workflows/](workflows/) | 컨텍스트 기반 워크플로 |

## 라이선스

MIT License - 자세한 내용은 [LICENSE](LICENSE)를 참고.
