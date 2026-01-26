# Skills → Tools Mapping

This document defines the relationship between Skills and Tools in the agent-context framework.

## Overview

**Skills** provide conceptual guidance for AI agents (via SKILL.md).  
**Tools** are executable scripts/binaries that perform actual work.

Skills reference tools in their documentation, but don't directly execute them.  
The agent CLI (`tools/agent/`) orchestrates tool execution based on skill guidance.

---

## Mapping Table

### Validation Skills

| Skill | Tools Used | Command Example | Notes |
|-------|------------|-----------------|-------|
| `validate/check-style` | `tools/lint/` | `make lint`, `flake8`, `shellcheck` | Detects via project files (Makefile, package.json) |
| `validate/run-tests` | pytest, jest, make | `pytest tests/`, `npm test`, `make test` | Test framework detection |
| `validate/review-code` | git, static analyzers | `git diff`, lint tools | Manual + automated checks |
| `validate/verify-requirements` | grep, diff | Compare implementation vs design docs | File-based verification |
| `validate/analyze-impact` | git, grep | `git diff --stat`, dependency analysis | Impact assessment |
| `validate/check-intent` | N/A | Human review | Conceptual validation |

### Integration Skills

| Skill | Tools Used | Command Example | Notes |
|-------|------------|-----------------|-------|
| `integrate/commit-changes` | git | `git add`, `git commit` | Direct git usage |
| `integrate/create-merge-request` | `tools/pm/` | `pm mr create` | Platform-agnostic MR creation |
| `integrate/merge-changes` | git, `tools/pm/` | `git merge`, `pm mr merge` | Merge execution |
| `integrate/notify-stakeholders` | `tools/pm/` | `pm notify` | Notifications via PM tools |
| `integrate/publish-report` | `tools/pm/` | `pm report publish` | Report publishing |

### Analysis Skills

| Skill | Tools Used | Command Example | Notes |
|-------|------------|-----------------|-------|
| `analyze/parse-requirement` | N/A | Interactive Q&A | Agent-driven dialogue |
| `analyze/inspect-codebase` | grep, find, LSP | `rg`, `fd`, language servers | Code exploration |
| `analyze/inspect-logs` | grep, awk, jq | Log parsing tools | Log analysis |
| `analyze/evaluate-priority` | `tools/pm/` | `pm issue get` | Issue metadata retrieval |
| `analyze/assess-status` | `tools/pm/`, git | `pm status`, `git log` | Status tracking |

### Planning Skills

| Skill | Tools Used | Command Example | Notes |
|-------|------------|-----------------|-------|
| `planning/design-solution` | N/A | Document generation | Creates design/*.md files |
| `planning/breakdown-work` | `tools/pm/` | `pm task create` | Task creation |
| `planning/estimate-effort` | N/A | Estimation logic | Story point calculation |
| `planning/schedule-timeline` | `tools/pm/` | `pm milestone set` | Timeline management |
| `planning/allocate-resources` | `tools/pm/` | `pm assign` | Resource allocation |

### Execution Skills

| Skill | Tools Used | Command Example | Notes |
|-------|------------|-----------------|-------|
| `execute/write-code` | Editor, test runners | Code generation + TDD | Agent-generated code |
| `execute/refactor-code` | Refactoring tools | Code transformation | Incremental refactoring |
| `execute/fix-defect` | Debugger, test tools | Bug fixing workflow | TDD-based bug fixing |
| `execute/update-documentation` | Markdown editors | Documentation updates | Markdown file editing |
| `execute/manage-issues` | `tools/pm/` | `pm issue update` | Issue management |

---

## Tool Categories

### 1. Agent CLI (`tools/agent/`)

Entry point for all workflows. Orchestrates skill execution.

**Key Commands:**
- `agent dev start` → Initialize development context
- `agent dev check` → Run validation skills
- `agent dev commit` → Execute commit-changes skill
- `agent dev submit` → Execute create-merge-request skill

### 2. PM Tools (`tools/pm/`)

Platform-agnostic project management interface.

**Implementations:**
- `lib/jira.sh` → JIRA API
- `lib/gitlab.sh` → GitLab API
- `lib/github.sh` → GitHub API
- `lib/confluence.sh` → Confluence API (future)

**Key Commands:**
- `pm mr create` → Create merge request
- `pm issue get` → Retrieve issue details
- `pm task create` → Create new task

### 3. Lint Tools (`tools/lint/`)

Code quality validation.

**Supported Languages:**
- C/C++ → clang-format, custom checkers
- Bash → shellcheck
- Python → flake8, black
- YAML → yamllint
- Make → make-lint

### 4. System Tools

Standard Unix/Git tools used directly:
- `git` → Version control
- `grep/rg` → Text search
- `make` → Build automation
- `docker` → Containerization

---

## Validation Strategy

### Unit Tests

Test individual tool functionality:
```bash
tests/unit/lint/test_c_lint.sh
tests/unit/pm/test_pm_api.sh
```

### Integration Tests

Test skills → tools interaction:
```bash
tests/integration/test_skills_tools.sh
```

Validates:
- Skills reference correct tools
- Tools are available when needed
- Error handling works

### Scenario Tests

End-to-end workflow validation:
```bash
tests/scenario/001-dev-standard-loop.md
```

---

## Design Principles

### 1. Loose Coupling

Skills provide guidance, not tool invocation.  
Agent CLI orchestrates actual tool execution.

### 2. Platform Abstraction

`tools/pm/` abstracts platform differences.  
Skills reference generic operations, not specific APIs.

### 3. Graceful Degradation

If tools are unavailable:
- Warn user
- Provide manual alternatives
- Don't hard-block

### 4. Discoverable

Tools self-document via `--help`.  
Skills document tool usage in SKILL.md.

---

## Future Extensions

### RFC-007: Intermediate Representation (IR)

Planned enhancement for explicit skill-to-tool mapping:

```yaml
# .context/TASK-123/intermediate.yaml
stages:
  validate:
    check-style:
      tools_invoked:
        - command: make lint
          exit_code: 0
          duration_ms: 1234
```

This would enable:
- Runtime tool usage tracking
- Performance profiling
- Automated test generation

---

## References

- [ARCHITECTURE.md](../../ARCHITECTURE.md) - Design philosophy
- [skills/PIPELINE.md](../../skills/PIPELINE.md) - Skills pipeline
- [tools/agent/README.md](../../tools/agent/README.md) - CLI usage
- [tools/pm/README.md](../../tools/pm/README.md) - PM tools
- [RFC-007](../rfcs/007-architecture-improvements.md) - IR proposal
