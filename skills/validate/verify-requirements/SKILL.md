---
name: verify-requirements
category: validate
description: Verify implementation matches original intent
version: 1.0.0
role: developer
mode: verification
cursor_mode: debug
inputs:
  - Original requirements (design/*.md)
  - Implementation plan (plan/*.md)
  - Current implementation
outputs:
  - Verification checklist
  - Gap analysis (if any)
---

# Verify

## State Assertion

**Mode**: verification
**Cursor Mode**: debug
**Purpose**: Verify implementation matches requirements
**Boundaries**:
- Will: Compare implementation to design, identify gaps, document findings
- Will NOT: Modify code, change requirements, or approve completion

## When to Use

- After implementation complete
- Before commit/PR
- When unsure if requirements are met
- After major refactoring

## Prerequisites

- [ ] Implementation complete
- [ ] Original design/plan exists

## Workflow

### 1. Find Original Intent

Locate the source of requirements:

```
design/{feature}.md     # Original design doc
plan/{feature}-plan.md  # Implementation plan
```

If no design doc exists, check:
- User's original request
- Issue description (JIRA/GitLab)
- Commit history for context

### 2. Extract Requirements

From design/plan, list:

| ID | Requirement | Source |
|----|-------------|--------|
| R1 | Must do X | design/feature.md |
| R2 | Should support Y | plan/feature-plan.md |
| R3 | Handle edge case Z | User request |

### 3. Check Each Requirement

For each requirement:

```
[x] R1: Must do X
    -> Implemented in src/feature.py:45
    
[ ] R2: Should support Y
    -> NOT FOUND - Gap identified
    
[x] R3: Handle edge case Z
    -> Handled in src/feature.py:78
```

### 4. Verify Side Effects

Check unintended changes:

- [ ] No breaking changes to existing functionality
- [ ] Documentation updated if needed
- [ ] Tests cover new behavior
- [ ] Config/paths updated if structure changed

### 5. Gap Analysis

If gaps found:

| Gap | Severity | Action |
|-----|----------|--------|
| R2 not implemented | Major | Implement before commit |
| Missing test case | Minor | Add test |
| Doc outdated | Minor | Update doc |

### 6. Result

```
Verification: PASS / NEEDS WORK

Requirements: 5/5 met
Side effects: None detected
Gaps: 0 critical, 1 minor
```

## Outputs

| Output | Format | Description |
|--------|--------|-------------|
| Checklist | Markdown | Requirement verification list |
| Gap analysis | Table | Missing/incomplete items |

## Quality Gate

- All "Must Have" requirements met
- No critical gaps
- Side effects documented

## Examples

### Example 1: Directory Restructure

```
Original Intent (design/why.md):
- Separate docs from tools
- configs/ at root
- tools/lint/, tools/pm/

Verification:
[x] coding-convention/ contains only docs
[x] configs/ moved to root
[x] tools/lint/ has bin, scripts, tests
[x] tools/pm/ has bin, lib
[x] All paths updated in scripts
[x] CI templates updated
[x] Documentation updated

Result: PASS (7/7 requirements met)
```

### Example 2: Feature with Gap

```
Original Intent (design/auth.md):
- JWT authentication
- Session timeout
- Role-based access

Verification:
[x] JWT authentication implemented
[x] Session timeout: 30 min default
[ ] Role-based access: NOT IMPLEMENTED

Result: NEEDS WORK
Gap: R3 (Role-based access) - Major
Action: Implement before commit
```

## Notes

- Always verify against original intent, not just code quality
- Re-read design docs before marking complete
- Different from review: verify = "right thing", review = "thing right"
