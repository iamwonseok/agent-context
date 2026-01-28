# Changelog

All notable changes to the Agent Context system will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Changed
- **BREAKING**: Renamed CLI from `agent` to `agnt-c` to avoid conflicts with other tools (e.g., cursor-agent)
- PATH prepending instead of appending in activate.sh and setup.sh for tool precedence

## [2.0.0] - 2026-01-28

### Major Features

**RFC-004: Agent Workflow System v2.0**
- Phase 1: State Visibility - Mode display, cursor mode hints, self-correction protocol
- Phase 2: Feedback Loops - Question-driven planning, debrief command
- All skills updated with mode/cursor_mode frontmatter

**RFC-005: Manual Fallback Improvement**
- `agent dev submit --only=<steps>` - Run specific steps (sync, push, pr, jira)
- `agent dev submit --skip=<steps>` - Skip specific steps
- `agent dev check --install-hook` - Install pre-commit hook
- `agent dev check --uninstall-hook` - Remove hook
- `agent dev check --status` - Show hook status
- Short aliases: `agent sync`, `agent check`, `agent submit` (without 'dev')

**RFC-012: Test Planning Framework**
- All 10 RFCs now include standardized Test Plan sections
- Template: Unit/Integration/E2E test requirements

### Added
- `tools/agent/lib/checks.sh` - Pre-commit hook management
- `docs/guides/manual-fallback-guide.md` - Manual workflow documentation
- `docs/guides/troubleshooting.md` - Common issues and solutions
- `docs/architecture/skills-tools-mapping.md` - Skill-tool relationships

### Changed
- `tools/agent/bin/agent` - Extended aliases, updated help
- `tools/agent/lib/branch.sh` - `dev_submit` with --only/--skip, `dev_check` with hook options
- Skills frontmatter now includes `mode` and `cursor_mode` fields
- All scenario tests include Manual Flow sections

### Documentation
- `docs/rfcs/future-work.md` - FW-11 (RFC-006 deferred)
- `docs/internal/handoff.md` - Updated to v1.6

### Statistics
- RFCs Implemented: 4/10 (RFC-004, 005, 011, 012)
- Unit Tests: 413+ passing
- Skills: 26 (all with mode metadata)
- Workflows: 9 (all with manual fallback)

## [0.2.0] - 2026-01-23

### Added
- Design philosophy document (`why.md`) - simplicity, user autonomy, feedback over enforcement
- Over-engineering prevention rules in `.cursorrules`
- `agent dev check` - Quality checks (lint, test, intent alignment) with warnings only
- `agent dev verify` - Generate verification report (`.context/{task-id}/verification.md`)
- `agent dev retro` - Create retrospective document (`.context/{task-id}/retrospective.md`)
- Lightweight checks library (`lib/checks.sh`) - ~170 lines vs planned ~800 lines
- New skill: `validate/check-intent` - Intent alignment checking
- Templates: `verification.md`, `retrospective.md`

### Changed
- `agent dev submit` now checks for verification.md and retrospective.md (warnings, not blocking)
- `agent dev submit --force` option to skip pre-submit checks
- Updated help text with workflow guidance

### Design Decisions
- Rejected 12-state FSM in favor of simple warning system (see `why.md`)
- All checks are warnings by default, not hard blocks
- Progressive enforcement: Phase 1 (warn) -> Phase 2 (soft) -> Phase 3 (hard)

## [0.1.0] - 2026-01-20

### Added
- Initial CLI structure (`agent dev`, `agent mgr`)
- Branch management (Interactive Mode)
- Worktree management (Detached Mode)
- Context tracking (`.context/{task-id}/`)
- Basic commands: start, list, switch, status, sync, submit, cleanup
- Skills directory structure (analyze, plan, execute, validate, integrate)
- Workflow templates (feature, bug-fix, hotfix, refactor)

---

## How to Use This Changelog

```bash
# View recent changes
head -50 .agent/CHANGELOG.md

# Check specific file history
git log --oneline -10 -- .cursorrules
git log --oneline -10 -- .agent/why.md

# Compare versions
git diff v0.1.0..v0.2.0 -- .cursorrules
```
