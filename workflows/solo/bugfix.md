# Solo Bugfix Workflow

> Fix a reported bug with verification.

## Overview

| Aspect | Value |
|--------|-------|
| **Scope** | Individual developer |
| **Trigger** | Bug ticket assigned |
| **Output** | Merged PR with fix |
| **Duration** | Hours |

---

## Prerequisites

- [ ] Bug ticket exists with reproduction steps
- [ ] Bug is reproducible
- [ ] On bugfix branch (not main)

---

## Step 1: Analyze Bug

**Context Mapping:**
| Skill Input | Source |
|-------------|--------|
| `context` | Bug report + reproduction steps |
| `artifacts` | Logs, screenshots, stack traces |
| `goal` | Find root cause |

**Call Skill:** `skills/analyze.md`

**Focus Areas:**
- Reproduce the bug first
- Identify root cause (not just symptoms)
- Understand impact scope

**Output:** Root cause identified, fix approach determined

---

## Step 2: Implement Fix

> **Note:** Skip `skills/design.md` for simple bugs. Use design skill only if fix requires architectural changes.

**Context Mapping:**
| Skill Input | Source |
|-------------|--------|
| `design` | Root cause analysis + fix approach |
| `acceptance_criteria` | Bug no longer reproducible |
| `codebase` | File(s) containing the bug |

**Call Skill:** `skills/implement.md`

**Output:** Bug fix committed

---

## Step 3: Test Fix

**Context Mapping:**
| Skill Input | Source |
|-------------|--------|
| `implementation` | Bug fix commit |
| `acceptance_criteria` | Bug not reproducible + no regression |
| `test_scope` | Unit (bug-specific) + Regression |

**Call Skill:** `skills/test.md`

**Required Tests:**
1. Test that reproduces the bug (should fail before fix)
2. Test that verifies the fix (should pass after fix)
3. Existing tests still pass (no regression)

**Output:** All tests passing, bug verified fixed

---

## Step 4: Self-Review & PR

**Context Mapping:**
| Skill Input | Source |
|-------------|--------|
| `changes` | `git diff main...HEAD` |
| `context` | Bug ticket + root cause analysis |
| `standards` | Project conventions |

**Call Skill:** `skills/review.md`

**PR Description Must Include:**
- Root cause explanation
- Fix approach
- Test verification
- Link to bug ticket

**Output:** PR ready for review

---

## Completion Criteria

- [ ] Bug no longer reproducible
- [ ] Root cause addressed (not just symptom)
- [ ] Regression test added
- [ ] No new bugs introduced
- [ ] PR approved and merged
- [ ] Bug ticket closed

---

## Bugfix-Specific Guidance

### When to Escalate to Design
- Fix requires changing public API
- Fix affects multiple components
- Fix might introduce breaking changes

### Regression Test Template
```
Test: {bug_id}_regression_test
Given: {precondition that triggered bug}
When: {action that caused bug}
Then: {expected correct behavior}
```
