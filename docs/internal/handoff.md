# Handoff: Test Planning Framework Implementation

**Date**: 2026-01-26  
**Previous Agent**: Claude Sonnet 4.5  
**Next Branch**: `feat/test-planning-framework` (to be created)  
**Last Commit on main**: To be updated after merge

---

## 🔒 CRITICAL: Branch & Merge Policy

**DO NOT MERGE TO MAIN UNTIL ALL TASKS COMPLETE**

**Policy for this handoff:**
1. Next agent creates NEW branch: `feat/test-planning-framework`
2. Complete RFC-012 Tasks 1-4
3. Complete RFC-010 Checkpoints 2-4
4. **Only then**: Create single MR to main
5. **Do NOT** merge incrementally

**Merge criteria** (all required):
- [ ] RFC-012 Task 1: design-test-plan skill created
- [ ] RFC-012 Task 2: Meta-validation suite created
- [ ] RFC-012 Task 3: RFC template created
- [ ] RFC-012 Task 4: All RFCs have test plans
- [ ] RFC-010 Checkpoint 2: Test scenarios written
- [ ] RFC-010 Checkpoint 3: Examples validated
- [ ] RFC-010 Checkpoint 4: Documentation integrated
- [ ] All tests passing (unit + integration + meta)
- [ ] This handoff deleted

---

## ✅ Completed Work (On main after merge)

### Checkpoint 1: Foundation

**Branch**: `feat/structure-alignment-and-efficiency`

**Commits**:
1. `400e216` - Structure alignment (Phase 1-5)
2. `342fda1` - RFC-010 implementation plan
3. `a55d4dd` - RFC-011 + merge policy

**What was done:**
- ✅ Path unification: `plan/` → `planning/`
- ✅ Workflow paths: `workflows/developer/*.md`, `workflows/manager/*.md`
- ✅ Language policy: English for skills/workflows
- ✅ CI integration: Unit tests in pipeline
- ✅ New tests: Integration tests (14 checks)
- ✅ Documentation: 3 guides, 1 architecture doc
- ✅ RFC-010: Agent Efficiency & Best Practices
- ✅ RFC-011: Language Policy
- ✅ RFC-012: Test Planning Framework (document only)

**Test results**:
```
✅ Unit tests: 401/401 passed
✅ Integration tests: 14/14 passed
✅ Language policy: No violations
```

**Files created/modified**: 87 files, +6,743 lines

---

## 📋 Next Work: RFC-012 Implementation

### RFC-012: Test Planning Framework

**Goal**: Add systematic test planning to all levels of the framework

**Why this is needed:**
1. **No test planning skill**: Current planning skills don't include test design
2. **Inconsistent test plans**: RFCs vary from 0 to 9 test sections
3. **No meta-validation**: .cursorrules is not validated
4. **Missing bottom-up validation**: Need Skills → Workflows → .cursorrules validation chain

**Documents ready:**
- ✅ [`docs/rfcs/012-test-planning-framework.md`](docs/rfcs/012-test-planning-framework.md)
- ✅ This handoff with detailed task breakdown

---

## 🎯 Task Breakdown (RFC-012)

### Task 1: design-test-plan Skill (HIGH PRIORITY)

**Objective**: Create new planning skill for test design

**Files to create**:
```
skills/planning/design-test-plan/
├── SKILL.md                           (~150 lines)
└── templates/
    └── test-plan.md                   (~80 lines)
```

**SKILL.md content** (key sections):
```yaml
---
name: design-test-plan
category: planning
description: Design comprehensive test plan for implementation
version: 1.0.0
role: developer
inputs:
  - design/{feature}.md
  - plan/{feature}-plan.md
outputs:
  - tests/plan/{feature}-test-plan.md
---

## When to Use
- After design-solution complete
- Before implementation starts
- Complex features requiring multiple test levels
- When test strategy is unclear

## Workflow
1. Identify Test Levels (unit, integration, e2e, performance)
2. List Test Cases per Component
3. Define Coverage Targets (80% line, 70% branch)
4. Specify Test Tools (pytest, jest, etc.)
5. Create Test Plan Document (use template)

## Outputs
- tests/plan/{feature}-test-plan.md
```

**test-plan.md template** (key sections):
- Test Levels table
- Test Cases detail (input, expected output, implementation)
- Success Criteria checklist
- CI Integration section

**Files to update**:
1. [`skills/planning/README.md`](skills/planning/README.md):
   ```markdown
   | `design-test-plan` | Design test plan | Developer |
   ```

2. [`tests/unit/skills/test_skills.sh`](tests/unit/skills/test_skills.sh):
   ```bash
   SKILL_PATHS="
   ...
   planning/design-test-plan
   ...
   "
   ```

3. [`workflows/developer/feature.md`](workflows/developer/feature.md):
   ```yaml
   skills:
     - analyze/parse-requirement
     - planning/design-solution
     - planning/design-test-plan    # ← ADD HERE
     - execute/write-code
   ```

**Test validation**:
```bash
# Structure valid
bash tests/unit/skills/test_skills.sh | grep "planning/design-test-plan"
# Expected: (v) SKILL.md exists, all sections present

# Template exists
ls skills/planning/design-test-plan/templates/test-plan.md
# Expected: file exists

# Workflow references it
grep "planning/design-test-plan" workflows/developer/feature.md
# Expected: found
```

**Success criteria**:
- [ ] SKILL.md follows standard structure
- [ ] Template is complete and usable
- [ ] All structure tests pass
- [ ] Workflow integration works

**Estimated effort**: 2-3 hours  
**Context window**: ~25k tokens  
**Commit message**: "feat: add design-test-plan skill for systematic test planning"

---

### Task 2: Meta-Validation Suite (HIGH PRIORITY)

**Objective**: Implement bottom-up validation (Skills → Workflows → .cursorrules)

**Files to create**:
```
tests/meta/
├── README.md                          (~100 lines)
├── test_skills_structure.sh           (~50 lines)
├── test_workflows_structure.sh        (~150 lines)
├── test_cursorrules.sh                (~200 lines)
└── run-all-meta-tests.sh              (~80 lines)
```

**README.md** (methodology):
```markdown
# Meta-Validation Suite

## Purpose
Validate the framework itself (not user code).

## Levels
1. Skills: Validate all skills are well-formed
2. Workflows: Validate workflows reference valid skills
3. .cursorrules: Validate rules reference valid skills/workflows

## Usage
bash tests/meta/run-all-meta-tests.sh

## Design
Bottom-up validation: Level 1 must pass before Level 2 runs.
```

**test_skills_structure.sh** (wrapper):
```bash
#!/bin/bash
# Level 1: Skills Structure Validation

echo "Level 1: Skills Validation"
bash tests/unit/skills/test_skills.sh
```

**test_workflows_structure.sh** (new):
```bash
#!/bin/bash
# Level 2: Workflows Structure Validation

test_workflow_has_validation_skills() {
    # Developer workflows should have validate/run-tests
    for wf in workflows/developer/*.md; do
        if grep -q "validate/run-tests\|validate/check-style" "$wf"; then
            test_pass "Validation in: $(basename $wf)"
        else
            test_warn "No validation: $(basename $wf)"
        fi
    done
}

test_workflow_skill_references() {
    # Already validated in test_skills.sh
    # Just verify it runs
    echo "Skill reference validation done in Level 1"
}

test_workflow_test_plan_skill() {
    # Feature workflow should have design-test-plan
    if grep -q "planning/design-test-plan" workflows/developer/feature.md; then
        test_pass "feature.md has design-test-plan skill"
    else
        test_fail "feature.md missing design-test-plan skill"
    fi
}
```

**test_cursorrules.sh** (comprehensive):
```bash
#!/bin/bash
# Level 3: .cursorrules Validation

test_required_sections() {
    sections=(
        "Agent Behavior"
        "Language Policy"
        "Batch Operations"
        "Common Task Patterns"
        "Skills & Workflows"
        "Branch & Merge Policy"
    )
    
    for sec in "${sections[@]}"; do
        if grep -q "## $sec" .cursorrules; then
            test_pass "Section exists: $sec"
        else
            test_fail "Missing section: $sec"
        fi
    done
}

test_file_references() {
    # Extract markdown file references
    grep -o 'workflows/[^)]*\.md\|skills/[^)]*\.md\|docs/[^)]*\.md' .cursorrules | \
    sort -u | while read ref; do
        if [ -f "$ref" ]; then
            test_pass "Valid reference: $ref"
        else
            test_fail "Broken reference: $ref"
        fi
    done
}

test_skill_directory_references() {
    # Extract skill directory references (skills/category/name)
    grep -o 'skills/[a-z]*/[a-z-]*' .cursorrules | sort -u | while read skill; do
        if [ -d "$skill" ]; then
            test_pass "Skill exists: $skill"
        else
            test_fail "Skill not found: $skill"
        fi
    done
}

test_no_language_policy_conflicts() {
    # Ensure no contradictions in language policy
    local korean_allowed=$(grep -c "Korean.*allowed.*skills" .cursorrules || echo 0)
    local korean_forbidden=$(grep -c "Korean.*forbidden.*skills\|Korean.*Required.*skills" .cursorrules || echo 0)
    
    if [ "$korean_allowed" -gt 0 ] && [ "$korean_forbidden" -gt 0 ]; then
        # Check if they're in different contexts (docs vs skills)
        test_pass "Language policy has nuanced rules (expected)"
    fi
    
    # Should NOT have both "allowed" and "forbidden" for same file type
    # This is OK: "skills: forbidden" and "docs: allowed"
    # This is BAD: "skills: forbidden" and "skills: allowed"
}

test_workflow_path_references() {
    # Workflow paths should be workflows/developer/ or workflows/manager/
    # NOT workflows/{name}.md
    if grep -q 'workflows/[a-z-]*\.md' .cursorrules | grep -v 'developer\|manager'; then
        test_fail "Old workflow path format found"
    else
        test_pass "Workflow paths use developer/manager/ structure"
    fi
}
```

**run-all-meta-tests.sh** (orchestrator):
```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Meta-Validation Suite (Bottom-up)"
echo "=========================================="

echo ""
echo "[LEVEL 1] Skills Validation"
bash "${SCRIPT_DIR}/../unit/skills/test_skills.sh" || {
    echo "[FAIL] Level 1 failed. Cannot proceed to Level 2."
    exit 1
}

echo ""
echo "[LEVEL 2] Workflows Validation"
bash "${SCRIPT_DIR}/test_workflows_structure.sh" || {
    echo "[FAIL] Level 2 failed. Cannot proceed to Level 3."
    exit 1
}

echo ""
echo "[LEVEL 3] .cursorrules Validation"
bash "${SCRIPT_DIR}/test_cursorrules.sh" || {
    echo "[FAIL] Level 3 failed."
    exit 1
}

echo ""
echo "=========================================="
echo "All Meta-Validations Passed!"
echo "=========================================="
echo "Level 1: Skills structure validated"
echo "Level 2: Workflows structure validated"
echo "Level 3: .cursorrules validated"
echo ""
```

**Files to update**:

1. [`tests/docker-compose.test.yml`](tests/docker-compose.test.yml):
   ```yaml
   meta:
     image: agent-context-test:latest
     depends_on:
       test-base:
         condition: service_completed_successfully
     volumes:
       - meta-workspace:/workspace
     working_dir: /agent-context
     command: ["bash", "/agent-context/tests/meta/run-all-meta-tests.sh"]
   
   volumes:
     meta-workspace:  # Add to volumes section
   ```

2. [`.gitlab-ci.yml`](.gitlab-ci.yml):
   ```yaml
   # Add after test:workflow
   test:meta:
     stage: test
     image: docker:24
     services:
       - docker:24-dind
     variables:
       DOCKER_TLS_CERTDIR: ""
     script:
       - docker compose -f tests/docker-compose.test.yml build
       - docker compose -f tests/docker-compose.test.yml run meta
     rules:
       - if: $CI_PIPELINE_SOURCE == "merge_request_event"
         changes:
           - .cursorrules
           - skills/**/*
           - workflows/**/*
       - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
   ```

**Test validation**:
```bash
bash tests/meta/run-all-meta-tests.sh

# Expected output:
# [LEVEL 1] Skills Validation
#   → 402 checks passed (401 + design-test-plan)
# [LEVEL 2] Workflows Validation
#   → All workflows valid
# [LEVEL 3] .cursorrules Validation
#   → All sections exist, no broken references
# All Meta-Validations Passed!
```

**Success criteria**:
- [ ] All 5 meta-test scripts created
- [ ] Scripts are executable (chmod +x)
- [ ] Bottom-up flow works (Level 1 → 2 → 3)
- [ ] CI configured
- [ ] Docker compose service added

**Estimated effort**: 2 hours  
**Context window**: ~20k tokens  
**Commit message**: "test: add meta-validation suite for bottom-up framework validation"

---

### Task 3: RFC Template (MEDIUM PRIORITY)

**Objective**: Create reusable RFC template with mandatory Test Plan section

**Files to create**:
```
docs/rfcs/_template/
├── RFC-TEMPLATE.md                    (~300 lines)
└── README.md                          (~100 lines)
```

**RFC-TEMPLATE.md structure**:
```markdown
# RFC-XXX: {Title}

## Status: Draft|Active|Completed
## Author: {name}
## Created: {date}

---

## 1. Overview
{One paragraph summary}

## 2. Motivation
{Why is this needed}

## 3. Design
{How it works}

## 4. Implementation Plan

### 4.1 Phase 0: Foundation
### 4.2 Phase 1: Core
### 4.3 Phase N: ...

## 5. Test Plan (REQUIRED)

### 5.1 Test Strategy

**Scope**:
- What will be tested: {components}
- What won't be tested: {out of scope}

**Levels**:
- Unit tests: {description}
- Integration tests: {description}
- E2E tests: {description, if applicable}

### 5.2 Test Cases

#### Unit Tests

| Test ID | Component | Test Case | Expected Result |
|---------|-----------|-----------|-----------------|
| UT-1 | {Component} | {Input} → {Output} | Pass/Fail |
| UT-2 | {Component} | {Edge case} | Error handling |

#### Integration Tests

| Test ID | Scenario | Steps | Expected Result |
|---------|----------|-------|-----------------|
| IT-1 | {Workflow} | 1. {Step} 2. {Step} | Success |

### 5.3 Success Criteria

**Must have**:
- [ ] All critical tests pass
- [ ] Coverage >= {target}%
- [ ] No regressions

**Should have**:
- [ ] Performance benchmarks met
- [ ] Edge cases covered

### 5.4 Validation Checklist

- [ ] Test plan reviewed
- [ ] Tests implemented
- [ ] CI configured
- [ ] Tests documented
- [ ] All tests passing

## 6. Validation Strategy

### 6.1 Pre-implementation
- Design review
- Test plan review

### 6.2 During implementation
- TDD approach
- Continuous integration

### 6.3 Post-implementation
- Full test suite
- Documentation review

## 7. References
- Related RFCs
- Related skills
- Architecture docs

## 8. Change Log

| Date | Change | Author |
|------|--------|--------|
| {date} | Initial draft | {author} |

---

**Next Review**: {When to review}
```

**README.md** (usage guide):
```markdown
# RFC Template Usage

## Creating New RFC

1. Copy `RFC-TEMPLATE.md` to `docs/rfcs/XXX-title.md`
2. Replace all {placeholders}
3. Fill in ALL sections
4. **Test Plan section is REQUIRED** - do not skip
5. Submit for review

## Test Plan Requirements

Every RFC MUST include Section 5: Test Plan with:
- **Test Strategy**: Scope and levels
- **Test Cases**: Detailed test cases with expected results
- **Success Criteria**: Must have / Should have
- **Validation Checklist**: Implementation checklist

## Reference Examples

**Excellent**:
- RFC-010: 9 test sections, comprehensive scenarios
- RFC-011: 5 test sections, clear validation

**Minimal acceptable**:
- At minimum: Test Strategy + Success Criteria

## Template Sections

| Section | Required | Skippable Condition |
|---------|----------|---------------------|
| 1-4 | Yes | Never |
| 5. Test Plan | **Yes** | **Never** |
| 6. Validation Strategy | Recommended | Simple changes only |
| 7-8 | Yes | Never |
```

**Test validation**:
```bash
ls docs/rfcs/_template/
# Expected: RFC-TEMPLATE.md, README.md

grep -c "## .*Test Plan.*REQUIRED" docs/rfcs/_template/RFC-TEMPLATE.md
# Expected: >= 1

grep "Reference Examples" docs/rfcs/_template/README.md
# Expected: found (usage guide complete)
```

**Success criteria**:
- [ ] Template created with all sections
- [ ] Test Plan section marked REQUIRED
- [ ] Usage guide written
- [ ] Reference examples listed

**Estimated effort**: 1 hour  
**Context window**: ~10k tokens  
**Commit message**: "docs: add RFC template with mandatory Test Plan section"

---

### Task 4: Existing RFC Backfill (MEDIUM PRIORITY)

**Objective**: Add test plans to all existing RFCs

**RFCs to update** (priority order):

#### High Priority (Active RFCs)

**1. RFC-004: Agent Workflow System**
- Current: 6 test sections (partial)
- Add:
  ```markdown
  ## 8. Test Plan
  
  ### 8.1 Test Strategy
  - Phase 1 (State Visibility): Unit tests for state assertion
  - Phase 2 (Feedback Loops): Integration tests for knowledge caching
  
  ### 8.2 Test Cases
  #### Unit Tests
  | UT-1 | State assertion | Mode tracking | Correct mode recorded |
  | UT-2 | Self-correction | Mode violation | Warning issued |
  
  #### Integration Tests
  | IT-1 | Full workflow | State → Feedback → Execution | All phases work |
  
  ### 8.3 Success Criteria
  - [ ] State assertion working in all skills
  - [ ] Knowledge caching reduces token usage 20%
  - [ ] Self-correction catches 80% of violations
  ```

**2. RFC-005: Manual Fallback**
- Current: 5 test sections (partial)
- Add:
  ```markdown
  ## 7. Test Plan
  
  ### 7.1 Test Strategy
  - Validate manual steps produce same result as agent
  - Test CLI options (--only, --skip)
  
  ### 7.2 Test Cases
  #### Manual Validation
  | MV-1 | Manual commit | Follow guide | Same git log as agent |
  | MV-2 | Manual MR | Follow guide | Same MR as agent |
  
  ### 7.3 Success Criteria
  - [ ] Manual fallback works for all workflows
  - [ ] CLI options tested
  - [ ] Guide is clear (user feedback)
  ```

#### Medium Priority (Draft RFCs)

**3. RFC-006: Unified Platform Abstraction**
- Current: 0 test sections
- Add comprehensive test plan:
  ```markdown
  ## 7. Test Plan
  
  ### 7.1 Test Strategy
  - Unit test each provider (jira, gitlab, github)
  - Integration test provider switching
  
  ### 7.2 Test Cases
  | UT-1 | JIRA provider | Create issue | Issue created |
  | UT-2 | GitLab provider | Create MR | MR created |
  | IT-1 | Provider switch | JIRA → GitLab | Switch works |
  
  ### 7.3 Success Criteria
  - [ ] All providers tested
  - [ ] Provider interface consistent
  - [ ] Switching works seamlessly
  ```

**4. RFC-007: Architecture Improvements**
**5. RFC-008: Domain Extension**
**6. RFC-009: CLI Documentation**

Similar structure for each.

#### Low Priority

**7. RFC-002: Proposal**
- Reference document, minimal testing needed
- Add basic validation checklist

**Files to modify**:
- `docs/rfcs/002-proposal.md`
- `docs/rfcs/004-agent-workflow-system.md`
- `docs/rfcs/005-manual-fallback-improvement.md`
- `docs/rfcs/006-unified-platform-abstraction.md`
- `docs/rfcs/007-architecture-improvements.md`
- `docs/rfcs/008-domain-extension.md`
- `docs/rfcs/009-cli-documentation-policy.md`

**Test validation**:
```bash
# Check all RFCs have test plans
for rfc in docs/rfcs/00{2..9}-*.md docs/rfcs/01{0..2}-*.md; do
  if [ -f "$rfc" ]; then
    if grep -q "## .*Test Plan" "$rfc"; then
      echo "✅ $(basename $rfc)"
    else
      echo "❌ $(basename $rfc)"
    fi
  fi
done

# Expected: All ✅
```

**Success criteria**:
- [ ] All 10 RFCs have Test Plan sections
- [ ] Test plans follow template structure
- [ ] Test cases are specific and testable
- [ ] Success criteria are clear

**Estimated effort**: 2-3 hours  
**Context window**: ~30k tokens  
**Commit message**: "docs: backfill test plans in all existing RFCs (RFC-002~011)"

---

## 📋 Then: RFC-010 Checkpoints 2-4

**After RFC-012 Tasks 1-4 complete**, continue with RFC-010 implementation:

### Checkpoint 2: Test Scenarios

**Now uses design-test-plan skill!**

**Files to create**:
```
tests/efficiency/
├── README.md
├── scenario-01-path-update.md
├── scenario-02-language-cleanup.md
├── scenario-03-doc-creation.md
├── scenario-04-test-update.md
├── scenario-05-batch-files.md
├── success-criteria.yaml
└── measure-efficiency.sh
```

**Each scenario uses test plan template**:
1. Apply design-test-plan skill to the scenario
2. Generate test-plan.md
3. Execute and measure
4. Compare against baseline

**Effort**: 2-3 hours, ~20k tokens

---

### Checkpoint 3: Examples & Validation

**Files to create**:
```
docs/examples/efficiency/
├── README.md
├── pattern-1-path-update-example.md
├── pattern-2-language-cleanup-example.md
└── efficiency-comparison.md

docs/rfcs/
└── 010-case-study-phase-5.md
```

**Effort**: 3-4 hours, ~30k tokens

---

### Checkpoint 4: Documentation Integration

**Files to create/update**:
```
docs/guides/
└── efficiency-quick-reference.md

skills/_template/
└── SKILL.md (add efficiency hints)

README.md (add links)
docs/README.md (update index)
```

**Effort**: 2 hours, ~15k tokens

---

## 🧪 Comprehensive Test Plan

### Per-Task Validation

**After Task 1** (design-test-plan skill):
```bash
# 1. Structure validation
bash tests/unit/skills/test_skills.sh
# → planning/design-test-plan passes

# 2. Template exists
ls skills/planning/design-test-plan/templates/test-plan.md
# → exists

# 3. Workflow integration
grep "planning/design-test-plan" workflows/developer/feature.md
# → found

# 4. Total skills count
ls skills/*/SKILL.md | wc -l
# → 27 (was 26, added 1)
```

**After Task 2** (Meta-validation):
```bash
# 1. All scripts executable
ls -l tests/meta/*.sh | grep -v "^-rw"
# → All have -rwxr-xr-x

# 2. Bottom-up flow works
bash tests/meta/run-all-meta-tests.sh
# → Level 1, 2, 3 all pass

# 3. CI configured
grep "test:meta" .gitlab-ci.yml
# → job exists

# 4. Docker service
grep "meta:" tests/docker-compose.test.yml
# → service defined
```

**After Task 3** (RFC template):
```bash
# 1. Template exists
ls docs/rfcs/_template/
# → RFC-TEMPLATE.md, README.md

# 2. Test Plan marked required
grep "REQUIRED" docs/rfcs/_template/RFC-TEMPLATE.md
# → "## 5. Test Plan (REQUIRED)"

# 3. Usage guide complete
grep "Reference Examples" docs/rfcs/_template/README.md
# → found
```

**After Task 4** (RFC backfill):
```bash
# 1. All RFCs have test plans
for rfc in docs/rfcs/00{2..9}-*.md docs/rfcs/01{0..2}-*.md; do
  [ -f "$rfc" ] && grep -q "## .*Test Plan" "$rfc" && echo "✅" || echo "❌ $rfc"
done
# → All ✅

# 2. Test plan quality check
for rfc in docs/rfcs/*.md; do
  [ -f "$rfc" ] && grep -A 5 "## .*Test Plan" "$rfc" | grep -q "Success Criteria" && echo "✅ $(basename $rfc)" || continue
done
# → 10+ RFCs with success criteria
```

**After Checkpoint 2-4** (RFC-010):
```bash
# 1. Efficiency scenarios exist
ls tests/efficiency/scenario-*.md | wc -l
# → 5

# 2. Examples documented
ls docs/examples/efficiency/*.md | wc -l
# → 3+

# 3. Quick reference exists
ls docs/guides/efficiency-quick-reference.md
# → exists
```

### Final Validation (Before MR)

```bash
#!/bin/bash
# tests/final-validation.sh

echo "Running final validation..."

# 1. Meta-validation (all levels)
bash tests/meta/run-all-meta-tests.sh || exit 1

# 2. Unit tests (no regressions)
bash tests/unit/run-all-unit-tests.sh || exit 1

# 3. Integration tests
bash tests/integration/test_skills_tools.sh || exit 1

# 4. RFC test plan coverage
missing=$(grep -L "## .*Test Plan" docs/rfcs/0*.md | grep -v "future-work")
if [ -n "$missing" ]; then
    echo "❌ RFCs missing test plans:"
    echo "$missing"
    exit 1
fi

# 5. No broken references in .cursorrules
bash tests/meta/test_cursorrules.sh | grep "Broken reference" && exit 1

# 6. Skill count correct
skill_count=$(ls skills/*/SKILL.md | wc -l)
if [ "$skill_count" -lt 27 ]; then
    echo "❌ Expected 27+ skills, found $skill_count"
    exit 1
fi

echo "✅ All final validations passed!"
echo "Ready to create MR."
```

---

## 📊 Context Window Budget

### Updated Budget

| Phase | Tasks | Tokens | % of 1M | Status |
|-------|-------|--------|---------|--------|
| **Current** | Docs only | ~10k | 1% | ✅ Done |
| **Task 1** | Skill creation | ~25k | 2.5% | Next |
| **Task 2** | Meta-tests | ~20k | 2% | Next |
| **Task 3** | RFC template | ~10k | 1% | Next |
| **Task 4** | RFC backfill | ~30k | 3% | Next |
| **Checkpoint 2** | Scenarios | ~20k | 2% | Next |
| **Checkpoint 3** | Examples | ~30k | 3% | Next |
| **Checkpoint 4** | Integration | ~15k | 1.5% | Next |
| **Total** | **All work** | **~160k** | **16%** | Safe ✅ |

**Safety margin**: 840k tokens (84%)

**Checkpoint safety**:
- Each task: 10-30k tokens (safe for single session)
- Total: 160k tokens (can complete in 2-3 sessions if needed)
- Handoff can be created between any tasks

---

## 🚀 Next Agent Start Here

### Step 1: Take Over

```bash
# 1. Read this handoff completely
cat docs/internal/handoff.md

# 2. Verify current state
git status
git branch

# 3. Check main branch is up to date
git checkout main
git pull

# 4. Create new feature branch
git checkout -b feat/test-planning-framework

# 5. Verify tests pass on main
bash tests/unit/run-all-unit-tests.sh
bash tests/integration/test_skills_tools.sh

# Expected: All passing
```

### Step 2: Start Task 1

```bash
# 1. Create directory
mkdir -p skills/planning/design-test-plan/templates

# 2. Create SKILL.md
# Use skills/_template/SKILL.md as base
# Fill in content per this handoff (Task 1 section)

# 3. Create test-plan.md template
# Use skills/planning/design-solution/templates/implementation-plan.md as reference

# 4. Update related files
# - skills/planning/README.md
# - tests/unit/skills/test_skills.sh
# - workflows/developer/feature.md

# 5. Test
bash tests/unit/skills/test_skills.sh

# 6. Commit
git add skills/planning/design-test-plan/
git commit -m "feat: add design-test-plan skill for systematic test planning"
```

### Step 3: Continue Tasks 2-4

Follow task breakdown in this handoff.

Commit after each task:
- Task 1 → Commit
- Task 2 → Commit
- Task 3 → Commit
- Task 4 → Commit

### Step 4: Checkpoints 2-4

After Task 4 complete, proceed to RFC-010 Checkpoints.

### Step 5: Final MR

**Only after ALL work complete**:
```bash
# Final validation
bash tests/final-validation.sh

# Push branch
git push -u origin feat/test-planning-framework

# Create MR (via UI or CLI)
# Title: "feat: test planning framework and efficiency patterns"
# Description: Link to RFC-012 and RFC-010

# DO NOT merge yet - wait for review
```

---

## 📁 File Organization

### New Directories

```
skills/planning/design-test-plan/     ← Task 1
├── SKILL.md
└── templates/
    └── test-plan.md

tests/meta/                            ← Task 2
├── README.md
├── test_skills_structure.sh
├── test_workflows_structure.sh
├── test_cursorrules.sh
└── run-all-meta-tests.sh

docs/rfcs/_template/                   ← Task 3
├── RFC-TEMPLATE.md
└── README.md

tests/efficiency/                      ← Checkpoint 2
├── README.md
├── scenario-*.md (5 files)
├── success-criteria.yaml
└── measure-efficiency.sh

docs/examples/efficiency/              ← Checkpoint 3
├── README.md
└── pattern-*.md (2+ files)
```

### Modified Files

```
skills/planning/README.md              ← Task 1
tests/unit/skills/test_skills.sh       ← Task 1
workflows/developer/feature.md         ← Task 1

tests/docker-compose.test.yml          ← Task 2
.gitlab-ci.yml                         ← Task 2

docs/rfcs/002-proposal.md              ← Task 4
docs/rfcs/004-agent-workflow-system.md ← Task 4
docs/rfcs/005-manual-fallback-improvement.md ← Task 4
docs/rfcs/006-unified-platform-abstraction.md ← Task 4
docs/rfcs/007-architecture-improvements.md ← Task 4
docs/rfcs/008-domain-extension.md     ← Task 4
docs/rfcs/009-cli-documentation-policy.md ← Task 4

skills/_template/SKILL.md              ← Checkpoint 4
README.md                              ← Checkpoint 4
docs/README.md                         ← Checkpoint 4
```

---

## 🎯 Success Metrics

### Quantitative

| Metric | Current | Target | How to Measure |
|--------|---------|--------|----------------|
| Skills with test guidance | 0 | 1 | design-test-plan exists |
| RFCs with test plans | 3/11 (27%) | 11/11 (100%) | grep "Test Plan" |
| Validation levels | 1 | 3 | Meta-suite passes |
| Test automation | Partial | Complete | CI runs meta-tests |

### Qualitative

- [ ] Agents can design test plans systematically
- [ ] RFCs have consistent test planning
- [ ] Framework validates itself (meta-validation)
- [ ] Bottom-up validation prevents inconsistencies

---

## ⚠️ Important Notes

### Complexity Budget Check

Per [ARCHITECTURE.md](../../ARCHITECTURE.md):

| Component | Limit | Planned | Status |
|-----------|-------|---------|--------|
| design-test-plan skill | 200 lines | ~150 lines | ✅ Within budget |
| Meta-test scripts | 300 lines ea | ~200 lines max | ✅ Within budget |
| RFC template | N/A | ~300 lines | ✅ Reasonable |

**Total new code**: ~1,200 lines (documentation + tests)

### Philosophy Alignment

**Simplicity Over Completeness**: ✅
- No complex test frameworks, just bash scripts
- Template provides structure, not enforcement
- Meta-validation is optional (can skip in emergencies)

**User Autonomy**: ✅
- Test plans are guidelines, not mandates
- Can skip design-test-plan for simple features
- --force escape hatch for CI

**Feedback Over Enforcement**: ✅
- Meta-tests warn before failing
- RFC template suggests, doesn't mandate
- Progressive rollout (warnings first)

---

## 🔄 Handoff Protocol

### After Taking Over

1. ✅ Read this handoff completely
2. ✅ Check main branch state:
   ```bash
   git checkout main
   git log -3
   bash tests/unit/run-all-unit-tests.sh
   ```
3. ✅ Create feature branch:
   ```bash
   git checkout -b feat/test-planning-framework
   ```
4. ✅ Start Task 1

### During Work

- **Commit after each task** (incremental progress)
- **Run tests before each commit**
- **Update this handoff if context window grows** (create new handoff)
- **Do NOT merge to main until all tasks complete**

### Before Finishing

- [ ] All tasks complete (1-4)
- [ ] All checkpoints complete (2-4)
- [ ] All tests passing
- [ ] Final validation script passes
- [ ] Delete this handoff:
  ```bash
  git rm docs/internal/handoff.md
  git commit -m "chore: remove handoff after completion"
  ```
- [ ] Create MR (do NOT merge directly)

---

## 🔗 Quick Links

### Must Read Before Starting

- [RFC-012](../rfcs/012-test-planning-framework.md): Full RFC for this work
- [RFC-010](../rfcs/010-agent-efficiency-best-practices.md): Reference for excellent test plans
- [ARCHITECTURE.md](../../ARCHITECTURE.md): Design philosophy and complexity budget
- [.cursorrules](../../.cursorrules): Current rules (will be validated)

### Reference Documents

- [skills/_template/SKILL.md](../../skills/_template/SKILL.md): Skill template
- [skills/planning/design-solution](../../skills/planning/design-solution/SKILL.md): Similar planning skill
- [tests/unit/skills/test_skills.sh](../../tests/unit/skills/test_skills.sh): Existing validation

---

## 📝 Task Checklist (Quick Reference)

```
RFC-012 Implementation:
├── [ ] Task 1: design-test-plan skill (2-3h)
│   ├── [ ] Create SKILL.md
│   ├── [ ] Create test-plan.md template
│   ├── [ ] Update skills/planning/README.md
│   ├── [ ] Update tests/unit/skills/test_skills.sh
│   ├── [ ] Update workflows/developer/feature.md
│   └── [ ] Test & commit
│
├── [ ] Task 2: Meta-validation suite (2h)
│   ├── [ ] Create tests/meta/ directory
│   ├── [ ] Create 5 test scripts
│   ├── [ ] Update docker-compose
│   ├── [ ] Update .gitlab-ci.yml
│   └── [ ] Test & commit
│
├── [ ] Task 3: RFC template (1h)
│   ├── [ ] Create RFC-TEMPLATE.md
│   ├── [ ] Create README.md
│   └── [ ] Test & commit
│
└── [ ] Task 4: RFC backfill (2-3h)
    ├── [ ] Update RFC-002~009 (7 files)
    ├── [ ] Verify all have test plans
    └── [ ] Test & commit

RFC-010 Checkpoints:
├── [ ] Checkpoint 2: Test scenarios (2-3h)
├── [ ] Checkpoint 3: Examples (3-4h)
└── [ ] Checkpoint 4: Integration (2h)

Final:
└── [ ] Create MR (do NOT merge without review)
```

---

**Delete this handoff after taking over and completing all work.**

**Next Agent: Start with Task 1 (design-test-plan skill)**
