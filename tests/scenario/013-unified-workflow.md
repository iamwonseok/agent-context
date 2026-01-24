# 013 - Unified Workflow (Platform-Agnostic)

## 목적

- **플랫폼에 관계없이 동일한 명령어**로 전체 개발 사이클을 실행합니다.
- `project.yaml` 설정에 따라 적절한 플랫폼(JIRA/GitLab/GitHub)이 자동 선택됩니다.
- 하나의 시나리오로 모든 환경(GitHub-only, GitLab-only, JIRA+GitLab 등)을 테스트할 수 있습니다.

## 지원 환경 조합

| 환경 | Issue Tracker | Code Review | Documentation |
|------|--------------|-------------|---------------|
| GitHub only | GitHub Issues | GitHub PR | - |
| GitLab only | GitLab Issues | GitLab MR | - |
| JIRA + GitLab | JIRA | GitLab MR | Confluence |
| JIRA + GitHub | JIRA | GitHub PR | Confluence |
| Full Stack | JIRA | GitLab MR | Confluence |

## Provider 자동 선택 규칙

| 기능 | 우선순위 |
|------|---------|
| Issue Tracking | JIRA > GitLab > GitHub |
| Code Review | GitLab > GitHub |
| Documentation | Confluence > GitLab > GitHub |

명시적 설정으로 재정의 가능:
```yaml
# .project.yaml
providers:
  issue: github       # 강제로 GitHub Issues 사용
  code_review: github # 강제로 GitHub PR 사용
  document: confluence
```

---

## 커맨드 시퀀스 (Unified)

### 0) Provider 설정 확인

```bash
agent status
pm config show
pm provider show
```

**기대 결과**
```
==================================================
Provider Configuration
==================================================

[Issue Tracking]
  Provider: jira
  Platform: JIRA (https://company.atlassian.net)

[Code Review]
  Provider: gitlab
  Platform: GitLab Merge Requests (ns/project)

[Documentation]
  Provider: confluence
  Platform: Confluence (https://company.atlassian.net)
==================================================
```

### 1) Issue 생성 (Unified)

```bash
pm issue create "Add user authentication feature" --type Task
```

**기대 결과 (설정에 따라 다름)**
- JIRA: `(v) Issue created: PROJ-123`
- GitLab: `(v) Issue created: gl-42`
- GitHub: `(v) Issue created: gh-42`

### 2) 개발자가 작업 시작

```bash
# Issue ID를 task-id로 사용
agent dev start PROJ-123  # JIRA
agent dev start gl-42     # GitLab
agent dev start gh-42     # GitHub

agent dev status
agent dev list
```

**기대 결과**
- 브랜치 생성: `feat/PROJ-123-add-user-auth` 또는 `feat/gl-42-add-user-auth`
- `.context/<task-id>/` 디렉터리 생성

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

Refs: PROJ-123"
```

### 5) 검증/회고

```bash
agent dev verify
agent dev retro
```

**기대 결과**
- `.context/<task-id>/verification.md` 생성
- `.context/<task-id>/retrospective.md` 생성

### 6) MR/PR 생성 (Unified)

#### Option A: agent CLI (권장)

```bash
agent dev submit --sync
```

#### Option B: pm review (직접)

```bash
pm review create --draft
pm review create --title "feat(auth): implement OAuth2 login"
```

**기대 결과 (설정에 따라 다름)**
- GitLab: `(v) Created: !123` + MR URL
- GitHub: `(v) Created: #45` + PR URL

### 7) MR/PR 목록 및 상세 조회 (Unified)

```bash
pm review list
pm review view 123
```

**기대 결과**
- 플랫폼에 관계없이 동일한 형식으로 출력

### 8) Issue 목록 조회 (Unified)

```bash
pm issue list
pm issue list --status closed
pm issue list --limit 50
```

**기대 결과**
- 설정된 issue provider의 이슈 목록 출력

---

## 체크리스트

| 단계 | 확인 항목 | 결과 |
|------|----------|------|
| 0 | `pm provider show`가 설정된 provider를 출력하는가 | [ ] |
| 1 | `pm issue create`가 설정된 provider로 이슈를 생성하는가 | [ ] |
| 2 | `agent dev start`가 브랜치와 `.context/`를 생성했는가 | [ ] |
| 3 | `agent dev check`가 크래시 없이 완료되었는가 | [ ] |
| 4 | 커밋이 정상 생성되었는가 | [ ] |
| 5 | `agent dev verify/retro`가 산출물을 생성했는가 | [ ] |
| 6 | `pm review create`가 설정된 provider로 MR/PR을 생성하는가 | [ ] |
| 7 | `pm review list/view`가 동작하는가 | [ ] |
| 8 | `pm issue list`가 동작하는가 | [ ] |

---

## 환경별 테스트

### Test Case 1: GitHub Only

```yaml
# .project.yaml
github:
  repo: myorg/myrepo
```

```bash
pm provider show
# -> Issue: github, Review: github

pm issue create "Test feature"
# -> (v) Issue created: gh-1

pm review create --title "Test PR"
# -> (v) Created: #1
```

### Test Case 2: GitLab Only

```yaml
# .project.yaml
gitlab:
  base_url: https://gitlab.example.com
  project: ns/proj
```

```bash
pm provider show
# -> Issue: gitlab, Review: gitlab

pm issue create "Test feature"
# -> (v) Issue created: gl-1

pm review create --title "Test MR"
# -> (v) Created: !1
```

### Test Case 3: JIRA + GitLab

```yaml
# .project.yaml
jira:
  base_url: https://company.atlassian.net
  project_key: PROJ
  email: user@company.com

gitlab:
  base_url: https://gitlab.example.com
  project: ns/proj
```

```bash
pm provider show
# -> Issue: jira, Review: gitlab

pm issue create "Test feature"
# -> (v) Issue created: PROJ-123

pm review create --title "Test MR"
# -> (v) Created: !1
```

### Test Case 4: Explicit Provider Override

```yaml
# .project.yaml
jira:
  base_url: https://company.atlassian.net
  project_key: PROJ

gitlab:
  base_url: https://gitlab.example.com
  project: ns/proj

github:
  repo: myorg/myrepo

providers:
  issue: github       # JIRA 대신 GitHub Issues 사용
  code_review: github # GitLab 대신 GitHub PR 사용
```

```bash
pm provider show
# -> Issue: github, Review: github (override)
```

---

## Unified vs Platform-specific 명령어

### Unified (권장)

```bash
pm issue create "Title"      # 자동 선택
pm issue list
pm review create
pm review list
pm doc create "Title"
pm doc list
```

### Platform-specific (직접 호출)

```bash
pm jira issue create "Title"
pm github issue create "Title"
pm gitlab issue create "Title"

pm github pr create ...
pm gitlab mr create ...

pm confluence page create ...
```

**사용 시점**
- Unified: 일반적인 워크플로우, 시나리오 테스트
- Platform-specific: 디버깅, 플랫폼 고유 기능 사용

---

## Troubleshooting

### "No issue provider configured"

```bash
# 설정 확인
pm config show
pm provider show

# .project.yaml에 최소 하나의 플랫폼 설정 필요
```

### Provider 우선순위 변경하고 싶을 때

```yaml
# .project.yaml에 명시적 설정 추가
providers:
  issue: github       # JIRA 대신 GitHub 사용
  code_review: github # GitLab 대신 GitHub 사용
```

### 특정 플랫폼만 사용하고 싶을 때

```yaml
# GitHub만 사용
github:
  repo: myorg/myrepo

# 다른 플랫폼 설정 제거 또는 주석 처리
# jira: ...
# gitlab: ...
```

---

## 아키텍처

```
┌─────────────────────────────────────────────────────┐
│              Unified CLI Layer                      │
│         pm issue | pm review | pm doc               │
├─────────────────────────────────────────────────────┤
│              Provider Selection                     │
│         project.yaml + Auto-detection               │
├─────────────────────────────────────────────────────┤
│  JIRA  │  GitLab  │  GitHub  │  Confluence          │
│  API   │  API     │  API     │  API                 │
└─────────────────────────────────────────────────────┘
```

**장점**
- 시나리오 테스트가 플랫폼에 독립적
- 환경 변경 시 `.project.yaml`만 수정
- 기존 플랫폼별 명령어도 유지 (하위 호환성)
