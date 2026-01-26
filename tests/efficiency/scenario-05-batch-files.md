# Scenario 05: Batch File Operations

## Context

Modifying 5+ similar files with the same type of change.

## Trigger

- Bulk updates (headers, metadata, formatting)
- Consistent change across category
- Template updates

## Inefficient Approach

```
Read file1 → Modify → Read file2 → Modify → Read file3 → Modify
... (one by one)
```

**Problems:**
- N read operations for N files
- N write operations
- No pattern recognition

## Efficient Approach

```bash
# 1. Batch read all files (parallel reads)
# Read all 10 workflow files at once

# 2. Identify common pattern
# All need: "## Implementation Status" section

# 3. Replace all at once (grouped by pattern)
# Similar content replaced together

# 4. Single verification
bash tests/unit/skills/test_skills.sh
```

## Test Plan

### Setup

Prepare 5+ files needing similar updates.

### Execution

1. Parallel reads
2. Pattern identification
3. Batch modifications
4. Single verification

### Success Criteria

| Metric | Target | Red Flag |
|--------|--------|----------|
| Files read | Parallel | Sequential |
| Pattern types | Group by type | Per file |
| Verifications | 1 | Per file |

## Example

**Adding Implementation Status to 9 workflows:**

**Efficient Approach:**

```bash
# 1. Batch read all workflow files (parallel)
# Read: feature.md, bug-fix.md, hotfix.md, refactor.md
# Read: initiative.md, epic.md, task-assignment.md, monitoring.md, approval.md

# 2. Group by pattern:
# - Developer workflows: All need ## Implementation Status after YAML
# - Manager workflows: Same pattern

# 3. Batch add section (2 groups):
# Group 1: Developer workflows
# Group 2: Manager workflows

# 4. Verify once
bash tests/unit/skills/test_skills.sh | grep "workflow"
```

**Tool Call Count:**
- Inefficient: 9 reads + 9 writes + 9 verifications = 27
- Efficient: 2 batch reads + 2 batch writes + 1 verification = 5

## Validation

```bash
# Verify all have Implementation Status
for wf in workflows/*/*.md; do
  grep -q "Implementation Status" "$wf" && echo "OK: $wf" || echo "MISS: $wf"
done
# Expected: All OK

# Run tests
bash tests/unit/skills/test_skills.sh | tail -10
# Expected: All pass
```

## Metrics

| Approach | Tool Calls | Time |
|----------|------------|------|
| Inefficient | 27+ | 15+ min |
| Efficient | 5-10 | 3-5 min |
| Savings | 70% | 70% |
