# 003: --e2e-optional 모드에서 step 008 실패 시 graceful skip 미동작

| 항목 | 값 |
|------|---|
| 상태 | OPEN |
| 심각도 | minor |
| 발견 단계 | docker-ubuntu |
| 발견일 | 2026-02-06 |
| 수정일 | |

## 증상

```
[X] Could not find GitLab group: soc-ip/agentic-ai
[X] GitLab setup failed. Cannot proceed without repository.
[X] Step 008 run failed
[X] Demo installation failed at step 008
```

`--e2e-optional` 모드에서 step 007 (demo-check)이 통과했으나 step 008
(demo-run)에서 GitLab 접근 실패 시 전체 테스트가 실패로 처리됨.

## 원인

`install.sh`의 E2E_OPTIONAL 로직이 step 007에만 적용됨.
step 008 실패는 별도 처리 없이 그대로 fatal 에러로 전파됨.

## 비고

- 이것은 실제 GitLab/Jira API 토큰 + 네트워크가 필요한 E2E 테스트의
  제약사항이므로, `--skip-e2e` 또는 `--only 6` 사용이 권장됨.
- step 007에서 GitLab 인증 상태를 더 엄격하게 확인하면 step 008 진입 전에
  차단 가능.

## 수정 방법 (optional)

- [ ] install.sh에서 step 008 실패 시에도 E2E_OPTIONAL 검사 추가
- [ ] 또는 step 007에서 GitLab glab auth status를 필수 검증으로 변경

## 관련 파일

- `demo/install.sh` (run_step 함수)
- `demo/installation/007-demo-check.sh`
- `demo/installation/008-demo-run.sh`
