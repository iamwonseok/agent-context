# Documentation

agent-context 프로젝트의 모든 문서를 관리하는 디렉터리입니다.

## Language Policy

| Document Type | Language | Notes |
|---------------|----------|-------|
| ARCHITECTURE.md, README.md | English | Official baseline (English first) |
| Internal guides, scenarios | Korean OK | Internal team use |
| Executable code, commits | English only | Per .cursorrules policy |

**On change**: Update English docs first, sync Korean docs if needed.

## 구조

```
docs/
├── installation.md          # 설치 가이드
├── cli/                     # CLI 사용법
│   ├── agent.md             # Main CLI 개요
│   ├── agent-dev.md         # Developer 명령어
│   ├── agent-mgr.md         # Manager 명령어
│   └── agent-init.md        # 프로젝트 초기화
├── guides/                  # 가이드 문서
│   ├── manual-fallback-guide.md
│   └── efficiency-quick-reference.md  # Agent efficiency patterns
├── examples/                # 예제 문서
│   └── efficiency/          # Efficiency pattern examples
├── style/                   # 코딩 컨벤션 (coding-convention)
│   ├── bash.md
│   ├── c.md
│   ├── cpp.md               # (Out of scope)
│   ├── make.md
│   ├── python.md
│   └── yaml.md
├── rfcs/                    # RFC/계획 문서 (plan)
│   ├── _template/           # RFC template (NEW)
│   ├── 002-proposal.md
│   ├── 004-agent-workflow-system.md
│   ├── 005-manual-fallback-improvement.md
│   └── archive/             # 이전 버전 아카이브
├── references/              # 외부 참조 문서/프로젝트
│   └── README.md            # 참고 링크 모음
└── internal/                # 내부 임시 문서 (handoff, draft)
    └── README.md            # 정책 및 lifecycle
```

## Quick Links

| 문서 | 설명 |
|------|------|
| [installation.md](installation.md) | 설치 및 설정 가이드 |
| [cli/agent.md](cli/agent.md) | CLI 전체 개요 |
| [cli/agent-dev.md](cli/agent-dev.md) | 개발자 명령어 상세 |
| [cli/agent-mgr.md](cli/agent-mgr.md) | 매니저 명령어 상세 |
| [guides/efficiency-quick-reference.md](guides/efficiency-quick-reference.md) | Agent 효율성 패턴 가이드 |
| [examples/efficiency/](examples/efficiency/) | 효율성 패턴 예제 |
| [rfcs/_template/](rfcs/_template/) | RFC 템플릿 |
| [references/README.md](references/README.md) | 외부 참조 문서/프로젝트 모음 |
| [internal/README.md](internal/README.md) | 내부 문서 정책 (handoff lifecycle) |

## 관련 문서

- [ARCHITECTURE.md](../ARCHITECTURE.md) - 설계 철학
- [skills/README.md](../skills/README.md) - 스킬 레퍼런스
- [workflows/README.md](../workflows/README.md) - 워크플로우 정의
