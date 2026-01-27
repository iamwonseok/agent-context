---
name: analyze-impact
category: validate
description: Analyze impact of proposed changes
version: 1.0.0
role: manager
mode: verification
cursor_mode: debug
inputs:
  - Proposed changes
  - Affected systems
outputs:
  - Impact assessment
  - Risk analysis
---

# Analyze Impact

## State Assertion

**Mode**: verification
**Cursor Mode**: debug
**Purpose**: Assess impact and risks of proposed changes
**Boundaries**:
- Will: Analyze dependencies, identify affected systems, assess risks
- Will NOT: Make changes, approve releases, or execute deployments

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
