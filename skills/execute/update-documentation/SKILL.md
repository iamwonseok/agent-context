---
name: update-documentation
category: execute
description: Update documentation to match code changes
version: 1.0.0
role: developer
inputs:
  - Code changes
  - Existing documentation
outputs:
  - Updated documentation
---

# Update Documentation

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

```python
def calculate_price(base_price: float, discount: float = 0) -> float:
    """Calculate final price after discount.
    
    Args:
        base_price: Original price before discount
        discount: Discount percentage (0-100). Default is 0.
    
    Returns:
        Final price after discount applied.
    
    Raises:
        ValueError: If discount is negative or > 100.
    
    Example:
        >>> calculate_price(100, 10)
        90.0
    """
```

#### CHANGELOG.md

```markdown
## [1.2.0] - 2026-01-23

### Added
- User role field in POST /api/users endpoint
- Role-based access control

### Changed
- Default timeout increased from 30s to 60s

### Fixed
- BUG-123: Division by zero in price calculation

### Deprecated
- `legacy_auth()` function, use `authenticate()` instead
```

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

### Example 1: New Feature

```markdown
# Before (README.md)
## Features
- User authentication
- File upload

# After (README.md)
## Features
- User authentication
- File upload
- **Role-based access control** (new in v1.2)
```

### Example 2: Configuration Change

```markdown
# config.yaml reference

# Before
timeout: 30  # Request timeout in seconds

# After
timeout: 60  # Request timeout in seconds (changed from 30 in v1.2)
max_retries: 3  # NEW: Number of retry attempts
```

### Example 3: Breaking Change

```markdown
## Migration Guide: v1.x to v2.0

### Breaking Changes

#### Authentication
The `legacy_auth()` function has been removed.

**Before (v1.x):**
```python
from auth import legacy_auth
token = legacy_auth(username, password)
```

**After (v2.0):**
```python
from auth import authenticate
token = authenticate(username, password)
```
```

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
