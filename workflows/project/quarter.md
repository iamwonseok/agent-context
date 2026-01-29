# Project Quarter Workflow

> Plan and track quarterly objectives at organization level.

## Overview

| Aspect | Value |
|--------|-------|
| **Scope** | Organization/Project |
| **Trigger** | Quarter start |
| **Output** | Quarterly OKRs achieved |
| **Duration** | 3 months |

---

## Quarter Phases

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    PLAN     │ -> │   EXECUTE   │ -> │   REVIEW    │
│  (Week 1)   │    │ (Weeks 2-12)│    │ (Week 13)   │
└─────────────┘    └─────────────┘    └─────────────┘
```

---

## Phase 1: Quarter Planning

### Context Mapping
| Skill Input | Source |
|-------------|--------|
| `context` | Company strategy + last quarter results |
| `artifacts` | Roadmap, OKR history, resource plan |
| `goal` | Define achievable quarterly objectives |

**Call Skill:** `skills/analyze.md`

### Planning Activities

1. **Strategy Alignment**
   | Company Goal | Our Contribution |
   |--------------|------------------|
   | {goal} | {how we contribute} |

2. **Objectives & Key Results**
   
   **Objective 1:** {What we want to achieve}
   | Key Result | Target | Baseline |
   |------------|--------|----------|
   | KR1.1 | {target} | {current} |
   | KR1.2 | {target} | {current} |
   
   **Objective 2:** {What we want to achieve}
   | Key Result | Target | Baseline |
   |------------|--------|----------|
   | KR2.1 | {target} | {current} |

3. **Resource Allocation**
   | Team | Headcount | Focus |
   |------|-----------|-------|
   | {team} | {count} | {objective} |

4. **Key Milestones**
   | Milestone | Target Date | Owner |
   |-----------|-------------|-------|
   | {milestone} | {date} | {team/person} |

---

## Phase 2: Quarter Execution

### Monthly Cadence

**Monthly Check-in:**
| OKR | Progress | Status | Action Needed |
|-----|----------|--------|---------------|
| O1/KR1 | {%} | {On Track/At Risk/Off Track} | {action} |
| O1/KR2 | {%} | {status} | {action} |

### Team Coordination
Each team follows team workflows:
- Sprint work: `workflows/team/sprint.md`
- Releases: `workflows/team/release.md`

### Mid-Quarter Review (Week 6-7)

**Context Mapping:**
| Skill Input | Source |
|-------------|--------|
| `context` | OKR progress + blockers |
| `artifacts` | Sprint metrics, release logs |
| `goal` | Course correction if needed |

**Call Skill:** `skills/analyze.md`

**Review Questions:**
- [ ] Are we on track for each KR?
- [ ] What's blocking progress?
- [ ] Do we need to adjust scope?

---

## Phase 3: Quarter Review

### OKR Scoring

**Scoring Guide:**
| Score | Meaning |
|-------|---------|
| 1.0 | Fully achieved |
| 0.7 | Substantially achieved |
| 0.5 | Partially achieved |
| 0.3 | Some progress |
| 0.0 | Not achieved |

**Final Scores:**
| OKR | Score | Notes |
|-----|-------|-------|
| O1/KR1 | {score} | {notes} |
| O1/KR2 | {score} | {notes} |
| **O1 Average** | {avg} | |

### Retrospective

**Context Mapping:**
| Skill Input | Source |
|-------------|--------|
| `changes` | All deliverables this quarter |
| `context` | OKR targets vs actuals |
| `standards` | Organization goals |

**Call Skill:** `skills/review.md`

**What Worked:**
- {success_1}
- {success_2}

**What Didn't:**
- {failure_1}
- {failure_2}

**Learnings for Next Quarter:**
- {learning_1}
- {learning_2}

---

## Completion Criteria

- [ ] All OKRs scored
- [ ] Retrospective completed
- [ ] Learnings documented
- [ ] Next quarter planning inputs ready
- [ ] Stakeholder report delivered

---

## Quarter Artifacts

| Artifact | Location | Owner |
|----------|----------|-------|
| OKR Document | Confluence/Notion | Product Lead |
| Progress Dashboard | JIRA/Analytics | Tech Lead |
| Quarter Report | Email/Slides | Project Lead |
| Retro Notes | Wiki | Project Lead |
