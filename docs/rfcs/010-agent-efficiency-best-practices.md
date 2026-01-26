# RFC-010: Agent Efficiency & Best Practices

## Status: Active
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

## 6. Implementation Plan

### 6.1 Phase 0: Foundation (Completed)

**Status**: ✅ Completed

- [x] RFC-010 document creation
- [x] .cursorrules integration
  - Batch Operations & Efficiency section
  - Common Task Patterns quick reference
  - Agent Efficiency Metrics table
- [x] Language Policy enforcement matrix
- [x] Basic documentation structure

**Deliverables**:
- `docs/rfcs/010-agent-efficiency-best-practices.md`
- Updated `.cursorrules`
- `ARCHITECTURE.md` language policy section

---

### 6.2 Phase 1: Test Plan & Validation Framework

**Goal**: Define how to measure and validate efficiency improvements

**Tasks**:

1. **Create Test Scenarios** (`tests/efficiency/`)
   ```bash
   tests/efficiency/
   ├── README.md                    # Testing methodology
   ├── scenario-path-update.md      # Pattern 1 test
   ├── scenario-language-cleanup.md # Pattern 2 test
   └── measure-efficiency.sh        # Metrics collection script
   ```

2. **Define Metrics Collection**
   - Tool call counter (manual tracking for now)
   - Test run counter
   - File operation grouping analysis

3. **Success Criteria**
   ```yaml
   # tests/efficiency/success-criteria.yaml
   pattern_1_path_update:
     max_tool_calls: 15
     max_test_runs: 2
     target_reduction: 70%
   
   pattern_2_language_cleanup:
     max_tool_calls: 12
     max_test_runs: 1
     target_reduction: 66%
   ```

**Deliverables**:
- Test scenario documents
- Metrics collection methodology
- Success criteria definition

**Estimated effort**: 2-3 hours
**Context window**: ~20k tokens (safe)

---

### 6.3 Phase 2: Example Implementation & Validation

**Goal**: Demonstrate patterns with real examples

**Tasks**:

1. **Create "Before" Baseline**
   - Document current inefficient approach
   - Measure actual tool calls/time

2. **Apply Pattern 1: Path Reference Updates**
   - Create example with 10+ files to update
   - Apply batch strategy
   - Measure improvement

3. **Apply Pattern 2: Language Policy Cleanup**
   - Use actual Phase 5 as case study
   - Document the 30→10 calls improvement
   - Extract lessons learned

4. **Document Results**
   ```markdown
   # docs/rfcs/010-implementation-results.md
   
   ## Pattern 1 Results
   - Before: 42 tool calls
   - After: 12 tool calls
   - Reduction: 71%
   
   ## Pattern 2 Results
   - Before: 30 tool calls
   - After: 10 tool calls
   - Reduction: 66%
   ```

**Deliverables**:
- Implementation examples
- Measurement results
- Lessons learned document

**Estimated effort**: 3-4 hours
**Context window**: ~30k tokens (safe)

---

### 6.4 Phase 3: Documentation Integration

**Goal**: Integrate efficiency patterns into existing workflows

**Tasks**:

1. **Update Workflow Templates**
   - Add efficiency checklist to workflows
   - Reference patterns in SKILL.md templates

2. **Create Quick Reference Card**
   ```markdown
   # docs/guides/efficiency-quick-reference.md
   
   ## Before You Start
   - [ ] Will you repeat the same operation 3+ times?
   - [ ] Can you find ALL files at once?
   - [ ] Can you group by pattern type?
   
   ## Pattern Selection
   - Path updates → Pattern 1
   - Language cleanup → Pattern 2
   - Documentation → Pattern 3
   ```

3. **Update Troubleshooting Guide**
   - Add "Task taking too long?" section
   - Reference efficiency patterns

**Deliverables**:
- Updated workflow templates
- Efficiency quick reference card
- Enhanced troubleshooting guide

**Estimated effort**: 2 hours
**Context window**: ~15k tokens (safe)

---

### 6.5 Phase 4: Final Validation & Handoff

**Goal**: Verify all components work together

**Tasks**:

1. **Run Complete Test Suite**
   ```bash
   # All tests must pass
   bash tests/unit/run-all-unit-tests.sh
   bash tests/integration/test_skills_tools.sh
   bash tests/efficiency/validate-patterns.sh  # New
   ```

2. **Measure Efficiency Baseline**
   - Track next 3-5 tasks
   - Collect actual metrics
   - Compare against targets

3. **Update Documentation**
   - Final polish on all docs
   - Ensure cross-references work
   - Add to main README

4. **Create Handoff Document**
   - Summary of what was implemented
   - How to use efficiency patterns
   - Next steps (optional improvements)

**Deliverables**:
- All tests passing
- Efficiency baseline established
- Complete documentation set
- Handoff document

**Estimated effort**: 2 hours
**Context window**: ~15k tokens (safe)

---

### 6.6 Testing Strategy

**No automated enforcement** (by design, per ARCHITECTURE.md):
- Agents self-optimize based on patterns
- Human review catches excessive tool calls
- Metrics tracked in task summaries

**Validation approach**:
1. Scenario-based testing (Phase 1)
2. Real-world examples (Phase 2)
3. Metric collection (Phase 4)
4. Continuous improvement (ongoing)

---

### 6.7 Rollout Plan

| Phase | Duration | Context Window | Dependencies |
|-------|----------|----------------|--------------|
| Phase 0 | Completed | - | None |
| Phase 1 | 2-3 hours | ~20k tokens | Phase 0 |
| Phase 2 | 3-4 hours | ~30k tokens | Phase 1 |
| Phase 3 | 2 hours | ~15k tokens | Phase 2 |
| Phase 4 | 2 hours | ~15k tokens | Phase 3 |

**Total estimated effort**: 9-11 hours
**Total context window budget**: ~80k tokens (well within 1M limit)

**Checkpoints**:
- ✅ Checkpoint 1: Phase 0 complete (current)
- ⏸️ Checkpoint 2: Phase 1 test plan ready
- ⏸️ Checkpoint 3: Phase 2 examples validated
- ⏸️ Checkpoint 4: Phase 3-4 documentation complete

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

## 9. Detailed Test Plan

### 9.1 Phase 1: Test Scenarios

**Objective**: Define measurable test cases for each pattern

#### Scenario 1: Path Reference Updates (Pattern 1)

**Setup**:
```bash
# Create test environment
mkdir -p tests/efficiency/fixtures/path-update/
cp -r workflows/ tests/efficiency/fixtures/path-update/
```

**Test case**:
```yaml
name: path-reference-update
description: Update 10 files with path references
baseline_approach:
  steps:
    - Read file 1
    - Find pattern
    - Replace
    - Repeat for files 2-10
  tool_calls: 40
  test_runs: 10

efficient_approach:
  steps:
    - grep -r to find ALL files
    - Show all matches
    - Batch replace by type
    - Test once
  tool_calls: 15
  test_runs: 1

success_criteria:
  tool_call_reduction: ">60%"
  test_run_reduction: ">80%"
  all_tests_pass: true
```

**Validation**:
```bash
bash tests/efficiency/scenario-01-path-update.sh
# Expected output:
# Baseline: 40 calls
# Efficient: 15 calls
# Reduction: 62.5% ✅
```

---

#### Scenario 2: Language Policy Cleanup (Pattern 2)

**Setup**:
```bash
# Use Phase 5 as real-world data
git log --oneline | grep "language"
```

**Test case**:
```yaml
name: language-cleanup
description: Remove Korean from 8 files
baseline_approach:
  steps:
    - Read each file individually
    - Find Korean lines
    - Translate
    - Repeat 8 times
  tool_calls: 30

efficient_approach:
  steps:
    - grep -r for ALL Korean files
    - Show all Korean lines together
    - Group by content type
    - Batch translate
    - Test once
  tool_calls: 10

success_criteria:
  tool_call_reduction: ">65%"
  all_korean_removed: true
  tests_pass: true
```

**Validation**:
```bash
# Verify no Korean in skills/workflows
LC_ALL=C grep -r -l $'[\xEA-\xED]' skills/ workflows/
# Expected: empty

bash tests/unit/skills/test_skills.sh | grep "Language Policy"
# Expected: "No Korean characters" ✅
```

---

#### Scenario 3-5: Additional Patterns

**Similar structure** for:
- Scenario 3: Documentation creation (Pattern 3)
- Scenario 4: Test updates (Pattern 4)
- Scenario 5: Batch file operations (Pattern 5)

---

### 9.2 Phase 2: Measurement Methodology

**Tool call counting**:

```bash
# Manual counting (for now)
# Count from task start to task end

# Example log format:
Task: Update path references
Start: 10:00:00
End: 10:15:00

Tool calls:
1. grep -r "plan/" workflows/    # Find all
2. grep -n "plan/" file1.md      # Show context
3. StrReplace file1.md           # Replace
4. StrReplace file2.md           # Replace (batched)
5. StrReplace file3.md           # Replace (batched)
6. bash tests/unit/test.sh       # Test once

Total: 6 calls

Baseline estimate: 25 calls
Reduction: 76%
```

**Metrics to track**:

```yaml
# tests/efficiency/results/task-{id}.yaml
task_id: TASK-123
pattern_used: pattern-2-language-cleanup
start_time: "2026-01-26T10:00:00Z"
end_time: "2026-01-26T10:15:00Z"
duration_minutes: 15

metrics:
  tool_calls: 10
  baseline_estimate: 30
  reduction_percent: 66.7
  test_runs: 1
  files_modified: 8
  tests_passed: true

notes: |
  Used batch grep to find all files at once.
  Grouped translations by content type.
  Single test run at end.
```

---

### 9.3 Phase 3: Regression Testing

**After implementing efficiency patterns, ensure:**

1. **Functional correctness maintained**:
   ```bash
   # All unit tests still pass
   bash tests/unit/run-all-unit-tests.sh
   # Expected: 401/401
   
   # Integration tests still pass
   bash tests/integration/test_skills_tools.sh
   # Expected: 14/14
   ```

2. **No degradation in quality**:
   ```bash
   # Skills still well-formed
   grep "## When to Use" skills/*/SKILL.md | wc -l
   # Expected: 26 (all skills have it)
   
   # Workflows still valid
   bash tests/unit/skills/test_skills.sh | grep "Workflows"
   # Expected: All workflows pass
   ```

3. **Documentation completeness**:
   ```bash
   # All patterns documented
   grep -c "Pattern [1-5]" docs/rfcs/010-*.md
   # Expected: >=5
   
   # Cross-references valid
   grep -r "\[.*\](.*\.md)" docs/ | wc -l
   # Expected: >50 (many valid links)
   ```

---

### 9.4 Success Criteria Per Checkpoint

**Checkpoint 2 Success**:
- [ ] 5 scenario files created
- [ ] `success-criteria.yaml` defined
- [ ] `measure-efficiency.sh` executable
- [ ] README explains methodology

**Checkpoint 3 Success**:
- [ ] Pattern 1 example shows >60% reduction
- [ ] Pattern 2 example shows >60% reduction
- [ ] Case study documented
- [ ] Lessons learned captured

**Checkpoint 4 Success**:
- [ ] Quick reference card created
- [ ] Templates updated with efficiency hints
- [ ] Main docs reference efficiency guide
- [ ] All tests still passing (no regression)

---

### 9.5 Automated Test Commands

**Quick validation** (run after each checkpoint):

```bash
#!/bin/bash
# tests/efficiency/quick-validate.sh

echo "Phase 0 Validation..."
bash tests/unit/run-all-unit-tests.sh || exit 1
bash tests/integration/test_skills_tools.sh || exit 1

echo "Phase 1 Validation..."
[ -f tests/efficiency/success-criteria.yaml ] || exit 1
[ $(ls tests/efficiency/scenario-*.md 2>/dev/null | wc -l) -eq 5 ] || exit 1

echo "Phase 2 Validation..."
[ -d docs/examples/efficiency ] || exit 1
[ -f docs/rfcs/010-case-study-phase-5.md ] || exit 1

echo "Phase 3 Validation..."
[ -f docs/guides/efficiency-quick-reference.md ] || exit 1
grep -q "efficiency" README.md || exit 1

echo "All checkpoints validated! ✅"
```

---

## 10. References

- `.cursorrules`: Agent-readable quick reference
- `ARCHITECTURE.md`: Design philosophy and complexity budget
- `docs/internal/handoff.md`: Detailed work plan and progress tracking
- Phase 1-5 implementation: Real-world efficiency examples

### Related RFCs

- RFC-004: Agent Workflow System (State Visibility)
- RFC-007: Architecture Improvements (IR, Skill selection)
- RFC-009: CLI Documentation Policy

---

## 11. Change Log

| Date | Change | Author |
|------|--------|--------|
| 2026-01-26 | Initial draft | AI Agent |
| 2026-01-26 | Added Implementation Plan (Phase 0-4) | AI Agent |
| 2026-01-26 | Added Detailed Test Plan (Section 9) | AI Agent |
| 2026-01-27 | Status: Draft → Active (implementation complete) | AI Agent |

---

**Next Review**: After Checkpoint 4 completion (~9-11 hours of work)
