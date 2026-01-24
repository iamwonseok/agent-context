# docs/internal/ - Internal Working Documents

This directory contains **temporary internal documents** that are not part of the official documentation.

## Purpose

- Draft documents before promotion to `docs/`
- Session-to-session handoff notes
- Work-in-progress analysis or proposals
- Internal team coordination

## Lifecycle Policy

| Document Type | Lifecycle | Action on Completion |
|---------------|-----------|---------------------|
| `handoff.md` | Session handoff | Delete after takeover |
| Draft proposals | WIP → Review | Promote to `docs/rfcs/` or delete |
| Analysis notes | Temporary | Archive or delete |

### handoff.md

**Purpose**: Project-wide session handoff (not branch-specific)

**When to create**:
- Ending a work session with incomplete tasks
- Complex multi-session work requiring context preservation
- Handing off work to another person/agent

**When to delete**:
- After the next session takes over and understands the context
- After all tasks mentioned are completed
- After content is absorbed into RFC or other permanent docs

**Content template**:
```markdown
# Handoff: [Topic]

## Completed Work (Date)
- What was done

## Remaining Work
- What needs to be done next

## Notes
- Important context for the next session
```

## Relationship with Other Handoff Systems

### Branch-level Handoff (`.context/handoff-*.md`)

| Aspect | Branch Handoff | Project Handoff |
|--------|---------------|-----------------|
| Location | `.context/handoff-{branch}.md` | `docs/internal/handoff.md` |
| Git tracking | gitignore (local only) | Tracked (shareable) |
| Scope | Single branch work | Project-wide / multi-branch |
| Trigger | Branch switch | Session end |
| Cleanup | Auto-archive on show | Manual delete after takeover |

**Use branch handoff when**:
- Switching between feature branches
- Short interruptions within a session
- Local work state only

**Use project handoff when**:
- Ending a session with complex context
- Handing off to another person/agent
- Multi-branch or project-wide work state

### Branch Handoff Archive Policy

Files in `.context/handoff-archive/` should be cleaned up:
- After MR is merged for that branch
- After branch is deleted
- Periodically (e.g., older than 30 days)

**Suggested cleanup command** (future enhancement):
```bash
agent dev cleanup --handoff-archive [--older-than=30d]
```

## Guidelines

1. **Keep it temporary**: Documents here should not live permanently
2. **Be explicit about next steps**: Always include "what to do next"
3. **Delete when done**: Don't let stale handoffs accumulate
4. **Promote valuable content**: If analysis is valuable, move to `docs/rfcs/`

## Current Files

(No active handoff documents - all tasks migrated to RFCs)

**Reference**: For implementation status, see:
- [RFC 002](../rfcs/002-proposal.md#implementation-status) - v2.0 Implementation Status
- [RFC 005](../rfcs/005-manual-fallback-improvement.md) - Manual Fallback Tasks
