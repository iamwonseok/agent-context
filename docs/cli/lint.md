# lint CLI

코딩 컨벤션 검사를 위한 통합 린트 도구입니다.

## 사용법

```bash
lint <language> [OPTIONS] [PATH]
```

## 지원 언어

| 언어 | 명령어 | 외부 도구 | 보조 규칙 |
|------|--------|-----------|-----------|
| C/C++ | `lint c` | clang-format, clang-tidy | regex |
| Python | `lint python` | flake8, black | regex |
| Bash | `lint bash` | shellcheck | regex |
| Make | `lint make` | - | regex |
| YAML | `lint yaml` | yamllint | regex |
| Dockerfile | `lint yaml` | hadolint | regex |

## 검사 모드

기본적으로 **하이브리드 모드**로 동작합니다:

1. **1st Pass**: 외부 도구 (설치된 경우)
2. **2nd Pass**: regex 규칙 (보조)

```bash
# 기본 (하이브리드)
lint c file.c

# 외부 도구만 사용
lint c file.c --external-only

# regex 규칙만 사용 (기존 동작)
lint c file.c --regex-only

# 도구 설치 상태 확인
lint c --check-tools
```

## 공통 옵션

| 옵션 | 설명 |
|------|------|
| `-R, --recursive` | 디렉터리 재귀 검사 |
| `--junit` | JUnit XML 형식 출력 |
| `-o, --output FILE` | 출력 파일 지정 |
| `-q, --quiet` | 조용한 모드 (오류만 출력) |
| `--external-only` | 외부 도구만 사용 |
| `--regex-only` | regex 규칙만 사용 |
| `--check-tools` | 외부 도구 설치 상태 확인 |
| `-h, --help` | 도움말 |

## 예제

### 기본 사용

```bash
# 단일 파일 검사
lint c main.c
lint python script.py

# 디렉터리 검사
lint c src/
lint python . -R

# 조용한 모드
lint c . -q
```

### CI/CD 통합

```bash
# JUnit XML 출력
lint c . --junit -o results.xml
lint python src/ -R --junit -o python-lint.xml
```

### 도구 상태 확인

```bash
$ lint c --check-tools
=== Tool Availability ===
[OK] clang-format: clang-format version 19.0.0
[OK] clang-tidy: LLVM version 19.0.0
```

## 개별 린터

통합 명령어 대신 개별 린터를 직접 사용할 수도 있습니다:

```bash
lint-c file.c
lint-python script.py
lint-bash script.sh
lint-make Makefile
lint-yaml config.yaml
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

### 설정 파일 복사

프로젝트에 설정 파일을 복사하려면:

```bash
cp templates/configs/.clang-format .
cp templates/configs/.clang-tidy .
cp templates/configs/.flake8 .
# ... 등
```

## 외부 도구 설치

외부 도구가 없어도 기본 regex 검사는 동작합니다.
더 정확한 검사를 위해 외부 도구 설치를 권장합니다.

자세한 설치 방법은 [Installation Guide](../installation.md#lint-tools-optional)를 참조하세요.

## 관련 문서

- [tools/lint/README.md](../../tools/lint/README.md) - 상세 구현
- [docs/style/](../style/) - 코딩 컨벤션 정의
- [templates/configs/](../../templates/configs/) - 설정 파일 템플릿
