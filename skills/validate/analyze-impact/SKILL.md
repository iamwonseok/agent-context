---
name: analyze-impact
category: validate
description: Analyze impact of proposed changes
version: 1.0.0
role: manager
inputs:
  - Proposed changes
  - Affected systems
outputs:
  - Impact assessment
  - Risk analysis
---

# Analyze Impact

## When to Use

- Before major changes
- Release planning
- Risk assessment
- Change approval

## Prerequisites

- [ ] Change proposal
- [ ] System knowledge
- [ ] Stakeholder list

## Workflow

### 1. Identify Scope

What systems/components affected?

### 2. Assess Risk

| Risk Level | Impact | Probability |
|------------|--------|-------------|
| High | Major outage | Likely |
| Medium | Degraded service | Possible |
| Low | Minor issue | Unlikely |

### 3. Identify Stakeholders

Who needs to know?
- Users
- Dependent teams
- Operations

### 4. Document Impact

```markdown
## Impact Analysis

### Affected Systems
- User service
- Auth service

### Risk Level: Medium

### Stakeholders
- Frontend team
- Mobile team

### Mitigation
- Feature flag for rollback
- Monitor metrics closely
```

## Outputs

| Output | Format |
|--------|--------|
| Impact assessment | Document |
| Risk level | High/Med/Low |
| Stakeholder list | List |

## Notes

- Consider downstream effects
- Plan rollback strategy
- Communicate early
