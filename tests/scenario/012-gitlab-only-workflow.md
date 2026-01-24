# 012 - GitLab Only Workflow (JIRA/Confluence 없이)

## 목적

- **GitLab만 사용하는 환경**에서 전체 개발 사이클이 정상 동작하는지 확인합니다.
- Issue Tracker: GitLab Issues
- Code Review: GitLab Merge Requests
- JIRA/Confluence 없이 `agent` + `pm` CLI 조합으로 워크플로우 실행

## 전제/준비

### 필수 요구사항

- GitLab repository 접근 권한
- GitLab 토큰 설정:
  - 환경변수: `GITLAB_TOKEN`
  - 또는 파일: `.secrets/gitlab-api-token`

### 선택 요구사항 (권장)

- GitLab CLI (`glab`) 설치: https://gitlab.com/gitlab-org/cli
  ```bash
  # macOS
  brew install glab
  
  # Ubuntu/Debian
  # https://gitlab.com/gitlab-org/cli/-/releases 에서 다운로드
  
  # 로그인
  glab auth login
  ```

### 프로젝트 설정 (.project.yaml)

```yaml
# JIRA 없이 GitLab만 사용
gitlab:
  base_url: https://gitlab.com  # 또는 self-hosted URL
  project: namespace/project    # e.g., myorg/myproject

branch:
  feature_prefix: feat/
  bugfix_prefix: fix/
  hotfix_prefix: hotfix/
```

## 시나리오 상황

- JIRA 라이선스가 없거나, GitLab을 통합 플랫폼으로 사용하는 환경
- GitLab Issues로 작업 관리, GitLab MRs로 코드 리뷰 수행

---

## 커맨드 시퀀스

### 0) 상태 확인

```bash
agent status
pm config show
pm gitlab me
```

**기대 결과**
- `pm gitlab me`가 GitLab 사용자 정보 출력
- JIRA 설정이 없어도 에러 없이 진행 가능

### 1) GitLab Issue 생성

#### Option A: pm CLI 사용

```bash
pm gitlab issue create "Add user authentication feature" --description "Implement OAuth2 login flow"
```

#### Option B: glab CLI 사용 (더 많은 옵션)

```bash
glab issue create \
  --title "Add user authentication feature" \
  --description "Implement OAuth2 login flow" \
  --label "enhancement" \
  --assignee "@me" \
  --milestone "Sprint 5"
```

**기대 결과**
- `(v) GitLab issue: #<IID>` 출력
- GitLab Issues 페이지에서 확인 가능

### 2) 개발자가 작업 시작

```bash
# Issue IID를 task-id로 사용 (예: gl-42)
agent dev start gl-42

agent dev status
agent dev list
```

**기대 결과**
- 브랜치 생성: `feat/gl-42` 또는 `feat/gl-42-add-user-auth`
- `.context/gl-42/` 디렉터리 생성

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
- 커밋 메시지에 `Closes #42` 포함 시 MR 머지 때 자동으로 Issue 닫힘

### 5) 검증/회고

```bash
agent dev verify
agent dev retro
```

**기대 결과**
- `.context/gl-42/verification.md` 생성
- `.context/gl-42/retrospective.md` 생성

### 6) MR 생성 (제출)

#### Option A: agent CLI 사용

```bash
agent dev submit --sync
```

#### Option B: pm CLI 직접 사용

```bash
pm gitlab mr create \
  --source feat/gl-42 \
  --target main \
  --title "feat(auth): implement OAuth2 login" \
  --description "Closes #42"
```

#### Option C: glab CLI 사용 (더 많은 옵션)

```bash
glab mr create \
  --title "feat(auth): implement OAuth2 login" \
  --description "$(cat << 'EOF'
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
  --assignee "@me" \
  --reviewer "teammate1,teammate2" \
  --milestone "Sprint 5"
```

**기대 결과**
- `(v) Created: !<MR_IID>` 출력
- MR URL 출력

### 7) 매니저/리뷰어 리뷰

```bash
# MR 목록 확인
agent mgr pending
# 또는
pm gitlab mr list

# MR 상세 확인
pm gitlab mr view <MR_IID>
# 또는
glab mr view <MR_IID>

# 리뷰 승인 (glab CLI)
glab mr approve <MR_IID>

# 코멘트 추가
glab mr note <MR_IID> --message "LGTM!"
```

**기대 결과**
- MR 목록/상세 정보 확인 가능
- 리뷰 승인 처리

### 8) 머지 & 정리

```bash
# 머지 (glab CLI 권장)
glab mr merge <MR_IID> --squash --remove-source-branch

# Context 정리
agent dev cleanup gl-42
```

**기대 결과**
- MR 머지됨
- Issue #42 자동 닫힘 (커밋 메시지에 `Closes #42` 있을 경우)
- 소스 브랜치 삭제됨

---

## 체크리스트

| 단계 | 확인 항목 | 결과 |
|------|----------|------|
| 0 | `pm gitlab me`가 사용자 정보를 출력하는가 | [ ] |
| 1 | GitLab Issue가 생성되었는가 | [ ] |
| 2 | `agent dev start`가 브랜치와 `.context/`를 생성했는가 | [ ] |
| 3 | `agent dev check`가 크래시 없이 완료되었는가 | [ ] |
| 4 | 커밋이 정상 생성되었는가 | [ ] |
| 5 | `agent dev verify/retro`가 산출물을 생성했는가 | [ ] |
| 6 | MR이 생성되었는가 | [ ] |
| 7 | MR 목록/상세 조회가 가능한가 | [ ] |
| 8 | 머지 후 Issue가 닫혔는가 | [ ] |

---

## Manual Flow (glab CLI Only)

Agent 없이 `glab` CLI로 동일한 워크플로우를 수행하는 방법입니다.

```bash
# 1. Issue 생성
glab issue create --title "Add feature X" --description "Description" --assignee "@me"
# -> #42 생성됨

# 2. 브랜치 생성
git checkout -b feat/gl-42 main

# 3. 개발 작업
vim src/feature.py
make lint
make test

# 4. 커밋
git add -A
git commit -m "feat: add feature X

Closes #42"

# 5. Push & MR 생성
git push -u origin feat/gl-42
glab mr create --title "feat: add feature X" --description "Closes #42"

# 6. 리뷰 & 머지
glab mr approve 99
glab mr merge 99 --squash --remove-source-branch

# 7. 정리
git checkout main
git pull
git branch -d feat/gl-42
```

---

## Troubleshooting

### glab CLI 인증 문제

```bash
# 상태 확인
glab auth status

# 재로그인
glab auth login

# 토큰으로 로그인 (self-hosted)
glab auth login --hostname gitlab.company.com --token <TOKEN>
```

### pm CLI에서 GitLab 설정 안 됨

```bash
# .project.yaml 확인
cat .project.yaml | grep -A3 gitlab

# 토큰 확인
echo $GITLAB_TOKEN
cat .secrets/gitlab-api-token
```

### Self-hosted GitLab 설정

```yaml
# .project.yaml
gitlab:
  base_url: https://gitlab.company.com
  project: team/project-name
```

```bash
# glab CLI 설정
glab config set -g host gitlab.company.com
glab auth login --hostname gitlab.company.com
```

### JIRA 관련 경고 메시지

JIRA 설정이 없으면 일부 경고가 나올 수 있으나, GitLab 기능은 정상 동작합니다:
```
[WARN] Jira not configured, skipping Jira integration
```

---

## 참고: GitLab vs JIRA 기능 매핑

| JIRA 기능 | GitLab 대체 |
|-----------|------------|
| Issue 생성 | `glab issue create` |
| Issue 상태 전환 | Labels + Boards |
| Sprint | Milestones + Iterations |
| Assignee | `--assignee` 옵션 |
| Epic | Epics (Premium) 또는 Labels |
| 의존관계 | Related Issues / Linked Items |
| Story Points | Weight 필드 |

---

## CLI 비교

| 작업 | pm CLI | glab CLI |
|------|--------|----------|
| Issue 목록 | `pm gitlab issue list` | `glab issue list` |
| Issue 생성 | `pm gitlab issue create` | `glab issue create` |
| MR 목록 | `pm gitlab mr list` | `glab mr list` |
| MR 생성 | `pm gitlab mr create` | `glab mr create` |
| MR 상세 | `pm gitlab mr view` | `glab mr view` |
| MR 머지 | - | `glab mr merge` |
| 리뷰 승인 | - | `glab mr approve` |
| 코멘트 | - | `glab mr note` |

> **권장**: 기본 작업은 `pm` CLI로, 고급 기능(머지, 리뷰, Milestones 등)은 `glab` CLI로 사용

---

## GitLab CI/CD 연동

GitLab만 사용할 때의 추가 이점: CI/CD 파이프라인이 자동으로 연동됩니다.

```yaml
# .gitlab-ci.yml 예시
stages:
  - lint
  - test
  - deploy

lint:
  stage: lint
  script:
    - make lint

test:
  stage: test
  script:
    - make test
  coverage: '/TOTAL.*\s+(\d+%)/'

deploy:
  stage: deploy
  script:
    - make deploy
  only:
    - main
```

MR 생성 시 자동으로 파이프라인이 실행되고, MR 페이지에서 결과를 확인할 수 있습니다.
