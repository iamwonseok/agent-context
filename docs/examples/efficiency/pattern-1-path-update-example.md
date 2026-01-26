# Example: Path Update Pattern

## Scenario

Renaming `plan/` directory to `planning/` across the entire codebase.

## Context

- 15 files reference `plan/`
- Files spread across: workflows/, skills/, tests/, docs/
- Need to update all references while maintaining consistency

## Inefficient Approach (What NOT to Do)

```
Step 1: Read workflows/developer/feature.md
Step 2: Find "plan/" reference
Step 3: Replace with "planning/"
Step 4: Read workflows/developer/bug-fix.md
Step 5: Find "plan/" reference
Step 6: Replace with "planning/"
... (repeat 15 times)
Step 45: Run tests
```

**Result:**
- 30+ tool calls (2 per file)
- 15+ minutes
- Error-prone (might miss files)

## Efficient Approach (Best Practice)

### Step 1: Find ALL affected files (1 tool call)

```bash
grep -r "plan/" workflows/ skills/ tests/ docs/ | grep -v "planning/"
```

**Output:**
```
workflows/developer/feature.md:  - planning/design-solution → plan/design-solution
workflows/developer/bug-fix.md:  output: plan/fix-plan.md
skills/planning/README.md:  plan/template
tests/unit/skills/test_skills.sh:  "plan/"
... (15 files total)
```

### Step 2: Group by pattern type

**Group A: Workflow files (4 files)**
- workflows/developer/feature.md
- workflows/developer/bug-fix.md
- workflows/developer/hotfix.md
- workflows/developer/refactor.md

**Group B: Skill files (3 files)**
- skills/planning/README.md
- skills/planning/design-solution/SKILL.md
- skills/execute/write-code/SKILL.md

**Group C: Test files (2 files)**
- tests/unit/skills/test_skills.sh
- tests/integration/test_workflows.sh

### Step 3: Batch replace per group (3 tool calls)

**Replace in workflows (1 call):**
```
old: plan/
new: planning/
files: workflows/developer/*.md
```

**Replace in skills (1 call):**
```
old: plan/
new: planning/
files: skills/**/*.md
```

**Replace in tests (1 call):**
```
old: plan/
new: planning/
files: tests/**/*.sh
```

### Step 4: Verify once (1 tool call)

```bash
# Confirm no old paths remain
grep -r "plan/" workflows/ skills/ tests/ | grep -v "planning/"
# Expected: no output

# Run tests
bash tests/unit/run-all-unit-tests.sh
# Expected: All pass
```

## Comparison

| Metric | Inefficient | Efficient | Savings |
|--------|-------------|-----------|---------|
| Tool calls | 30+ | 6 | 80% |
| Time | 15+ min | 3 min | 80% |
| Risk of missing files | High | Low | - |
| Verification runs | Multiple | 1 | - |

## Key Insights

1. **Find first**: Always search for ALL occurrences before making changes
2. **Group by type**: Similar files get similar treatment
3. **Batch operations**: Replace in groups, not one-by-one
4. **Verify once**: Run tests after ALL changes, not after each

## When to Use

- Directory renames
- Path migrations
- URL updates
- Import path changes
- Configuration key renames

## Checklist

- [ ] Used grep to find ALL affected files first
- [ ] Grouped files by similarity
- [ ] Made batch replacements per group
- [ ] Ran verification only once at the end
- [ ] Confirmed no instances were missed
