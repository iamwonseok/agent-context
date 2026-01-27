---
name: check-intent
category: validate
description: Lightweight intent alignment check during development
version: 1.0.0
role: developer
mode: verification
cursor_mode: debug
inputs:
  - Current changes (git diff)
  - Plan files (plan/*.md)
outputs:
  - Alignment status (pass/warn)
  - List of unplanned changes (if any)
related:
  - validate/verify-requirements (full verification)
---

# Check Intent

## State Assertion

**Mode**: verification
**Cursor Mode**: debug
**Purpose**: Verify changes align with planned intent
**Boundaries**:
- Will: Compare changes to plan, detect drift, report warnings
- Will NOT: Modify code, revert changes, or block commits (warnings only)

Lightweight intent alignment check for use during development.
Unlike full verification (`verify-requirements`), this is designed to run frequently with minimal overhead.

## When to Use

- During `agent dev check` (automated)
- After making changes, before commit
- When unsure if changes align with plan

## Prerequisites

- [ ] Git repository with changes
- [ ] (Optional) Plan files in `plan/` or `design/`

## Philosophy

> "Warnings over blocking, user autonomy preserved"
> -- .agent/why.md

This skill provides **warnings only**, not hard blocks. Users can proceed even if alignment warnings are shown.

## Workflow

### 1. Find Plan Files

Look for plan documents:

```
plan/*.md                    # Implementation plans
design/*.md                  # Design documents
.cursor/plans/*.plan.md     # Cursor plans (if using Cursor)
```

### 2. Get Current Changes

```bash
# Staged + unstaged changes
git diff --name-only HEAD

# Or changes since base branch
git diff --name-only origin/main...HEAD
```

### 3. Check Alignment

Simple heuristic: Are changed files mentioned in any plan?

| Changed File | In Plan? | Status |
|--------------|----------|--------|
| src/auth.ts | Yes (plan/auth-plan.md) | [PASS] |
| src/utils.ts | No | [WARN] |

### 4. Report Results

```
[Intent Alignment]
  [PASS] Changes align with plan

  or

  [WARN] Some changes may not be in plan
    - src/utils.ts
    - src/helpers.ts
  [RECOMMEND] Review plan or document deviation
```

## Output Interpretation

| Status | Meaning | Action |
|--------|---------|--------|
| [PASS] | All changes mentioned in plan | Continue |
| [WARN] | Some changes not in plan | Review, document if intentional |
| [INFO] | No plan files found | Consider creating a plan |

## Integration

### CLI

```bash
# Run as part of check
agent dev check

# Output includes intent alignment section
```

### In Code

```bash
source .agent/tools/agent/lib/checks.sh

check_intent_alignment "$project_root" "$context_path"
# Returns: 0 = aligned, 1 = deviation (warning)
```

## Limitations

- Simple filename matching (not semantic)
- Does not understand refactoring (renamed files)
- Cannot detect scope creep within a file

For comprehensive verification, use `validate/verify-requirements`.

## Examples

### Example 1: Aligned Changes

```
Plan (plan/feature.md):
  - [ ] Implement login in src/auth.ts
  - [ ] Add tests in tests/auth.test.ts

Changes:
  - src/auth.ts
  - tests/auth.test.ts

Result: [PASS] Changes align with plan
```

### Example 2: Deviation Warning

```
Plan (plan/feature.md):
  - [ ] Implement login in src/auth.ts

Changes:
  - src/auth.ts
  - src/utils.ts  <- Not in plan

Result:
  [WARN] Some changes may not be in plan
    - src/utils.ts
  [RECOMMEND] Review plan or document deviation
```

### Example 3: No Plan

```
Plan: (none found)

Changes:
  - src/feature.ts

Result:
  [INFO] No plan files found in plan/
  [PASS] (no plan to check against)
```

## Outputs

- Alignment status (pass/warn/info)
- List of unplanned changes (if any)
- Recommendations for next steps

## Self-Correction Protocol

This skill is part of the Self-Correction Protocol (RFC-004 v2.0). Beyond intent alignment, it also checks for mode violations.

### Mode Violation Detection

| Current Mode | Violation Triggers |
|--------------|-------------------|
| planning | Code changes staged |
| research | Any file modifications |
| verification | New feature code added |
| implementation | (Generally permissive) |

### Self-Correction Triggers

When a mode violation is detected:

1. **Warning displayed** - Clear message about the violation
2. **Recommendation shown** - Suggested corrective action
3. **User decides** - Continue with `--force` or address the issue

### Integration with `detect_mode_violation()`

```bash
source .agent/tools/agent/lib/checks.sh

# Load current mode (default: planning)
current_mode=$(load_current_mode "$context_path")

# Check for mode violations
if detect_mode_violation "$current_mode" "$context_path"; then
    echo "No violations"
else
    echo "Mode violation detected - review changes"
fi
```

### Self-Correction Workflow

```
1. Agent declares intent (mode, purpose)
2. Agent performs actions
3. check-intent detects deviation:
   - Plan alignment check
   - Mode violation check
4. If deviation:
   - Display warning
   - Suggest correction
   - User decides next action
```

### Example: Self-Correction in Action

```
Current Mode: planning
Staged Changes: src/feature.ts (code file)

[SELF-CORRECTION] Mode Violation Detected
  Current Mode: planning
  Violation: Code changes detected in planning mode

  Recommended Actions:
    1. Review the changes - are they intentional?
    2. If yes, switch to implementation mode
    3. If no, unstage the code changes

  Note: This is a WARNING only. Use --force to proceed.
```

## Notes

- Intent check is **advisory**, not mandatory
- Warnings don't prevent commits or submissions
- Use full `verify-requirements` before final submission
- See `.agent/why.md` for design rationale
- Self-Correction follows the same advisory philosophy
