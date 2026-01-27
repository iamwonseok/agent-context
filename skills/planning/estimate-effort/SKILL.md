---
name: estimate-effort
category: plan
description: Estimate effort for tasks and features
version: 1.0.0
role: developer
mode: planning
cursor_mode: plan
inputs:
  - Task description
  - Historical data (optional)
outputs:
  - Effort estimate
  - Confidence level
  - Assumptions
---

# Estimate Effort

## State Assertion

**Mode**: planning
**Cursor Mode**: plan
**Purpose**: Provide effort estimates with confidence levels
**Boundaries**:
- Will: Analyze complexity, compare to historical data, document assumptions
- Will NOT: Commit to deadlines, update issue trackers, or schedule resources

## When to Use

- Sprint planning
- Project estimation
- Resource allocation
- Deadline negotiation

## Prerequisites

- [ ] Clear task description
- [ ] Understanding of scope
- [ ] Knowledge of technology

## Workflow

### 1. Understand the Task

Before estimating, clarify:
- What exactly needs to be done?
- What's in scope? Out of scope?
- What are the acceptance criteria?
- Are there unknowns?

### 2. Choose Estimation Method

| Method | Best For |
|--------|----------|
| T-Shirt Sizing | Quick relative sizing |
| Story Points | Agile teams, velocity tracking |
| Time-based | Fixed deadlines, contracts |
| Three-point | Uncertainty handling |

### 3. T-Shirt Sizing

| Size | Typical Duration | Complexity |
|------|------------------|------------|
| XS | < 2 hours | Trivial, known solution |
| S | 2-4 hours | Simple, clear scope |
| M | 4-8 hours | Moderate, some unknowns |
| L | 1-2 days | Complex, requires research |
| XL | 3-5 days | Very complex, high risk |
| XXL | > 1 week | Needs breakdown |

### 4. Three-Point Estimation

```
Estimate = (Optimistic + 4×Likely + Pessimistic) / 6
```

Example:
- Optimistic: 2 hours (everything goes right)
- Likely: 4 hours (normal conditions)
- Pessimistic: 10 hours (problems occur)
- **Estimate: (2 + 16 + 10) / 6 = 4.7 hours**

### 5. Consider Factors

| Factor | Multiplier |
|--------|------------|
| New technology | 1.5x |
| Legacy code | 1.3x |
| External dependency | 1.2x |
| First time doing | 2x |
| Unclear requirements | 1.5x |
| Testing included | 1.3x |
| Documentation | 1.1x |

### 6. Apply Confidence Level

| Confidence | Variance | When |
|------------|----------|------|
| High (90%) | ±20% | Done similar before |
| Medium (70%) | ±50% | Understood, some unknowns |
| Low (50%) | ±100% | New territory |

### 7. Document Estimate

```markdown
## Effort Estimate: {task-id}

### Task
Add user profile image upload

### Estimate
- **Size**: M (Medium)
- **Duration**: 6 hours
- **Confidence**: Medium (70%)

### Breakdown
| Component | Estimate |
|-----------|----------|
| API endpoint | 2h |
| Storage service | 2h |
| Image processing | 1h |
| Tests | 1h |
| **Total** | **6h** |

### Assumptions
- Using existing S3 bucket
- Max file size 5MB
- JPEG/PNG only
- No cropping required

### Risks
- Image processing library may need research (+2h)
- S3 permissions may need IT help (+delay)

### Confidence Justification
Done similar upload feature 6 months ago,
but image processing is new.
```

## Outputs

| Output | Format | Description |
|--------|--------|-------------|
| Estimate | Hours/Days/Points | Primary estimate |
| Confidence | High/Med/Low | Certainty level |
| Range | Min-Max | Possible variance |
| Assumptions | List | What estimate assumes |
| Risks | List | What could change estimate |

## Common Mistakes

| Mistake | Solution |
|---------|----------|
| Forgetting testing | Always include test time |
| Ignoring meetings | Add 20% overhead |
| Optimism bias | Use pessimistic anchor |
| Single number | Always give range |
| No assumptions | Document everything |

## Examples

| Task | Size | Confidence | Notes |
|------|------|------------|-------|
| Simple bug fix | S (2-4h) | High | Reproduce, fix, test |
| New 2FA feature | L (8-16h) | Medium | Research, implement, test |

## Notes

- Estimate relative to known tasks
- Track actuals to improve future estimates
- Re-estimate when scope changes
- Communicate uncertainty clearly
- It's okay to say "I don't know yet"
