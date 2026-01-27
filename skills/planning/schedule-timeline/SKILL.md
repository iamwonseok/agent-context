---
name: schedule-timeline
category: plan
description: Create project timeline and schedule
version: 1.0.0
role: manager
mode: planning
cursor_mode: plan
inputs:
  - Task list with estimates
  - Resource availability
  - Deadlines/milestones
outputs:
  - Project timeline
  - Milestone dates
  - Resource allocation
---

# Schedule Timeline

## State Assertion

**Mode**: planning
**Cursor Mode**: plan
**Purpose**: Create project timeline and milestone schedule
**Boundaries**:
- Will: Sequence tasks, identify dependencies, calculate dates, document timeline
- Will NOT: Create calendar events, assign issues, or notify stakeholders

## When to Use

- Project kickoff
- Sprint planning
- Release planning
- Stakeholder commitments

## Prerequisites

- [ ] Task breakdown complete
- [ ] Effort estimates available
- [ ] Team capacity known
- [ ] Dependencies identified

## Workflow

### 1. Gather Inputs

```markdown
### Tasks
| Task | Estimate | Depends On |
|------|----------|------------|
| A | 2 days | - |
| B | 3 days | - |
| C | 2 days | A |
| D | 1 day | B, C |

### Resources
- Developer 1: 100% available
- Developer 2: 50% available (other project)

### Constraints
- Start date: 2026-01-27
- Deadline: 2026-02-14
- No work on weekends
```

### 2. Calculate Critical Path

Longest path through dependencies:

```
A (2d) ──→ C (2d) ──→ D (1d) = 5 days
B (3d) ────────────→ D (1d) = 4 days

Critical path: A → C → D (5 days)
```

### 3. Build Schedule

```
Week 1 (Jan 27 - Jan 31)
├── Mon-Tue: Task A (Dev1)
├── Mon-Wed: Task B (Dev2, 50%)
├── Wed-Thu: Task C (Dev1)
└── Fri: Task D (Dev1)

Week 2 (Feb 3 - Feb 7)
├── Mon-Tue: Buffer/Testing
└── Wed: Release
```

### 4. Add Milestones

| Milestone | Date | Criteria |
|-----------|------|----------|
| M1: Development Complete | Feb 3 | All features coded |
| M2: Testing Complete | Feb 5 | All tests pass |
| M3: Release | Feb 7 | Deployed to production |

### 5. Account for Risks

Add buffer time:
- **Low risk**: +10%
- **Medium risk**: +20%
- **High risk**: +30%

### 6. Create Timeline Document

```markdown
## Project Timeline: {project-name}

### Summary
- Start: 2026-01-27
- End: 2026-02-07
- Duration: 10 working days
- Buffer: 2 days (20%)

### Gantt Chart

```
Task A  |████░░░░░░░░░░░░░░░░|
Task B  |██████░░░░░░░░░░░░░░|
Task C  |░░░░████░░░░░░░░░░░░|
Task D  |░░░░░░░░██░░░░░░░░░░|
Buffer  |░░░░░░░░░░████░░░░░░|
Release |░░░░░░░░░░░░░░██░░░░|
        Jan27        Feb3    Feb7
```

### Detailed Schedule

| Date | Task | Assignee | Status |
|------|------|----------|--------|
| Jan 27-28 | Task A | Dev1 | Planned |
| Jan 27-29 | Task B | Dev2 | Planned |
| Jan 29-30 | Task C | Dev1 | Planned |
| Jan 31 | Task D | Dev1 | Planned |
| Feb 3-4 | Testing | Team | Planned |
| Feb 5-6 | Buffer | - | Reserved |
| Feb 7 | Release | Team | Milestone |

### Key Milestones
- [ ] Jan 31: Feature Complete
- [ ] Feb 4: QA Sign-off
- [ ] Feb 7: Production Release

### Dependencies
- Task C blocked by Task A
- Task D blocked by Tasks B and C
- Release blocked by QA approval

### Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| Dev2 pulled to other project | 2 days delay | Dev1 can cover Task B |
| QA finds critical bug | 1-3 days delay | Buffer days available |

### Assumptions
- No scope changes after Jan 27
- Dev1 available full-time
- QA team available Feb 3-4
```

## Outputs

| Output | Format | Description |
|--------|--------|-------------|
| Timeline | Gantt/Table | Visual schedule |
| Milestones | List + Dates | Key checkpoints |
| Critical path | Task sequence | Longest path |
| Resource allocation | Table | Who does what when |

## Tools

| Tool | Use Case |
|------|----------|
| Gantt Chart | Visual timeline |
| Calendar | Date-based planning |
| Kanban | Flow-based tracking |
| Spreadsheet | Quick calculations |

## Examples

| Timeline Type | Pattern |
|--------------|---------|
| 2-Week Sprint | Week 1: Dev, Week 2: Test/Release |
| Quarterly Roadmap | Monthly phases with buffer |

## Notes

- Always include buffer time
- Communicate uncertainty in dates
- Update schedule as things change
- Track actual vs planned
- Don't forget holidays/vacations
