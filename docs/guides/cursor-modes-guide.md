# Cursor Modes Guide

This guide explains how agent-context integrates with Cursor IDE modes for optimal AI-assisted development.

## Overview

Cursor IDE provides specialized modes for different development activities. Agent-context skills and workflows are tagged with `cursor_mode` to indicate which Cursor mode best suits each activity.

## Mode Mapping

| Cursor Mode | Agent Mode | Primary Use | Skills |
|-------------|------------|-------------|--------|
| `plan` | planning | Design, architecture, task breakdown | planning/* |
| `ask` | research | Exploration, analysis, investigation | analyze/* |
| `agent` | implementation | Code changes, execution, integration | execute/*, integrate/* |
| `debug` | verification | Testing, validation, debugging | validate/* |

## When to Use Each Mode

### Plan Mode (`cursor_mode: plan`)

Use for high-level design and planning activities where the AI helps you think through architecture and approach before writing code.

**Appropriate for:**
- Creating design documents
- Breaking down tasks
- Estimating effort
- Creating timelines
- Resource allocation

**Skills:**
- `planning/design-solution`
- `planning/breakdown-work`
- `planning/estimate-effort`
- `planning/schedule-timeline`
- `planning/allocate-resources`
- `planning/design-test-plan`

**Boundaries:**
- Will: Create documentation, analyze options, suggest approaches
- Will NOT: Write implementation code, modify existing files

---

### Ask Mode (`cursor_mode: ask`)

Use for exploration and research activities where you need to understand code, systems, or requirements before taking action.

**Appropriate for:**
- Understanding codebase structure
- Investigating issues
- Parsing requirements
- Evaluating priorities
- Assessing project status

**Skills:**
- `analyze/parse-requirement`
- `analyze/inspect-codebase`
- `analyze/inspect-logs`
- `analyze/assess-status`
- `analyze/evaluate-priority`

**Boundaries:**
- Will: Read files, analyze patterns, document findings
- Will NOT: Modify any files or execute changes

---

### Agent Mode (`cursor_mode: agent`)

Use for actual implementation work where the AI helps write, modify, and integrate code.

**Appropriate for:**
- Writing new code
- Fixing bugs
- Refactoring
- Updating documentation
- Managing issues
- Creating commits
- Creating merge requests

**Skills:**
- `execute/write-code`
- `execute/fix-defect`
- `execute/refactor-code`
- `execute/update-documentation`
- `execute/manage-issues`
- `integrate/commit-changes`
- `integrate/create-merge-request`
- `integrate/merge-changes`
- `integrate/notify-stakeholders`
- `integrate/publish-report`

**Boundaries:**
- Will: Modify files, create commits, interact with external systems
- Will NOT: Skip validation, bypass reviews, ignore tests

---

### Debug Mode (`cursor_mode: debug`)

Use for testing and validation activities where you need to verify code behavior and quality.

**Appropriate for:**
- Running tests
- Checking code style
- Reviewing code
- Analyzing impact
- Verifying requirements
- Checking intent alignment

**Skills:**
- `validate/run-tests`
- `validate/check-style`
- `validate/review-code`
- `validate/analyze-impact`
- `validate/verify-requirements`
- `validate/check-intent`

**Boundaries:**
- Will: Execute tests, report results, identify issues
- Will NOT: Fix bugs, modify code (only report findings)

---

## Workflow Mode Transitions

Workflows typically transition through multiple modes as work progresses:

### Feature Development

```
ask → plan → agent → debug → agent
  │     │      │       │      │
  │     │      │       │      └─ commit/MR
  │     │      │       └─ run tests, review
  │     │      └─ write code
  │     └─ design, plan
  └─ understand requirements
```

### Bug Fix

```
debug → agent → debug → agent
   │      │       │       │
   │      │       │       └─ commit/MR
   │      │       └─ verify fix
   │      └─ fix code
   └─ investigate issue
```

### Hotfix

```
agent → debug → agent
   │      │       │
   │      │       └─ quick commit/deploy
   │      └─ critical tests
   └─ fast fix
```

### Refactoring

```
plan → agent → debug → agent
  │      │       │       │
  │      │       │       └─ commit/MR
  │      │       └─ regression tests
  │      └─ refactor code
  └─ plan approach
```

---

## Self-Correction Protocol

When the agent detects it's taking actions inappropriate for the current mode, the Self-Correction Protocol activates:

### Violation Detection

| Mode | Violation |
|------|-----------|
| plan | Code changes staged |
| ask | Any file modifications |
| debug | New feature code added |
| agent | (Generally permissive) |

### Response

When a violation is detected:

1. **Warning** - Clear message about the mismatch
2. **Recommendation** - Suggested mode or action
3. **User Choice** - Proceed with `--force` or correct

### Example

```
Current Mode: plan
Staged: src/feature.ts

[SELF-CORRECTION] Mode Violation Detected
  Current Mode: plan
  Violation: Code changes detected in planning mode

  Recommended Actions:
    1. Switch to agent mode for implementation
    2. Or unstage changes and continue planning

  Use --force to proceed anyway.
```

---

## Integration with Cursor IDE

### Setting Mode

When starting a workflow, consider:

1. **Check skill's cursor_mode** - Each skill specifies its ideal mode
2. **Follow workflow transitions** - Workflows define mode sequences
3. **Trust self-correction** - Let the system warn about mismatches

### CLI Support

```bash
# Show current mode
agent dev mode

# Run with specific mode context
agent dev start --mode planning

# Check for mode violations
agent dev check
```

### State File

Mode is tracked in `.context/<task>/mode.txt`:

```
planning
```

---

## Best Practices

1. **Start in plan/ask** - Understand before implementing
2. **Follow natural transitions** - Don't jump modes randomly
3. **Heed self-correction warnings** - They catch drift early
4. **Use debug mode for validation** - Separate testing from coding
5. **Let agent mode do the work** - Implementation belongs there

---

## Related Resources

- [RFC-004: Agent Workflow System](../rfcs/004-agent-workflow-system.md)
- [Skills Overview](../../skills/README.md)
- [Workflows Overview](../../workflows/)
- [Manual Fallback Guide](manual-fallback-guide.md)
