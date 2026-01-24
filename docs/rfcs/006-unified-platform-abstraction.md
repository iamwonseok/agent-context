# RFC-006: Unified Platform Abstraction Layer

## Status: Draft
## Author: wonseok
## Created: 2026-01-25

---

## 1. 개요

`pm` CLI의 플랫폼 추상화 레이어를 확장하여, JIRA/GitLab/GitHub/Confluence의 주요 기능을 공통 언어로 통합합니다.

### 1.1 목표

- 플랫폼에 관계없이 일관된 명령어 제공
- `project.yaml`의 `roles` 설정으로 플랫폼 자동 선택
- 플랫폼 전환 시 학습 비용 최소화

### 1.2 현재 상태

| Unified | 구현 | 지원 플랫폼 |
|---------|------|-------------|
| `pm issue` | O | JIRA, GitLab, GitHub |
| `pm review` | O | GitLab, GitHub |
| `pm doc` | O | Confluence |
| `pm milestone` | X | - |
| `pm label` | X | - |
| `pm board` | X | - |
| `pm wiki` | X | - |

---

## 2. 설계

### 2.1 Unified Commands 확장

```
pm issue      → Issue 관리
pm review     → Code Review (MR/PR)
pm milestone  → 일정 관리 (Sprint/Milestone)
pm label      → 라벨/태그 관리
pm board      → 보드/프로젝트 관리
pm wiki       → Wiki 문서 관리
pm doc        → 문서 관리 (Confluence)
```

### 2.2 플랫폼 매핑

| Unified Command | JIRA | GitLab | GitHub | Confluence |
|-----------------|------|--------|--------|------------|
| `issue create` | Issue | Issue | Issue | - |
| `issue list` | Issue | Issue | Issue | - |
| `issue view` | Issue | Issue | Issue | - |
| `issue close` | Transition | Close | Close | - |
| `review create` | - | MR | PR | - |
| `review list` | - | MR | PR | - |
| `review view` | - | MR | PR | - |
| `review merge` | - | Merge | Merge | - |
| `milestone create` | Sprint* | Milestone | Milestone | - |
| `milestone list` | Sprint | Milestone | Milestone | - |
| `milestone close` | Complete | Close | Close | - |
| `label create` | Label | Label | Label | - |
| `label list` | Label | Label | Label | - |
| `board list` | Board | Board | Project | - |
| `board view` | Board | Board | Project | - |
| `wiki create` | - | Wiki | Wiki | - |
| `wiki list` | - | Wiki | Wiki | - |
| `doc create` | - | - | - | Page |
| `doc list` | - | - | - | Page |

*JIRA Sprint는 Scrum Board에서만 사용 가능

### 2.3 Role 확장

```yaml
# project.yaml
roles:
  vcs: gitlab           # Version Control
  issue: jira           # Issue Tracking
  review: gitlab        # Code Review (MR/PR)
  docs: confluence      # Documentation (Confluence Pages)
  wiki: gitlab          # Wiki Pages (NEW)
  planning: jira        # Planning (Sprint/Milestone/Board) (NEW)
  labeling: gitlab      # Labels (NEW, optional - follows issue if not set)
```

### 2.4 Provider 선택 로직

```
pm milestone list
    ↓
get_planning_provider()
    ↓
roles.planning 확인
    ↓
jira → jira_sprint_list()
gitlab → gitlab_milestone_list()
github → github_milestone_list()
```

---

## 3. 구현 계획

### Phase 1: Milestone/Label (우선순위: HIGH)

가장 자주 사용되는 기능 먼저 구현

#### 3.1.1 pm milestone

```bash
pm milestone list [--state <active|closed|all>]
pm milestone create <TITLE> [--due <DATE>] [--description <TEXT>]
pm milestone view <ID>
pm milestone close <ID>
```

**플랫폼별 구현:**

| 명령 | JIRA | GitLab | GitHub |
|------|------|--------|--------|
| list | `GET /board/{id}/sprint` | `GET /projects/{id}/milestones` | `GET /repos/{owner}/{repo}/milestones` |
| create | `POST /sprint` | `POST /projects/{id}/milestones` | `POST /repos/{owner}/{repo}/milestones` |
| close | `POST /sprint/{id}/complete` | `PUT state=close` | `PATCH state=closed` |

#### 3.1.2 pm label

```bash
pm label list
pm label create <NAME> [--color <HEX>] [--description <TEXT>]
pm label delete <NAME>
```

**플랫폼별 구현:**

| 명령 | JIRA | GitLab | GitHub |
|------|------|--------|--------|
| list | `GET /label` | `GET /projects/{id}/labels` | `GET /repos/{owner}/{repo}/labels` |
| create | `POST /label` | `POST /projects/{id}/labels` | `POST /repos/{owner}/{repo}/labels` |
| delete | `DELETE /label/{id}` | `DELETE /projects/{id}/labels/{name}` | `DELETE /repos/{owner}/{repo}/labels/{name}` |

### Phase 2: Wiki (우선순위: MEDIUM)

```bash
pm wiki list
pm wiki view <SLUG>
pm wiki create <TITLE> --content <TEXT|FILE>
pm wiki update <SLUG> --content <TEXT|FILE>
pm wiki delete <SLUG>
```

**플랫폼별 구현:**

| 명령 | GitLab | GitHub |
|------|--------|--------|
| list | `GET /projects/{id}/wikis` | `gh api /repos/{owner}/{repo}/pages` |
| create | `POST /projects/{id}/wikis` | Git push to wiki repo |
| view | `GET /projects/{id}/wikis/{slug}` | Git clone wiki repo |

*GitHub Wiki는 별도 Git repo로 관리됨 (복잡)

### Phase 3: Board/Project (우선순위: LOW)

```bash
pm board list
pm board view <ID>
pm board create <NAME>
```

복잡도가 높아 Phase 3로 연기

---

## 4. 파일 변경 목록

### 4.1 신규 파일

| 파일 | 설명 |
|------|------|
| `tools/pm/lib/milestone.sh` | Milestone unified functions |
| `tools/pm/lib/label.sh` | Label unified functions |
| `tools/pm/lib/wiki.sh` | Wiki unified functions |

### 4.2 수정 파일

| 파일 | 변경 내용 |
|------|-----------|
| `tools/pm/bin/pm` | 새 unified commands 추가 |
| `tools/pm/lib/provider.sh` | `get_planning_provider()`, `get_wiki_provider()` 추가 |
| `tools/pm/lib/config.sh` | `ROLE_PLANNING`, `ROLE_WIKI` 로드 |
| `tools/pm/lib/jira.sh` | `jira_sprint_*`, `jira_label_*` 함수 추가 |
| `tools/pm/lib/gitlab.sh` | `gitlab_milestone_*`, `gitlab_label_*`, `gitlab_wiki_*` 함수 추가 |
| `tools/pm/lib/github.sh` | `github_milestone_*`, `github_label_*` 함수 추가 |
| `templates/.project.yaml.example` | 새 roles 예시 추가 |
| `tests/e2e/README.md` | 새 시나리오 추가 |

---

## 5. E2E 테스트 시나리오

### Scenario: Milestone Workflow

```bash
# GitLab demo
cd ~/project-iamwonseok/demo-gitlab

# Milestone 생성
pm milestone create "Sprint 1" --due 2026-02-07 --description "First sprint"

# Milestone 확인
pm milestone list

# Issue에 Milestone 연결
pm issue create "Task 1" --milestone "Sprint 1"

# Milestone 종료
pm milestone close 1
```

### Scenario: Label Workflow

```bash
# GitHub demo
cd ~/project-iamwonseok/demo-github

# Label 생성
pm label create "priority:high" --color "ff0000"
pm label create "type:feature" --color "0000ff"

# Label 확인
pm label list

# Issue에 Label 적용
pm issue create "New Feature" --labels "priority:high,type:feature"
```

---

## 6. 타임라인

| Phase | 내용 | 예상 |
|-------|------|------|
| Phase 1 | Milestone + Label | 1-2일 |
| Phase 2 | Wiki | 1일 |
| Phase 3 | Board/Project | 2-3일 |
| E2E Test | 전체 시나리오 검증 | 1일 |

---

## 7. 미해결 사항

1. **JIRA Sprint vs Milestone**: JIRA는 Sprint 개념이 Milestone과 다름 (Board 종속)
2. **GitHub Wiki**: Git repo 기반이라 API만으로 관리 어려움
3. **GitLab Epic**: Premium 기능이라 일반 사용자는 못 씀

---

## 8. 참고

- [GitLab Milestones API](https://docs.gitlab.com/ee/api/milestones.html)
- [GitHub Milestones API](https://docs.github.com/en/rest/issues/milestones)
- [JIRA Sprint API](https://developer.atlassian.com/cloud/jira/software/rest/api-group-sprint/)
