# RFC-XXX: {Title}

## Status: Draft | Active | Completed | Deprecated
## Author: {name}
## Created: {YYYY-MM-DD}

---

## 1. Overview

{One paragraph summary of what this RFC proposes}

## 2. Motivation

### 2.1 Problem Statement

{What problem does this solve?}

### 2.2 Goals

- Goal 1
- Goal 2

### 2.3 Non-Goals

- What this RFC does NOT address

## 3. Design

### 3.1 Architecture

{High-level design}

### 3.2 Components

| Component | Description |
|-----------|-------------|
| {name} | {what it does} |

### 3.3 Interfaces

{API/Interface definitions if applicable}

## 4. Implementation Plan

### 4.1 Phase 0: Foundation

- [ ] Task 0.1
- [ ] Task 0.2

### 4.2 Phase 1: Core

- [ ] Task 1.1
- [ ] Task 1.2

### 4.3 Phase N: {name}

- [ ] Task N.1

## 5. Test Plan (REQUIRED)

### 5.1 Test Strategy

**Scope:**
- What will be tested: {components}
- What won't be tested: {out of scope}

**Levels:**

| Level | Description | Tools |
|-------|-------------|-------|
| Unit | Individual functions | {pytest/jest} |
| Integration | Component interactions | {docker-compose} |
| E2E | Full workflows | {manual/automated} |

### 5.2 Test Cases

#### Unit Tests

| ID | Component | Test Case | Input | Expected |
|----|-----------|-----------|-------|----------|
| UT-1 | {Component} | {What to test} | {Input} | {Output} |
| UT-2 | {Component} | {Edge case} | {Input} | {Error} |

#### Integration Tests

| ID | Scenario | Steps | Expected |
|----|----------|-------|----------|
| IT-1 | {Workflow} | 1. {Step} 2. {Step} | {Result} |

### 5.3 Success Criteria

**Must Have (Blocking):**
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Coverage >= {target}%
- [ ] No critical bugs

**Should Have (Non-blocking):**
- [ ] Performance benchmarks met
- [ ] All edge cases covered

### 5.4 Validation Checklist

- [ ] Test plan reviewed
- [ ] Tests implemented
- [ ] CI configured
- [ ] Tests documented
- [ ] All tests passing

## 6. Validation Strategy

### 6.1 Pre-implementation

- [ ] Design review completed
- [ ] Test plan reviewed

### 6.2 During Implementation

- [ ] TDD approach followed
- [ ] CI passing on each commit

### 6.3 Post-implementation

- [ ] Full test suite passing
- [ ] Documentation updated
- [ ] Stakeholder review

## 7. Migration / Rollout

{How to deploy/migrate, if applicable}

### 7.1 Breaking Changes

- List any breaking changes

### 7.2 Rollback Plan

- How to rollback if issues occur

## 8. Alternatives Considered

| Alternative | Pros | Cons | Why Not |
|-------------|------|------|---------|
| {Option A} | {pros} | {cons} | {reason} |

## 9. References

- [Related RFC](./XXX-title.md)
- [Architecture Doc](../architecture/xxx.md)
- [External Link](https://example.com)

## 10. Change Log

| Date | Change | Author |
|------|--------|--------|
| {YYYY-MM-DD} | Initial draft | {author} |

---

**Next Review**: {When this RFC should be reviewed}
