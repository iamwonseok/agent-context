# Branch Naming

## Format

```
{type}/{issue}-{description}
```

| Part | Required | Example |
|------|----------|---------|
| type | Yes | feat, fix |
| issue | Recommended | PROJ-123 |
| description | Yes | uart-driver |

## Types

| Type | Use | Example |
|------|-----|---------|
| feat | New feature | `feat/PROJ-123-uart-driver` |
| fix | Bug fix | `fix/PROJ-456-null-error` |
| hotfix | Emergency | `hotfix/1.2.3-security` |
| refactor | Refactor | `refactor/PROJ-789-db` |
| perf | Performance | `perf/PROJ-101-query` |
| docs | Docs | `docs/PROJ-102-readme` |
| test | Tests | `test/PROJ-103-unit` |
| chore | Config | `chore/PROJ-104-ci` |

## Good Examples

```bash
feat/PROJ-123-user-auth
fix/PROJ-456-dma-timeout
hotfix/1.2.3-critical-fix
```

## Bad Examples

```bash
feature/PROJ-123-UserAuth  # camelCase
PROJ-123-auth              # no type
feat/user-auth             # no issue
feat/PROJ-123              # no description
```

## Special Cases

### Hotfix
```bash
hotfix/{version}-{desc}
hotfix/1.2.3-security-fix
```

### Release
```bash
release/{version}
release/1.3.0
```

## Validate with Hook

```bash
#!/bin/bash
# .git/hooks/pre-push

branch=$(git rev-parse --abbrev-ref HEAD)
pattern="^(feat|fix|hotfix|refactor)/.+"

if ! [[ $branch =~ $pattern ]]; then
    echo "Bad branch name: $branch"
    exit 1
fi
```
