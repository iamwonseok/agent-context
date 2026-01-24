# E2E Test Guide

실제 사용자 환경을 시뮬레이션하는 End-to-End 테스트입니다.

## 테스트 환경 구조

```
~/project-iamwonseok/
├── agent-context/          # 프레임워크 소스 (이 레포)
├── demo-github/            # GitHub E2E 테스트용 프로젝트
│   └── .agent/             # agent-context clone
└── demo-gitlab/            # GitLab E2E 테스트용 프로젝트
    └── .agent/             # agent-context clone
```

## 테스트 레포

| Platform | URL | 용도 |
|----------|-----|------|
| GitHub | https://github.com/iamwonseok/demo | GitHub Issue/PR 테스트 |
| GitLab | https://gitlab.fadutec.dev/soc-ip/demo | GitLab Issue/MR 테스트 |

## 환경 설정

### 1. Demo 레포 Clone

```bash
cd ~/project-iamwonseok

# GitHub demo
git clone git@github.com:iamwonseok/demo.git demo-github

# GitLab demo
git clone git@gitlab.fadutec.dev:soc-ip/demo.git demo-gitlab
```

### 2. Agent-Context 설치

```bash
# GitHub demo에 설치
cd ~/project-iamwonseok/demo-github
git clone git@github.com:iamwonseok/agent-context.git .agent

# GitLab demo에 설치
cd ~/project-iamwonseok/demo-gitlab
git clone git@gitlab.fadutec.dev:wonseok/agent-context.git .agent
```

### 3. 프로젝트 설정

각 demo 레포에 `.project.yaml` 생성:

**demo-github/.project.yaml**
```yaml
roles:
  vcs: github
  issue: github
  review: github

platforms:
  github:
    repo: iamwonseok/demo

branch:
  feature_prefix: feat/
  bugfix_prefix: fix/
```

**demo-gitlab/.project.yaml**
```yaml
roles:
  vcs: gitlab
  issue: gitlab
  review: gitlab

platforms:
  gitlab:
    base_url: https://gitlab.fadutec.dev
    project: soc-ip/demo

branch:
  feature_prefix: feat/
  bugfix_prefix: fix/
```

### 4. API 토큰 설정

```bash
# 각 demo 레포에 .secrets 디렉토리 생성
mkdir -p ~/project-iamwonseok/demo-github/.secrets
mkdir -p ~/project-iamwonseok/demo-gitlab/.secrets

# 토큰 복사 (agent-context에서)
cp ~/project-iamwonseok/agent-context/.secrets/github-api-token ~/project-iamwonseok/demo-github/.secrets/
cp ~/project-iamwonseok/agent-context/.secrets/gitlab-api-token ~/project-iamwonseok/demo-gitlab/.secrets/
```

---

## E2E 시나리오

### Scenario 1: GitHub-only Workflow

**목적**: GitHub Issues + GitHub PRs로 전체 개발 사이클 테스트

```bash
cd ~/project-iamwonseok/demo-github
export PATH="$PWD/.agent/tools/pm/bin:$PATH"

# Step 1: 설정 확인
pm config show
pm provider show

# Step 2: Issue 생성
pm issue create "E2E Test: Add new feature" -b "Testing GitHub workflow"
# => 생성된 Issue 번호 확인 (예: #1)

# Step 3: Issue 확인
pm issue list

# Step 4: Feature Branch 생성
git checkout -b feat/e2e-test-feature

# Step 5: 코드 변경
echo "// E2E test $(date)" >> test.js
git add test.js
git commit -m "feat: add e2e test file"

# Step 6: Push
git push -u origin feat/e2e-test-feature

# Step 7: PR 생성
pm review create --title "feat: E2E Test Feature" -b "Closes #1"
# => 생성된 PR 번호 확인 (예: #2)

# Step 8: PR 확인
pm review list
pm github pr view 2

# Step 9: Cleanup
pm github pr close 2
pm github issue close 1
git checkout main
git branch -D feat/e2e-test-feature
git push origin --delete feat/e2e-test-feature
```

---

### Scenario 2: GitLab-only Workflow

**목적**: GitLab Issues + GitLab MRs로 전체 개발 사이클 테스트

```bash
cd ~/project-iamwonseok/demo-gitlab
export PATH="$PWD/.agent/tools/pm/bin:$PATH"

# Step 1: 설정 확인
pm config show
pm provider show

# Step 2: Issue 생성
pm issue create "E2E Test: Add new feature" -d "Testing GitLab workflow"
# => 생성된 Issue IID 확인 (예: #1)

# Step 3: Issue 확인
pm issue list

# Step 4: Feature Branch 생성
git checkout -b feat/e2e-test-feature

# Step 5: 코드 변경
echo "// E2E test $(date)" >> test.js
git add test.js
git commit -m "feat: add e2e test file"

# Step 6: Push
git push -u origin feat/e2e-test-feature

# Step 7: MR 생성
pm review create --title "feat: E2E Test Feature" -d "Closes #1"
# => 생성된 MR IID 확인 (예: !1)

# Step 8: MR 확인
pm review list
pm gitlab mr view 1

# Step 9: Cleanup
# GitLab MR/Issue close는 웹에서 또는 API로
git checkout main
git branch -D feat/e2e-test-feature
git push origin --delete feat/e2e-test-feature
```

---

### Scenario 3: Milestone/Label Workflow

**목적**: Milestone과 Label 생성/관리 테스트

```bash
cd ~/project-iamwonseok/demo-gitlab
export PATH="$PWD/.agent/tools/pm/bin:$PATH"

# Step 1: Milestone 생성
pm milestone create "Sprint 1" --due 2026-02-07 -d "First sprint"
# => 생성된 Milestone ID 확인 (예: #1)

# Step 2: Milestone 확인
pm milestone list
pm milestone view 1

# Step 3: Label 생성
pm label create "priority:high" --color "ff0000"
pm label create "type:feature" --color "0000ff"

# Step 4: Label 확인
pm label list

# Step 5: Cleanup
pm milestone close 1
pm label delete "priority:high"
pm label delete "type:feature"
```

---

### Scenario 4: Wiki Workflow (GitLab Only)

**목적**: Wiki 페이지 생성/수정/삭제 테스트

```bash
cd ~/project-iamwonseok/demo-gitlab
export PATH="$PWD/.agent/tools/pm/bin:$PATH"

# Step 1: Wiki 페이지 생성
pm wiki create "Getting Started" -c "# Getting Started

Welcome to the project wiki."
# => 생성된 Slug 확인 (예: Getting-Started)

# Step 2: Wiki 목록 확인
pm wiki list

# Step 3: Wiki 페이지 보기
pm wiki view "Getting-Started"

# Step 4: Wiki 페이지 업데이트
pm wiki update "Getting-Started" -c "# Getting Started

Welcome to the project wiki.

## Quick Links
- [Installation](Installation)
- [Configuration](Configuration)"

# Step 5: 업데이트 확인
pm wiki view "Getting-Started"

# Step 6: Cleanup
pm wiki delete "Getting-Started"
```

**Note**: GitHub Wiki는 별도 Git 저장소로 관리되어 API 지원이 제한됩니다.

---

### Scenario 5: Unified Command 전환 테스트

**목적**: `roles` 설정 변경 시 명령어가 올바른 플랫폼으로 라우팅되는지 확인

```bash
cd ~/project-iamwonseok/demo-github

# GitHub 모드 (기본)
pm provider show
# => Issue: github, Review: github

pm issue list  # GitHub Issues 표시

# GitLab 모드로 전환 (project.yaml 수정)
yq -i '.roles.issue = "gitlab"' .project.yaml
yq -i '.platforms.gitlab.base_url = "https://gitlab.fadutec.dev"' .project.yaml
yq -i '.platforms.gitlab.project = "wonseok/demo"' .project.yaml

pm provider show
# => Issue: gitlab (변경됨)

pm issue list  # GitLab Issues 표시

# 원복
yq -i '.roles.issue = "github"' .project.yaml
```

---

## 자동화 스크립트

### tests/e2e/run-e2e.sh

E2E 테스트 자동 실행 스크립트 (TODO: 구현 예정)

```bash
./tests/e2e/run-e2e.sh --platform github  # GitHub만
./tests/e2e/run-e2e.sh --platform gitlab  # GitLab만
./tests/e2e/run-e2e.sh --all              # 전체
```

---

## 체크리스트

### GitHub Workflow
- [ ] pm config show 정상
- [ ] pm issue create 정상
- [ ] pm issue list 정상
- [ ] pm review create (PR) 정상
- [ ] pm review list 정상

### GitLab Workflow
- [ ] pm config show 정상
- [ ] pm issue create 정상
- [ ] pm issue list 정상
- [ ] pm review create (MR) 정상
- [ ] pm review list 정상

### Unified Commands
- [ ] roles 전환 시 provider 변경 확인
- [ ] pm issue가 올바른 플랫폼으로 라우팅

### Milestone/Label (Phase 1)
- [ ] pm milestone list 정상
- [ ] pm milestone create 정상
- [ ] pm milestone view 정상
- [ ] pm milestone close 정상
- [ ] pm label list 정상
- [ ] pm label create 정상
- [ ] pm label delete 정상

### Wiki (Phase 2 - GitLab Only)
- [ ] pm wiki list 정상
- [ ] pm wiki create 정상
- [ ] pm wiki view 정상
- [ ] pm wiki update 정상
- [ ] pm wiki delete 정상

---

## 테스트 결과 기록

테스트 완료 후 `tests/test-report.sh` 실행:

```bash
cd ~/project-iamwonseok/demo-github
../.agent/tests/test-report.sh
```

리포트에 commit, user@hostname 자동 기록됨.
