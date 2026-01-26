# Test Plan: {Feature Name}

## Overview

**Feature**: {Brief description}  
**Design Doc**: `design/{feature}.md`  
**Plan Doc**: `plan/{feature}-plan.md`  
**Date**: {YYYY-MM-DD}

---

## 1. Test Strategy

### 1.1 Scope

**In Scope:**
- {Component 1}
- {Component 2}

**Out of Scope:**
- {What won't be tested and why}

### 1.2 Test Levels

| Level | Description | Tools |
|-------|-------------|-------|
| Unit | Individual functions/methods | {pytest/jest/go test} |
| Integration | Component interactions | {docker-compose} |
| E2E | Full user workflows | {cypress/manual} |
| Performance | Load/stress testing | {k6/locust} |

### 1.3 Coverage Targets

| Metric | Target | Notes |
|--------|--------|-------|
| Line coverage | >= 80% | Required |
| Branch coverage | >= 70% | Recommended |
| Critical paths | 100% | Must cover |

---

## 2. Test Cases

### 2.1 Unit Tests

| ID | Component | Test Case | Input | Expected Output |
|----|-----------|-----------|-------|-----------------|
| UT-1 | {Component} | {What to test} | {Input} | {Output} |
| UT-2 | {Component} | {Edge case} | {Input} | {Error/Output} |

### 2.2 Integration Tests

| ID | Scenario | Steps | Expected Result |
|----|----------|-------|-----------------|
| IT-1 | {Workflow name} | 1. {Step 1} 2. {Step 2} | {Success criteria} |

### 2.3 Edge Cases

| ID | Condition | Expected Behavior |
|----|-----------|-------------------|
| EC-1 | {Edge condition} | {How system handles it} |

---

## 3. Success Criteria

### 3.1 Must Have (Blocking)

- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Coverage targets met
- [ ] No critical bugs
- [ ] CI pipeline green

### 3.2 Should Have (Non-blocking)

- [ ] Performance benchmarks met
- [ ] All edge cases covered
- [ ] Documentation updated

---

## 4. CI Integration

### 4.1 Pipeline Configuration

```yaml
test:
  script:
    - {test command}
  coverage: '/coverage: (\d+\.\d+)%/'
```

### 4.2 Artifacts

- Test results: `tests/results/{feature}/`
- Coverage report: `coverage/`

---

## 5. Validation Checklist

Before implementation:
- [ ] Test plan reviewed
- [ ] Test cases complete
- [ ] Tools configured

After implementation:
- [ ] All tests implemented
- [ ] All tests passing
- [ ] Coverage verified
- [ ] CI configured

---

## 6. Change Log

| Date | Change | Author |
|------|--------|--------|
| {date} | Initial draft | {author} |
