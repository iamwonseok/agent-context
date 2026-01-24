---
name: allocate-resources
category: plan
description: Allocate team resources to tasks and projects
version: 1.0.0
role: manager
inputs:
  - Task list with estimates
  - Team member availability
  - Skill requirements
outputs:
  - Resource allocation plan
  - Capacity utilization
---

# Allocate Resources

## When to Use

- Sprint planning
- Project staffing
- Workload balancing
- Capacity planning

## Prerequisites

- [ ] Task list with estimates
- [ ] Team roster and availability
- [ ] Skill matrix
- [ ] Project priorities

## Workflow

### 1. Assess Team Capacity

```markdown
### Team Capacity (Sprint: Jan 27 - Feb 7)

| Member | Role | Availability | Hours |
|--------|------|--------------|-------|
| Alice | Senior Dev | 100% | 80h |
| Bob | Junior Dev | 100% | 80h |
| Carol | Senior Dev | 50% | 40h |
| Dave | QA | 100% | 80h |

**Total Capacity**: 280 hours
**Effective (80%)**: 224 hours
```

### 2. Map Skills to Tasks

```markdown
### Skill Matrix

| Member | Backend | Frontend | DevOps | Testing |
|--------|---------|----------|--------|---------|
| Alice | 3 | 2 | 1 | 2 |
| Bob | 2 | 3 | 0 | 1 |
| Carol | 3 | 1 | 3 | 2 |
| Dave | 1 | 1 | 0 | 3 |

### Task Requirements

| Task | Required Skill | Level |
|------|----------------|-------|
| Auth Service | Backend | 3 |
| Login UI | Frontend | 2 |
| CI Pipeline | DevOps | 2 |
| E2E Tests | Testing | 3 |
```

### 3. Match Tasks to People

Consider:
- Skill match
- Availability
- Growth opportunities
- Load balancing

### 4. Create Allocation Plan

```markdown
### Resource Allocation

| Task | Estimate | Assignee | Reason |
|------|----------|----------|--------|
| Auth Service | 16h | Alice | Backend expert |
| Login UI | 12h | Bob | Frontend strength |
| CI Pipeline | 8h | Carol | DevOps experience |
| E2E Tests | 16h | Dave | QA specialist |
| Code Review | 8h | Alice, Carol | Senior review |
| Documentation | 4h | Bob | Learning opportunity |

### Load Summary

| Member | Allocated | Capacity | Utilization |
|--------|-----------|----------|-------------|
| Alice | 24h | 80h | 30% |
| Bob | 16h | 80h | 20% |
| Carol | 12h | 40h | 30% |
| Dave | 16h | 80h | 20% |

**Total**: 68h / 224h = 30%
```

### 5. Identify Gaps

Check for:
- Over-allocation (> 80%)
- Under-allocation (< 50%)
- Missing skills
- Single points of failure

### 6. Optimize Allocation

Strategies:
- **Load balancing**: Redistribute to underutilized
- **Pair programming**: Skill transfer, reduce risk
- **Parallel work**: Independent tasks simultaneously
- **Buffer**: Leave 20% for unexpected

### 7. Document Final Plan

```markdown
## Resource Allocation: Sprint 5

### Summary
- Team: 4 members
- Capacity: 224 effective hours
- Allocated: 180 hours (80%)
- Buffer: 44 hours (20%)

### Allocation Table

| Member | Tasks | Hours | Util% |
|--------|-------|-------|-------|
| Alice | Auth Service, Review | 64h | 80% |
| Bob | Login UI, Docs | 56h | 70% |
| Carol | CI Pipeline, Review | 32h | 80% |
| Dave | E2E Tests | 64h | 80% |

### Visual Timeline

```
Alice:  |████Auth████|░░Review░░|
Bob:    |████Login████|░░Docs░░░|
Carol:  |░░░░|██CI██|░░Review░░░|
Dave:   |████████E2E Tests█████|
        Jan27               Feb7
```

### Risk Mitigation
- **Alice unavailable**: Carol can cover backend
- **CI blocked**: Skip to testing, return later
- **Scope increase**: Use buffer hours first

### Agreements
- Daily standup at 9:30 AM
- Review sessions Wed/Fri
- Escalate blockers within 4 hours
```

## Outputs

| Output | Format | Description |
|--------|--------|-------------|
| Allocation plan | Table | Who does what |
| Utilization % | Numbers | Capacity usage |
| Timeline | Gantt/Visual | When things happen |
| Risk mitigation | List | Backup plans |

## Capacity Guidelines

| Utilization | Meaning |
|-------------|---------|
| < 50% | Under-utilized, can take more |
| 50-70% | Healthy, room for support |
| 70-80% | Optimal, sustainable |
| 80-90% | High, limited flexibility |
| > 90% | Over-allocated, risky |

## Examples

### Example 1: Balanced Team

```
Project: E-commerce Cart Feature

Allocation:
- Senior Dev (Alice): Core logic, review (60%)
- Mid Dev (Bob): API endpoints (70%)
- Junior Dev (Eve): Frontend components (70%)
- QA (Dave): Test planning, execution (80%)

Pairing: Eve shadows Alice on complex logic
```

### Example 2: Specialized Needs

```
Project: Database Migration

Challenge: Only Carol knows legacy DB

Allocation:
- Carol: Migration scripts (100% - critical path)
- Alice: New schema design (50%)
- Bob: Documentation (50%)

Risk: Carol is single point of failure
Mitigation: Alice shadows Carol, learns legacy system
```

## Notes

- People are not fungible resources
- Include learning/growth opportunities
- Account for meetings and overhead
- Respect work-life balance
- Communicate changes promptly
