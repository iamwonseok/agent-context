# Implement

> Execute the solution with quality and traceability.

## Interface Definition

**Input (Required):**
- `design`: Solution design or specification
- `acceptance_criteria`: Definition of done
- `codebase`: Target repository and location

**Output:**
- Working code changes
- Commit(s) with clear messages
- Updated documentation (if needed)

---

## Template

### 1. Implementation Target

| Item | Value |
|------|-------|
| Design Reference | {design_doc_or_ticket} |
| Target Module | {module_or_component} |

### 2. Acceptance Criteria

- [ ] {ac_1}
- [ ] {ac_2}
- [ ] {ac_3}

### 3. Change Summary

> Brief description of what was changed and why (avoid duplicating MR diff)

**Approach:** {brief_approach_description}

**Key Decisions:**
- {decision_1}: {rationale}
- {decision_2}: {rationale}

### 4. Files Changed

| File | Change Type | Description |
|------|-------------|-------------|
| {file_1} | {add/modify/delete} | {what_changed} |
| {file_2} | {add/modify/delete} | {what_changed} |

### 5. Traceability

| Item | Reference |
|------|-----------|
| Ticket | {ticket_key} |
| MR/PR | {mr_url_or_number} |
| Related | {related_tickets_or_docs} |

---

## Checklist

- [ ] Design/spec reviewed before coding
- [ ] Follows project coding conventions
- [ ] No hardcoded values (use config/constants)
- [ ] Error handling implemented
- [ ] Logging added for key operations
- [ ] Self-review completed before commit
- [ ] Commit message follows convention
- [ ] Documentation updated if API changed
