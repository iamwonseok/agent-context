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
**Design Reference:** {design_doc_or_ticket}
**Target Location:** {file_path_or_module}

### 2. Acceptance Criteria
- [ ] {ac_1}
- [ ] {ac_2}
- [ ] {ac_3}

### 3. Implementation Steps

#### Step 1: {step_name}
```{language}
{code_change}
```

**Rationale:** {why_this_approach}

#### Step 2: {step_name}
```{language}
{code_change}
```

### 4. Files Changed
| File | Change Type | Description |
|------|-------------|-------------|
| {file_1} | {add/modify/delete} | {what_changed} |
| {file_2} | {add/modify/delete} | {what_changed} |

### 5. Commit Message
```
{type}({scope}): {description}

{body}

{footer}
```

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
