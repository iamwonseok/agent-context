# Team Sprint Workflow

> Coordinate team work across a sprint cycle.

## Overview

| Aspect | Value |
|--------|-------|
| **Scope** | Team/Squad |
| **Trigger** | Sprint start |
| **Output** | Sprint goal achieved |
| **Duration** | 1-2 weeks |

---

## Sprint Phases

```
PLAN (Day 1) -> EXECUTE (Days 2-N) -> REVIEW (Last Day)
```

---

## Phase 1: Sprint Planning

### Context Mapping
| Skill Input | Source |
|-------------|--------|
| `context` | Product backlog + team capacity |
| `artifacts` | Previous sprint retro, velocity data |
| `goal` | Define achievable sprint goal |

**Call Skill:** `skills/analyze.md`

### Planning Activities

1. **Review Backlog**
   - Prioritized items from Product Owner
   - Dependencies identified
   - Blockers surfaced

2. **Capacity Check**
   | Team Member | Availability | Focus Area |
   |-------------|--------------|------------|
   | {name} | {days} | {area} |

3. **Sprint Goal**
   > {One sentence describing what success looks like}

4. **Commitment**
   | Ticket | Assignee | Estimate | Priority |
   |--------|----------|----------|----------|
   | {id} | {name} | {points/hours} | {P1/P2/P3} |

---

## Phase 2: Sprint Execution

### Daily Coordination

**Async Standup Template:**
```
Yesterday: {what was done}
Today: {what will be done}
Blockers: {any blockers}
```

### Individual Work
Each team member follows solo workflows:
- New features: `workflows/solo/feature.md`
- Bug fixes: `workflows/solo/bugfix.md`
- Hotfixes: `workflows/solo/hotfix.md`

### Mid-Sprint Check (Day N/2)
- [ ] Sprint goal still achievable?
- [ ] Any scope adjustment needed?
- [ ] Blockers escalated?

---

## Phase 3: Sprint Review & Retro

### Sprint Review

**Context Mapping:**
| Skill Input | Source |
|-------------|--------|
| `changes` | All merged PRs this sprint |
| `context` | Sprint goal + committed items |
| `standards` | Definition of Done |

**Call Skill:** `skills/review.md`

**Review Checklist:**
- [ ] Demo completed items
- [ ] Stakeholder feedback captured
- [ ] Incomplete items documented with reason

### Sprint Metrics
| Metric | Target | Actual |
|--------|--------|--------|
| Velocity | {expected} | {actual} |
| Completion Rate | 80%+ | {actual}% |
| Bug Escape Rate | <10% | {actual}% |

### Retrospective

**Format: Start/Stop/Continue**

| Start Doing | Stop Doing | Continue Doing |
|-------------|------------|----------------|
| {suggestion} | {pain point} | {working well} |

**Action Items:**
| Action | Owner | Due |
|--------|-------|-----|
| {action} | {name} | {date} |

---

## Completion Criteria

- [ ] Sprint goal achieved (or documented why not)
- [ ] All committed items: Done or explicitly carried over
- [ ] Sprint review completed
- [ ] Retrospective completed
- [ ] Action items assigned

---

## Sprint Artifacts

| Artifact | Location | Owner |
|----------|----------|-------|
| Sprint Board | JIRA/GitHub Project | Scrum Master |
| Sprint Goal | Board description | Product Owner |
| Retro Notes | Confluence/Wiki | Scrum Master |
| Velocity Chart | JIRA/Analytics | Team |
