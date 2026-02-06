# .context/ - 테스트 버그 추적

테스트 중 발견된 버그를 추적하고 수정 현황을 관리하는 디렉토리.

## 파일 네이밍 규칙

```
NNN-bug-SHORT_DESC.md
```

- `NNN`: 3자리 일련번호 (001, 002, ...)
- `SHORT_DESC`: 버그 요약 (snake_case, 영문)

예시:
- `001-bug-smoke_test_auth_fail.md`
- `002-bug-docker_ubuntu_yq_missing.md`
- `003-bug-install_noninteractive_exit_code.md`

## 파일 구조

```markdown
# NNN: 버그 제목

| 항목 | 값 |
|------|---|
| 상태 | OPEN / IN_PROGRESS / FIXED / WONTFIX |
| 심각도 | critical / major / minor / trivial |
| 발견 단계 | smoke / install / docker-ubuntu / docker-ubi9 / e2e |
| 발견일 | YYYY-MM-DD |
| 수정일 | YYYY-MM-DD (수정 시) |

## 증상

(에러 메시지 또는 출력 복사)

## 원인

(분석 결과)

## 수정 방법

- [ ] 체크리스트 항목 1
- [ ] 체크리스트 항목 2

## 검증

(수정 후 확인 방법)
```

## 하위 디렉토리

- `test-results/` - CI 테스트 실행 결과 자동 저장

## 상태 흐름

```
OPEN -> IN_PROGRESS -> FIXED
                    -> WONTFIX
```
