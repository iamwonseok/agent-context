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

## Examples

| Scenario | Result | Meaning |
|----------|--------|---------|
| Changes match plan | [PASS] | Aligned |
| Extra file changed | [WARN] | Review if intentional |
| No plan files | [INFO] + [PASS] | No plan to check |

## Outputs

- Alignment status (pass/warn/info)
- List of unplanned changes (if any)
- Recommendations for next steps

## Self-Correction Protocol

Part of RFC-004 v2.0. Checks for mode violations beyond intent alignment.

| Current Mode | Violation Triggers |
|--------------|-------------------|
| planning | Code changes staged |
| research | Any file modifications |
| verification | New feature code added |
| implementation | (Generally permissive) |

When violation detected: Warning → Recommendation → User decides (`--force` to proceed)

## Notes

- Intent check is **advisory**, not mandatory
- Warnings don't prevent commits or submissions
- Use full `verify-requirements` before final submission
- See `.agent/why.md` for design rationale
- Self-Correction follows the same advisory philosophy
