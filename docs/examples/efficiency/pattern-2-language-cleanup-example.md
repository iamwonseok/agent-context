# Example: Language Cleanup Pattern

## Scenario

Removing Korean text from skills/ and workflows/ per RFC-011 Language Policy.

## Context

- 10 files contain Korean text
- Must translate to English
- Need to maintain consistency across translations

## Inefficient Approach (What NOT to Do)

```
Step 1: Read skills/analyze/parse-requirement/SKILL.md
Step 2: Find Korean text on line 15
Step 3: Translate to English
Step 4: Run test for this file
Step 5: Read skills/planning/design-solution/SKILL.md
Step 6: Find Korean text on line 22
Step 7: Translate to English
Step 8: Run test for this file
... (repeat 10 times)
```

**Result:**
- 40+ tool calls
- 20+ minutes
- Inconsistent translations

## Efficient Approach (Best Practice)

### Step 1: Find ALL violations at once (1 tool call)

```bash
LC_ALL=C grep -r -l $'[\xEA-\xED]' skills/ workflows/
```

**Output:**
```
skills/analyze/parse-requirement/SKILL.md
skills/planning/design-solution/SKILL.md
skills/execute/write-code/SKILL.md
workflows/developer/feature.md
workflows/developer/bug-fix.md
... (10 files)
```

### Step 2: Show ALL Korean text with context (1 tool call)

```bash
for file in $(LC_ALL=C grep -r -l $'[\xEA-\xED]' skills/ workflows/); do
  echo "=== $file ==="
  LC_ALL=C grep -n $'[\xEA-\xED]' "$file" | head -5
done
```

**Output:**
```
=== skills/analyze/parse-requirement/SKILL.md ===
15:## 사용 시점
16:- 요구사항이 불명확할 때
22:## 출력
=== skills/planning/design-solution/SKILL.md ===
18:## 언제 사용
19:- 설계가 필요할 때
...
```

### Step 3: Group by pattern type

**Pattern A: Section headers (## 사용 시점, ## 언제 사용)**
- All should become: "## When to Use"

**Pattern B: List items (- 요구사항이...)**
- Translate individually but batch per file type

**Pattern C: Output sections (## 출력)**
- All should become: "## Outputs"

### Step 4: Batch translate per pattern (3-4 tool calls)

**Batch 1: Replace common headers**
```
"## 사용 시점" → "## When to Use"
"## 언제 사용" → "## When to Use"
"## 출력" → "## Outputs"
```

**Batch 2: Translate skill descriptions (grouped)**

**Batch 3: Translate workflow descriptions (grouped)**

### Step 5: Verify once (1 tool call)

```bash
# Confirm no Korean remains
LC_ALL=C grep -r $'[\xEA-\xED]' skills/ workflows/
# Expected: no output

# Run language policy test
bash tests/unit/skills/test_skills.sh | grep -A 2 "Language Policy"
# Expected: "No Korean characters"
```

## Comparison

| Metric | Inefficient | Efficient | Savings |
|--------|-------------|-----------|---------|
| Find operations | 10 | 1 | 90% |
| Read operations | 10 | 2 | 80% |
| Translations | Per line | Per pattern | 50% |
| Test runs | 10 | 1 | 90% |
| Total tool calls | 40+ | 8 | 80% |

## Key Insights

1. **Find all violations first**: Single grep command shows entire scope
2. **Group by pattern**: Common translations (headers) done once
3. **Consistency**: Same pattern = same translation
4. **Verify once**: Language policy test at the end

## Translation Consistency Guide

| Korean | English |
|--------|---------|
| 사용 시점 | When to Use |
| 언제 사용 | When to Use |
| 출력 | Outputs |
| 전제 조건 | Prerequisites |
| 워크플로우 | Workflow |
| 예제 | Examples |
| 참고 | Notes |

## When to Use

- Language policy enforcement
- Internationalization
- Documentation cleanup
- Consistent terminology updates

## Checklist

- [ ] Found all violations with single grep
- [ ] Grouped similar translations together
- [ ] Used consistent translations for same patterns
- [ ] Ran verification only once at the end
- [ ] Confirmed no violations remain
