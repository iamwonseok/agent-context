# Scenario 04: Test Update After Structure Change

## Context

Updating test scripts after skills/workflows/tools structure changes.

## Trigger

- New skill added
- Directory reorganization
- Path changes

## Inefficient Approach

```
1. Read test_skills.sh
2. Find SKILL_PATHS variable
3. Add new skill
4. Read test_workflows.sh
5. Find workflow paths
6. Update paths
7. Run test
8. Fix failure
9. Run test again
...
```

**Problems:**
- Incremental test runs
- Sequential file updates
- Multiple verification cycles

## Efficient Approach

```bash
# 1. Identify ALL test files to update
grep -l "SKILL_PATHS\|skill_path\|workflow" tests/unit/skills/*.sh

# 2. Update ALL test scripts in batch
# - Update SKILL_PATHS in test_skills.sh
# - Update workflow checks
# - Update integration tests

# 3. Run ALL tests once
bash tests/unit/run-all-unit-tests.sh

# 4. Fix failures in batch (if any)
# Then run tests once more
```

## Test Plan

### Setup

Add new skill directory.

### Execution

1. Batch update test files
2. Single test run
3. Batch fix if needed

### Success Criteria

| Metric | Target | Red Flag |
|--------|--------|----------|
| Test runs | 1-2 | > 3 |
| File updates | Batch | One-by-one |
| Fix cycles | 0-1 | > 2 |

## Example

**Adding design-test-plan skill:**

```bash
# 1. Create skill directory
mkdir -p skills/planning/design-test-plan/templates

# 2. Identify test files (1 call)
grep -l "SKILL_PATHS" tests/unit/skills/*.sh
# Output: tests/unit/skills/test_skills.sh

# 3. Update test file
# Add: planning/design-test-plan to SKILL_PATHS

# 4. Run all tests (1 call)
bash tests/unit/run-all-unit-tests.sh
# Expected: PASS

# 5. Verify skill count
ls skills/*/SKILL.md | wc -l
# Expected: 27 (was 26)
```

## Validation

```bash
# Verify tests pass
bash tests/unit/run-all-unit-tests.sh
# Expected: All pass

# Verify new skill tested
bash tests/unit/skills/test_skills.sh | grep "design-test-plan"
# Expected: "(v) SKILL.md exists"
```
