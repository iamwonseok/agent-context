# 006 - Draft MR 반복 리뷰(Dev+Mgr): Iterative Review 사이클

## 목적

- 실무에서 MR/PR은 한 번에 승인되지 않습니다.
- **Draft MR 생성 → 리뷰어 피드백 → 수정/재커밋 → 재요청 → 최종 승인** 사이클을 검증합니다.
- `--draft` 옵션과 반복적인 push/review 플로우가 올바르게 동작하는지 확인합니다.

## 핵심 결론(현재 구현 기준)

- 가능한 것(현재 구현):
  - `agent dev submit --draft`: Draft 상태의 MR 생성
  - 추가 커밋 후 `git push`: 기존 MR에 변경 사항 자동 반영
  - `agent mgr pending`: Draft 포함 MR 목록 조회
  - `agent mgr review <mr-id> --comment "..."`: 리뷰 코멘트 추가
  - `agent mgr approve <mr-id>`: 최종 승인 (human_only)
- 갭(CLI 직접 지원 안 됨):
  - Draft → Ready 전환은 GitLab/GitHub UI 또는 API 직접 호출 필요
  - 리뷰 요청(Request Review) 기능은 플랫폼 UI 사용 권장

## 전제/준비

- `.project.yaml`에 GitLab 또는 GitHub 설정이 되어 있어야 합니다.
- 리뷰어 역할을 할 두 번째 사용자(또는 본인이 두 역할 수행)가 필요합니다.

---

## 시나리오 상황

- 개발자가 새 기능을 구현하고 있습니다.
- 아직 완성되지 않았지만 초기 피드백을 받고 싶어 Draft MR을 생성합니다.
- 리뷰어가 피드백을 주고, 개발자가 수정합니다.
- 이 사이클을 2-3회 반복 후 최종 승인합니다.

---

## 커맨드 시퀀스

### Phase 1: 초기 개발 및 Draft MR 생성

#### 1-1) 작업 시작

```bash
agent dev start TASK-400
agent dev status
```

#### 1-2) 초기 구현 (WIP 상태)

```bash
# 초기 구현 (아직 완성 아님)
echo "function featureX() { /* TODO: implement */ }" > feature-x.js
git add feature-x.js
git commit -m "feat: WIP - initial featureX scaffold"

# 품질 체크 (경고 있어도 계속)
agent dev check
```

#### 1-3) Draft MR 생성

```bash
agent dev submit --draft
```

**기대 결과**
- MR이 **Draft** 상태로 생성됨
- 출력에 `[DRAFT]` 또는 `Draft:` 표시
- MR URL이 출력됨

---

### Phase 2: 첫 번째 리뷰 사이클

#### 2-1) 리뷰어가 MR 확인

```bash
# 리뷰어 역할
agent mgr pending
```

**기대 결과**
- Draft MR이 목록에 표시됨 (상태에 Draft 표시)

#### 2-2) 리뷰어가 코멘트 작성

```bash
# MR 상세 확인
agent mgr review <mr-id>

# 피드백 코멘트 추가
agent mgr review <mr-id> --comment "featureX needs error handling. Also add unit tests."
```

**기대 결과**
- 코멘트가 MR에 추가됨

#### 2-3) 개발자가 피드백 반영

```bash
# 개발자 역할로 복귀
# 피드백 반영하여 수정
cat > feature-x.js << 'EOF'
function featureX() {
  try {
    // implementation
    return { success: true };
  } catch (error) {
    console.error('featureX failed:', error);
    throw error;
  }
}

// Unit test
function testFeatureX() {
  const result = featureX();
  console.assert(result.success === true, 'featureX should succeed');
}
EOF

# 커밋
git add feature-x.js
git commit -m "feat: add error handling and unit test for featureX"

# 기존 MR에 push (새 MR 생성 아님!)
git push
```

**기대 결과**
- 기존 Draft MR에 새 커밋이 자동 추가됨
- MR 페이지에서 새 커밋 확인 가능

---

### Phase 3: 두 번째 리뷰 사이클

#### 3-1) 리뷰어가 재확인

```bash
agent mgr review <mr-id>
```

**기대 결과**
- 이전 코멘트 + 새 커밋이 모두 표시됨

#### 3-2) 리뷰어가 추가 피드백

```bash
agent mgr review <mr-id> --comment "Looks better! Please add JSDoc comments for the function."
```

#### 3-3) 개발자가 최종 수정

```bash
# JSDoc 추가
cat > feature-x.js << 'EOF'
/**
 * Feature X implementation
 * @returns {Object} Result object with success status
 * @throws {Error} When feature execution fails
 */
function featureX() {
  try {
    // implementation
    return { success: true };
  } catch (error) {
    console.error('featureX failed:', error);
    throw error;
  }
}

/**
 * Unit test for featureX
 */
function testFeatureX() {
  const result = featureX();
  console.assert(result.success === true, 'featureX should succeed');
}
EOF

git add feature-x.js
git commit -m "docs: add JSDoc comments to featureX"
git push
```

---

### Phase 4: Draft → Ready 전환

#### 4-1) 개발자가 완료 선언

현재 CLI에 Draft → Ready 전환 커맨드가 없으므로, 다음 중 하나를 사용합니다.

**방법 A: GitLab UI 사용**
- MR 페이지에서 "Mark as ready" 버튼 클릭

**방법 B: GitLab API 직접 호출 (예시)**

```bash
# GitLab API로 Draft 해제
curl -X PUT \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/merge_requests/${MR_IID}" \
  -d "title=feat: featureX implementation"  # "Draft:" 접두사 제거
```

**방법 C: GitHub의 경우**
- PR 페이지에서 "Ready for review" 버튼 클릭

---

### Phase 5: 최종 승인

#### 5-1) 리뷰어가 최종 확인

```bash
agent mgr review <mr-id>
```

**기대 결과**
- Draft 상태가 해제되어 있음
- 모든 피드백이 반영되어 있음

#### 5-2) 리뷰어가 LGTM 코멘트

```bash
agent mgr review <mr-id> --comment "LGTM! Approved."
```

#### 5-3) 승인

```bash
agent mgr approve <mr-id>
```

**기대 결과**
- MR이 승인됨
- `human_only` 설정에 따라 사람이 직접 실행해야 할 수 있음

---

### Phase 6: 정리

```bash
# 머지 후 브랜치 정리 (머지는 UI에서 또는 자동)
agent dev cleanup TASK-400
```

---

## 전체 플로우 다이어그램

```
Developer                          Reviewer
    |                                  |
    |-- agent dev start TASK-400       |
    |-- (initial implementation)       |
    |-- agent dev submit --draft ------+
    |                                  |
    |                   agent mgr pending
    |                   agent mgr review
    |         <-------- comment: "add error handling"
    |                                  |
    |-- (fix: add error handling)      |
    |-- git push ----------------------+
    |                                  |
    |                   agent mgr review
    |         <-------- comment: "add JSDoc"
    |                                  |
    |-- (docs: add JSDoc)              |
    |-- git push ----------------------+
    |                                  |
    |-- (Mark as Ready via UI) --------+
    |                                  |
    |                   agent mgr review
    |                   agent mgr approve
    |         <-------- APPROVED
    |                                  |
    |-- agent dev cleanup              |
    +----------------------------------+
```

---

## 여러 리뷰어가 있는 경우

```bash
# 여러 리뷰어가 각자 코멘트
agent mgr review <mr-id> --comment "[Reviewer1] Code looks good"
agent mgr review <mr-id> --comment "[Reviewer2] Please check edge cases"

# 모든 리뷰어가 승인해야 머지 가능 (GitLab 설정에 따름)
agent mgr approve <mr-id>  # Reviewer1
agent mgr approve <mr-id>  # Reviewer2
```

---

## 체크리스트(기록용)

| 단계 | 확인 항목 | 결과 |
|------|----------|------|
| 1 | `agent dev submit --draft`가 Draft MR을 생성하는가 | [ ] |
| 2 | `agent mgr pending`에서 Draft MR이 표시되는가 | [ ] |
| 3 | `agent mgr review --comment`로 피드백을 추가할 수 있는가 | [ ] |
| 4 | 추가 커밋 후 `git push`가 기존 MR에 반영되는가 | [ ] |
| 5 | Draft → Ready 전환이 가능한가 (UI 또는 API) | [ ] |
| 6 | `agent mgr approve`로 최종 승인이 되는가 | [ ] |
| 7 | 반복 리뷰 사이클이 원활하게 동작하는가 | [ ] |

## 주의사항

- Draft MR은 **머지 불가** 상태입니다. 반드시 Ready로 전환해야 머지 가능합니다.
- 리뷰 코멘트는 **인라인 코멘트가 아닌 MR 전체 코멘트**입니다. 인라인 코멘트는 UI 사용 권장.
- `--force` 옵션으로 기존 MR을 덮어쓰지 않도록 주의하세요.
- 긴 리뷰 사이클에서는 주기적으로 `agent dev sync`로 base와 동기화하세요.

## 개선 제안(후속 작업 후보)

이 시나리오를 더 원활하게 하려면:

- `agent dev ready`: Draft → Ready 전환 커맨드
- `agent mgr request-changes <mr-id>`: 변경 요청 상태 설정
- `agent mgr inline-comment <mr-id> <file> <line> "..."`: 인라인 코멘트
