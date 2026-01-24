# Lint Tools

코딩 컨벤션 검사를 위한 통합 린트 도구입니다.

## 지원 언어

| 언어 | 명령어 | 검사 도구 |
|------|--------|-----------|
| C/C++ | `lint c`, `lint-c` | clang-format, clang-tidy |
| Python | `lint python`, `lint-python` | flake8, black |
| Bash | `lint bash`, `lint-bash` | shellcheck |
| Make | `lint make`, `lint-make` | custom rules |
| YAML | `lint yaml`, `lint-yaml` | yamllint |
| Dockerfile | `lint yaml` | hadolint |

## 사용법

### 기본 사용

```bash
# 단일 파일 검사
lint c main.c
lint python script.py

# 디렉터리 재귀 검사
lint c src/ -R
lint python . --recursive

# 조용한 모드 (오류만 출력)
lint c . -q
```

### JUnit XML 출력

```bash
# CI/CD 파이프라인용 JUnit 출력
lint c . --junit -o results.xml
lint python src/ -R --junit -o python-results.xml
```

### 개별 린터

```bash
lint-c file.c
lint-python script.py
lint-bash script.sh
lint-make Makefile
lint-yaml config.yaml
```

## 디렉터리 구조

```
tools/lint/
├── bin/                    # 실행 파일
│   ├── lint               # 통합 진입점
│   ├── lint-c
│   ├── lint-python
│   ├── lint-bash
│   ├── lint-make
│   └── lint-yaml
├── scripts/               # 내부 스크립트
│   ├── rules/             # 언어별 규칙
│   ├── junit_helper.sh    # JUnit 출력 헬퍼
│   └── test_*.sh          # 테스트 스크립트
├── ci-templates/          # CI 파이프라인 템플릿
│   └── lint.yml
└── install.sh             # 설치 스크립트
```

## 테스트

테스트 파일은 `tests/unit/lint-rules/`에 위치합니다.

```bash
# 테스트 실행
cd tests/unit/lint-rules
make test

# 개별 언어 테스트
make test-c
make test-python
make test-bash
```

## AI 기반 도구

### commit-agent

Ollama 기반 커밋 메시지 자동 생성:

```bash
commit-agent
```

### coding-agent

Ollama 기반 로컬 자율 코딩 에이전트:

```bash
coding-agent
```

## CI/CD 통합

`ci-templates/lint.yml`을 GitLab CI에 포함:

```yaml
include:
  - local: 'tools/lint/ci-templates/lint.yml'
```

## 설치

```bash
./install.sh
```

또는 PATH에 추가:

```bash
export PATH="$PATH:$(pwd)/tools/lint/bin"
```

## 관련 문서

- [docs/style/](../../docs/style/) - 코딩 컨벤션 상세
- [tests/unit/lint-rules/](../../tests/unit/lint-rules/) - 테스트 픽스처
