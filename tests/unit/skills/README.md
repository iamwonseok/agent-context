# Skills Tests

Automated verification of skills framework integrity.

## Quick Start

```bash
# Run all tests
./tests/unit/skills/test_skills.sh

# Expected output
All tests passed!
```

## Run Tests

```bash
cd /path/to/agent-context

# Option 1: Direct execution
./tests/unit/skills/test_skills.sh

# Option 2: From anywhere
bash tests/unit/skills/test_skills.sh
```

## Test Output

```
==========================================
Skills Framework Test Suite
==========================================
Skills: /path/to/agent-context/skills

--- SKILL.md Structure ---

  [analyze/parse-requirement]
  (v) SKILL.md exists
  (v) YAML frontmatter
  (v) Has: name:
  (v) Has: description:
  (v) Has: version:
  (v) Has: inputs:
  (v) Has: outputs:
  (v) Has: ## When to Use
  (v) Has: ## Prerequisites
  (v) Has: ## Workflow
  (v) Has: ## Outputs

  [plan/design-solution]
  ...

--- Template ---
  (v) _template/SKILL.md exists
  (v) Template has YAML

--- README ---
  (v) README.md exists
  (v) Mentions: analyze
  (v) Mentions: plan
  ...

--- Scripts ---

  [integrate/create-merge-request/scripts/pre-merge-check.sh]
  (v) Executable
  (v) Has shebang
  (v) Valid syntax
  ...

--- Workflows ---
  (v) workflows/README.md exists
  (v) Workflow: feature.md
  (v) Workflow: bug-fix.md
  (v) Workflow: hotfix.md
  (v) Workflow: refactor.md

==========================================
Results
==========================================
Total:  129
Passed: 129
Failed: 0

All tests passed!
```

## Test Categories

### 1. SKILL.md Structure

Verifies each skill directory:

| Check | Description |
|-------|-------------|
| SKILL.md exists | File present |
| YAML frontmatter | Starts with `---` |
| name: | Has name field |
| description: | Has description field |
| version: | Has version field |
| inputs: | Has inputs field |
| outputs: | Has outputs field |
| ## When to Use | Section exists |
| ## Prerequisites | Section exists |
| ## Workflow | Section exists |
| ## Outputs | Section exists |

### 2. Template

Verifies `_template/SKILL.md`:
- File exists
- Has YAML frontmatter

### 3. README

Verifies `skills/README.md`:
- File exists
- All skills mentioned

### 4. References

Verifies `references/` directories:
- All `.md` files exist

### 5. Scripts

Verifies `scripts/` directories:
- Executable permission (`chmod +x`)
- Bash shebang (`#!/bin/bash`)
- Valid syntax (`bash -n`)

### 6. Workflows

Verifies `workflows/` directory:
- README.md exists
- feature.md exists
- bug-fix.md exists
- hotfix.md exists
- refactor.md exists

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All tests passed |
| 1 | Some tests failed |

## CI/CD Integration

```yaml
# .gitlab-ci.yml
test:skills:
  stage: test
  script:
    - ./tests/unit/skills/test_skills.sh
  allow_failure: false
```

## Adding New Skills

When adding a new skill:

1. Choose category (analyze, plan, execute, validate, integrate)

2. Copy template:
   ```bash
   cp -r skills/_template skills/category/new-skill
   ```

3. Edit SKILL.md:
   ```bash
   vim skills/category/new-skill/SKILL.md
   ```

4. Update category README:
   ```bash
   vim skills/category/README.md
   ```

5. Run tests:
   ```bash
   ./tests/unit/skills/test_skills.sh
   ```

6. Verify:
   ```
   (v) Has: ## When to Use
   (v) Has: ## Prerequisites
   ...
   ```

## Troubleshooting

### Test Failed: SKILL.md missing

```
(x) SKILL.md missing
```

**Fix**: Create SKILL.md in the skill directory.

### Test Failed: Missing field

```
(x) Missing: inputs:
```

**Fix**: Add the field to YAML frontmatter:
```yaml
---
name: skill-name
inputs:
  - Input 1
---
```

### Test Failed: Not executable

```
(x) Not executable
```

**Fix**: Add execute permission:
```bash
chmod +x skills/*/scripts/*.sh
```

### Test Failed: Missing shebang

```
(x) Missing shebang
```

**Fix**: Add to first line of script:
```bash
#!/bin/bash
```

## Extending Tests

Edit `test_skills.sh` to add new checks:

```bash
# Add new test function
test_custom() {
    section "Custom Tests"
    
    if [ -f "some_file" ]; then
        test_pass "File exists"
    else
        test_fail "File missing"
    fi
}

# Call in main()
main() {
    ...
    test_custom
    ...
}
```
