# Validate Skills

**Purpose**: Verify quality before delivery.

## Skills

| Skill | Description | Role |
|-------|-------------|------|
| `run-tests` | Run tests and check coverage | Developer |
| `check-style` | Check code style and lint | Developer |
| `review-code` | Review code quality | Developer |
| `verify-requirements` | Verify implementation matches intent | Developer |
| `analyze-impact` | Analyze change impact | Manager |

## When to Use

- After code changes
- Before committing
- Before submitting MR
- Reviewing others' code

## Typical Flow

```
Code → check-style → Style OK
Code → run-tests → Tests Pass
Code → review-code → Quality OK
Implementation → verify-requirements → Requirements Met
```
