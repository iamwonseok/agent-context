---
name: allocate-resources
category: plan
description: Allocate team resources to tasks and projects
version: 1.0.0
role: manager
mode: planning
cursor_mode: plan
inputs:
  - Task list with estimates
  - Team member availability
  - Skill requirements
outputs:
  - Resource allocation plan
  - Capacity utilization
---

# Allocate Resources

## State Assertion

**Mode**: planning
**Cursor Mode**: plan
**Purpose**: Plan resource allocation without executing assignments
**Boundaries**:
- Will: Analyze capacity, match skills to tasks, create allocation plan
- Will NOT: Assign tasks in issue tracker, modify team settings, or send notifications

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

Final plan should include: Summary, Allocation Table, Risk Mitigation, Agreements.

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

| Scenario | Strategy |
|----------|----------|
| Balanced Team | Distribute by skill level (60-80% utilization) |
| Specialized Needs | Cover single points of failure with shadowing |

## Notes

- People are not fungible resources
- Include learning/growth opportunities
- Account for meetings and overhead
- Respect work-life balance
- Communicate changes promptly
