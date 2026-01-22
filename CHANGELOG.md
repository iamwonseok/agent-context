# Changelog

All notable changes to the Agent Context system will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

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
