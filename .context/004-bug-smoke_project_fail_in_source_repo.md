# 004: smoke 테스트 project 태그가 소스 저장소에서 실패

| 항목 | 값 |
|------|---|
| 상태 | OPEN |
| 심각도 | trivial |
| 발견 단계 | smoke |
| 발견일 | 2026-02-06 |
| 수정일 | |

## 증상

```
Summary: total=3 passed=2 failed=1 warned=0 skipped=0
```

agent-context 소스 저장소 루트에서 `tests smoke` 실행 시 `project` 태그가
실패 (`.agent/` 디렉토리 미존재).

## 재현 방법

```bash
cd /path/to/agent-context  # 소스 저장소
./bin/agent-context.sh tests --tags project
```

## 원인

`test_project()` 함수가 `find_project_root`로 `.cursorrules` 파일을 발견하고
프로젝트로 인식하지만, 소스 저장소에는 `.agent/` 디렉토리가 없어서
`[X] .agent/ missing` 실패가 발생함.

## 비고

- 이것은 정상 동작임: 소스 저장소 != 설치된 프로젝트
- 개발 환경에서만 발생하며 사용자에게는 영향 없음
- CI에서는 설치 후 테스트하므로 문제 없음

## 수정 방법 (optional)

- [ ] `test_project()`에서 agent-context 소스 저장소 감지 시 skip 처리
- [ ] 또는 `.agent/` 미존재를 warn으로 변경 (fail 대신)

## 관련 파일

- `builtin/tests.sh` (test_project 함수)
