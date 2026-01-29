# Design

> Define the solution before implementing it.

## Interface Definition

**Input (Required):**
- `problem`: The problem to solve
- `scope`: Boundaries of the solution
- `constraints`: Technical, time, or resource limitations

**Output:**
- Solution design document or PR description
- Architecture decisions with rationale
- Implementation approach

---

## Template

### 1. Problem Statement
{problem}

### 2. Scope

**In Scope:**
- {in_scope_1}
- {in_scope_2}

**Out of Scope:**
- {out_scope_1}

### 3. Constraints
| Type | Constraint | Impact |
|------|------------|--------|
| Technical | {constraint} | {impact} |
| Time | {constraint} | {impact} |
| Resource | {constraint} | {impact} |

### 4. Solution Design

#### Approach
{approach_description}

#### Key Components
```
{architecture_diagram_or_structure}
```

#### Alternatives Considered
| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| {option_1} | {pros} | {cons} | {chosen/rejected} |
| {option_2} | {pros} | {cons} | {chosen/rejected} |

### 5. Implementation Plan
1. {step_1}
2. {step_2}
3. {step_3}

### 6. Risks & Mitigations
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| {risk} | {H/M/L} | {H/M/L} | {mitigation} |

---

## Checklist

- [ ] Problem clearly stated
- [ ] Scope explicitly defined (in/out)
- [ ] Constraints documented
- [ ] At least 2 alternatives considered
- [ ] Decision rationale documented
- [ ] Risks identified with mitigations
- [ ] Implementation steps are concrete
