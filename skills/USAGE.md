# How to Use Skills & Workflows

Guide for AI agents to use skills and workflows effectively.

## Quick Start

1. User requests a task
2. Choose workflow based on task type
3. Follow skill sequence in workflow
4. Check quality gates between skills

## Choose Workflow

```
User request
    |
    v
New feature? --Yes--> workflows/feature.md
    |
    No
    |
    v
Bug fix? --Yes--> Production issue?
    |                  |
    No            Yes: workflows/hotfix.md
    |              No: workflows/bug-fix.md
    v
Code improvement? --Yes--> workflows/refactor.md
```

## Workflow Execution

### 1. Read Workflow File

```
Read workflows/{workflow}.md
- Check skills: field in YAML
- Understand flow diagram
- Note quality gates
```

### 2. Execute Skills in Order

For each skill in workflow:

```
1. Read skills/{skill}/SKILL.md
2. Check prerequisites
3. Follow workflow steps
4. Produce outputs
5. Pass quality gate (if any)
6. Move to next skill
```

### 3. Quality Gates

| After | Check | Criteria |
|-------|-------|----------|
| check-style | Lint | 0 violations |
| run-tests | Test | All pass, >=80% coverage |
| review-code | Review | 0 critical issues |

If gate fails: fix issues, re-run skill, check again.

---

## Example: Feature Development

**User**: "Add UART driver for debug console"

### Step 1: Choose Workflow

New feature -> `workflows/feature.md`

### Step 2: Parse Requirement

```
Read: skills/analyze/parse-requirement/SKILL.md

AI: "I have some questions about the UART driver:
     1. Baud rate? (115200, 921600, configurable)
     2. Buffer type? (ring buffer, DMA)
     3. Interrupt or polling?"

User: "115200, ring buffer, interrupt-driven"

AI: Writing design document...
    Output: design/uart-driver.md
```

### Step 3: Design Solution

```
Read: skills/planning/design-solution/SKILL.md

AI: Breaking into tasks...
    - Task 1: UART register definitions
    - Task 2: Ring buffer implementation
    - Task 3: Interrupt handler
    - Task 4: Public API (init, read, write)
    
    Output: plan/uart-driver-plan.md
```

### Step 4: Implementation Loop

For each task, repeat:

```
[write-code]
    Write failing test
    Implement code
    Test passes

[check-style]
    Run linter
    Fix violations
    Gate: 0 violations

[run-tests]
    Run all tests
    Check coverage
    Gate: all pass, >=80%

[review-code]
    Self-review code
    Check memory safety, timing
    Gate: 0 critical

[commit-changes]
    git add .
    git commit -m "feat(uart): add ring buffer"
```

### Step 5: Create Merge Request

```
Read: skills/integrate/create-merge-request/SKILL.md

AI: Running pre-merge checks...
    All tests pass
    Lint clean
    
    git push -u origin feat/PROJ-123-uart-driver
    Creating MR...
    
    Done: MR !123 created
```

---

## Example: Bug Fix

**User**: "DMA transfer timeout on high-speed data"

### Step 1: Choose Workflow

Bug fix, not production -> `workflows/bug-fix.md`

### Step 2: Write Code (TDD)

```
// Write failing test (reproduces bug)
void test_dma_transfer_large_buffer(void) {
    uint8_t buf[4096];
    int result = dma_transfer(buf, sizeof(buf));
    TEST_ASSERT_EQUAL(DMA_OK, result);
}

// Run: FAIL (reproduces bug)

// Fix code: increase timeout for large transfers
int dma_transfer(uint8_t *buf, size_t len) {
    uint32_t timeout = DMA_BASE_TIMEOUT + (len / 1024) * DMA_TIMEOUT_PER_KB;
    ...
}

// Run: PASS
```

### Step 3: Check Style -> Run Tests -> Review -> Commit

```
[check-style]    make lint -> Pass
[run-tests]      make test -> All pass
[review-code]    No critical issues
[commit-changes] git commit -m "fix(dma): adjust timeout for large transfers"
```

### Step 4: Finish

```
git push -u origin fix/PROJ-456-dma-timeout
gh pr create --title "fix(dma): adjust timeout for large transfers"
```

---

## Example: Hotfix

**User**: "Board stuck in watchdog reset loop!"

### Step 1: Choose Workflow

Production issue -> `workflows/hotfix.md`

### Step 2: Quick Fix

```
[write-code]     Quick test + fix
[check-style]    Quick check
[run-tests]      Run critical tests only
[commit-changes] git commit -m "fix: watchdog feed in main loop"
```

### Step 3: Fast Finish

```
git push -u origin hotfix/1.2.3
gh pr create --title "fix: watchdog feed in main loop" --label urgent
# Fast-track merge
```

---

## Tips

### Skip Skills When Appropriate

- **Skip parse-requirement**: Requirements already clear
- **Skip design-solution**: Simple 1-2 file change
- **Skip review-code**: Trivial fix (typo, formatting)

### Combine Small Changes

Multiple small fixes -> single commit is OK:

```
git commit -m "fix: typos and formatting"
```

### Ask When Uncertain

If workflow choice is unclear, ask:

```
AI: "This could be a bug fix or a new feature. 
     Which workflow should I follow?"
```

---

## Reference

- Skills: `skills/*/SKILL.md`
- Workflows: `workflows/*.md`
- Quality gates: Each workflow's "Quality Gates" section
