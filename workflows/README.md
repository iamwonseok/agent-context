# Workflows

> **"Workflow는 친절할수록(Context-Aware) 좋다"**

Workflows are **thick orchestrators** that inject context into skills based on the current situation.
Concepts and philosophy are maintained in [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md).

## Global Defaults

> All workflows inherit these minimum policies. Override per-project if needed.

### Branch Naming

| Type | Rule |
|------|------|
| General | Free (no enforcement) |
| Release | `release/<anything>/v<MAJOR>.<MINOR>.<PATCH>` (last segment only matters) |

**Release branch detection regex:** `^release\/.+\/v[0-9]+\.[0-9]+\.[0-9]+$`

### MR/PR Policy

| Item | Rule |
|------|------|
| Title | Jira key required (e.g., `[SPF-1290] ...` or `SPF-1290 ...`) |
| Evidence | Optional (pipeline results visible in MR UI) |

### Jira-GitLab Integration

- **Direction**: GitLab -> Jira (via Jira key in branch/commit/MR title)
- **Limitation**: Jira -> GitLab attach/create may be restricted depending on setup
- **Recommendation**: Always include Jira key in MR title for automatic linking

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
