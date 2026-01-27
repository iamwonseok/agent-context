---
name: design-test-plan
category: plan
description: Design comprehensive test plan for implementation
version: 1.0.0
role: developer
mode: planning
cursor_mode: plan
inputs:
  - design/{feature}.md
  - plan/{feature}-plan.md
outputs:
  - tests/plan/{feature}-test-plan.md
---

# Design Test Plan

## State Assertion

**Mode**: planning
**Cursor Mode**: plan
**Purpose**: Create comprehensive test plan before implementation
**Boundaries**:
- Will: Identify test levels, list test cases, define coverage targets, document plan
- Will NOT: Write test code, execute tests, or modify production code

## When to Use

- After design-solution complete
- Before implementation starts
- Complex features requiring multiple test levels
- When test strategy is unclear
- For RFC implementations requiring validation

## Prerequisites

- [ ] Design document exists (design/{feature}.md)
- [ ] Implementation plan exists (plan/{feature}-plan.md)
- [ ] Test infrastructure available (test runner, CI)

## Workflow

### 1. Identify Test Levels

Determine which levels apply:

| Level | When Needed | Example |
|-------|-------------|---------|
| Unit | Always | Function behavior |
| Integration | Multiple components | API + DB |
| E2E | User-facing | Full workflow |
| Performance | Scale concerns | Load testing |

### 2. List Test Cases per Component

For each component in the design:

```markdown
### Component: {name}

#### Unit Tests
| ID | Input | Expected Output | Edge Case? |
|----|-------|-----------------|------------|
| UT-1 | Valid input | Success | No |
| UT-2 | Empty input | Error message | Yes |

#### Integration Tests
| ID | Scenario | Steps | Expected |
|----|----------|-------|----------|
| IT-1 | Full flow | 1. A 2. B 3. C | Success |
```

### 3. Define Coverage Targets

Set measurable targets:

| Metric | Target | Rationale |
|--------|--------|-----------|
| Line coverage | >= 80% | Standard minimum |
| Branch coverage | >= 70% | Critical paths |
| Critical paths | 100% | No exceptions |

### 4. Specify Test Tools

Document tools and configuration:

```yaml
test_tools:
  unit: pytest / jest / go test
  integration: docker-compose + test runner
  e2e: cypress / playwright (if applicable)
  coverage: coverage.py / istanbul
```

### 5. Create Test Plan Document

Use the template:

```bash
# Copy template
cp skills/planning/design-test-plan/templates/test-plan.md \
   tests/plan/{feature}-test-plan.md

# Fill in sections
# 1. Test Strategy
# 2. Test Cases
# 3. Success Criteria
# 4. CI Integration
```

### 6. Review Test Plan

Before implementation:

- [ ] All components have test cases
- [ ] Edge cases identified
- [ ] Coverage targets realistic
- [ ] CI integration defined

## Outputs

| Output | Format | Description |
|--------|--------|-------------|
| `tests/plan/{feature}-test-plan.md` | Markdown | Comprehensive test plan |

See `templates/test-plan.md` for full template.

## Examples

### Example 1: API Feature

```markdown
# Test Plan: User Authentication API

## Test Strategy
- Unit: Auth logic, token validation
- Integration: API + Database + Cache
- E2E: Login flow

## Test Cases

### Unit Tests
| ID | Component | Test | Expected |
|----|-----------|------|----------|
| UT-1 | AuthService | Valid credentials | Token returned |
| UT-2 | AuthService | Invalid password | Error 401 |
| UT-3 | TokenValidator | Expired token | Error 401 |

### Integration Tests
| ID | Scenario | Expected |
|----|----------|----------|
| IT-1 | Login -> Access protected | Success |
| IT-2 | Invalid token -> Reject | 401 error |

## Success Criteria
- [ ] All unit tests pass
- [ ] Line coverage >= 85%
- [ ] Integration tests pass
- [ ] No security vulnerabilities
```

### Example 2: CLI Tool

```markdown
# Test Plan: agent dev sync

## Test Strategy
- Unit: Argument parsing, git operations
- Integration: Full command execution

## Test Cases
| ID | Input | Expected |
|----|-------|----------|
| UT-1 | --help | Show usage |
| UT-2 | No args | Default behavior |
| IT-1 | Dirty repo | Warning + abort |
| IT-2 | Clean repo | Sync success |

## Success Criteria
- [ ] All commands work as documented
- [ ] Error messages are clear
- [ ] Exit codes correct (0=success, 1=error)
```

## Notes

- Skip for trivial changes (< 50 lines)
- Prioritize critical path tests
- Include both happy path and edge cases
- Test plan should be reviewable before coding
- Update test plan if design changes

## Related Skills

- `planning/design-solution`: Creates implementation plan
- `validate/run-tests`: Executes the test plan
- `validate/review-code`: Reviews test quality
