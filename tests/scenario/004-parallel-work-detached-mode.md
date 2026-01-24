# 004 - 병렬 작업(Dev): Detached Mode / Worktree를 활용한 A-B 테스팅

## 목적

- "한 개발자가 여러 접근법을 동시에 실험"하거나 "긴급 작업이 들어와 현재 작업 보존하며 병렬 처리"하는 플로우를 검증합니다.
- `--detached` 및 `--try=<name>` 옵션이 실제로 worktree를 생성하고 관리되는지 확인합니다.

## 핵심 결론(현재 구현 기준)

- 가능한 것(현재 구현):
  - `agent dev start <task> --detached`: `.worktrees/<task>/` 생성
  - `agent dev start <task> --detached --try=<name>`: `.worktrees/<task>-<name>/` 생성
  - `agent dev list`: Interactive + Detached 작업 모두 표시
  - `agent dev switch <target>`: 브랜치/worktree 간 전환
  - `agent dev cleanup <task>`: worktree 정리
- 주의:
  - Detached Mode에서 작업할 때는 해당 worktree 디렉터리로 이동해야 함
  - 각 worktree는 독립적인 `.context/` 를 가짐

## 전제/준비

- 이 저장소 루트에서 실행합니다.
- Git bare repo 또는 remote가 설정되어 있으면 더 완전한 테스트가 가능합니다.

## 시나리오 상황

- 새 기능을 구현하는데 두 가지 접근법이 있습니다.
  - approach-a: 기존 코드 리팩토링 후 기능 추가
  - approach-b: 새 모듈로 분리하여 기능 추가
- 두 접근법을 동시에 실험하고, 더 나은 쪽을 선택하여 제출합니다.

---

## 커맨드 시퀀스

### 0) 현재 상태 확인

```bash
agent status
agent dev list
ls -la .worktrees/ 2>/dev/null || echo "No worktrees yet"
```

**기대 결과**
- `agent dev list`가 현재 활성 작업 목록을 표시(없으면 "No active" 메시지)
- `.worktrees/` 디렉터리가 없거나 비어 있음

### 1) 첫 번째 접근법 시작 (approach-a)

```bash
agent dev start TASK-100 --detached --try=approach-a
```

**기대 결과**
- `.worktrees/TASK-100-approach-a/` 디렉터리 생성
- 해당 worktree 내에 `.context/TASK-100/` 생성
- 출력에 worktree 경로가 표시됨

### 2) 두 번째 접근법 시작 (approach-b)

```bash
agent dev start TASK-100 --detached --try=approach-b
```

**기대 결과**
- `.worktrees/TASK-100-approach-b/` 디렉터리 생성
- 두 worktree가 **서로 독립적**으로 존재

### 3) 활성 작업 목록 확인

```bash
agent dev list
```

**기대 결과**
- 두 개의 detached 작업이 표시:
  - `.worktrees/TASK-100-approach-a`
  - `.worktrees/TASK-100-approach-b`

### 4) approach-a에서 작업

```bash
cd .worktrees/TASK-100-approach-a

# 현재 위치 확인
pwd
agent dev status

# 코드 수정 (예시: 테스트용 파일 생성)
echo "// approach-a: refactor existing code" > approach-a-test.txt
git add approach-a-test.txt
git commit -m "feat: approach-a - refactor existing code"

# 품질 체크
agent dev check
```

**기대 결과**
- worktree 내에서 독립적으로 커밋 가능
- `agent dev status`가 해당 worktree의 상태를 표시

### 5) approach-b에서 작업

```bash
cd ../TASK-100-approach-b

# 현재 위치 확인
pwd
agent dev status

# 코드 수정 (예시: 테스트용 파일 생성)
echo "// approach-b: new module" > approach-b-test.txt
git add approach-b-test.txt
git commit -m "feat: approach-b - new module design"

# 품질 체크
agent dev check
```

**기대 결과**
- approach-a와 완전히 독립적인 커밋 히스토리
- 서로 다른 파일/변경 사항

### 6) 두 접근법 비교 후 선택

> 실제 상황에서는 테스트 결과, 코드 품질, 성능 등을 비교합니다.

```bash
# 메인 디렉터리로 복귀
cd ../../..

# 두 접근법의 차이 확인 (예시)
ls -la .worktrees/TASK-100-approach-a/
ls -la .worktrees/TASK-100-approach-b/

# 커밋 히스토리 비교
git -C .worktrees/TASK-100-approach-a log --oneline -3
git -C .worktrees/TASK-100-approach-b log --oneline -3
```

### 7) 선택한 접근법 제출 (approach-a 선택 가정)

```bash
cd .worktrees/TASK-100-approach-a

# 검증/회고
agent dev verify
agent dev retro

# 제출
agent dev submit --sync
```

**기대 결과**
- approach-a의 변경 사항이 MR로 생성됨
- `.context/` 아티팩트가 MR 설명에 포함되거나 아카이브됨

### 8) 선택하지 않은 접근법 정리

```bash
# 메인 디렉터리로 복귀
cd ../../..

# approach-b 정리
agent dev cleanup TASK-100-approach-b
```

**기대 결과**
- `.worktrees/TASK-100-approach-b/` 삭제됨
- `agent dev list`에서 approach-b가 사라짐

### 9) 최종 상태 확인

```bash
agent dev list
ls -la .worktrees/
```

**기대 결과**
- approach-a만 남아있거나 (submit 후 cleanup에 따라) 모두 정리됨

---

## 추가 시나리오: 긴급 작업 중간 삽입

### A) 기존 작업 중 긴급 태스크 발생

```bash
# Interactive Mode로 기능 개발 중
agent dev start TASK-200

# ... 작업 중 ...

# 긴급 태스크 발생! 현재 작업을 보존하며 긴급 처리
agent dev start URGENT-001 --detached
```

### B) 긴급 작업 처리

```bash
cd .worktrees/URGENT-001
# 긴급 수정
agent dev check
git commit -m "fix: urgent issue"
agent dev submit --sync
```

### C) 원래 작업으로 복귀

```bash
cd ../..
agent dev switch TASK-200
# 또는: git checkout feat/TASK-200

agent dev status
# 이전 작업 상태가 그대로 유지됨
```

---

## 체크리스트(기록용)

| 단계 | 확인 항목 | 결과 |
|------|----------|------|
| 1 | `--detached --try=approach-a`가 worktree를 생성했는가 | [ ] |
| 2 | `--detached --try=approach-b`가 별도 worktree를 생성했는가 | [ ] |
| 3 | `agent dev list`가 두 worktree를 모두 표시하는가 | [ ] |
| 4 | 각 worktree에서 독립적으로 커밋이 가능한가 | [ ] |
| 5 | worktree 간 전환이 원활한가 | [ ] |
| 6 | 선택한 접근법만 submit 가능한가 | [ ] |
| 7 | `agent dev cleanup`으로 불필요한 worktree 정리가 가능한가 | [ ] |
| 8 | 긴급 작업 후 원래 작업으로 복귀가 가능한가 | [ ] |

## 주의사항

- Worktree 내에서 작업 시 **반드시 해당 디렉터리로 이동**해야 합니다.
- 같은 브랜치를 여러 worktree에서 checkout하면 충돌이 발생할 수 있습니다.
- Cleanup하지 않은 worktree는 디스크 공간을 차지합니다.

---

## Manual Flow (Without Agent)

Agent 없이 순수 `git worktree`로 병렬 작업을 수행하는 방법입니다.

### Git Only (Worktree 직접 사용)

```bash
# 1. Approach A 시작
git worktree add .worktrees/TASK-100-approach-a \
  -b feat/TASK-100-approach-a \
  main

cd .worktrees/TASK-100-approach-a

# Context 생성 (선택)
mkdir -p .context/TASK-100
cat > .context/TASK-100/summary.yaml << EOF
task_id: TASK-100
approach: approach-a
strategy: refactor existing code
EOF

# 작업
echo "// approach-a: refactor existing code" > approach-a-test.txt
git add approach-a-test.txt
git commit -m "feat: approach-a - refactor existing code"

# 품질 체크
make lint && make test

cd ../..

# 2. Approach B 시작
git worktree add .worktrees/TASK-100-approach-b \
  -b feat/TASK-100-approach-b \
  main

cd .worktrees/TASK-100-approach-b

# Context 생성 (선택)
mkdir -p .context/TASK-100
cat > .context/TASK-100/summary.yaml << EOF
task_id: TASK-100
approach: approach-b
strategy: new module design
EOF

# 작업
echo "// approach-b: new module" > approach-b-test.txt
git add approach-b-test.txt
git commit -m "feat: approach-b - new module design"

# 품질 체크
make lint && make test

cd ../..

# 3. 비교
git log feat/TASK-100-approach-a --oneline
git log feat/TASK-100-approach-b --oneline

# 파일 차이
diff .worktrees/TASK-100-approach-a/src \
     .worktrees/TASK-100-approach-b/src

# 복잡도 비교 (radon 등)
cd .worktrees/TASK-100-approach-a
radon cc src/ -s
cd ../../.worktrees/TASK-100-approach-b
radon cc src/ -s
cd ../..

# 4. 승자 선택 및 제출 (approach-a)
cd .worktrees/TASK-100-approach-a

# Verification (선택)
cat > .context/TASK-100/verification.md << EOF
# Comparison Results

## Approach A (Selected)
- Complexity: 3.2
- Test coverage: 92%
- Code reuse: High

## Approach B
- Complexity: 4.1
- Test coverage: 88%
- Code reuse: Low

## Decision
Selected approach-a for better maintainability
EOF

# Push & MR
git push -u origin feat/TASK-100-approach-a
glab mr create \
  --title "feat: TASK-100 (approach-a selected)" \
  --description "$(cat .context/TASK-100/verification.md)"

cd ../..

# 5. 정리
# approach-b 제거
git worktree remove .worktrees/TASK-100-approach-b
git branch -D feat/TASK-100-approach-b

# approach-a는 MR 머지 후 정리
# (MR 머지 후)
git worktree remove .worktrees/TASK-100-approach-a
git branch -d feat/TASK-100-approach-a
```

### UI Steps

**GitLab/GitHub UI**:
- MR/PR 생성 (또는 glab/gh CLI)
- 리뷰/승인
- 머지

**Worktree 전환** (선택):
- 터미널에서 `cd` 명령으로 직접 전환
- 또는 IDE의 폴더 열기 기능 사용

---

## Responsibility Boundary

### CLI Responsibilities

**Git Worktree 관리**:
- Worktree 생성 (`git worktree add`)
- Worktree 목록 (`git worktree list`)
- Worktree 제거 (`git worktree remove`)

**각 Worktree 내 작업**:
- 독립적인 개발/커밋
- 품질 체크
- Context 관리

**비교 & 선택**:
- 커밋 히스토리 비교
- 복잡도/성능 비교
- 승자 선택 후 MR 생성

### UI Responsibilities

**MR/PR 관리**:
- 리뷰/승인/머지

**Agent가 추가로 제공하는 것**:
- `agent dev list`: Interactive + Detached 통합 뷰
- `agent dev switch <target>`: 자동 디렉터리 전환
- `agent dev cleanup <task>`: 안전한 정리 (stale 감지)
- Context 통합 관리

### Manual vs Agent

| 작업 | Manual | Agent |
|------|--------|-------|
| Worktree 생성 | `git worktree add` | `agent dev start --detached` |
| 전환 | `cd .worktrees/...` | `agent dev switch <target>` |
| 목록 | `git worktree list` | `agent dev list` (통합 뷰) |
| 정리 | `git worktree remove` | `agent dev cleanup` (안전) |
