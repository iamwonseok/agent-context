# Feature: {Name}

## Overview

{One line description}

## Background

### Problem
- Current state
- Issue to solve
- Why needed

### Goals
- Goal 1
- Goal 2

## Requirements

### Must Have
- [ ] Req 1
- [ ] Req 2

### Nice to Have
- [ ] Req 3

### Non-functional
- Performance: {target}
- Security: {needs}
- Scale: {expected}

## Architecture

```
+--------+     +--------+     +--------+
| Client |---->| Server |---->|   DB   |
+--------+     +--------+     +--------+
```

### Components
- **A**: Role
- **B**: Role

## Data Models

### {Entity}

```
Entity
+-- id: UUID (PK)
+-- name: string
+-- created_at: timestamp
+-- updated_at: timestamp
```

### Relations

```
User --1:N--> Post --1:N--> Comment
```

## API

### POST /api/{resource}

**Request**:
```json
{"field": "value"}
```

**Response 200**:
```json
{"id": "uuid", "field": "value"}
```

**Errors**: 400, 401, 500

## Files to Change

| File | Change |
|------|--------|
| `src/file.py` | Add logic |
| `tests/test.py` | Add tests |

## Testing

### Unit
- Test 1
- Test 2

### Integration
- Scenario 1

### Edge Cases
- Case 1

## Security

- [ ] Input validation
- [ ] Auth/authz
- [ ] SQL injection
- [ ] XSS

## Migration

### Data
How to handle existing data

### Rollback
Steps if issues occur

## Open Questions

- [ ] Question 1
- [ ] Question 2

---

**Created**: {date} | **Author**: {name}
**Approved**: {date} | **Approver**: {name}
