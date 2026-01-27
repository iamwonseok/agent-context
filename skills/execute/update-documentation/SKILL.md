---
name: update-documentation
category: execute
description: Update documentation to match code changes
version: 1.0.0
role: developer
mode: implementation
cursor_mode: agent
inputs:
  - Code changes
  - Existing documentation
outputs:
  - Updated documentation
---

# Update Documentation

## State Assertion

**Mode**: implementation
**Cursor Mode**: agent
**Purpose**: Update documentation to reflect code changes
**Boundaries**:
- Will: Update README, API docs, comments, examples
- Will NOT: Change code functionality, create new features, or delete documentation without reason

## When to Use

- After adding new features
- After changing APIs
- After fixing bugs (if user-facing)
- After configuration changes
- When documentation is outdated

## Prerequisites

- [ ] Code changes complete
- [ ] Understanding of what changed
- [ ] Access to documentation

## Workflow

### 1. Identify What Needs Update

| Code Change | Documentation Update |
|-------------|---------------------|
| New API endpoint | API docs, examples |
| New feature | User guide, README |
| Configuration change | Setup guide, config reference |
| Bug fix | Changelog, known issues |
| Breaking change | Migration guide, changelog |

### 2. Locate Documentation Files

Common locations:

```
project/
├── README.md           # Project overview
├── docs/
│   ├── api/            # API reference
│   ├── guides/         # How-to guides
│   └── reference/      # Technical reference
├── CHANGELOG.md        # Version history
└── src/
    └── module.py       # Docstrings
```

### 3. Update Relevant Sections

#### README.md

```markdown
## Installation
(update if dependencies changed)

## Quick Start
(update if basic usage changed)

## Configuration
(update if new config options added)
```

#### API Documentation

```markdown
### POST /api/users

Create a new user.

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| email | string | Yes | User email |
| name | string | Yes | User name |
| role | string | No | User role (default: "user") |  # NEW

**Response:**
```json
{
  "id": 123,
  "email": "user@example.com",
  "name": "John",
  "role": "user"  // NEW
}
```
```

#### Code Docstrings

Include: Args, Returns, Raises, Example in docstrings.

#### CHANGELOG.md

Use sections: Added, Changed, Fixed, Deprecated for each version.

### 4. Verify Documentation

- [ ] Code and docs match
- [ ] Examples work
- [ ] Links are valid
- [ ] No typos

### 5. Test Examples

```bash
# Run documentation tests if available
pytest --doctest-modules src/

# Or manually verify examples work
python -c "from module import calculate_price; print(calculate_price(100, 10))"
```

## Outputs

| Output | Format | Description |
|--------|--------|-------------|
| Updated docs | Markdown/RST | Changed documentation |
| Changelog entry | Markdown | Version history update |
| Updated docstrings | Python/etc | Code-level docs |

## Documentation Types

| Type | Purpose | Update Frequency |
|------|---------|-----------------|
| README | First impression | Major changes |
| API Reference | Endpoint details | Every API change |
| User Guide | How-to instructions | Feature changes |
| Changelog | Version history | Every release |
| Docstrings | Function details | Code changes |
| Comments | Implementation notes | As needed |

## Examples

| Scenario | Update |
|----------|--------|
| New Feature | Add to Features list with version note |
| Config Change | Update value + add comment with version |
| Breaking Change | Migration guide with before/after code |

## Documentation Checklist

- [ ] README up to date
- [ ] API docs match implementation
- [ ] Examples are tested
- [ ] Changelog updated
- [ ] Docstrings complete
- [ ] Links work
- [ ] No outdated information

## Notes

- Documentation is part of the feature
- Write docs as you code, not after
- Keep examples simple and runnable
- Use consistent formatting
- Review docs in PR review
