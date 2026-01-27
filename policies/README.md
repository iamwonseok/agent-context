# Agent-Context Framework Policies

This directory contains framework development rules and conventions for agent-context itself.

## Purpose

| Directory | Purpose | Content |
|-----------|---------|---------|
| `docs/style/` | "How to write code" | Coding conventions, formatting |
| `policies/` | "What to know" | Framework rules, design decisions |

## Framework Rules

### 1. Complexity Budget

| Component | Max Lines |
|-----------|-----------|
| Single skill | 200 |
| Workflow | 100 |
| CLI command | 100 |
| Helper library | 300 |

See: `ARCHITECTURE.md` for rationale.

### 2. Language Policy

| File Type | English | Korean |
|-----------|:-------:|:------:|
| Skills/Workflows | Required | Forbidden |
| Code/Comments | Required | Forbidden |
| Internal docs | Recommended | Allowed |

See: `docs/rfcs/011-language-policy.md`

### 3. Output Style

- ASCII only, no emoji icons
- Use: `[PASS]`, `[FAIL]`, `[WARN]`, `[INFO]`
- Checkmarks: `[x]` or `(v)` not checkmark symbols

### 4. File Naming

- Skills: `skills/{category}/{skill-name}/SKILL.md`
- Workflows: `workflows/{role}/{workflow-name}.md`
- RFCs: `docs/rfcs/NNN-descriptive-title.md`

## See Also

- [ARCHITECTURE.md](../ARCHITECTURE.md) - Design philosophy
- [.cursorrules](../.cursorrules) - Agent behavior rules
- [docs/rfcs/](../docs/rfcs/) - Framework plans
