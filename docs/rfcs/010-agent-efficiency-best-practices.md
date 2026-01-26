# RFC-010: Agent Efficiency & Best Practices

## Status: Draft
## Author: AI Agent (based on implementation feedback)
## Created: 2026-01-26

---

## 1. Overview

This RFC documents efficiency patterns and best practices discovered during agent-context development.

### 1.1 Background

During implementation of structure alignment (Phase 1-5), we observed:
- **Repetitive operations**: Same grep/replace pattern repeated 8+ times
- **No batch strategy**: Each file processed individually
- **Excessive tool calls**: ~100+ calls for tasks requiring ~10-15
- **No efficiency metrics**: No way to measure or improve

### 1.2 Goals

1. **Prevent repetition**: Stop agent from repeating same operation 3+ times
2. **Define patterns**: Document common task patterns as reusable templates
3. **Establish metrics**: Set efficiency targets and red flags
4. **Enable batching**: Provide strategies for batch operations

---

## 2. Core Principle: "Stop at 3rd Repetition"

### 2.1 The Rule

**If you're about to do the same thing for the 3rd time → STOP and batch it.**

### 2.2 Example: Language Policy Cleanup

**❌ Inefficient (actual behavior):**
```
1. Read workflows/developer/feature.md
2. Find Korean text
3. StrReplace Korean → English
4. Read workflows/developer/refactor.md
5. Find Korean text
6. StrReplace Korean → English
... (repeat 8 times = ~30 tool calls)
```

**✅ Efficient (should be):**
```bash
# 1. Find ALL violations at once
LC_ALL=C grep -r -l $'[\xEA-\xED]' skills/ workflows/

# 2. Show ALL context together
for file in <files>; do
  LC_ALL=C grep -n $'[\xEA-\xED]' "$file"
done

# 3. Replace in batches by pattern type
# - "Implementation Status" blocks: 6 files together
# - "Manual Alternative" blocks: 4 files together

# 4. Verify once
bash tests/unit/skills/test_skills.sh

# Result: ~30 calls → ~10 calls (66% reduction)
```

---

## 3. Batch Operation Strategies

### 3.1 When to Use Shell vs Individual Tools

| Task Type | Use Shell | Use Individual Tools |
|-----------|-----------|---------------------|
| Find patterns | ✅ `grep -r` | ❌ Read each file |
| List files | ✅ `ls`, `find` | ❌ Multiple LS calls |
| Simple replace | ✅ `sed` (if simple) | ❌ StrReplace per file |
| Complex replace | ❌ | ✅ StrReplace (context-aware) |
| File creation | ❌ | ✅ Write tool |
| Git operations | ✅ `git` commands | ❌ |

### 3.2 Batch Operation Decision Tree

```
Need to modify 3+ similar files?
    |
    Yes
    |
    v
Can you identify pattern in ONE command?
    |
    +-- Yes --> Use grep/find to list ALL files
    |           |
    |           v
    |           Group files by replacement pattern
    |           |
    |           v
    |           Replace in batches
    |           |
    |           v
    |           Test ONCE at end
    |
    +-- No ---> Process individually
                (but still parallelize reads)
```

---

## 4. Common Task Patterns

### Pattern 1: Fix All Path References

**When:** Changing skill/workflow paths across multiple files

**Template:**
```bash
# 1. Find ALL affected files
grep -r "old-path/" workflows/ skills/ tests/

# 2. Show context (identify patterns)
grep -n "old-path/" <files>

# 3. Replace in batches
# Group by file type:
# - All workflows together
# - All skills together  
# - All tests together

# 4. Verify once
bash tests/unit/skills/test_skills.sh
```

**Efficiency gain:** 70-80% fewer tool calls

---

### Pattern 2: Language Policy Cleanup

**When:** Removing Korean from skills/workflows

**Template:**
```bash
# 1. Find ALL violations
LC_ALL=C grep -r -l $'[\xEA-\xED]' skills/ workflows/

# 2. Show ALL Korean lines grouped
for file in <files>; do
  echo "=== $file ==="
  LC_ALL=C grep -n $'[\xEA-\xED]' "$file"
done

# 3. Translate in batches
# Group by content type:
# - Status/metadata lines
# - Documentation notes
# - Examples

# 4. Verify once
bash tests/unit/skills/test_skills.sh | tail -20
```

**Efficiency gain:** 60-70% fewer tool calls

---

### Pattern 3: Add New Documentation

**When:** Creating related docs (guide + examples + architecture)

**Template:**
```bash
# 1. Check existing structure
ls docs/guides/ docs/architecture/

# 2. Create ALL related docs at once:
Write docs/guides/troubleshooting.md
Write docs/guides/platform-setup-examples.md
Write docs/architecture/skills-tools-mapping.md

# 3. Link from main README once
```

**Efficiency gain:** Single verification pass

---

### Pattern 4: Update Tests After Structure Change

**When:** Modified skills/workflows/tools structure

**Template:**
```bash
# 1. Identify ALL test files affected
ls tests/unit/

# 2. Update test configuration
# - SKILL_PATHS
# - Workflow paths
# - Expected structures

# 3. Run ALL tests once
bash tests/unit/run-all-unit-tests.sh

# 4. Fix failures in batch

# 5. Verify CI config
grep -A 5 "test:" .gitlab-ci.yml
```

---

### Pattern 5: Batch File Operations

**When:** Need to modify 5+ similar files

**Strategy:**
```bash
# DON'T:
Read file1 → Modify → Read file2 → Modify...

# DO:
# 1. Parallel read (all at once)
# 2. Identify common pattern
# 3. Batch replace (grouped by pattern)
# 4. Single test run
```

---

## 5. Efficiency Metrics

### 5.1 Targets

| Metric | Simple Task | Complex Task | Red Flag |
|--------|-------------|--------------|----------|
| Tool calls | <20 | <50 | >100 |
| Repeated identical ops | 0 | 0 | 3+ |
| Test runs per batch | 1 | 2 | Per file |
| Individual file reads | Group related | Group related | 10+ sequential |

### 5.2 Measurement

Track in task summaries:
```markdown
## Efficiency Metrics

- Tool calls: 15 (target: <20) ✅
- Repeated operations: 0 ✅
- Test runs: 1 ✅
- Files processed: 12 in 3 batches ✅
```

### 5.3 Optimization Examples

**Before optimization:**
- 8 files × 4 operations = 32 tool calls
- Test after each file = 8 test runs
- Total: 40+ tool calls

**After optimization:**
- 1 find + 3 batches + 1 test = 5 tool calls
- Efficiency: 87.5% reduction

---

## 6. Implementation

### 6.1 .cursorrules Integration

Added sections:
- "Batch Operations & Efficiency"
- "Common Task Patterns"
- "Agent Efficiency Metrics"

### 6.2 Documentation

- This RFC: Detailed rationale and patterns
- `.cursorrules`: Agent-readable quick reference
- `docs/guides/troubleshooting.md`: User-facing examples

### 6.3 Testing

No automated enforcement (by design):
- Agents should self-optimize based on patterns
- Human review can catch excessive tool calls
- Metrics tracked in task summaries

---

## 7. Future Work

### 7.1 Automated Pattern Detection

Agent could self-detect repetition:
```python
# Hypothetical
if same_operation_count >= 3:
    warn("Consider batching this operation")
    suggest_batch_command()
```

### 7.2 Efficiency Benchmarks

Collect efficiency data:
- Average tool calls per task type
- Identify inefficient patterns
- Generate best practices

### 7.3 Tool Call Budget

Set hard limits (optional):
```yaml
# .agent/config.yaml
efficiency:
  max_tool_calls_per_task: 100
  warn_at: 50
```

---

## 8. Philosophy Alignment

### 8.1 Simplicity Over Completeness

✅ **Aligned**: Simple pattern templates, no complex enforcement

### 8.2 Feedback Over Enforcement

✅ **Aligned**: Patterns are guidelines, not hard rules

### 8.3 User Autonomy

✅ **Aligned**: Agents choose whether to batch

### 8.4 State Through Artifacts

✅ **Aligned**: Efficiency metrics in task summaries (files)

---

## 9. References

- `.cursorrules`: Implementation
- `ARCHITECTURE.md`: Design philosophy
- Phase 1-5 implementation: Real-world examples

---

## 10. Change Log

| Date | Change | Author |
|------|--------|--------|
| 2026-01-26 | Initial draft | AI Agent |

---

**Next Review**: After 3-5 tasks using these patterns
