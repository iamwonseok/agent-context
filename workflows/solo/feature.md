# Solo Feature Workflow

> Full development cycle for a new feature.

## Overview

| Aspect | Value |
|--------|-------|
| **Scope** | Individual developer |
| **Trigger** | Feature ticket assigned |
| **Output** | Merged PR with feature |
| **Duration** | Hours to days |

---

## Prerequisites

- [ ] Feature ticket exists (JIRA, GitHub Issue, etc.)
- [ ] Acceptance criteria defined
- [ ] On feature branch (not main)

---

## Step 1: Analyze Requirements

**Context Mapping:**
| Skill Input | Source |
|-------------|--------|
| `context` | Ticket description + linked docs |
| `artifacts` | Ticket, existing code, design docs |
| `goal` | Understand what to build and why |

**Call Skill:** `skills/analyze.md`

**Output:** Clear understanding of requirements, unknowns identified

---

## Step 2: Design Solution

**Context Mapping:**
| Skill Input | Source |
|-------------|--------|
| `problem` | Analysis output > Problem statement |
| `scope` | Ticket > Acceptance criteria |
| `constraints` | Sprint deadline, tech stack, dependencies |

**Call Skill:** `skills/design.md`

**Output:** Tech spec or detailed PR description

---

## Step 3: Implement

**Context Mapping:**
| Skill Input | Source |
|-------------|--------|
| `design` | Design output or ticket AC |
| `acceptance_criteria` | Ticket > AC |
| `codebase` | Target repo and module |

**Call Skill:** `skills/implement.md`

**Output:** Code changes committed

---

## Step 4: Test

**Context Mapping:**
| Skill Input | Source |
|-------------|--------|
| `implementation` | Commits from Step 3 |
| `acceptance_criteria` | Ticket > AC |
| `test_scope` | Unit + Integration (minimum) |

**Call Skill:** `skills/test.md`

**Output:** All tests passing

---

## Step 5: Self-Review & PR

**Context Mapping:**
| Skill Input | Source |
|-------------|--------|
| `changes` | `git diff main...HEAD` |
| `context` | Ticket description + design doc |
| `standards` | Project conventions |

**Call Skill:** `skills/review.md` (self-review mode)

**Actions:**
1. Self-review using checklist
2. Create PR with description
3. Request team review

**Output:** PR ready for review

---

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests passing
- [ ] PR approved
- [ ] Merged to main
- [ ] Ticket updated to Done

---

## Context Sources Reference

| Source | How to Access |
|--------|---------------|
| Ticket | JIRA/GitHub Issue link |
| Codebase | `git log`, `git diff`, file exploration |
| Design Docs | `docs/` or linked in ticket |
| Conventions | `.cursorrules`, `docs/convention/` |
