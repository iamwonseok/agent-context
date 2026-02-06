# 001: entrypoint.sh SSH preflight가 SKIP_E2E=true일 때도 강제 실행

| 항목 | 값 |
|------|---|
| 상태 | FIXED |
| 심각도 | critical |
| 발견 단계 | docker-ubuntu |
| 발견일 | 2026-02-06 |
| 수정일 | 2026-02-06 |

## 증상

```
[i] SSH preflight: testing connection to gitlab.com...
[X] SSH preflight failed
[X] Output: git@gitlab.com: Permission denied (publickey).
[X] Docker run failed
```

`SKIP_E2E=true`로 설정했음에도 entrypoint.sh에서 SSH preflight check가
실행되어 컨테이너가 즉시 종료됨.

## 재현 방법

```bash
./demo/install.sh --os ubuntu --skip-e2e --only 6
```

## 원인

`demo/docker/ubuntu/entrypoint.sh`의 `main()` 함수에서 `setup_ssh()`와
`ssh_preflight()`를 무조건 호출함. `SKIP_E2E` 환경변수를 확인하지 않음.

## 수정 방법

- [x] entrypoint.sh에서 SKIP_E2E=true일 때 SSH setup/preflight를 선택적으로 수행
- [x] SSH 키가 없을 경우 setup_ssh()에서 exit 대신 warn 처리 (SKIP_E2E 시)
- [x] ubuntu/ubi9 양쪽 entrypoint.sh 모두 수정
- [x] Docker 재빌드 후 테스트 확인

## 검증

```bash
./demo/install.sh --os ubuntu --skip-e2e --only 6
# 기대: SSH preflight 건너뛰고 설치 테스트 진행
```

## 관련 파일

- `demo/docker/ubuntu/entrypoint.sh`
- `demo/docker/ubi9/entrypoint.sh`
