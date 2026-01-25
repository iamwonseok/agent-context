# RFC-008: Domain Extension & Installation Improvements

**Status**: Draft
**Author**: wonseok
**Created**: 2026-01-25
**Related**: NotebookLM Domain-Specific RFC Analysis (4 documents consolidated)

---

## 1. Summary

This RFC proposes three improvements to agent-context:

1. **Domain Extension**: `policies/` directory for domain-specific knowledge management
2. **Installation Flow**: Clear separation of responsibilities (bootstrap -> setup -> activate -> agent setup)
3. **Template Fix**: Update `.cursorrules.template` paths to match current structure

---

## 2. Motivation

### Problem 1: No Space for Domain Knowledge

- No dedicated location for domain-specific rules (e.g., OpenTitan HW design, security policies)
- `docs/style/` focuses on coding conventions, not domain knowledge
- Teams cannot share domain expertise across projects

### Problem 2: Confused Installation Flow

- `setup.sh` handles both "installation" and "template copying"
- Project-local installation requires manual PATH setup every session
- `agent setup` command does not exist (mentioned in RFC-004 but not implemented)

### Problem 3: Template Path Mismatch

- `templates/.cursorrules.template` references outdated paths:
  - `skills/plan/` -> should be `skills/planning/`
  - `workflows/feature.md` -> should be `workflows/developer/feature.md`
  - `coding-convention/` -> should be `docs/style/`

---

## 3. Design

### 3.1 Domain Extension

#### Concept: Separation of Concerns

| Directory | Purpose | Content |
|-----------|---------|---------|
| `docs/style/` | "How to write code" | Coding conventions, formatting |
| `policies/` | "What to know" | Domain knowledge, design rules, security policies |

#### Directory Structure (agent-context development)

```
agent-context/
├── policies/                    # Framework development rules
│   └── README.md               # Framework conventions
│
├── templates/
│   └── policies/               # User project templates
│       ├── README.md           # Extension guide
│       └── _template.md        # Policy file template
```

#### Directory Structure (user project)

```
user-project/
├── .agent/                     # Installed via git clone
│   └── policies/              # Framework rules (read-only concept)
│
└── policies/                   # User domain policies (writable)
    ├── README.md
    └── opentitan_hw_design.md  # User-added domain knowledge
```

#### Path Resolution Priority

```
1. ./policies/              # Project local (highest priority)
2. ./.agent/policies/       # Framework rules
3. ~/.agent/policies/       # Global (if exists)
```

### 3.2 Installation Flow Improvement

#### Role Separation

| Script | Role | When to Run |
|--------|------|-------------|
| `bootstrap.sh` | Check prerequisites | Once per machine |
| `setup.sh --global` | Install to ~/.agent | Once per machine |
| `activate.sh` | Load session env vars | Every session (project-local) |
| `agent setup` | Install templates to project | Once per project |

#### Usage Flow: Global Installation

```bash
# 1. Clone to global location
git clone https://github.com/iamwonseok/agent-context.git ~/.agent

# 2. Run global setup
cd ~/.agent
./setup.sh --global

# 3. Reload shell or source profile
source ~/.bashrc

# 4. In any project, install templates
cd your-project
agent setup
```

#### Usage Flow: Project-Local Installation

```bash
# 1. Clone to project
cd your-project
git clone https://github.com/iamwonseok/agent-context.git .agent

# 2. Activate for this session
source .agent/activate.sh

# 3. Install templates
agent setup
```

### 3.3 agent setup Command

#### Behavior: Idempotent with --force

```bash
# Default: skip existing files
$ agent setup
[INFO] .cursorrules already exists, skipping
[INFO] configs/ already exists, skipping
[OK] Created policies/
[OK] Setup complete (1 created, 2 skipped)

# Force: overwrite all
$ agent setup --force
[WARN] Overwriting .cursorrules
[WARN] Overwriting configs/
[WARN] Overwriting policies/
[OK] Setup complete (3 created)
```

#### Files Installed

| Source | Destination | Description |
|--------|-------------|-------------|
| `templates/.cursorrules.template` | `.cursorrules` | Agent behavior rules |
| `templates/configs/` | `configs/` | Tool configurations |
| `templates/policies/` | `policies/` | Domain policy templates |

### 3.4 Template Path Fixes

#### .cursorrules.template Updates

| Current (Wrong) | Should Be |
|-----------------|-----------|
| `.agent/skills/plan/design-solution/` | `.agent/skills/planning/design-solution/` |
| `.agent/workflows/feature.md` | `.agent/workflows/developer/feature.md` |
| `.agent/coding-convention/` | `.agent/docs/style/` |

---

## 4. Implementation Plan

### Phase 1: Documentation (This RFC)

- [x] RFC-008 creation
- [ ] Update docs/rfcs/README.md
- [ ] Update docs/rfcs/future-work.md (FW-9, FW-10)

### Phase 2: Template Fixes

| File | Action | Priority |
|------|--------|----------|
| `templates/.cursorrules.template` | FIX paths + add policies | High |
| `templates/policies/README.md` | NEW | High |
| `templates/policies/_template.md` | NEW | High |

### Phase 3: Tool Implementation

| File | Action | Priority |
|------|--------|----------|
| `activate.sh` | NEW | High |
| `tools/agent/lib/setup.sh` | NEW | High |
| `tools/agent/bin/agent` | UPDATE (add setup subcommand) | High |
| `setup.sh` | UPDATE (simplify) | Medium |

### Phase 4: Documentation Update

| File | Action | Priority |
|------|--------|----------|
| `README.md` | UPDATE usage | Medium |
| `ARCHITECTURE.md` | UPDATE (add policies/) | Medium |
| `.cursorrules` | UPDATE (add policies rule) | Medium |
| `policies/README.md` | NEW (framework rules) | Low |

---

## 5. Philosophy Compliance

| Principle | Compliance | Notes |
|-----------|------------|-------|
| Simplicity Over Completeness | Yes | Directory convention only, no complex loader |
| User Autonomy | Yes | opt-in, --force option |
| Feedback Over Enforcement | Yes | policies = reference, not enforcement |
| Composability | Yes | skills/workflows unchanged |
| State Through Artifacts | Yes | File-based, Git-managed |

---

## 6. Future Work References

### FW-9: Domain Extension Ecosystem

- Community domain pack sharing
- `agent extension search/install` commands
- Registry server (high complexity, post-Phase 2)

### FW-10: Retrospective Skill

- `skills/integrate/create-retrospective/`
- Bug fix -> retrospective -> policy update workflow
- Team review before merging to knowledge base

---

## 7. References

- NotebookLM Domain-Specific Analysis (4 RFC documents)
- [RFC-004](004-agent-workflow-system.md): Agent Workflow System v2.0
- [RFC-007](007-architecture-improvements.md): Architecture Pattern Improvements
- [ARCHITECTURE.md](../../ARCHITECTURE.md): Design Philosophy

---

## 8. Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-01-25 | Initial draft | wonseok |
