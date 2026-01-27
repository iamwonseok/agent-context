# Complexity Budget Exceptions

This document records intentional exceptions to the complexity budget defined in ARCHITECTURE.md.

## Background

Per ARCHITECTURE.md, we maintain complexity limits:

| Component | Max Lines | Rationale |
|-----------|-----------|-----------|
| Single skill | 200 | Focused, single responsibility |
| Workflow | 100 | Composition of skills |
| CLI command | 100 | Simple interface |
| Helper library | 300 | Shared utilities |

## Documented Exceptions

### CLI Platform Libraries (`tools/pm/lib/`)

These files intentionally exceed the 100-line limit due to their role as **platform abstraction layers**:

| File | Lines | Reason |
|------|-------|--------|
| `jira.sh` | ~1100 | Complete JIRA API coverage |
| `gitlab.sh` | ~800 | Complete GitLab API coverage |
| `github.sh` | ~520 | Complete GitHub API coverage |
| `confluence.sh` | ~620 | Complete Confluence API coverage |
| `provider.sh` | ~460 | Provider selection and routing |

**Rationale**:

1. **Platform Abstraction Pattern**: These files implement the vertical abstraction pattern described in ARCHITECTURE.md. Each provider must implement the full interface contract.

2. **Complete API Coverage**: Each platform adapter must support all CLI commands uniformly. Splitting would break the abstraction.

3. **Single Responsibility**: Despite size, each file has one responsibility - interfacing with one platform.

4. **User Independence**: Users shouldn't need to know which platform is being used. The abstraction layer handles all platform-specific logic.

**Alternative Considered**: Splitting by API domain (issues, projects, users) was rejected because:
- Would require complex import chains
- Would break the provider pattern
- Each domain is too interrelated

**Acceptance Criteria**:
- All provider files implement the same function interface
- No business logic in provider files (only API calls)
- Well-documented function signatures

---

### Agent Execution Libraries (`tools/agent/lib/`)

| File | Lines | Reason |
|------|-------|--------|
| `branch.sh` | ~680 | Git workflow complexity |
| `checks.sh` | ~430 | Multiple validation functions |
| `executor.sh` | ~340 | Pipeline execution logic |
| `pipeline.sh` | ~350 | Stage orchestration |
| `manager.sh` | ~420 | Manager workflow commands |

**Rationale**:

1. **Workflow Complexity**: Agent commands orchestrate multiple operations that must be atomic.

2. **State Management**: Some commands manage complex state that's difficult to split without introducing bugs.

3. **Cohesion**: Functions in these files are tightly coupled and share significant context.

**Future Work**: Consider refactoring `executor.sh` state management to use simpler flags (see RFC-010).

---

### Test Helpers (`tools/lint/scripts/`)

| File | Lines | Reason |
|------|-------|--------|
| `test_c_ai_review.sh` | ~370 | AI integration complexity |

**Rationale**: AI review integration requires extensive prompt construction and response parsing.

**Future Work**: Consider splitting into prompt builder and response parser modules.

---

## Adding New Exceptions

If you need to exceed complexity limits:

1. **First, try to refactor**. Can the file be split? Can common code be extracted?

2. **If split is not feasible**, document here:
   - File path and current line count
   - Why it cannot be split
   - What makes this case different
   - Future work to address it

3. **Get approval** from the team before merging.

4. **Update TEST_RESULTS.md** to note the exception.

---

## Exception Review Schedule

Exceptions should be reviewed quarterly:

- [ ] Q1 2026: Review platform library sizes
- [ ] Q2 2026: Review executor.sh state management
- [ ] Q3 2026: Review AI review helper

---

## References

- `ARCHITECTURE.md`: Complexity budget definition
- `policies/README.md`: Framework policies
- `tests/meta/test_complexity_budget.sh`: Automated validation
- `tests/meta/TEST_RESULTS.md`: Current test results

---

**Last Updated**: 2026-01-27  
**Approved By**: Agent Context Team
