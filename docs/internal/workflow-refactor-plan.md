# Workflow Complexity Refactoring Plan

## Overview

**Problem**: 9 workflows 중 8개가 100줄 예산 초과  
**Goal**: 모든 workflow를 100줄 이내로 압축  
**Reference**: `hotfix.md` (95줄) - 유일하게 예산 내, 좋은 예시

---

## Current State

| Workflow | Lines | Over | Priority |
|----------|-------|------|----------|
| developer/refactor.md | 158 | +58 | **High** |
| developer/feature.md | 143 | +43 | **High** |
| manager/initiative.md | 135 | +35 | Medium |
| manager/monitoring.md | 123 | +23 | Medium |
| manager/approval.md | 123 | +23 | Medium |
| manager/epic.md | 120 | +20 | Medium |
| manager/task-assignment.md | 115 | +15 | Low |
| developer/bug-fix.md | 113 | +13 | Low |
| developer/hotfix.md | 95 | -5 | **OK** |

---

## Analysis: Section-wise Line Distribution

### developer/refactor.md (158줄)
| Section | Lines | Notes |
|---------|-------|-------|
| YAML frontmatter | 14 | Required |
| Implementation Status | 7 | Can compress to 4 |
| When to Use | 5 | Keep |
| Prerequisites | 4 | Keep |
| Flow (ASCII) | 60 | **Largest** - can simplify |
| Quality Gates | 12 | Can compress to 6 |
| Example | 40 | **Can remove or external** |
| Notes | 6 | Keep |

### developer/feature.md (143줄)
| Section | Lines | Notes |
|---------|-------|-------|
| YAML frontmatter | 16 | Required |
| Implementation Status | 7 | Can compress to 4 |
| When to Use | 5 | Keep |
| Prerequisites | 4 | Keep |
| Flow (ASCII) | 55 | Can simplify |
| Quality Gates | 12 | Can compress to 6 |
| Example | 28 | Can remove or external |
| Notes | 6 | Keep |

### Baseline: developer/hotfix.md (95줄 - GOOD)
| Section | Lines | Notes |
|---------|-------|-------|
| YAML frontmatter | 11 | Minimal |
| Implementation Status | 7 | Standard |
| When to Use | 5 | Minimal |
| Flow (ASCII) | 25 | **Simple, effective** |
| Quality Gates | 6 | **Compact** |
| Example | 24 | Adequate |
| Notes | 6 | Minimal |

---

## Refactoring Strategy

### Strategy A: Section Compression (Recommended)

**Approach**: Compress each section to match `hotfix.md` style

**Changes**:
1. **Flow diagram**: Simplify to essential steps only (25-30줄)
2. **Example**: Remove inline, link to external document
3. **Quality Gates**: Use compact table format (4-6줄)
4. **Implementation Status**: Standardize to 4-line format

**Expected Result**:
| Workflow | Before | After | Reduction |
|----------|--------|-------|-----------|
| refactor.md | 158 | ~95 | -40% |
| feature.md | 143 | ~90 | -37% |
| Others | 113-135 | ~90-100 | -20% |

### Strategy B: External Examples (Alternative)

**Approach**: Move Example sections to separate files

**Structure**:
```
workflows/
├── developer/
│   ├── feature.md          <- Main workflow (~100줄)
│   ├── examples/
│   │   └── feature-example.md  <- Detailed example
│   └── ...
```

**Pros**: Clear separation, unlimited example depth
**Cons**: Multiple files to navigate

### Strategy C: Budget Adjustment (Fallback)

**Approach**: Raise budget from 100 → 120줄

**Rationale**: 
- `hotfix.md` (95줄) is tight but good
- Adding 20줄 buffer allows for necessary detail
- Still enforces discipline

**When to use**: If Strategy A/B insufficient

---

## Recommended Action Plan

### Phase 1: High Priority (refactor.md, feature.md)

**Target**: 100줄 이내

**Actions**:

1. **Simplify Flow diagrams**
   - Remove intermediate boxes
   - Use linear flow where possible
   - Reference: hotfix.md Flow section

2. **Compress Example section**
   - Keep only essential steps
   - Or move to `workflows/examples/` directory

3. **Standardize Quality Gates**
   - Use 4-line format (table header + 3 gates)
   - Remove verbose explanation

**Before (refactor.md Flow - 60줄)**:
```
+---------------------+
|  design-solution    | <- Plan refactoring scope
+---------+-----------+
          |
          v
+---------------------+
|    write-code       | <- Ensure tests exist first
... (60 lines total)
```

**After (25줄)**:
```
design-solution → write-code → [Loop: refactor → run-tests → commit] → check-style → review-code → verify-requirements → create-merge-request
```

Or compact ASCII:
```
┌──────────────┐   ┌──────────────┐   ┌────────────────────┐
│design-solution│ → │  write-code  │ → │ Loop: refactor →   │
└──────────────┘   └──────────────┘   │ test → commit      │
                                       └────────────────────┘
                                                ↓
┌──────────────┐   ┌──────────────┐   ┌────────────────────┐
│ check-style  │ → │ review-code  │ → │ create-merge-request│
└──────────────┘   └──────────────┘   └────────────────────┘
```

### Phase 2: Medium Priority (manager workflows)

**Target**: 100줄 이내

**Actions**:
- Apply same compression techniques
- manager workflows have more "NOT IMPLEMENTED" sections - remove or minimize

### Phase 3: Verification

**Commands**:
```bash
# Check all workflows
for wf in workflows/*/*.md; do
  lines=$(wc -l < "$wf")
  status="OK"
  [ "$lines" -gt 100 ] && status="OVER"
  printf "%s %3d %s\n" "$status" "$lines" "$wf"
done

# Run tests
bash tests/meta/run-all-meta-tests.sh
```

---

## Implementation Templates

### Compressed Implementation Status (4줄)

**Before**:
```markdown
## Implementation Status

- **Status**: Implemented
- **CLI Coverage**: 95% (Jira auto-transition optional)
- **Manual Alternative**: [Manual Fallback Guide](../../docs/manual-fallback-guide.md#refactor-manual)
- **Last Updated**: 2026-01-24
```

**After**:
```markdown
## Status
Implemented | CLI 95% | [Manual Guide](../../docs/guides/manual-fallback-guide.md#refactor)
```

### Compressed Quality Gates (5줄)

**Before** (12줄):
```markdown
## Quality Gates (Recommended)

> These are **recommended targets**, not hard blocks.
> In exceptional cases, document the rationale in MR description and proceed.
> See: [ARCHITECTURE.md](../../ARCHITECTURE.md#3-feedback-over-enforcement)

| After | Gate | Target |
|-------|------|--------|
| check-style | Lint | 0 violations |
| run-tests | Test | All pass |
| review-code | Review | 0 critical |
```

**After** (5줄):
```markdown
## Quality Gates
| Gate | Target |
|------|--------|
| Lint | 0 violations |
| Test | All pass |
| Review | 0 critical |
```

### Simplified Flow (Linear Format)

**For simple workflows** (bug-fix, hotfix):
```markdown
## Flow
`write-code` → `check-style` → `run-tests` → `commit-changes` → `create-merge-request`
```

**For workflows with loops** (feature, refactor):
```markdown
## Flow
1. `parse-requirement` → `design-solution`
2. Loop per task:
   - `write-code` → `check-style` → `run-tests` → `review-code` → `commit-changes`
3. `verify-requirements` → `create-merge-request`
```

---

## Decision Required

**Option 1**: Full compression (recommended)
- Compress all sections to hotfix.md level
- Achieves 100줄 target
- Effort: 2-3 hours

**Option 2**: External examples only
- Keep main content, move examples external
- May still exceed 100줄
- Effort: 1 hour

**Option 3**: Budget adjustment (fallback)
- Raise budget to 120줄
- Update .cursorrules
- Effort: 10 minutes

**Recommendation**: Option 1 (Full compression)
- Maintains architectural discipline
- Improves readability (less is more)
- hotfix.md proves 95줄 is sufficient

---

## Next Steps

1. [ ] Choose refactoring strategy (Option 1 recommended)
2. [ ] Refactor developer/refactor.md (High priority)
3. [ ] Refactor developer/feature.md (High priority)
4. [ ] Apply to remaining workflows
5. [ ] Run tests: `bash tests/meta/run-all-meta-tests.sh`
6. [ ] Update handoff with results

---

*Created: 2026-01-27*
*Author: AI Agent*
