# 온보딩 문구 초안 (임시)

이 문서는 `README.md` 및 관련 문서에 반영할 **구체 문구 초안**이다.
현재 기준은 **글로벌 설치**를 권장하며, 데모는 **오프라인 설치 검증(스모크)** 과 **E2E(외부 인프라 통합)** 로 구분해 안내한다.

---

## README.md에 넣을 문구 초안

### 빠른 시작 (글로벌 설치, 권장)

다음 방식은 agent-context를 1회만 설치한 뒤, 여러 프로젝트에 반복 적용할 수 있다.

#### Step 1) 의존성 설치

macOS (Homebrew):

```bash
brew install git curl jq yq gh glab
python3 -m pip install --user pre-commit
```

Ubuntu/Debian/WSL:

```bash
sudo apt-get update
sudo apt-get install -y git curl jq python3 python3-pip
python3 -m pip install --user pre-commit

# yq (mikefarah/yq) 설치는 배포판/정책에 따라 다르다.
# 예: snap 또는 GitHub release 바이너리 사용.
```

#### Step 2) agent-context 클론 (글로벌 설치)

```bash
git clone <REPO_URL> ~/.agent-context
```

주의:
- `<REPO_URL>`은 본인의 org/fork에 맞는 URL로 교체해야 한다.

#### Step 3) 글로벌 환경 초기화 (alias + 토큰 로딩)

```bash
~/.agent-context/agent-context.sh init
source ~/.zshrc  # zsh
```

#### Step 4) 토큰 저장

```bash
mkdir -p ~/.secrets && chmod 700 ~/.secrets
echo "YOUR_ATLASSIAN_API_TOKEN" > ~/.secrets/atlassian-api-token
chmod 600 ~/.secrets/atlassian-api-token

# (선택) GitLab/GitHub 토큰을 사용하는 경우
echo "YOUR_GITLAB_TOKEN" > ~/.secrets/gitlab-api-token
chmod 600 ~/.secrets/gitlab-api-token
```

#### Step 5) 프로젝트에 설치

```bash
cd /path/to/your-project
agent-context install
```

#### Step 6) 설정 확인 및 연결 테스트

```bash
agent-context pm config show
agent-context pm jira me
```

---

### 설치 검증 (권장: 오프라인 스모크)

외부 계정/권한이 준비되지 않은 경우에도, 설치 자체가 정상 동작하는지 빠르게 검증할 수 있다.

```bash
./demo/install.sh --skip-e2e --only 6
```

이 모드는 다음을 검증한다:
- 설치 스크립트가 실행되고, `.cursorrules` / `.project.yaml` / `.agent/` 레이아웃이 생성된다.
- 정적 검증(스킬/워크플로 검증)이 통과한다.

---

### 통합 테스트 (오프라인 + E2E optional)

오프라인(설치/정적 검증)을 항상 수행하고, E2E 전제조건이 만족되면 E2E까지 수행한다.
전제조건이 부족하면 E2E는 스킵되며, 오프라인 결과는 검증된다.

```bash
./demo/install.sh --e2e-optional
```

---

### E2E 데모 (Jira/GitLab/Confluence 통합)

E2E는 실제 외부 시스템(Jira/GitLab/Confluence)에 리소스를 생성/수정한다.
조직 정책(권한, 네트워크, 프로젝트/스페이스 존재 여부)에 따라 실패할 수 있으므로, 먼저 오프라인 스모크를 권장한다.

```bash
export JIRA_EMAIL="your-email@example.com"
./demo/install.sh
```

E2E 전제조건(요약):
- `~/.secrets/atlassian-api-token` (필수)
- `JIRA_EMAIL` (필수)
- (GitLab 통합 시) `~/.secrets/gitlab-api-token` 및 SSH 키 준비

관리자 문의가 필요한 항목:
- Atlassian API token 발급 권한 및 Jira 프로젝트 접근 권한
- (Confluence 사용 시) space 접근/생성 권한, space key 정보
- (GitLab 통합 시) personal access token 발급 권한, repo/group 권한, SSH 키 등록, commit signing 정책

---

## docs/USER_GUIDE.md에 넣을 문구 초안

### 설치 방식 (권장)

본 가이드는 글로벌 설치를 권장한다:
- 장점: 여러 프로젝트에서 `agent-context install`을 반복 사용 가능
- 단점: 셸 설정(alias/환경변수)을 1회 반영해야 함

대안(권장하지 않음):
- 일회성 clone 후 `install.sh` 직접 실행
- 이유: 프로젝트마다 스크립트 위치가 달라지고, 업데이트 추적이 어려움

---

## tools/pm/README.md 또는 pm 에러 메시지에 넣을 문구 초안

### yq 설치 안내 (OS 독립)

`pm`은 `.project.yaml` 파싱을 위해 `yq`(mikefarah/yq)가 필요하다.
설치 방법은 OS/정책에 따라 다르며, 다음 중 하나를 사용한다:
- macOS: `brew install yq`
- Ubuntu/Debian: snap 또는 GitHub release 바이너리 설치

---

## 질문에 대한 정리 (의사결정 근거)

### 오프라인 검증과 E2E를 분리하면 의미가 떨어지지 않나?

의미가 떨어지기보다는, **실패 원인 분리가 가능해져서 디버깅 비용이 크게 줄어든다.**
- 오프라인 스모크는 "설치/레이아웃/정적 검증"만 보장한다.
- E2E는 여기에 더해 "외부 인프라/권한/네트워크/레이트리밋/일관성" 변수를 포함한다.

권장 흐름은 다음과 같다:
1) 오프라인 스모크로 설치 품질을 먼저 확정
2) E2E는 환경이 갖춰진 경우에만 수행(실패가 곧 코드 문제는 아님)

즉, "데모의 의미"는 유지하면서, 신규 사용자에게는 실패를 정상적인 경로로 흡수할 수 있게 한다.

### OS 정합성은 Docker 테스트로 확인 가능하지 않나?

부분적으로만 가능하다.
- Docker(ubuntu/ubi9)는 "리눅스 계열 2종"에 대한 재현성을 올려준다.
- 하지만 사용자가 로컬에서 실행하는 경우(특히 macOS)는:
  - `brew`, 기본 bash 버전, PATH, 권한, 키체인, 기업 보안 정책 등 Docker 밖 변수가 존재한다.

따라서 문서의 OS별 설치 안내는 여전히 필요하고,
Docker 테스트는 "스크립트/도구가 최소한 리눅스에서 동작한다"는 하한을 제공한다.

### 윈도우는 Docker가 없나?

Windows도 Docker를 사용할 수 있다.
- 일반적으로 **Docker Desktop**을 설치하고, 백엔드로 WSL2를 사용한다.
- 기업 정책상 Docker Desktop 설치가 제한될 수는 있다.

Windows 사용자를 위한 현실적인 안내 예시는 다음 중 하나다:
- WSL2 + Docker Desktop 환경에서 `./demo/install.sh --os ubuntu --skip-e2e --only 6`
- 또는 WSL2 환경에서 로컬 실행(필요 의존성 설치)
