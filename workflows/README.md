# Workflows

> **"Workflow는 친절할수록(Context-Aware) 좋다"**

Workflows are **thick orchestrators** that inject context into skills based on the current situation.

## Philosophy

| Concept | Role | Developer Analogy |
|---------|------|-------------------|
| **Skill** | Interface definition, Template | Function signature, Abstract class |
| **Workflow** | Context injection, Mapping | DI Container, Implementation |

### Design Principles

1. **Context-aware**: Knows about tickets, tools, project specifics
2. **Skill orchestration**: Calls skills with mapped inputs
3. **Situation-specific**: Different workflows for different scenarios
4. **Focused on WHAT**: What information goes where

---

## Engineering Coordinate System

```
Y-Axis (Layer)          X-Axis (Timeline)
─────────────────────────────────────────────
PROJECT (Org)           PLAN → EXECUTE → REVIEW
    ↑
TEAM (Squad)            PLAN → EXECUTE → REVIEW
    ↑
SOLO (Dev)              PLAN → EXECUTE → REVIEW
```

---

## Available Workflows

### Solo (Individual Developer)

| Workflow | Trigger | Duration |
|----------|---------|----------|
| [solo/feature.md](solo/feature.md) | Feature ticket assigned | Hours to days |
| [solo/bugfix.md](solo/bugfix.md) | Bug ticket assigned | Hours |
| [solo/hotfix.md](solo/hotfix.md) | Production incident | Minutes to hours |

### Team (Squad Level)

| Workflow | Trigger | Duration |
|----------|---------|----------|
| [team/sprint.md](team/sprint.md) | Sprint start | 1-2 weeks |
| [team/release.md](team/release.md) | Release scheduled | Hours to 1 day |

### Project (Organization Level)

| Workflow | Trigger | Duration |
|----------|---------|----------|
| [project/quarter.md](project/quarter.md) | Quarter start | 3 months |
| [project/roadmap.md](project/roadmap.md) | Annual planning | Ongoing |

---

## Context Injection Flow

```
Context (Jira, Logs, Code)
       │
       │ Read
       ▼
Workflow (Orchestrator)
  - Context Mapping: Skill Input ← Source
  - Tool Rules: Git branch, commit format
       │
       │ Inject Input
       ▼
Skill (Template)
  - Input: problem, scope, constraints
  - Output: Artifact
       │
       │ Generate
       ▼
Output (PR, Doc, Report)
```

---

## How Workflows Use Skills

### Example: Feature Development

```markdown
## Step 2: Design Solution

**Context Mapping:**
| Skill Input | Source |
|-------------|--------|
| `problem` | Jira Ticket > Description |
| `scope` | Jira Ticket > Acceptance Criteria |
| `constraints` | Sprint deadline, tech stack |

**Call Skill:** `skills/design.md`
```

### Same Skill, Different Workflows

| Workflow | How `design.md` is called |
|----------|---------------------------|
| **feature.md** | Full design with alternatives |
| **bugfix.md** | Minimal (skip if simple fix) |
| **hotfix.md** | Skip entirely |

---

## Layer Interactions

```
PROJECT (quarter.md, roadmap.md)
    │
    │ Defines OKRs, Initiatives
    ▼
TEAM (sprint.md, release.md)
    │
    │ Breaks into Tickets, Coordinates
    ▼
SOLO (feature.md, bugfix.md, hotfix.md)
    │
    │ Implements, Tests, Reviews
    ▼
Merged Code + Artifacts
```

---

## Choosing the Right Workflow

| Situation | Workflow |
|-----------|----------|
| New feature from ticket | `solo/feature.md` |
| Bug report to fix | `solo/bugfix.md` |
| Production is down | `solo/hotfix.md` |
| Starting a sprint | `team/sprint.md` |
| Deploying to production | `team/release.md` |
| Planning the quarter | `project/quarter.md` |
| Long-term planning | `project/roadmap.md` |

---

## Creating New Workflows

새 workflow 생성 시 기존 파일(`solo/feature.md`, `team/sprint.md` 등) 참고.
