# Demo Directory

agent-context 데모 및 테스트 환경을 위한 디렉토리.

## 구조

```
demo/
├── .env.example       # 환경 변수 템플릿
├── docker/            # Docker 이미지 정의
│   ├── ubuntu/        # Ubuntu 기반 이미지
│   └── ubi9/          # Red Hat UBI9 기반 이미지
├── installation/      # 설치 데모 (단계별 스크립트)
│   ├── lib.sh         # 공통 라이브러리
│   └── 001-*.sh ~ 010-*.sh
└── scenario/          # E2E 시나리오 데모
    ├── demo.sh        # 시나리오 실행 스크립트
    ├── cleanup.sh     # 정리 스크립트
    ├── lib/           # 시나리오 라이브러리
    └── sample/        # 샘플 데이터
```

## 설치 데모 (installation/)

agent-context를 임의의 프로젝트에 설치하고 검증하는 데모.

```bash
# 전체 실행
./demo/install.sh

# E2E 제외 (오프라인)
./demo/install.sh --skip-e2e

# Docker에서 실행
./demo/install.sh --os ubuntu
./demo/install.sh --os ubi9
```

자세한 내용은 [설치 데모 가이드](installation/docs/guide.md) 참조.

## 시나리오 데모 (scenario/)

Jira/GitLab/Confluence E2E 시나리오 데모.

```bash
# 의존성 확인
./demo/scenario/demo.sh check

# 시나리오 실행
./demo/scenario/demo.sh run
```

자세한 내용은 [시나리오 README](scenario/README.md) 참조.

## Docker 환경 (docker/)

Ubuntu 및 UBI9 기반 테스트 환경.

```bash
# Ubuntu 이미지 빌드
docker build -t agent-context-demo-ubuntu -f demo/docker/ubuntu/Dockerfile demo/docker/ubuntu

# UBI9 이미지 빌드
docker build -t agent-context-demo-ubi9 -f demo/docker/ubi9/Dockerfile demo/docker/ubi9
```

## 환경 변수

`.env.example`을 복사하여 `.env`로 사용:

```bash
cp demo/.env.example demo/.env
# .env 파일 편집
```

**주의:** `.env` 파일은 git에 커밋하지 않음.
