# Solo Hotfix Workflow

> Emergency fix for production issues.

## Overview

| Aspect | Value |
|--------|-------|
| **Scope** | Individual developer |
| **Trigger** | Production incident |
| **Output** | Deployed fix |
| **Duration** | Minutes to hours |

**Inherits:** [Global Defaults](../README.md#global-defaults)

---

## Hotfix Policy

### MR Requirements

| Item | Rule |
|------|------|
| Title | Jira key required (e.g., `[SPF-1290] Fix critical auth failure`) |
| Evidence | Optional (pipeline visible in MR UI) |

---

## Prerequisites

- [ ] Production incident confirmed
- [ ] Hotfix authorized (manager/on-call approval)
- [ ] On hotfix branch from production tag

---

## Step 1: Implement Hotfix

> **Skip Analysis & Design** - Time is critical. Fix first, analyze later.

**Context Mapping:**
| Skill Input | Source |
|-------------|--------|
| `design` | Minimal fix approach (stop the bleeding) |
| `acceptance_criteria` | Production incident resolved |
| `codebase` | Production branch/tag |

**Call Skill:** `skills/implement.md`

**Hotfix Principles:**
- Smallest possible change
- No refactoring
- No new features
- Fix only the immediate issue

**Output:** Hotfix committed

---

## Step 2: Verify Fix

**Context Mapping:**
| Skill Input | Source |
|-------------|--------|
| `implementation` | Hotfix commit |
| `acceptance_criteria` | Incident resolved, no new issues |
| `test_scope` | Smoke test + incident-specific |

**Call Skill:** `skills/test.md`

**Minimum Verification:**
1. Incident no longer reproducible
2. Core functionality works (smoke test)
3. No obvious new errors in logs

**Output:** Fix verified

---

## Step 3: Deploy & Monitor

**Actions:**
1. Create PR to production branch
2. Get expedited review (1 reviewer minimum)
3. Merge and deploy
4. Monitor for 15-30 minutes

**Monitoring Checklist:**
- [ ] Error rates back to normal
- [ ] No new error types
- [ ] Key metrics stable

---

## Step 4: Post-Incident

> **After incident resolved** - Now do the analysis you skipped.

**Context Mapping:**
| Skill Input | Source |
|-------------|--------|
| `context` | Incident timeline + fix applied |
| `artifacts` | Logs, metrics, alerts |
| `goal` | Root cause analysis + prevention |

**Call Skill:** `skills/analyze.md`

**Deliverables:**
1. Incident report (root cause, timeline, fix)
2. Follow-up ticket for proper fix (if hotfix was temporary)
3. Prevention measures (monitoring, tests, etc.)

---

## Completion Criteria

- [ ] Production incident resolved
- [ ] Fix deployed and monitored
- [ ] Incident report created
- [ ] Follow-up ticket created (if needed)
- [ ] Hotfix merged to main branch

---

## Hotfix-Specific Rules

### Branch Strategy
```
production (or release tag)
    `-- hotfix/incident-{id}
        |-- merge to production
        `-- cherry-pick to main
```

### Approval Matrix
| Severity | Approvers | Review |
|----------|-----------|--------|
| P1 (Down) | On-call + 1 reviewer | Post-deploy |
| P2 (Degraded) | Tech lead + 1 reviewer | Pre-deploy |

### Rollback Plan
Before deploying, know how to rollback:
- Previous stable version/tag
- Rollback command ready
- Rollback criteria defined

### Communication
- Notify: #incident channel
- Update: Status page (if external)
- Report: Within 24h of resolution
