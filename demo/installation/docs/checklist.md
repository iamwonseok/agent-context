## 목적

agent-context 사용자가 로컬에 agent-context를 설치한 뒤, 임의의 프로젝트 `${ANY_PROJECT}`에 다음 형태로 설치/검증하는 데모를 Docker 기반으로 재현 가능하게 만든다.

- `${ANY_PROJECT}/.cursorrules`
- `${ANY_PROJECT}/.project.yaml`
- `${ANY_PROJECT}/.agent/{skills,workflows,tools/pm,...}`
- (설정 파일) full/minimal/force 프로파일에 따라 다르게 설치

본 문서는 개발 단계 및 단계별 체크리스트를 정의한다. **각 단계는 반드시 PASS(스크립트 exit 0)일 때만 다음 단계로 진행한다.** FAIL(비정상 종료) 시 즉시 중단하고 원인을 수정한 뒤 같은 단계를 재실행한다.

---

## 데모 운영 원칙(게이트)

- **게이트 규칙**: 각 단계는 `run` + `verify`를 포함하며, `verify`가 PASS(0)면 다음 단계로 진행한다.
- **일관된 로그 형식**: `[V]`(pass), `[X]`(fail), `[!]`(warn), `[i]`(info)
- **토큰/시크릿 보호**: 로그에 토큰을 출력하지 않는다(마스킹/미출력).
- **시크릿은 설치 대상이 아님**: 스크립트가 토큰을 생성/설치하지 않는다.
  - 없으면 `[!]`로 “어디에/어떻게 설정할지” 가이드를 출력한다.
  - 단, 실제 API 호출이 필요한 단계에서는 누락 시 `[X]`로 FAIL 처리한다(다음 단계 진행 금지).
- **Idempotent 목표**: 같은 명령을 여러 번 실행해도 “검증 가능한 상태”로 수렴해야 한다.
- **pre-commit 정책**: `pre-commit run --all-files`는 **best-effort**로 실행한다.
  - 실패해도 데모는 계속 진행하되, `[X]`로 기록하고 “수정 가이드”를 출력한다.

---

## 입력(로컬 테스트 기본값)

로컬 우선 테스트 경로는 `~/.secrets`를 참조한다.

- Atlassian(Jira/Confluence)
  - `~/.secrets/atlassian-api-token` (필수)
  - `JIRA_EMAIL` (필수, env로 주입)
- GitLab
  - `~/.secrets/gitlab-api-token` (권장)
  - 또는 `GITLAB_TOKEN` env
  - `glab auth login` 비대화형 로그인 지원 필요

Docker에서 `~/.secrets` 주입 기본 정책:

- 기본(권장): **read-only 마운트**
- 옵션: 컨테이너 내부로 복사(마운트 제약 환경 대비)

데모 기본 설정(로컬 테스트 기준):

- **Jira Project Key**: `SVI4`
- Confluence/GitLab은 `demo/demo.sh`와 동일한 정책(옵션/기본값/인증 흐름)을 따른다.

---

## 산출물(스크립트/구조)

### 데모 스크립트 구조

- `demo/install.sh`: 단일 엔트리 포인트
  - `--profile full|minimal` (default: full)
  - `--force` (덮어쓰기)
  - `--os ubuntu|ubi9` (둘 다 테스트)
  - `--run-id <id>` (재현/격리)
  - `--skip-e2e` (오프라인만)
  - `--only <N>` (N 단계까지만)
- `demo/installation/001-*.sh`, `002-*.sh`, ...: 단계별 실행 + 검증 스크립트
  - 각 스크립트는 최소 `run`과 `verify` 커맨드를 제공한다.
  - `verify`는 PASS(0) 또는 FAIL(비0)로 게이트를 구현한다.

### 설치 프로파일(Installer)

- **minimal**
  - 루트: `.cursorrules`, `.project.yaml`
  - 로컬: `.agent/skills`, `.agent/workflows`, `.agent/tools/pm`
  - 설정 파일(.clang-format 등)은 설치하지 않음
- **full (default)**
  - minimal + 설정 파일 세트 설치
  - `.vimrc`는 루트 강제 설치가 아니라 `.agent/` 아래 “가이드 템플릿”로만 제공
- **force**
  - 기존 파일이 있어도 덮어쓰기(안전 병합 대상 제외)
  - `.gitignore`는 기본 “병합” 우선, force에서도 안전 병합을 기본으로 둔다.

---

## 단계별 체크리스트(개발 순서 + 게이트)

### 000: 공통 전제(개발/실행 환경)

- **목표**
  - 데모 실행에 필요한 최소 도구/환경을 준비한다.
- **Run**
  - (로컬) Docker 사용 가능
  - (로컬) `~/.secrets/atlassian-api-token` 존재
  - (로컬) `JIRA_EMAIL` 설정 가능
- **Verify (PASS 조건)**
  - Docker daemon 연결 가능
  - `~/.secrets/atlassian-api-token` 파일 권한이 과도하게 열려있지 않음(예: `chmod 600` 권장)
  - `JIRA_EMAIL`이 비어있지 않음
  - (Docker 실행 시) `~/.secrets`를 컨테이너로 주입할 계획이 준비됨
    - 기본: `-v ~/.secrets:<container-home>/.secrets:ro`
    - 옵션: 컨테이너로 복사(`--secrets-mode copy`)
- **PASS 후 다음 단계**
  - `001`로 진행

---

### 001: Installer 레이아웃 변경(.agent 설치)

- **목표**
  - `install.sh`가 `${ANY_PROJECT}`에 아래 구조로 설치할 수 있어야 한다.
    - `${ANY_PROJECT}/.cursorrules`
    - `${ANY_PROJECT}/.project.yaml`
    - `${ANY_PROJECT}/.agent/skills`
    - `${ANY_PROJECT}/.agent/workflows`
    - `${ANY_PROJECT}/.agent/tools/pm`
- **Run**
  - 임시 프로젝트(예: `/tmp/any-project`)를 생성하고 `install.sh` 실행
  - `--profile minimal|full`, `--force` 조합별로 실행
- **Verify (PASS 조건)**
  - 위 경로들이 생성됨(프로파일에 따라 예외 허용)
  - `tools/pm/bin/pm` 실행 가능
  - `.project.yaml`이 생성되거나 기존 파일이 있을 경우 정책대로 처리됨(스킵/덮어쓰기)
- **PASS 후 다음 단계**
  - `002`로 진행

---

### 002: `.cursorrules` 병합(기존 파일 보호)

- **목표**
  - 기존 `${ANY_PROJECT}/.cursorrules`가 있을 때 **덮어쓰지 않고** 상단에 agent-context Index Map 블록을 삽입한다.
- **Run**
  - (케이스 A) `.cursorrules` 없음: 새로 생성
  - (케이스 B) `.cursorrules` 있음: 병합 삽입
  - (케이스 C) 이미 삽입된 상태: 중복 삽입 방지
- **Verify (PASS 조건)**
  - (B) 기존 내용이 유지됨(본문 손상 없음)
  - (C) 마커 기반으로 중복 삽입이 발생하지 않음
  - Index Map의 경로 안내가 `.agent/...` 기준으로 맞음
- **PASS 후 다음 단계**
  - `003`으로 진행

---

### 003: 설정 파일 설치 프로파일(full/minimal/force)

- **목표**
  - full/minimal/force 각각의 설치 결과가 명확히 다르고, 검증이 가능해야 한다.
- **설치 대상(Full)**
  - 루트에 설치: `.editorconfig`, `.pre-commit-config.yaml`, `.shellcheckrc`, `.yamllint.yml`, `.hadolint.yaml`, `.clang-format`, `.clang-tidy`, `.flake8`
  - `.gitignore`: 기존이 있으면 병합
  - `.vimrc`: `.agent/` 아래 템플릿으로만 제공(루트 강제 설치 금지)
  - `pyproject.toml`: (정책 선택) 기본은 설치하지 않고, Python 프로젝트 감지 시에만 설치 또는 `--with-python` 같은 옵션으로만 설치
- **Run**
  - minimal 설치 후 파일 부재 확인
  - full 설치 후 파일 존재 확인
  - force 설치 후 덮어쓰기/병합 정책 확인
- **Verify (PASS 조건)**
  - 프로파일별로 기대한 파일 존재/부재가 정확함
  - `.gitignore` 병합이 중복 라인 없이 수행됨(동일 엔트리 재삽입 금지)
  - `.vimrc`가 루트에 무단 설치되지 않음
- **PASS 후 다음 단계**
  - `004`로 진행

---

### 004: 로컬 정적 검증(레포 내 테스트 스크립트)

- **목표**
  - 기존 검증 스크립트가 Docker 데모에서도 그대로 동작한다.
- **Run**
  - `bash tests/skills/verify.sh`
  - `bash tests/workflows/verify.sh`
- **Verify (PASS 조건)**
  - 두 스크립트가 PASS(0)
- **PASS 후 다음 단계**
  - `005`로 진행

---

### 005: 데모 설치 단계 스크립트(`demo/installation/NNN`)

- **목표**
  - `demo/install.sh`가 내부적으로 단계 스크립트를 순서대로 실행하고, 단계가 PASS일 때만 다음 단계로 진행한다.
- **Run**
  - `demo/installation/001-prereq.sh run/verify`
  - `demo/installation/002-clone.sh run/verify`
  - `demo/installation/003-any-project.sh run/verify`
  - `demo/installation/004-install.sh run/verify`
  - `demo/installation/005-configure-project-yaml.sh run/verify`
  - `demo/installation/006-pm-connectivity.sh run/verify`
  - `demo/installation/007-demo-check.sh run/verify`
  - `demo/installation/008-demo-run.sh run/verify`
  - `demo/installation/009-report.sh run/verify`
- **Verify (PASS 조건)**
  - 각 스크립트가 `verify`에서 0/비0를 명확히 리턴
  - 러너가 FAIL에서 즉시 중단
  - `--only N`로 N단계까지만 수행 가능
- **PASS 후 다음 단계**
  - `006`로 진행

---

### 006: Docker harness (Ubuntu 계열)

- **목표**
  - Ubuntu 기반 컨테이너에서 full/minimal/force 설치 및 E2E가 재현 가능하다.
- **Run**
  - Docker build (ubuntu)
  - 컨테이너 run 시 다음을 주입
    - 기본(권장): `-v ~/.secrets:/home/demo/.secrets:ro` (또는 root 기준 경로)
    - 옵션: `--secrets-mode copy`로 컨테이너 내부에 복사
    - `-e JIRA_EMAIL=...`
    - (필요 시) `-e GITLAB_TOKEN=...`
  - `demo/install.sh --os ubuntu --profile full --run-id ...`
- **Verify (PASS 조건)**
  - 단계 001~009가 게이트 규칙대로 진행
  - Jira Project Key가 `SVI4`로 실제 생성/조회가 동작
  - 보고서 산출물 생성
- **PASS 후 다음 단계**
  - `007`로 진행

---

### 007: Docker harness (RedHat 계열: UBI9)

- **목표**
  - RedHat 계열(UBI9)에서도 동일하게 재현 가능하다.
- **Run**
  - Docker build (ubi9)
  - 컨테이너 run(동일한 secrets/env 주입)
  - `demo/install.sh --os ubi9 --profile full --run-id ...`
- **Verify (PASS 조건)**
  - ubuntu와 동일한 결과(단계 게이트/산출물)
- **PASS 후 다음 단계**
  - `008`로 진행

---

### 008: pre-commit 가이드 + best-effort 실행

- **목표**
  - pre-commit 설치/실행 가이드를 제공하고, 데모에서 best-effort로 실행한다.
- **Run**
  - 컨테이너에서 `pre-commit --version` 확인
  - `pre-commit install` 가이드 출력(필요 시)
  - `pre-commit run --all-files` 실행(best-effort)
- **Verify (PASS 조건)**
  - (best-effort) 실행 자체가 수행되고 결과가 로그로 기록됨
  - 실패 시에도 다음 단계로 진행하되, 어떤 도구/패키지가 필요한지 가이드가 출력됨
- **PASS 후 다음 단계**
  - `009`로 진행

---

### 009: 문서화(토큰/설치/실행)

- **목표**
  - 사용자가 Docker 데모를 따라할 수 있도록 문서가 완결된다.
- **Run**
  - 토큰 발급/보관/주입 문서 작성
  - 데모 실행 커맨드(ubuntu/ubi9) 예시 제공
  - 실패 케이스(401, 권한, space key, glab auth) 트러블슈팅 제공
- **Verify (PASS 조건)**
  - 문서만으로 최소 1회 실행이 가능
  - 토큰 노출 없이 안내 가능
- **PASS 후 다음 단계**
  - 개발 완료

---

## 체크리스트 러너 요구사항(구현 계약)

`demo/install.sh` 및 `demo/installation/*.sh`는 다음을 만족해야 한다.

- **표준 인터페이스**
  - `./demo/installation/NNN-*.sh run` : 단계 실행(가능하면 idempotent)
  - `./demo/installation/NNN-*.sh verify` : 단계 검증(게이트)
- **상태 전달**
  - 단계 스크립트는 환경 변수를 통해 상태를 공유한다(예: `RUN_ID`, `WORKDIR`, `PROFILE`).
  - 러너는 각 단계 실행 후 즉시 `verify`를 호출한다.
- **FAIL-fast**
  - `verify`가 FAIL이면 러너는 즉시 중단한다.
- **best-effort 구간**
  - pre-commit은 별도 단계에서 best-effort로 실행하되, 실패를 기록하고 계속 진행한다.
