# Scenario 02: Language Cleanup

## Context

Removing Korean characters from skills/workflows (per RFC-011 Language Policy).

## Trigger

- Language policy enforcement
- Internationalization
- AI instruction optimization

## Inefficient Approach

```
1. Read skills/analyze/parse-requirement/SKILL.md
2. Find Korean text
3. Translate to English
4. Write file
5. Read skills/planning/design-solution/SKILL.md
6. Find Korean text
... (repeat for each file)
```

**Problems:**
- Individual file processing
- Multiple read operations
- No pattern grouping

## Efficient Approach

```bash
# 1. Find ALL violations at once
LC_ALL=C grep -r -l $'[\xEA-\xED]' skills/ workflows/

# 2. Show ALL Korean lines grouped by file
for file in <files>; do
  echo "=== $file ==="
  LC_ALL=C grep -n $'[\xEA-\xED]' "$file"
done

# 3. Batch translate (group similar content)
# - All headers together
# - All descriptions together
# - All examples together

# 4. Verify once
bash tests/unit/skills/test_skills.sh | tail -20
```

## Test Plan

### Setup

Create test files with Korean text in various locations.

### Execution

1. Run efficient approach
2. Count tool calls
3. Verify all Korean removed

### Success Criteria

| Metric | Target | Red Flag |
|--------|--------|----------|
| Find operations | 1 | > 3 |
| Batch translations | Per pattern type | Per file |
| Verification runs | 1 | > 2 |

## Example

**Before:**
```
skills/analyze/parse-requirement/SKILL.md:
## 사용 시점 (Korean)
- 요구사항이 불명확할 때

skills/planning/design-solution/SKILL.md:
## 언제 사용 (Korean)
- 설계 문서가 필요할 때
```

**Command:**
```bash
LC_ALL=C grep -r -l $'[\xEA-\xED]' skills/
```

**After:**
```
skills/analyze/parse-requirement/SKILL.md:
## When to Use
- When requirements are unclear

skills/planning/design-solution/SKILL.md:
## When to Use
- When design document is needed
```

## Validation

```bash
# Verify no Korean remains
LC_ALL=C grep -r $'[\xEA-\xED]' skills/ workflows/
# Expected: no output

# Run language policy test
bash tests/unit/skills/test_skills.sh | grep "Korean"
# Expected: "No Korean characters"
```
