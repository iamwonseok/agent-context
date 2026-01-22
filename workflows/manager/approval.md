---
name: approval
description: MR review and approval workflow
role: manager
skills:
  - analyze/parse-requirement
  - validate/review-code
  - validate/analyze-impact
  - integrate/notify-stakeholders
---

# MR Approval

## When to Use

- MR ready for review
- Code quality verification
- Release gate

## Command Flow

### Step 1: List Pending MRs

```bash
agent mgr pending
```

- Show MRs awaiting review
- Display CI status
- Show age/priority

### Step 2: Review MR

```bash
agent mgr review MR-456
```

- Check CI status
- Analyze changes
- Show metrics (coverage, complexity)
- Auto-review findings

**Skills**: `validate/review-code`, `validate/analyze-impact`

### Step 3: Decision

#### Approve

```bash
agent mgr approve MR-456
```

- GitLab/GitHub approval
- Update JIRA status
- Notify author

#### Request Changes

```bash
agent mgr review MR-456 --comment "Please fix complexity issue"
```

- Add review comments
- Notify author
- Track follow-up

**Skills**: `integrate/notify-stakeholders`

### Step 4: Post-Approval

```bash
agent mgr merge MR-456  # If auto-merge not enabled
```

## Outputs

| Output | Description |
|--------|-------------|
| Review | Approval or feedback |
| Comments | Review notes |
| Notification | Author notified |

## Review Checklist

- [ ] CI passes
- [ ] Tests adequate
- [ ] No security issues
- [ ] Documentation updated
- [ ] Follows conventions

## Example

```bash
# Check pending
agent mgr pending
# Output: MR-456 (TASK-123), MR-457 (BUG-789)

# Review
agent mgr review MR-456
# Output: 
#   CI: PASSED
#   Coverage: 85%
#   Changes: +150 -30
#   Findings: 0 critical, 2 minor

# Approve
agent mgr approve MR-456
# Output: MR-456 approved, author notified
```

## Notes

- Review within 24 hours
- Be constructive in feedback
- Approve if minor issues only
- Block only for critical issues
