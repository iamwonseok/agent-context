# Scenario 03: Documentation Creation

## Context

Creating multiple related documentation files (guides, troubleshooting, references).

## Trigger

- New feature documentation
- Guide creation
- Architecture documentation

## Inefficient Approach

```
1. Create guide.md
2. Check existing docs structure
3. Create troubleshooting.md
4. Check existing docs structure again
5. Create reference.md
6. Update README with links
... (interleaved with checks)
```

**Problems:**
- Repeated structure checks
- Non-parallel creation
- Multiple README updates

## Efficient Approach

```bash
# 1. Check structure once
ls docs/guides/ docs/architecture/

# 2. Create ALL related docs at once (parallel):
# - Main guide (troubleshooting.md)
# - Examples (platform-setup-examples.md)
# - Architecture (skills-tools-mapping.md)

# 3. Update README once with all links
```

## Test Plan

### Setup

Identify documentation set to create.

### Execution

1. Single structure check
2. Parallel document creation
3. Single index update

### Success Criteria

| Metric | Target | Red Flag |
|--------|--------|----------|
| Structure checks | 1 | > 3 |
| Doc creations | Parallel | Sequential |
| Index updates | 1 | > 2 |

## Example

**Documentation Set:**
- docs/guides/efficiency-quick-reference.md
- docs/guides/troubleshooting-efficiency.md
- docs/architecture/efficiency-patterns.md

**Efficient Approach:**

```bash
# 1. Check structure (1 call)
ls docs/guides/ docs/architecture/

# 2. Create all docs (parallel tool calls in one message)
# - Write efficiency-quick-reference.md
# - Write troubleshooting-efficiency.md
# - Write efficiency-patterns.md

# 3. Update index (1 call)
# Add links to docs/README.md
```

## Validation

```bash
# Verify all docs created
ls docs/guides/efficiency*.md docs/architecture/efficiency*.md
# Expected: All files exist

# Verify links in README
grep "efficiency" docs/README.md
# Expected: All links present
```
