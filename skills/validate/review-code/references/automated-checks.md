# Automated Checks

## Tools

### Static Analysis

**Python**:
| Tool | Purpose |
|------|---------|
| flake8 | Style |
| pylint | All |
| mypy | Types |
| bandit | Security |

**JavaScript**:
| Tool | Purpose |
|------|---------|
| ESLint | Style |
| TypeScript | Types |

### Complexity

```bash
# Python
radon cc src/ -a -nc
```

| Score | Meaning |
|-------|---------|
| 1-10 | OK |
| 11-20 | Refactor |
| 21+ | Split |

### Duplication

```bash
jscpd src/ --min-lines 5
```

### Security

```bash
# Python
bandit -r src/
safety check

# JavaScript
npm audit
```

### Coverage

```bash
pytest --cov=src --cov-fail-under=80
```

## CI Integration

```yaml
# GitLab CI
review:
  script:
    - flake8 src/
    - mypy src/
    - bandit -r src/
    - radon cc src/ -a -nc
    - safety check || true
```

## Config

### flake8
```ini
[flake8]
max-line-length = 100
max-complexity = 10
ignore = E203,W503
```

### ESLint
```json
{
  "rules": {
    "complexity": ["error", 10],
    "max-lines-per-function": ["warn", 50]
  }
}
```

## Auto Fix

```bash
# Python
black src/
isort src/

# JavaScript
eslint --fix src/
prettier --write src/
```

## Thresholds

| Metric | Target |
|--------|--------|
| Line coverage | 80% |
| Branch coverage | 70% |
| Complexity | <=10 |
| Function lines | <=50 |
| File lines | <=500 |
| Duplication | <=5% |
