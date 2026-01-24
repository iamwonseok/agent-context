# Documentation

agent-context 프로젝트의 모든 문서를 관리하는 디렉터리입니다.

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
│   └── manual-fallback-guide.md
├── style/                   # 코딩 컨벤션 (coding-convention)
│   ├── bash.md
│   ├── c.md
│   ├── cpp.md
│   ├── make.md
│   ├── python.md
│   └── yaml.md
├── rfcs/                    # RFC/계획 문서 (plan)
│   ├── proposal.md
│   ├── proposal-v2.md
│   ├── agent-workflow-system-plan.md
│   ├── agent-workflow-system-plan-v2.md
│   └── manual-fallback-improvement-plan.md
└── internal/                # 내부 문서
    └── handoff.md
```

## Quick Links

| 문서 | 설명 |
|------|------|
| [installation.md](installation.md) | 설치 및 설정 가이드 |
| [cli/agent.md](cli/agent.md) | CLI 전체 개요 |
| [cli/agent-dev.md](cli/agent-dev.md) | 개발자 명령어 상세 |
| [cli/agent-mgr.md](cli/agent-mgr.md) | 매니저 명령어 상세 |

## 관련 문서

- [ARCHITECTURE.md](../ARCHITECTURE.md) - 설계 철학
- [skills/README.md](../skills/README.md) - 스킬 레퍼런스
- [workflows/README.md](../workflows/README.md) - 워크플로우 정의
