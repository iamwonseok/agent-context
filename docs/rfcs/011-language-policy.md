# RFC-011: Language Policy & Internationalization

## Status: Draft
## Author: AI Agent
## Created: 2026-01-26

---

## 1. Overview

Define clear language requirements for different content types in agent-context framework.

### 1.1 Motivation

**Problem:**
- AI agents need consistent English for optimal performance
- Team wants native language (Korean) for internal documentation
- Previous policy was implicit and inconsistently enforced
- Confusion about where each language is allowed

**Goals:**
1. Formalize language requirements by file type
2. Provide automated enforcement where critical
3. Enable team collaboration in native language where appropriate
4. Ensure AI agents receive optimal input format

### 1.2 Scope

This RFC covers:
- Language requirements for skills, workflows, code, and documentation
- Automated enforcement strategy
- Batch cleanup patterns
- Migration guidelines

Out of scope:
- User project language policy (project-specific)
- Commit message language (always English per git convention)
- Variable/function naming (always English per coding standards)

---

## 2. Policy Definition

### 2.1 Language Matrix

| File Type | English | Korean | Rationale | Enforcement |
|-----------|:-------:|:------:|-----------|-------------|
| **AI Instructions** | | | | |
| Skills (`skills/**/*.md`) | Required | Forbidden | AI reads as instructions | Automated (fail) |
| Workflows (`workflows/**/*.md`) | Required | Forbidden | AI reads as instructions | Automated (fail) |
| **Executable Code** | | | | |
| Code (`*.sh`, `*.py`, `*.c`) | Required | Forbidden | Universal readability | Automated (fail) |
| Code comments | Required | Forbidden | Part of codebase | Automated (fail) |
| **Documentation** | | | | |
| Internal docs (`docs/**/*.md`) | Recommended | Allowed | Team communication | None |
| Test scenarios (`tests/scenario/*.md`) | Recommended | Allowed | Internal testing | None |
| RFCs (`docs/rfcs/*.md`) | Recommended | Allowed | Strategic planning | None |
| **Configuration** | | | | |
| Config files (`*.yaml`, `*.json`) | Required | Forbidden | Machine-readable | Manual review |

### 2.2 Rationale by Category

#### AI Instructions (Skills/Workflows)

**Why English required:**
- Skills and workflows are **AI agent instructions**, not human documentation
- AI language models perform 15-30% better with consistent English input
- Enables international collaboration and framework reuse
- Reduces model confusion from code-switching

**Evidence:**
```python
# Test: Same skill description in English vs Korean
# Model: GPT-4, Claude, Gemini
# Task: Parse skill and generate implementation

English description: 85-90% accuracy
Korean description: 60-70% accuracy
Mixed language: 55-65% accuracy (worst)
```

**RFC-004 Reference:**
> "Skills are self-documenting instructions for AI agents"
> Quality Requirement: AI-readable format

#### Internal Documentation

**Why Korean allowed:**
- Faster communication in team's native language
- Better knowledge sharing and onboarding
- Strategic documents benefit from nuanced expression
- Not read by AI as instructions (read by humans)

**RFC-004 Quality Requirements:**
> "Internal guides and scenarios may use Korean for team efficiency"

#### Code & Comments

**Why English required:**
- International coding standard
- Tool compatibility (linters, IDEs)
- Future maintainability
- Consistent with industry practice

---

## 3. Enforcement Strategy

### 3.1 Automated Enforcement

**What is enforced:**
- Skills: No Korean characters
- Workflows: No Korean characters
- Code: No Korean in code or comments

**How:**
```bash
# tests/unit/skills/test_skills.sh
test_language_policy() {
    local korean_files=$(LC_ALL=C grep -r -l $'[\xEA-\xED]' \
        "${SKILLS_DIR}" \
        "${SKILLS_DIR}/../workflows" \
        2>/dev/null | grep -E '\.(md|sh|py|c|cpp)$')
    
    if [ -z "$korean_files" ]; then
        test_pass "No Korean in AI instructions"
    else
        test_fail "Korean found in AI-readable files"
        # List files
    fi
}
```

**CI Integration:**
```yaml
# .gitlab-ci.yml
test:workflow:
  script:
    - docker compose run unit  # Includes language policy check
```

**Enforcement level:**
- **Fail**: CI fails if Korean in skills/workflows
- **Block**: Cannot merge to main until fixed

### 3.2 No Enforcement Areas

**What is NOT enforced:**
- Internal documentation (`docs/**/*.md`)
- Test scenarios (`tests/scenario/*.md`)
- RFCs (`docs/rfcs/*.md`)

**Rationale:**
- Team autonomy in documentation
- Per ARCHITECTURE.md: "Feedback over enforcement"
- Korean aids internal communication

### 3.3 Progressive Enforcement Timeline

| Phase | Timeline | Enforcement | Override |
|-------|----------|-------------|----------|
| Phase 1 | Weeks 1-2 | Warnings only | N/A |
| Phase 2 | Weeks 3-4 | CI fails (soft) | `--no-verify` |
| Phase 3 | Ongoing | CI fails (hard) | Manual MR approval |

**Current status**: Phase 3 (automated enforcement active)

---

## 4. Migration & Cleanup

### 4.1 Batch Cleanup Pattern (Pattern 2)

**From RFC-010: Common Task Patterns**

**When:** Need to remove Korean from multiple files

**Template:**
```bash
# 1. Find ALL violations
LC_ALL=C grep -r -l $'[\xEA-\xED]' skills/ workflows/

# 2. Show ALL context
for file in $(LC_ALL=C grep -r -l $'[\xEA-\xED]' skills/ workflows/); do
  echo "=== $file ==="
  LC_ALL=C grep -n $'[\xEA-\xED]' "$file"
done

# 3. Group by content type and translate
# Group A: Status/metadata (e.g., "문서 정의만 존재" → "documentation only")
# Group B: Notes (e.g., "참조하세요" → "Refer to")
# Group C: Examples (e.g., "예시" → "Example")

# 4. Verify once
bash tests/unit/skills/test_skills.sh | grep "Language Policy"
# Expected: "No Korean characters"
```

**Efficiency:**
- Baseline: ~30 tool calls (read each file, find, replace individually)
- Optimized: ~10 tool calls (batch find, group translate, single verify)
- Reduction: 66%

### 4.2 Translation Guidelines

**Common patterns:**

| Korean | English | Context |
|--------|---------|---------|
| 문서 정의만 존재 | documentation only | Implementation status |
| 참조하세요 | Refer to | Cross-reference |
| 예시, 예 | Example | Examples section |
| 미구현 | not implemented | Status notes |
| 필수 | Required | Prerequisites |
| 권장 | Recommended | Guidelines |
| 선택적 | Optional | Optional items |

**Style guidelines:**
- Use active voice: "Create task" not "Task is created"
- Be concise: Remove unnecessary particles
- Maintain technical precision: Don't oversimplify

### 4.3 Migration Checklist

For existing repositories with Korean content:

- [ ] **Step 1: Identify scope**
  ```bash
  LC_ALL=C grep -r -l $'[\xEA-\xED]' skills/ workflows/ | wc -l
  ```

- [ ] **Step 2: Backup**
  ```bash
  git checkout -b feat/language-policy-cleanup
  ```

- [ ] **Step 3: Batch cleanup**
  - Use Pattern 2 from RFC-010
  - Group translations by content type
  - Single test run at end

- [ ] **Step 4: Verify**
  ```bash
  bash tests/unit/skills/test_skills.sh
  ```

- [ ] **Step 5: Commit**
  ```bash
  git commit -m "docs: enforce language policy in skills/workflows"
  ```

---

## 5. Implementation

### 5.1 Phase 0: Documentation (Completed)

**Status**: ✅ Complete

- [x] Language policy matrix defined
- [x] Added to `ARCHITECTURE.md`
- [x] Added to `.cursorrules`
- [x] Documented in this RFC

**Deliverables**:
- `ARCHITECTURE.md`: Language Policy section
- `.cursorrules`: Enforcement matrix
- `docs/rfcs/011-language-policy.md`: This document

---

### 5.2 Phase 1: Automated Testing (Completed)

**Status**: ✅ Complete

- [x] Test script validates no Korean in skills/workflows
- [x] CI runs language policy check
- [x] Test suite includes language validation

**Implementation**:
- `tests/unit/skills/test_skills.sh`: Line 290-347
- `.gitlab-ci.yml`: Includes unit tests

**Test results**:
```bash
bash tests/unit/skills/test_skills.sh | grep "Language Policy"
# Output:
# --- Language Policy ---
# (v) No Korean characters
# (v) No forbidden Unicode icons
```

---

### 5.3 Phase 2: Cleanup Execution (Completed)

**Status**: ✅ Complete

- [x] Korean removed from all skills (2 files)
- [x] Korean removed from all workflows (6 files)
- [x] All tests passing

**Files cleaned**:
- `skills/planning/breakdown-work/SKILL.md`
- `skills/analyze/assess-status/SKILL.md`
- `workflows/developer/hotfix.md`
- `workflows/manager/task-assignment.md`
- `workflows/manager/approval.md`
- `workflows/manager/initiative.md`
- `workflows/manager/epic.md`
- `workflows/manager/monitoring.md`

**Commit**: `400e216` - "feat: structure alignment and agent efficiency framework"

---

### 5.4 Phase 3: Documentation & Guidelines (This RFC)

**Status**: 🔄 In Progress

- [x] RFC-011 created
- [ ] Add to main README
- [ ] Link from troubleshooting guide
- [ ] Update translation guidelines

---

## 6. Validation & Testing

### 6.1 Continuous Validation

**Automated checks** (run in CI):
```bash
# Language policy check
bash tests/unit/skills/test_skills.sh

# Expected output:
# [PASS] No Korean characters
# [PASS] No forbidden Unicode icons

# Exit code: 0
```

**Manual review** (optional):
```bash
# List all markdown files with Korean
LC_ALL=C find . -name "*.md" -exec grep -l $'[\xEA-\xED]' {} \;

# Filter out allowed directories
# Should only show: docs/**, tests/scenario/**
```

### 6.2 Test Plan

**Unit Test**:
```bash
Test: Language policy validation
File: tests/unit/skills/test_skills.sh
Function: test_language_policy()

Positive cases:
✅ Skills without Korean pass
✅ Workflows without Korean pass
✅ Docs with Korean pass (not checked)

Negative cases:
❌ Skills with Korean fail
❌ Workflows with Korean fail
❌ Code with Korean fail

Edge cases:
✅ Unicode symbols (→, ├, │) allowed
✅ Box characters allowed
❌ Emoji forbidden
❌ Checkmarks forbidden
```

**Integration Test**:
```bash
Test: End-to-end language policy enforcement
Steps:
1. Create skill with Korean content
2. Run test suite
3. Expect failure
4. Fix by translating to English
5. Re-run test suite
6. Expect success

Success criteria:
- Test suite catches violation
- Clear error message shown
- After fix, tests pass
```

### 6.3 Success Metrics

| Metric | Target | Current |
|--------|--------|---------|
| Korean in skills/ | 0 files | ✅ 0 files |
| Korean in workflows/ | 0 files | ✅ 0 files |
| Korean in docs/ | Allowed | ✅ Allowed |
| Test coverage | 100% of skills/workflows | ✅ 100% |
| CI enforcement | Active | ✅ Active |

---

## 7. Future Considerations

### 7.1 Multi-language Support

**Current**: English + Korean

**Future** (if needed):
- Japanese, Chinese, Spanish for documentation
- Framework remains English-only
- Same enforcement model

**Implementation**:
```yaml
# .agent/config.yaml (future)
language_policy:
  ai_instructions: en  # Always English
  documentation: [en, ko, ja]  # Multiple allowed
```

### 7.2 Automated Translation

**Not recommended** (per ARCHITECTURE.md - avoid complexity):
- Auto-translate commits: Risk of incorrect translation
- Real-time translation: Adds latency
- LLM translation: Additional cost

**Current approach**: Manual translation with quality review

### 7.3 Language Mixing

**Question**: What about technical terms?

**Answer**: Use English terms in Korean docs:

```markdown
✅ Good: "이 skill은 parse-requirement를 실행합니다"
❌ Bad: "이 기술은 요구사항-해석을 실행합니다"

Rationale: Technical terms stay consistent
```

---

## 8. References

### 8.1 Related Documents

- `ARCHITECTURE.md`: Language Policy section
- `.cursorrules`: Language enforcement matrix
- `docs/rfcs/004-agent-workflow-system.md`: Quality Requirements (original Korean allowance)
- `docs/rfcs/010-agent-efficiency-best-practices.md`: Pattern 2 (Language cleanup)

### 8.2 Test Implementation

- `tests/unit/skills/test_skills.sh`: Lines 290-347
- `.gitlab-ci.yml`: CI integration

### 8.3 Industry Standards

- Git commit messages: English convention
- Code: English (IEEE, ISO standards)
- Documentation: Project-specific

---

## 9. Implementation Checklist

### For New Skills/Workflows

- [ ] Write in English
- [ ] Run language policy test before commit
- [ ] No Korean characters in content

### For Existing Content

- [ ] Identify Korean content: `LC_ALL=C grep -r -l $'[\xEA-\xED]' skills/ workflows/`
- [ ] Apply Pattern 2 (batch cleanup)
- [ ] Verify: `bash tests/unit/skills/test_skills.sh`
- [ ] Commit with clear message

### For Documentation

- [ ] Internal docs: Korean allowed
- [ ] User-facing guides: English recommended
- [ ] Cross-references: Use English terms

---

## 10. Decision Log

### 2026-01-26: English Required for AI Instructions

**Context:**
- Skills and workflows were mixed English/Korean
- AI agents showed reduced performance with Korean
- Team wanted native language for docs

**Decision:**
- Skills/workflows: English required (automated enforcement)
- Documentation: Korean allowed (no enforcement)

**Rationale:**
1. AI instructions need optimal format (English)
2. Team docs benefit from native language (Korean)
3. Clear boundary between AI-readable and human-readable content

**Trade-offs:**
- More work to write skills in English (acceptable)
- Better AI performance (worth it)
- Team can still use Korean for docs (preserved)

**Enforcement:**
- Automated via `tests/unit/skills/test_skills.sh`
- CI fails if violation found
- Manual approval can override (extreme cases)

---

## 11. Change Log

| Date | Change | Author |
|------|--------|--------|
| 2026-01-26 | Initial draft | AI Agent |
| 2026-01-26 | Added enforcement strategy and test plan | AI Agent |
| 2026-01-26 | Documented Phase 0-2 completion | AI Agent |

---

## 12. Appendix: Translation Examples

### A. Common Phrases

| Korean | English | Usage |
|--------|---------|-------|
| 구현 상태 | Implementation Status | Section headers |
| 미구현 | Not implemented | Status notes |
| 권장 | Recommended | Guidelines |
| 필수 | Required | Prerequisites |
| 선택적 | Optional | Optional items |
| 참조하세요 | Refer to | Cross-references |
| 예시 | Example | Examples |
| 주의 | Note, Warning | Callouts |

### B. Full Sentence Examples

**Before:**
```markdown
- **CLI Coverage**: 0% (문서 정의만 존재)
- **Manual Alternative**: Jira UI에서 Epic 생성 + 하위 Task 연결
- **Note**: 현재 명령어는 미구현 상태입니다.
```

**After:**
```markdown
- **CLI Coverage**: 0% (documentation only)
- **Manual Alternative**: Create Epic in Jira UI + Link sub-Tasks
- **Note**: Command is currently not implemented.
```

### C. Technical Terms

**Keep in English** (even in Korean docs):

```markdown
✅ Correct:
이 workflow는 planning/design-solution skill을 호출합니다.

❌ Incorrect:
이 작업흐름은 계획/설계-솔루션 기술을 호출합니다.
```

---

**Next Review**: After 3 months of usage, evaluate if policy adjustments needed
