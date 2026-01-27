---
name: parse-requirement
category: analyze
description: Parse and clarify requirements before coding
version: 1.0.0
role: developer
mode: research
cursor_mode: ask
inputs:
  - User request (vague or clear)
outputs:
  - design/{feature}.md
---

# Parse Requirement

## State Assertion

**Mode**: research
**Cursor Mode**: ask
**Purpose**: Clarify requirements and create design documentation
**Boundaries**:
- Will: Ask questions, compare options, write design docs
- Will NOT: Write implementation code, create tests, or make commits

## Design Philosophy

Apply these principles when evaluating solutions:

| Principle | Description | Anti-pattern |
|-----------|-------------|--------------|
| **Simple** | Minimal implementation that works | Over-engineering, premature abstraction |
| **Composable** | Independent modules that combine | Monolithic designs, tight coupling |
| **Pattern-based** | Repeatable, proven approaches | One-off solutions, reinventing wheels |
| **Maintainable** | Easy to understand and modify | Clever code, hidden dependencies |

**Decision heuristic**: When comparing options, prefer the one that is simpler to explain, easier to test, and has fewer moving parts.

## When to Use

- User request is vague
- Need clear specs
- Multiple approaches possible

## Prerequisites

None.

## Workflow

### 1. Ask Questions

Clarify:
- **What**: Core feature
- **Why**: Problem to solve
- **How**: Expected behavior
- **Limits**: Constraints

#### Integration / automation checklist (when the request touches external systems)

If the work involves JIRA/GitLab/CI events, add these questions:

- **Actors**: Who can trigger it? (assignee, author, reviewer, maintainer)
- **Triggers**: What events start the workflow? (comment command, label, assignment, branch prefix)
- **Scope**: What is the maximum safe change? (files/LOC, repo areas, allowed operations)
- **Routing**: How is the workflow selected? (explicit command vs metadata vs branch naming)
- **State**: What is the state machine and mapping? (JIRA status <-> GitLab issue/MR signals)
- **Idempotency**: How to avoid repeated runs spamming comments?
- **Auditability**: What logs or comments must be left behind?
- **Permissions**: What auth is required? What actions are forbidden? (no force-push, no main edits)
- **Failure modes**: API rate limits, missing context, conflicts, CI failures
- **Outputs**: What artifacts must be produced? (design doc, plan, MR, issue links)

### 2. Compare Options

| Option | Pros | Cons | Best For |
|--------|------|------|----------|
| A | ... | ... | ... |
| B | ... | ... | ... |

Recommend one.

### 3. Write Design Doc

Show in chunks. Get approval.

### 4. Save

```bash
design/{feature}.md
```

## Outputs

| Output | Format |
|--------|--------|
| `design/{feature}.md` | Markdown |

See `templates/design-doc.md`.

## Examples

### UART Driver

```
User: "Add UART driver"

AI: Questions:
    1. Baud rate? (115200, 921600, configurable)
    2. Buffer? (ring buffer, DMA)
    3. Mode? (interrupt, polling)

User: "115200, ring buffer, interrupt"

AI: Writing design doc...
```

## Notes

- No design = big rework later
- Even small changes need analysis
