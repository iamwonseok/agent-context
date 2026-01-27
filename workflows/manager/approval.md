---
name: approval
description: MR review and approval workflow
role: manager
cursor_mode: ask
mode_transitions:
  - ask     # analyze/parse-requirement
  - debug   # validate/review-code, analyze-impact
  - agent   # integrate/notify-stakeholders
skills:
  - analyze/parse-requirement
  - validate/review-code
  - validate/analyze-impact
  - integrate/notify-stakeholders
---

# MR Approval

## Status

Implemented | CLI 85% | Manual: GitLab/GitHub UI or `glab`/`gh` CLI

## When to Use

- MR ready for review
- Code quality verification
- Release gate

## Flow

1. `agent mgr pending` - List pending MRs with CI status
2. `agent mgr review MR-456` - Check CI, analyze changes, show metrics
3. Decision:
   - Approve: `agent mgr approve MR-456`
   - Request changes: `agent mgr review MR-456 --comment "..."`
4. `agent mgr merge MR-456` - If auto-merge not enabled

## Review Checklist

- [ ] CI passes
- [ ] Tests adequate
- [ ] No security issues
- [ ] Documentation updated
- [ ] Follows conventions

## Outputs

| Output | Description |
|--------|-------------|
| Review | Approval or feedback |
| Comments | Review notes |
| Notification | Author notified |

## Example

```bash
agent mgr pending           # MR-456 (TASK-123)
agent mgr review MR-456     # CI: PASSED, Coverage: 85%
agent mgr approve MR-456    # MR-456 approved
```

## Notes

- Review within 24 hours
- Be constructive in feedback
- Approve if minor issues only
- Block only for critical issues
