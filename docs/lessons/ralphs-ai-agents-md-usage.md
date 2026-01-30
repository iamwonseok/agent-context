# Ralph's AI AGENTS.md Usage

## Overview

[Ralph](https://github.com/snarktank/ralph)는 AI 코딩 도구(Amp 또는 Claude Code)를 반복 실행하여 PRD 항목이 완료될 때까지 자율적으로 작업하는 에이전트 루프 시스템.

## AGENTS.md Pattern

Ralph에서 AGENTS.md는 **루프 기반 에이전트의 메모리** 역할:

> "After each iteration, Ralph updates the relevant AGENTS.md files with learnings.
> This is key because AI coding tools automatically read these files,
> so future iterations benefit from discovered patterns, gotchas, and conventions."

### What to Record

- **Patterns discovered**: "this codebase uses X for Y"
- **Gotchas**: "do not forget to update Z when changing W"
- **Useful context**: "the settings panel is in component X"

### Memory Structure in Ralph

| File | Purpose |
|------|---------|
| `AGENTS.md` | Discovered patterns, gotchas (summary) |
| `progress.txt` | Append-only learnings (detail) |
| `prd.json` | Task status tracking |
| Git history | Code changes |

## When to Use AGENTS.md

### Suitable Use Cases

- **Loop-based agent systems**: 매 iteration마다 fresh context로 시작하는 시스템
- **PRD-driven task completion**: 자동으로 태스크를 반복 실행하여 완료하는 시스템
- **Context window reset**: 각 실행이 독립적이고 이전 컨텍스트를 모르는 경우

### Unsuitable Use Cases

- **Interactive sessions**: 대화형 세션에서는 컨텍스트가 유지됨
- **Single context work**: 같은 세션 안에서 작업이 완료되는 경우
- **Human-in-the-loop**: 사람이 직접 개입하여 컨텍스트를 전달하는 경우

## Alternative: docs/lessons/

대화형 세션이나 1 clone = 1 agent 환경에서는:

- AGENTS.md 대신 `docs/lessons/`에 교훈을 축적
- Git으로 공유되므로 다른 개발자/에이전트도 참조 가능
- 상세한 배경 설명 포함 가능

## References

- [Ralph GitHub](https://github.com/snarktank/ralph)
- [Geoffrey Huntley's Ralph Article](https://ghuntley.com/ralph/)
