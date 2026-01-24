# 011 - GitHub Only Workflow (JIRA/Confluence 없이)

## 목적

- **GitHub만 사용하는 환경**에서 전체 개발 사이클이 정상 동작하는지 확인합니다.
- Issue Tracker: GitHub Issues
- Code Review: GitHub Pull Requests
- JIRA/Confluence 없이 `agent` + `pm` CLI 조합으로 워크플로우 실행

## 전제/준비

### 필수 요구사항

- GitHub repository 접근 권한
- GitHub 토큰 설정:
  - 환경변수: `GITHUB_TOKEN`
  - 또는 파일: `.secrets/github-api-token`

### 선택 요구사항 (권장)

- GitHub CLI (`gh`) 설치: https://cli.github.com/
  ```bash
  # macOS
  brew install gh
  
  # Ubuntu/Debian
  sudo apt install gh
  
  # 로그인
  gh auth login
  ```

### 프로젝트 설정 (.project.yaml)

```yaml
# JIRA 없이 GitHub만 사용
github:
  repo: owner/repo  # e.g., myorg/myproject

branch:
  feature_prefix: feat/
  bugfix_prefix: fix/
  hotfix_prefix: hotfix/
```

## 시나리오 상황

- JIRA 라이선스가 없거나, 소규모 팀/오픈소스 프로젝트에서 GitHub만 사용
- GitHub Issues로 작업 관리, GitHub PRs로 코드 리뷰 수행

---

## 커맨드 시퀀스

### 0) 상태 확인

```bash
agent status
pm config show
pm github me
```

**기대 결과**
- `pm github me`가 GitHub 사용자 정보 출력
- JIRA 설정이 없어도 에러 없이 진행 가능

### 1) GitHub Issue 생성

#### Option A: pm CLI 사용

```bash
pm github issue create "Add user authentication feature" --body "Implement OAuth2 login flow"
```

#### Option B: gh CLI 사용 (더 많은 옵션)

```bash
gh issue create \
  --title "Add user authentication feature" \
  --body "Implement OAuth2 login flow" \
  --label "enhancement" \
  --assignee "@me"
```

**기대 결과**
- `(v) GitHub issue: #<NUMBER>` 출력
- GitHub Issues 페이지에서 확인 가능

### 2) 개발자가 작업 시작

```bash
# Issue 번호를 task-id로 사용 (예: gh-42)
agent dev start gh-42

agent dev status
agent dev list
```

**기대 결과**
- 브랜치 생성: `feat/gh-42` 또는 `feat/gh-42-add-user-auth`
- `.context/gh-42/` 디렉터리 생성

### 3) 개발/테스트 루프

```bash
# 코드 작성 후
agent dev check
```

**기대 결과**
- Lint/Test 체크 실행
- 경고는 출력하되 하드 블로킹 없음

### 4) 커밋

```bash
git add -A
git commit -m "feat(auth): implement OAuth2 login flow

- Add OAuth2 provider configuration
- Implement callback handler
- Add session management

Closes #42"
```

**기대 결과**
- 커밋 메시지에 `Closes #42` 포함 시 PR 머지 때 자동으로 Issue 닫힘

### 5) 검증/회고

```bash
agent dev verify
agent dev retro
```

**기대 결과**
- `.context/gh-42/verification.md` 생성
- `.context/gh-42/retrospective.md` 생성

### 6) PR 생성 (제출)

#### Option A: agent CLI 사용

```bash
agent dev submit --sync
```

#### Option B: pm CLI 직접 사용

```bash
pm github pr create \
  --source feat/gh-42 \
  --target main \
  --title "feat(auth): implement OAuth2 login" \
  --description "Closes #42"
```

#### Option C: gh CLI 사용 (더 많은 옵션)

```bash
gh pr create \
  --title "feat(auth): implement OAuth2 login" \
  --body "$(cat << 'EOF'
## Summary
- Implement OAuth2 login flow
- Add session management

## Test Plan
- [x] Unit tests passing
- [x] Manual testing done

Closes #42
EOF
)" \
  --label "enhancement" \
  --reviewer "teammate1,teammate2"
```

**기대 결과**
- `(v) Created: #<PR_NUMBER>` 출력
- PR URL 출력

### 7) 매니저/리뷰어 리뷰

```bash
# PR 목록 확인
agent mgr pending
# 또는
pm github pr list

# PR 상세 확인
pm github pr view <PR_NUMBER>
# 또는
gh pr view <PR_NUMBER>

# 리뷰 코멘트 (gh CLI)
gh pr review <PR_NUMBER> --approve --body "LGTM!"
```

**기대 결과**
- PR 목록/상세 정보 확인 가능
- 리뷰 승인 처리

### 8) 머지 & 정리

```bash
# 머지 (gh CLI 권장)
gh pr merge <PR_NUMBER> --squash --delete-branch

# Context 정리
agent dev cleanup gh-42
```

**기대 결과**
- PR 머지됨
- Issue #42 자동 닫힘 (커밋 메시지에 `Closes #42` 있을 경우)
- 로컬 브랜치 정리됨

---

## 체크리스트

| 단계 | 확인 항목 | 결과 |
|------|----------|------|
| 0 | `pm github me`가 사용자 정보를 출력하는가 | [ ] |
| 1 | GitHub Issue가 생성되었는가 | [ ] |
| 2 | `agent dev start`가 브랜치와 `.context/`를 생성했는가 | [ ] |
| 3 | `agent dev check`가 크래시 없이 완료되었는가 | [ ] |
| 4 | 커밋이 정상 생성되었는가 | [ ] |
| 5 | `agent dev verify/retro`가 산출물을 생성했는가 | [ ] |
| 6 | PR이 생성되었는가 | [ ] |
| 7 | PR 목록/상세 조회가 가능한가 | [ ] |
| 8 | 머지 후 Issue가 닫혔는가 | [ ] |

---

## Manual Flow (gh CLI Only)

Agent 없이 `gh` CLI로 동일한 워크플로우를 수행하는 방법입니다.

```bash
# 1. Issue 생성
gh issue create --title "Add feature X" --body "Description" --assignee "@me"
# -> #42 생성됨

# 2. 브랜치 생성
git checkout -b feat/gh-42 main

# 3. 개발 작업
vim src/feature.py
make lint
make test

# 4. 커밋
git add -A
git commit -m "feat: add feature X

Closes #42"

# 5. Push & PR 생성
git push -u origin feat/gh-42
gh pr create --title "feat: add feature X" --body "Closes #42"

# 6. 리뷰 & 머지
gh pr review 99 --approve
gh pr merge 99 --squash --delete-branch

# 7. 정리
git checkout main
git pull
git branch -d feat/gh-42
```

---

## Troubleshooting

### gh CLI 인증 문제

```bash
# 상태 확인
gh auth status

# 재로그인
gh auth login

# 토큰으로 로그인
gh auth login --with-token < ~/.secrets/github-api-token
```

### pm CLI에서 GitHub 설정 안 됨

```bash
# .project.yaml 확인
cat .project.yaml | grep -A2 github

# 토큰 확인
echo $GITHUB_TOKEN
cat .secrets/github-api-token
```

### JIRA 관련 경고 메시지

JIRA 설정이 없으면 일부 경고가 나올 수 있으나, GitHub 기능은 정상 동작합니다:
```
[WARN] Jira not configured, skipping Jira integration
```

---

## 참고: GitHub vs JIRA 기능 매핑

| JIRA 기능 | GitHub 대체 |
|-----------|------------|
| Issue 생성 | `gh issue create` |
| Issue 상태 전환 | Labels 또는 Projects |
| Sprint | GitHub Projects (Kanban) |
| Assignee | `--assignee` 옵션 |
| Epic | Milestones 또는 Labels |
| 의존관계 | Issue 본문에 링크 |

---

## CLI 비교

| 작업 | pm CLI | gh CLI |
|------|--------|--------|
| Issue 목록 | `pm github issue list` | `gh issue list` |
| Issue 생성 | `pm github issue create` | `gh issue create` |
| PR 목록 | `pm github pr list` | `gh pr list` |
| PR 생성 | `pm github pr create` | `gh pr create` |
| PR 상세 | `pm github pr view` | `gh pr view` |
| PR 머지 | - | `gh pr merge` |
| 리뷰 승인 | - | `gh pr review --approve` |

> **권장**: 기본 작업은 `pm` CLI로, 고급 기능(머지, 리뷰 등)은 `gh` CLI로 사용
