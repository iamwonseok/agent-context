# 005 - 리베이스 충돌 해결(Dev): Conflict Resolution 플로우

## 목적

- `agent dev sync` 중 충돌 발생 시 **해결 → 재시도 → 완료** 플로우를 검증합니다.
- `--continue`와 `--abort` 옵션이 올바르게 동작하는지 확인합니다.
- Git 워크플로우의 가장 큰 pain point를 체계적으로 처리하는 절차를 문서화합니다.

## 핵심 결론(현재 구현 기준)

- 가능한 것(현재 구현):
  - `agent dev sync`: base branch(기본값 main)와 rebase 시도
  - `agent dev sync --continue`: 충돌 해결 후 rebase 계속
  - `agent dev sync --abort`: rebase 중단 및 이전 상태 복원
  - `agent dev sync --base=<branch>`: 다른 브랜치 기준으로 sync
- 주의:
  - 충돌 해결은 **수동**으로 파일을 수정해야 함
  - `git add`로 해결된 파일을 staging해야 `--continue` 가능

## 전제/준비

- Git remote가 설정되어 있어야 합니다(또는 로컬 bare repo).
- base branch(main)에 충돌을 유발할 변경 사항이 있어야 합니다.

---

## 시나리오 상황

- 개발자 A가 `feat/TASK-300` 브랜치에서 `config.yaml`을 수정하고 있습니다.
- 동시에 main 브랜치에 다른 개발자가 같은 파일을 수정하여 머지했습니다.
- A가 `agent dev sync`를 실행하면 충돌이 발생합니다.

---

## 커맨드 시퀀스

### Phase 1: 충돌 상황 만들기 (테스트용)

> 실제 상황에서는 이 단계가 자연스럽게 발생합니다.

```bash
# 1. 작업 브랜치 생성
agent dev start TASK-300

# 2. 충돌 유발 파일 생성/수정
echo "feature_flag: enabled" > conflict-test.txt
git add conflict-test.txt
git commit -m "feat: add feature flag (branch)"

# 3. main 브랜치에서 같은 파일 수정 (다른 터미널 또는 시뮬레이션)
git stash  # 현재 변경 임시 저장 (있다면)
git checkout main
echo "feature_flag: disabled" > conflict-test.txt
git add conflict-test.txt
git commit -m "chore: disable feature flag (main)"

# 4. 다시 작업 브랜치로 복귀
git checkout feat/TASK-300
git stash pop 2>/dev/null || true
```

### Phase 2: 충돌 발생 및 확인

```bash
# sync 시도 (충돌 발생 예상)
agent dev sync
```

**기대 결과**
- 충돌 발생 메시지 출력:
  ```
  CONFLICT (content): Merge conflict in conflict-test.txt
  error: could not apply ...
  ```
- rebase가 중단된 상태(REBASE-i 또는 REBASE 상태)

### Phase 3: 충돌 상태 확인

```bash
# 현재 상태 확인
git status
agent dev status
```

**기대 결과**
- `git status`에 "You are currently rebasing" 또는 "Unmerged paths" 표시
- 충돌 파일 목록이 표시됨

### Phase 4: 충돌 파일 확인 및 수동 해결

```bash
# 충돌 내용 확인
cat conflict-test.txt
```

**기대 결과 (충돌 마커)**
```
<<<<<<< HEAD
feature_flag: disabled
=======
feature_flag: enabled
>>>>>>> feat: add feature flag (branch)
```

```bash
# 수동으로 충돌 해결 (원하는 값으로 수정)
echo "feature_flag: enabled  # merged: keep feature branch value" > conflict-test.txt

# 해결된 파일 staging
git add conflict-test.txt
```

### Phase 5: Rebase 계속 (--continue)

```bash
agent dev sync --continue
```

**기대 결과**
- rebase가 성공적으로 완료됨
- 선형 히스토리가 유지됨
- 출력: `Successfully rebased and updated...` 또는 유사 메시지

### Phase 6: 결과 확인

```bash
# 히스토리 확인 (선형인지)
git log --oneline --graph -10

# 상태 확인
agent dev status
```

**기대 결과**
- 브랜치가 main 위에 깔끔하게 rebase됨
- `*` 마커가 일직선으로 표시됨 (no merge commits)

---

## 대안 플로우: Rebase 중단 (--abort)

충돌이 너무 복잡하거나 잘못된 경우 중단할 수 있습니다.

### A) 충돌 발생 후

```bash
agent dev sync
# 충돌 발생!
```

### B) 해결 대신 중단 결정

```bash
# 이전 상태로 복원
agent dev sync --abort
```

**기대 결과**
- rebase 취소
- 브랜치가 sync 시도 전 상태로 복원
- `git status`에 "nothing to commit, working tree clean" (변경 전 상태)

### C) 상태 확인

```bash
git status
git log --oneline -5
```

**기대 결과**
- sync 시도 전과 동일한 커밋 히스토리

---

## 복잡한 충돌 시나리오

### 여러 파일에서 충돌

```bash
# 충돌 발생
agent dev sync

# 상태 확인
git status
# both modified: file1.txt
# both modified: file2.txt
# both modified: file3.txt

# 각 파일 해결
vim file1.txt  # 충돌 해결
git add file1.txt

vim file2.txt  # 충돌 해결
git add file2.txt

vim file3.txt  # 충돌 해결
git add file3.txt

# 모든 충돌 해결 후 계속
agent dev sync --continue
```

### 연속 커밋에서 충돌

rebase 중 여러 커밋에서 순차적으로 충돌이 발생할 수 있습니다.

```bash
# 첫 번째 커밋 충돌 해결
vim conflict-file.txt
git add conflict-file.txt
agent dev sync --continue

# 두 번째 커밋에서도 충돌 발생!
vim another-file.txt
git add another-file.txt
agent dev sync --continue

# 완료될 때까지 반복
```

---

## 충돌 해결 팁

### 충돌 마커 이해

```
<<<<<<< HEAD (또는 ours)
현재 브랜치(main/base)의 내용
=======
가져오려는 변경(feature branch)의 내용
>>>>>>> commit-message
```

### 해결 전략

| 상황 | 전략 |
|------|------|
| 내 변경만 유지 | 상단(HEAD) 삭제, 하단 유지 |
| base 변경만 유지 | 하단 삭제, 상단 유지 |
| 둘 다 병합 | 수동으로 합친 내용 작성 |
| 완전히 새로 작성 | 마커 모두 삭제 후 새 내용 |

### 유용한 Git 명령어

```bash
# 충돌 파일 목록
git diff --name-only --diff-filter=U

# 특정 파일의 양쪽 버전 확인
git show :1:filename  # common ancestor
git show :2:filename  # ours (HEAD)
git show :3:filename  # theirs (incoming)

# 머지 툴 사용 (설정된 경우)
git mergetool
```

---

## 체크리스트(기록용)

| 단계 | 확인 항목 | 결과 |
|------|----------|------|
| 1 | `agent dev sync`가 충돌을 감지하고 안내하는가 | [ ] |
| 2 | 충돌 상태에서 `git status`가 명확한 정보를 보여주는가 | [ ] |
| 3 | 수동으로 충돌을 해결하고 `git add`할 수 있는가 | [ ] |
| 4 | `agent dev sync --continue`가 rebase를 완료하는가 | [ ] |
| 5 | `agent dev sync --abort`가 이전 상태를 복원하는가 | [ ] |
| 6 | 완료 후 히스토리가 선형인가 (no merge commits) | [ ] |
| 7 | 여러 파일/커밋 충돌도 순차적으로 처리 가능한가 | [ ] |

## 주의사항

- 충돌 해결 중에는 **다른 git 명령을 주의해서 사용**해야 합니다.
- `--abort`는 모든 해결 작업을 버리므로 신중하게 사용합니다.
- 복잡한 충돌은 팀원과 상의하거나, 작은 단위로 나눠서 sync하는 것이 좋습니다.
- 충돌이 자주 발생하면 sync 주기를 짧게 가져가세요.
