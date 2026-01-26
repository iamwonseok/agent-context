# Agent Efficiency Quick Reference

## Core Principle

> If you're about to do the same thing for the 3rd time, STOP and batch it.

## Batch Operation Strategy

### 1. Find First, Then Act

```bash
# GOOD: Find ALL affected files first
grep -r "old-pattern" dir/

# BAD: Read each file individually to check
```

### 2. Group by Pattern Type

| Task | Strategy |
|------|----------|
| Replace text | Group files by content similarity |
| Add sections | Group by document type |
| Update configs | Group by config structure |

### 3. Verify Once at End

```bash
# GOOD: Run tests once after ALL changes
make all-changes
bash tests/run-all.sh

# BAD: Test after each individual change
```

## Common Patterns

### Path Update Pattern

```bash
# 1. Find all (1 call)
grep -r "old-path/" workflows/ skills/

# 2. Group and replace (2-3 calls)
# - workflows together
# - skills together

# 3. Verify (1 call)
bash tests/unit/run-all-unit-tests.sh
```

### Language Cleanup Pattern

```bash
# 1. Find violations (1 call)
LC_ALL=C grep -r -l $'[\xEA-\xED]' skills/ workflows/

# 2. Show all Korean lines (1 call)
for f in <files>; do grep -n Korean "$f"; done

# 3. Translate in batches by pattern type

# 4. Verify (1 call)
bash tests/unit/skills/test_skills.sh
```

### Multi-File Update Pattern

```bash
# 1. Read all files in parallel (1 message, N reads)

# 2. Identify common pattern

# 3. Apply changes in groups (2-3 calls)

# 4. Single verification
```

## Efficiency Metrics

| Metric | Target | Red Flag |
|--------|--------|----------|
| Tool calls (simple task) | < 20 | > 50 |
| Tool calls (complex task) | < 50 | > 100 |
| Repeated identical operations | 0 | 3+ |
| Test runs per change batch | 1-2 | > 3 |

## Anti-patterns to Avoid

| Anti-pattern | Problem | Solution |
|--------------|---------|----------|
| Read → Modify → Read → Modify | N tool calls | Batch read, batch modify |
| Test after each file | N test runs | Test once at end |
| Same grep 3+ times | Wasted calls | Store results, reuse |
| Sequential when parallel possible | Slower | Use parallel tool calls |

## Quick Decision Tree

```
Is this a repetitive task?
├─ Yes → Can I find all instances first?
│        ├─ Yes → Use batch pattern
│        └─ No → Consider if truly repetitive
└─ No → Proceed normally
```

## Tool Selection

| Task | Preferred Tool |
|------|----------------|
| Find patterns | Grep (not find + cat) |
| Read files | Read tool (not cat) |
| Edit files | StrReplace (not sed) |
| Search code | Grep/SemanticSearch |

## Related Resources

- [RFC-010: Agent Efficiency Best Practices](../rfcs/010-agent-efficiency-best-practices.md)
- [Efficiency Examples](../examples/efficiency/)
- [Test Scenarios](../../tests/efficiency/)
- [.cursorrules Batch Operations Section](../../.cursorrules)
