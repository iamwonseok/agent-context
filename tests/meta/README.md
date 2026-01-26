# Meta-Validation Suite

## Purpose

Validate the framework itself (not user code).

This suite ensures consistency between:
- Skills structure and content
- Workflows referencing valid skills
- `.cursorrules` referencing valid skills/workflows

## Validation Levels

| Level | What | Script |
|-------|------|--------|
| 1 | Skills structure | `test_skills_structure.sh` |
| 2 | Workflows structure | `test_workflows_structure.sh` |
| 3 | .cursorrules validity | `test_cursorrules.sh` |

## Usage

```bash
# Run all meta-validation (recommended)
bash tests/meta/run-all-meta-tests.sh

# Run individual level
bash tests/meta/test_skills_structure.sh
bash tests/meta/test_workflows_structure.sh
bash tests/meta/test_cursorrules.sh
```

## Design

**Bottom-up validation**: Level 1 must pass before Level 2 runs.

```
Level 1: Skills
    |
    v
Level 2: Workflows (reference skills)
    |
    v
Level 3: .cursorrules (reference skills + workflows)
```

## Integration

### CI Pipeline

```yaml
test:meta:
  stage: test
  script:
    - bash tests/meta/run-all-meta-tests.sh
  rules:
    - changes:
        - .cursorrules
        - skills/**/*
        - workflows/**/*
```

### Docker

```bash
docker compose -f tests/docker-compose.test.yml run meta
```

## When to Run

- Before merging changes to skills/workflows
- After modifying `.cursorrules`
- In CI pipeline for relevant changes

## Success Criteria

- All 3 levels pass
- No broken references
- Consistent structure across all skills/workflows
