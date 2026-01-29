# Test

> Verify the implementation meets requirements.

## Interface Definition

**Input (Required):**
- `implementation`: Code changes to test
- `acceptance_criteria`: Expected behaviors
- `test_scope`: Unit, integration, E2E, or manual

**Output:**
- Test results (pass/fail)
- Coverage report (if applicable)
- Bug reports (if issues found)

---

## Template

### 1. Test Scope
**Implementation:** {pr_or_commit_reference}
**Test Level:** {unit/integration/e2e/manual}

### 2. Test Cases

#### TC-001: {test_case_name}
| Attribute | Value |
|-----------|-------|
| **Precondition** | {setup_required} |
| **Input** | {test_input} |
| **Expected** | {expected_output} |
| **Actual** | {actual_result} |
| **Status** | {PASS/FAIL} |

#### TC-002: {test_case_name}
| Attribute | Value |
|-----------|-------|
| **Precondition** | {setup_required} |
| **Input** | {test_input} |
| **Expected** | {expected_output} |
| **Actual** | {actual_result} |
| **Status** | {PASS/FAIL} |

### 3. Edge Cases
- [ ] Empty input: {result}
- [ ] Invalid input: {result}
- [ ] Boundary values: {result}
- [ ] Concurrent access: {result}

### 4. Test Results Summary
| Category | Total | Pass | Fail | Skip |
|----------|-------|------|------|------|
| Unit | {n} | {n} | {n} | {n} |
| Integration | {n} | {n} | {n} | {n} |
| E2E | {n} | {n} | {n} | {n} |

### 5. Coverage
- Line coverage: {percent}%
- Branch coverage: {percent}%
- Critical paths: {covered/not_covered}

### 6. Issues Found
| ID | Severity | Description | Status |
|----|----------|-------------|--------|
| {bug_id} | {critical/major/minor} | {description} | {open/fixed} |

---

## Checklist

- [ ] All acceptance criteria have test cases
- [ ] Happy path tested
- [ ] Error cases tested
- [ ] Edge cases tested
- [ ] No flaky tests
- [ ] Tests are repeatable
- [ ] Coverage meets project target
- [ ] All critical paths covered
