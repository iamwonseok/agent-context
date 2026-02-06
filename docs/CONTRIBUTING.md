# 기여자 가이드

agent-context 개발에 참여하는 방법을 안내합니다.

## 목차

- [개발 환경 설정](#개발-환경-설정)
- [프로젝트 구조](#프로젝트-구조)
- [개발 워크플로](#개발-워크플로)
- [테스트](#테스트)
- [데모 실행](#데모-실행)
- [기여 규칙](#기여-규칙)

---

## 개발 환경 설정

### 필수 도구

```bash
# macOS
brew install gh glab jq yq shellcheck shfmt hadolint
pip install pre-commit

# 인증
gh auth login
glab auth login
```

### 저장소 클론 및 설정

```bash
# 1. 저장소 클론
git clone https://github.com/your-org/agent-context.git
cd agent-context

# 2. pre-commit 훅 설치
pre-commit install

# 3. 훅 동작 확인
pre-commit run --all-files
```

### 권장 에디터 설정

VSCode/Cursor 사용 시 권장 확장:

- ShellCheck (shell script linting)
- shell-format (shfmt)
- Markdown All in One
- YAML (Red Hat)

---

## 프로젝트 구조

```
agent-context/
├── .cursorrules           # 에이전트 규칙 (이 저장소용)
├── .pre-commit-config.yaml
│
├── bin/                   # CLI 진입점
│   └── agent-context.sh   # 메인 CLI
│
├── lib/                   # 공통 라이브러리
│   ├── logging.sh         # 로깅 ([V]/[X]/[!] 마커)
│   └── platform.sh        # 플랫폼 감지
│
├── builtin/               # 내장 명령어
│   ├── install.sh         # 설치 스크립트
│   ├── doctor.sh, tests.sh, audit.sh
│   ├── init.sh, update.sh, upgrade.sh
│   └── clean.sh, log.sh, report.sh
│
├── docs/                  # 문서
│   ├── ARCHITECTURE.md    # 설계 철학 (SSOT)
│   ├── USER_GUIDE.md      # 사용자 가이드
│   ├── CONTRIBUTING.md    # 이 파일
│   ├── convention/        # 코딩 컨벤션
│   └── rfc/               # 설계 제안
│
├── skills/                # 범용 스킬 템플릿 (Thin)
│   ├── README.md
│   ├── analyze.md
│   ├── design.md
│   ├── implement.md
│   ├── test.md
│   └── review.md
│
├── workflows/             # 컨텍스트 기반 워크플로 (Thick)
│   ├── README.md          # 공통 정책 (Global Defaults)
│   ├── solo/              # 개인 개발
│   ├── team/              # 팀 협업
│   └── project/           # 조직 레벨
│
├── tools/                 # CLI 도구
│   └── pm/                # JIRA/Confluence API
│       ├── bin/pm
│       └── lib/
│
├── templates/             # 설치 시 복사되는 템플릿
│   ├── cursorrules.index_map.tmpl
│   ├── project.yaml.tmpl
│   └── ...
│
└── (removed) demo/, tests/ # 데모/E2E 및 테스트 디렉터리는 제거됨
```

### 핵심 파일 설명

| 파일/디렉토리 | 용도 | 수정 시 주의 |
|--------------|------|-------------|
| `bin/agent-context.sh` | CLI 메인 진입점 | 하위 호환성 유지 |
| `lib/` | 공통 라이브러리 | logging/platform 변경 시 전체 영향 |
| `builtin/` | 내장 명령어 구현 | exit code 규격 준수 (0/1/2/3) |
| `builtin/install.sh` | 사용자 프로젝트에 설치 | 하위 호환성 유지 |
| `skills/` | 범용 템플릿 | Thin 원칙 유지 |
| `workflows/` | 컨텍스트 워크플로 | Thick 원칙 유지 |
| `tools/pm/` | CLI 도구 | POSIX 호환 |
| `docs/ARCHITECTURE.md` | 설계 SSOT | 중요 변경 시 RFC 필요 |

---

## 개발 워크플로

### 브랜치 전략

```bash
# main: 안정 버전
# feat/*: 새 기능
# fix/*: 버그 수정
# docs/*: 문서 변경
# refactor/*: 리팩토링

# 예시
git checkout -b feat/add-new-skill
git checkout -b fix/pm-cli-error
git checkout -b docs/update-readme
```

### 커밋 컨벤션

```bash
# 형식: <type>: <description>
feat: add new analyze skill variant
fix: resolve pm jira authentication error
docs: update installation guide
refactor: simplify workflow loading logic
test: add unit tests for pm config
chore: update pre-commit hooks
```

### PR/MR 생성

```bash
# 1. 변경사항 커밋
git add .
git commit -m "feat: add new feature"

# 2. 품질 검사
pre-commit run --all-files

# 3. 푸시 및 PR 생성
git push origin feat/my-feature
gh pr create --title "feat: Add new feature" --body "Description..."
```

---

## 테스트 (Deprecated)

현재 레포에서는 테스트 러너 기반의 테스트 디렉터리(`tests/`)와 데모(`demo/`)를 유지하지 않습니다.
기본 검증은 `pre-commit`, `agent-context doctor`, `agent-context audit`로 수행합니다.

### 정적 분석

```bash
# 전체 린트 실행
pre-commit run --all-files

# 개별 훅 실행
pre-commit run shellcheck --all-files
pre-commit run shfmt --all-files
pre-commit run trailing-whitespace --all-files
```

### agent-context 내장 검증

```bash
# 저장소 내부 감사 (개발자 모드)
agent-context audit --repo

# 저장소 내부 감사 (개발자 모드)
agent-context audit --repo
```

### 통합 테스트

```bash
# pm CLI 테스트
./tools/pm/bin/pm config show
./tools/pm/bin/pm jira me
```

---

## 데모 실행 (Deprecated)

`demo/` 디렉터리는 제거되었습니다.

---

## 기여 규칙

### 코딩 컨벤션

각 파일 타입별 컨벤션을 따릅니다:

| 파일 타입 | 컨벤션 문서 |
|-----------|------------|
| `*.sh` | [convention/bash.md](convention/bash.md) |
| `*.py` | [convention/python.md](convention/python.md) |
| `*.yml` | [convention/yaml.md](convention/yaml.md) |
| `Makefile` | [convention/make.md](convention/make.md) |

### 언어 정책

| 대상 | 언어 | 이모지 |
|------|------|:------:|
| 코드, 커밋 메시지 | 영어 | 금지 |
| Markdown 문서 | 한국어 우선 | 금지 |
| skills/, workflows/ | 영어 | 금지 |

### PR 체크리스트

- [ ] `pre-commit run --all-files` 통과
- [ ] `agent-context audit --repo` 통과 (저장소 변경 시)
- [ ] 관련 문서 업데이트 (README, 가이드 등)
- [ ] 커밋 메시지 컨벤션 준수

### RFC 프로세스

주요 설계 변경 시 RFC를 작성합니다:

```bash
# RFC 템플릿 복사
cp docs/rfc/000-template.md docs/rfc/XXX-my-proposal.md

# RFC 작성 후 PR 생성
git checkout -b rfc/my-proposal
git add docs/rfc/XXX-my-proposal.md
git commit -m "rfc: propose new feature"
gh pr create --title "RFC: My Proposal"
```

---

## 관련 문서

- [설계 철학 (ARCHITECTURE.md)](ARCHITECTURE.md)
- [RFC 가이드 (rfc/README.md)](rfc/README.md)
