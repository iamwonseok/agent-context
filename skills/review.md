# Review

> Validate quality before integration.

## Interface Definition

**Input (Required):**
- `changes`: Code diff or PR to review
- `context`: Why this change was made
- `standards`: Project conventions and guidelines

**Output:**
- Review decision (approve/request changes)
- Feedback comments
- Improvement suggestions

---

## Template

### 1. Review Target
**PR/MR:** {pr_link_or_reference}
**Author:** {author}
**Reviewer:** {reviewer}

### 2. Change Summary
{brief_description_of_changes}

**Files Changed:** {count}
**Lines Added:** +{count}
**Lines Removed:** -{count}

### 3. Review Checklist

#### Correctness
- [ ] Logic is correct
- [ ] Edge cases handled
- [ ] Error handling appropriate
- [ ] No obvious bugs

#### Design
- [ ] Follows project architecture
- [ ] Appropriate abstractions
- [ ] No unnecessary complexity
- [ ] DRY principle followed

#### Code Quality
- [ ] Readable and self-documenting
- [ ] Follows naming conventions
- [ ] No magic numbers/strings
- [ ] Comments where needed (not obvious code)

#### Testing
- [ ] Tests added/updated
- [ ] Tests are meaningful (not just for coverage)
- [ ] Test cases cover AC

#### Security
- [ ] No sensitive data exposed
- [ ] Input validation present
- [ ] No SQL injection/XSS risks

### 4. Feedback

#### Must Fix (Blocking)
| Location | Issue | Suggestion |
|----------|-------|------------|
| {file:line} | {issue} | {suggestion} |

#### Should Fix (Non-blocking)
| Location | Issue | Suggestion |
|----------|-------|------------|
| {file:line} | {issue} | {suggestion} |

#### Nitpicks (Optional)
- {suggestion}

### 5. Decision
- [ ] **Approved** - Good to merge
- [ ] **Approved with comments** - Minor issues, can merge after addressing
- [ ] **Request changes** - Must fix blocking issues before merge

---

## Checklist

- [ ] Understood the context/purpose
- [ ] Read all changed files
- [ ] Checked test coverage
- [ ] Feedback is constructive
- [ ] Blocking vs non-blocking clearly marked
- [ ] No personal preferences as blockers
- [ ] Response time < 24h (goal)
