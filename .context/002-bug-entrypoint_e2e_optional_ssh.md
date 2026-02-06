# 002: entrypoint.sh SSH preflight가 E2E_OPTIONAL 모드에서도 강제 실행

| 항목 | 값 |
|------|---|
| 상태 | FIXED |
| 심각도 | major |
| 발견 단계 | docker-ubuntu |
| 발견일 | 2026-02-06 |
| 수정일 | 2026-02-06 |

## 증상

```
[X] SSH preflight failed
[X] Output: git@gitlab.com: Permission denied (publickey).
[X] Docker run failed
```

`--e2e-optional` 모드에서 SKIP_E2E=false로 설정되므로 entrypoint.sh의
SSH 검사가 필수로 실행됨. E2E_OPTIONAL 모드에서는 SSH 실패가 fatal이 아니어야 함.

## 원인

`install.sh`에서 `--e2e-optional` 시 `SKIP_E2E=false`를 설정.
entrypoint.sh는 `SKIP_E2E`만 확인하고 `E2E_OPTIONAL`은 미확인.

## 수정 방법

- [x] entrypoint.sh의 setup_ssh()와 ssh_preflight()에서 E2E_OPTIONAL도 확인
- [x] E2E_OPTIONAL=true일 때 SSH 실패는 warn 처리
- [x] 테스트 확인 (SSH preflight 통과, step 008에서 GitLab 접근 문제로 실패 -- 별도 이슈 003)

## 관련 파일

- `demo/docker/ubuntu/entrypoint.sh`
- `demo/docker/ubi9/entrypoint.sh`
