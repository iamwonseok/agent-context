# RFC (Request for Comments)

## 개요

RFC는 구현 전에 중요한 설계 결정을 구조적으로 기록하기 위한 문서다.

**핵심 철학:**
- RFC 초안은 **개인 작업 공간**에 둔다(커밋하지 않음)
- 논의는 **Issue Tracker**(GitHub, GitLab, JIRA 등)에서 진행한다
- **구현된 RFC만** 참고용으로 이곳에 보관한다

---

## RFC 라이프사이클

```
Draft (local only) -> Issue (GitHub/GitLab/JIRA) -> Implementation -> Archive (docs/rfc/)
   |                        |                    |                |
   Personal              Discussion           Execute         Reference
   Workspace              & Review              Code           Material
```

---

## 워크플로

### 1. RFC 초안 작성

개인 작업 공간에서 RFC를 작성한다(커밋하지 않음):

```bash
# Find next number (check docs/rfc/)
ls -1 docs/rfc/*.md 2>/dev/null | grep -o '[0-9]\{3\}' | sort -n | tail -1

# Create new RFC
NEXT_NUM=$(printf "%03d" $((LAST_NUM + 1)))
cp docs/rfc/000-template.md "/tmp/${NEXT_NUM}-short-description.md"

# Edit RFC
# Fill in all required sections
```

**위치:** 로컬 파일(예: `/tmp/NNN-short-description.md`), 커밋하지 않음

### 2. Issue 생성

RFC 초안이 준비되면 논의를 위한 이슈를 생성한다.

`.project.yaml`의 설정(`roles.issue`, `roles.vcs`, `roles.review`)에 따라 도구를 선택한다.

```bash
# GitHub
gh issue create \
  --title "RFC-NNN: Short Description" \
  --label "rfc,proposal" \
  --body-file /tmp/NNN-short-description.md

# GitLab
# Note: glab does not have a stable --body-file flag across versions.
# Use --description and pass content via your shell, or paste manually.
glab issue create \
  --title "RFC-NNN: Short Description" \
  --label "rfc,proposal" \
  --description "$(cat /tmp/NNN-short-description.md)"

# JIRA (pm)
# Note: pm supports --description as a string (not a file flag).
pm jira issue create "RFC-NNN: Short Description" \
  --type Task \
  --description "$(cat /tmp/NNN-short-description.md)"
```

**결과:** Issue URL이 단일 진실 소스가 된다

### 3. 논의 및 결정

- 이슈 댓글로 피드백 수집
- 피드백을 반영해 로컬 RFC 초안을 수정
- 이슈 설명을 수정하거나 댓글 추가
- RFC 상태 업데이트:
  - `Proposed` (initial state)
  - `Accepted` (approved for implementation)
  - `Rejected` (not proceeding)

### 4. 구현

승인되면 구현 계획에 따라 진행한다:

```bash
# Create feature branch
git checkout -b feat/rfc-NNN-short-description

# Implement according to RFC plan
# Reference RFC in commits
git commit -m "feat: implement RFC-NNN phase 1"

# Update RFC status in local draft (optional)
# Status: Accepted -> Implemented
```

### 5. 아카이브 (선택)

구현이 끝나면 필요에 따라 RFC를 `docs/rfc/`에 보관한다:

```bash
# Copy implemented RFC to docs/rfc/ for permanent reference
cp /tmp/NNN-short-description.md docs/rfc/

# Commit as documentation
git add docs/rfc/NNN-short-description.md
git commit -m "docs: archive RFC-NNN (implemented)"

# Update index below
```

**Note:** 아카이브는 선택 사항이다. 이슈는 기본 참조 위치로 유지된다.

---

## RFC를 작성해야 하는 경우

### RFC를 작성할 때
- 새로운 주요 기능/컴포넌트 추가
- 기존 아키텍처의 중요한 변경
- 새로운 워크플로/컨벤션 도입
- 장기적인 영향을 갖는 의사결정

### RFC를 생략할 때
- 버그 수정
- 소규모 리팩터링
- 문서 업데이트
- 단순 기능 추가

---

## 컨벤션

이름 규칙, 구조, 상태 규칙은 [docs/convention/rfc.md](../convention/rfc.md)를 참고한다.

---

## 템플릿

RFC 템플릿: `docs/rfc/000-template.md`

새 RFC는 로컬 파일로 만든 뒤, 필요하면 `docs/rfc/`로 아카이브한다.

---

## 아카이브된 RFC (구현 완료)

이 섹션에는 구현 완료 후 아카이브된 RFC를 기록한다.

| Number | Title | Issue | Implemented |
|--------|-------|-------|-------------|
| - | No archived RFCs yet | - | - |

*(구현된 RFC를 아카이브할 때 여기에 추가)*

---

## 관련 문서

- Convention: [docs/convention/rfc.md](../convention/rfc.md)
- Design skill: [skills/design.md](../../skills/design.md)
- Architecture: [docs/ARCHITECTURE.md](../ARCHITECTURE.md)
