# Merge Strategies

## Comparison

| Strategy | History | When |
|----------|---------|------|
| Squash | Clean | Features |
| Merge commit | Preserved | Releases |
| Rebase | Linear | Personal branches |
| Fast-forward | Minimal | Simple changes |

## Squash Merge

Combines all commits into one.

```
Before:
main:    A---B---C
              \
feat:          D---E---F

After:
main:    A---B---C---G  (G = D+E+F)
```

**Use for**: Feature branches

```bash
git checkout main
git merge --squash feat/PROJ-123
git commit -m "feat: implement uart driver"
```

**Pros**: Clean history
**Cons**: Loses detailed commits

## Merge Commit

Preserves all commits.

```
Before:
main:    A---B---C
              \
feat:          D---E---F

After:
main:    A---B---C-------M
              \         /
feat:          D---E---F
```

**Use for**: Releases, hotfixes

```bash
git merge feat/PROJ-123 --no-ff
```

**Pros**: Full history
**Cons**: Complex graph

## Rebase

Moves branch to latest main.

```
Before:
main:    A---B---C
              \
feat:          D---E

After:
main:    A---B---C---D'---E'
```

**Use for**: Personal branches only

```bash
git checkout feat/PROJ-123
git rebase main
git checkout main
git merge feat/PROJ-123
```

**Warning**: Don't rebase shared branches

## Recommended

| Branch | Strategy |
|--------|----------|
| feat/* | Squash |
| fix/* | Squash |
| hotfix/* | Merge commit |
| release/* | Merge commit |

## Conflict Resolution

```bash
# Conflict occurs
git merge feat/PROJ-123
# CONFLICT in file.py

# Check files
git status

# Fix manually
vim file.py
# Remove <<<<<<< ======= >>>>>>>

# Complete
git add file.py
git commit
```

## Prevention

- Rebase on main often
- Commit small and often
- Avoid editing same files
