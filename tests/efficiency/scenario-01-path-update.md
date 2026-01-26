# Scenario 01: Path Update

## Context

When path references change across multiple files (e.g., `plan/` → `planning/`).

## Trigger

- Directory rename
- Structure reorganization
- Path standardization

## Inefficient Approach

```
1. Read file1
2. Find old path
3. Replace old path
4. Read file2
5. Find old path
6. Replace old path
... (repeat for each file)
```

**Problems:**
- Too many tool calls (N reads + N writes)
- No batching
- Repeated patterns not grouped

## Efficient Approach

```bash
# 1. Find ALL affected files at once (1 tool call)
grep -r "old-path/" workflows/ skills/ tests/

# 2. Show context for ALL files (1 tool call)
grep -n "old-path/" <files>

# 3. Replace in batch (grouped by similarity)
# - All workflows together
# - All skills together
# - All tests together

# 4. Verify once (1 tool call)
bash tests/unit/run-all-unit-tests.sh
```

## Test Plan

### Setup

Create test directory with sample files containing old paths.

### Execution

1. Run efficient approach
2. Count tool calls
3. Measure time

### Success Criteria

| Metric | Target | Red Flag |
|--------|--------|----------|
| Tool calls | < 15 | > 30 |
| grep operations | 1-2 | > 5 |
| Test runs | 1 | > 3 |

## Example

**Before:**
```
workflows/developer/feature.md: plan/design.md
workflows/developer/bug-fix.md: plan/fix.md
skills/planning/README.md: plan/template
```

**Command:**
```bash
grep -r "plan/" workflows/ skills/ | grep -v "planning/"
```

**After:**
```
All paths updated: plan/ → planning/
Tests: PASS
```

## Validation

```bash
# Verify no old paths remain
grep -r "plan/" workflows/ skills/ | grep -v "planning/"
# Expected: no output

# Run tests
bash tests/unit/run-all-unit-tests.sh
# Expected: All pass
```
