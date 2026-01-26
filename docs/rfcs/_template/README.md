# RFC Template Usage

## Creating New RFC

1. Copy `RFC-TEMPLATE.md` to `docs/rfcs/XXX-title.md`
2. Replace all `{placeholders}` with actual content
3. Fill in ALL sections
4. **Test Plan section is REQUIRED** - do not skip
5. Submit for review

```bash
# Example
cp docs/rfcs/_template/RFC-TEMPLATE.md docs/rfcs/015-my-feature.md
```

## Required Sections

| Section | Required | Notes |
|---------|----------|-------|
| 1. Overview | Yes | One paragraph summary |
| 2. Motivation | Yes | Problem and goals |
| 3. Design | Yes | Architecture and components |
| 4. Implementation Plan | Yes | Phased task breakdown |
| **5. Test Plan** | **Yes** | **NEVER skip this section** |
| 6. Validation Strategy | Recommended | Pre/during/post checks |
| 7. Migration | If applicable | Breaking changes, rollback |
| 8. Alternatives | Recommended | Why not other approaches |
| 9. References | Yes | Related docs and links |
| 10. Change Log | Yes | Track changes |

## Test Plan Requirements

Every RFC MUST include Section 5: Test Plan with:

### 5.1 Test Strategy
- Scope: What will/won't be tested
- Levels: Unit, Integration, E2E breakdown

### 5.2 Test Cases
- Detailed test cases with inputs and expected outputs
- Edge cases identified

### 5.3 Success Criteria
- Must have (blocking) requirements
- Should have (non-blocking) requirements

### 5.4 Validation Checklist
- Implementation checklist

## Reference Examples

**Excellent Test Plans:**
- RFC-010: Agent Efficiency - 9 test sections, comprehensive scenarios
- RFC-011: Language Policy - 5 test sections, clear validation matrix

**Minimal Acceptable:**
- At minimum: Test Strategy + Test Cases + Success Criteria

## Status Values

| Status | Meaning |
|--------|---------|
| Draft | Initial proposal, under discussion |
| Active | Approved, implementation in progress |
| Completed | Fully implemented and validated |
| Deprecated | No longer relevant or superseded |

## Numbering Convention

- RFC numbers are sequential: 001, 002, 003...
- Use 3-digit padding: RFC-001, RFC-012, RFC-123
- File naming: `XXX-kebab-case-title.md`

## Review Process

1. Create RFC document
2. Submit for design review
3. Address feedback
4. Get approval
5. Begin implementation
6. Update status as work progresses
