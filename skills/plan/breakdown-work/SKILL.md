---
name: breakdown-work
category: plan
description: Break down large tasks into manageable subtasks
version: 1.0.0
role: developer
inputs:
  - Task or feature description
  - Design document (optional)
outputs:
  - Subtask list with estimates
  - Dependency graph
---

# Breakdown Work

## When to Use

- Large feature implementation
- Epic to task decomposition
- Sprint planning
- When task seems too big (> 1 day)

## Prerequisites

- [ ] Clear understanding of requirements
- [ ] Design or approach decided
- [ ] Knowledge of codebase structure

## Workflow

### 1. Identify Major Components

Break by:
- Feature areas
- Technical layers
- User stories
- Deliverables

### 2. Apply INVEST Criteria

Each subtask should be:

| Criteria | Description |
|----------|-------------|
| **I**ndependent | Can be done separately |
| **N**egotiable | Scope can be discussed |
| **V**aluable | Delivers value on its own |
| **E**stimable | Can estimate effort |
| **S**mall | Fits in one sprint/day |
| **T**estable | Has clear done criteria |

### 3. Use Decomposition Patterns

#### By Layer
```
Feature: User Authentication
├── API Layer
│   ├── POST /auth/login endpoint
│   ├── POST /auth/logout endpoint
│   └── GET /auth/me endpoint
├── Service Layer
│   ├── AuthService implementation
│   └── TokenService implementation
├── Data Layer
│   ├── User model updates
│   └── Session model
└── Tests
    ├── Unit tests
    └── Integration tests
```

#### By User Story
```
Epic: Shopping Cart
├── As a user, I can add items to cart
├── As a user, I can remove items from cart
├── As a user, I can update quantities
├── As a user, I can view cart total
└── As a user, I can checkout
```

#### By Technical Step
```
Feature: Database Migration
├── 1. Write migration script
├── 2. Test on staging
├── 3. Backup production
├── 4. Run migration
└── 5. Verify data integrity
```

### 4. Estimate Each Subtask

| Size | Duration | Description |
|------|----------|-------------|
| XS | < 2 hours | Trivial change |
| S | 2-4 hours | Small task |
| M | 4-8 hours | Half to full day |
| L | 1-2 days | Needs breakdown |
| XL | > 2 days | Must breakdown |

### 5. Identify Dependencies

```
Task A ──┬──→ Task C ──→ Task E
         │
Task B ──┘
         
Legend: Arrow = "must complete before"
```

### 6. Create Task List

```markdown
## Task Breakdown: {feature-name}

### Overview
- Total subtasks: 8
- Total estimate: 3 days
- Critical path: A → C → E

### Subtasks

| ID | Task | Estimate | Depends On | Assignee |
|----|------|----------|------------|----------|
| 1 | Create User model | S (2h) | - | - |
| 2 | Create Session model | S (2h) | - | - |
| 3 | Implement AuthService | M (4h) | 1, 2 | - |
| 4 | Create login endpoint | M (4h) | 3 | - |
| 5 | Create logout endpoint | S (2h) | 3 | - |
| 6 | Write unit tests | M (4h) | 3 | - |
| 7 | Write integration tests | M (6h) | 4, 5 | - |
| 8 | Update documentation | S (2h) | 4, 5 | - |

### Risks
- Token storage approach TBD
- May need security review
```

## Outputs

| Output | Format | Description |
|--------|--------|-------------|
| Subtask list | Table | Tasks with estimates |
| Dependencies | Graph/List | Task order constraints |
| Critical path | List | Longest dependency chain |
| Total estimate | Time | Sum of estimates |

## Examples

### Example 1: API Feature

```
Feature: "Add product search API"

Breakdown:
1. [S] Define search request/response schema
2. [M] Implement search service with filters
3. [M] Create GET /products/search endpoint
4. [S] Add pagination support
5. [M] Write tests
6. [S] Update API documentation

Total: ~2 days
Critical path: 1 → 2 → 3 → 5
```

### Example 2: Bug Fix

```
Bug: "Intermittent timeout on large uploads"

Breakdown:
1. [S] Reproduce issue locally
2. [M] Profile upload handler
3. [S] Identify bottleneck
4. [M] Implement chunked upload
5. [M] Test with various file sizes
6. [S] Monitor production after deploy

Total: ~1.5 days
```

## Notes

- If you can't estimate, task is too vague
- Break down until tasks are < 1 day
- Include testing in estimates
- Don't forget documentation
- Add buffer for unknowns (20%)
