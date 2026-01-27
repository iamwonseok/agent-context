# Lint Tools

> **User manual**: [docs/cli/lint.md](../../docs/cli/lint.md)

Coding convention checker for multiple languages.

## 지원 언어

| 언어 | 명령어 | 외부 도구 | 보조 규칙 |
|------|--------|-----------|-----------|
| C/C++ | `lint c`, `lint-c` | clang-format, clang-tidy | regex (11 rules) |
| Python | `lint python`, `lint-python` | flake8, black | regex (10 rules) |
| Bash | `lint bash`, `lint-bash` | shellcheck | regex (9 rules) |
| Make | `lint make`, `lint-make` | - | regex (4 rules) |
| YAML | `lint yaml`, `lint-yaml` | yamllint | regex (5 rules) |
| Dockerfile | `lint yaml` | hadolint | regex (3 rules) |

## 검사 방식 (하이브리드)

기본적으로 **하이브리드 모드**로 동작합니다:

1. **1st Pass**: 외부 도구 (clang-format, flake8 등) - 자동화 가능한 규칙
2. **2nd Pass**: regex 규칙 - 외부 도구로 커버 안 되는 규칙

```bash
# 기본 (하이브리드)
lint-c file.c

# 외부 도구만 사용
lint-c file.c --external-only

# regex 규칙만 사용 (기존 동작)
lint-c file.c --regex-only

# 도구 설치 상태 확인
lint-c --check-tools
```

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
├── lib/                   # 공통 라이브러리
│   └── executor.sh        # 외부 도구 실행기
├── scripts/               # 내부 스크립트
│   ├── rules/             # 언어별 regex 규칙
│   ├── junit_helper.sh    # JUnit 출력 헬퍼
│   └── test_*.sh          # 테스트 스크립트
├── ci-templates/          # CI 파이프라인 템플릿
│   └── lint.yml
└── install.sh             # 설치 스크립트
```

## 설정 파일

외부 도구 설정 파일은 다음 순서로 검색됩니다:

1. 프로젝트 루트 (예: `.clang-format`)
2. `templates/configs/` (fallback)

| 언어 | 설정 파일 |
|------|-----------|
| C/C++ | `.clang-format`, `.clang-tidy` |
| Python | `.flake8`, `pyproject.toml` |
| Bash | `.shellcheckrc` |
| YAML | `.yamllint.yml` |
| Dockerfile | `.hadolint.yaml` |

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
