# RFC-007: Architecture Pattern Improvements

## Status: Draft
## Author: wonseok
## Created: 2026-01-25

---

## 1. Overview

This RFC documents architecture improvements based on external feedback analysis.
It strengthens the existing Horizontal (Pipeline) and Vertical (Abstraction) patterns.

### 1.1 Background

Four feedback documents analyzed the project's architecture:
- agent-context-architecture-feedback.md
- claude-architecture-feedback.md
- gemini-3-flash-architecture-feedback.md
- gpt-5.2-architecture-feedback.md

**Common findings:**
- Horizontal pattern (Skills Pipeline) is well-designed
- Vertical pattern (Platform Abstraction) follows good practices
- Improvement needed: Make implicit patterns explicit

### 1.2 Goals

1. **Horizontal enhancement**: Introduce IR for explicit stage-to-stage data flow
2. **Vertical enhancement**: Define interface contracts for providers
3. **Documentation**: Make architecture patterns explicit in code and docs

---

## 2. Horizontal Pattern Enhancement

### 2.1 Problem

Current skills communicate implicitly:
- No standard format for inter-skill data
- Debugging pipeline issues is difficult
- Testing individual skills requires full context

### 2.2 Solution: Intermediate Representation (IR)

Introduce `.context/{task}/intermediate.yaml` as the standard data format:

```yaml
# .context/TASK-123/intermediate.yaml
version: "1.0"
task_id: TASK-123
current_stage: execute
timestamp: "2026-01-25T10:30:00Z"

stages:
  analyze:
    completed: true
    timestamp: "2026-01-25T10:00:00Z"
    outputs:
      requirements:
        - id: REQ-1
          description: "Implement login feature"
          priority: high
      codebase_context:
        relevant_files:
          - src/auth/login.ts
          - src/auth/session.ts
      clarifications:
        - question: "OAuth provider?"
          answer: "Google only"

  planning:
    completed: true
    timestamp: "2026-01-25T10:15:00Z"
    outputs:
      design_decisions:
        - decision: "Use JWT for session"
          rationale: "Stateless, scalable"
      work_breakdown:
        - id: WB-1
          description: "Create auth module"
          estimate: "4h"

  execute:
    completed: false
    outputs: null

  validate:
    completed: false
    outputs: null

  integrate:
    completed: false
    outputs: null
```

### 2.3 Skill Template Update

Add inputs/outputs fields to `skills/_template/SKILL.md`:

```yaml
---
name: skill-name
category: analyze|planning|execute|validate|integrate
inputs:
  - intermediate.yaml:stages.analyze.outputs.requirements
outputs:
  - intermediate.yaml:stages.planning.outputs.design_decisions
---
```

### 2.4 Implementation

**New files:**
- `tools/agent/lib/pipeline.sh` - Pipeline state management

**Functions:**
```bash
# pipeline.sh
pipeline_init()           # Create intermediate.yaml
pipeline_get_stage()      # Get current stage
pipeline_set_output()     # Set stage output
pipeline_get_input()      # Get input from previous stage
pipeline_complete_stage() # Mark stage complete
```

---

## 3. Vertical Pattern Enhancement

### 3.1 Problem

Current providers lack explicit interface contracts:
- Required functions are not documented
- Missing functions fail silently
- New provider implementation lacks guidance

### 3.2 Solution: Interface Specification

Create `tools/pm/lib/interface.sh` with explicit contracts:

```bash
#!/bin/bash
# interface.sh - Platform Provider Interface Definition

# =============================================================================
# REQUIRED FUNCTIONS - All providers MUST implement these
# =============================================================================

# Issue operations (required)
# issue_create(title, description, [labels], [assignee]) -> issue_id
# issue_list([state], [assignee], [labels]) -> issue_list_json
# issue_view(issue_id) -> issue_detail_json
# issue_update(issue_id, [title], [description], [state]) -> success
# issue_close(issue_id) -> success

# Review operations (required for VCS providers)
# review_create(source_branch, target_branch, title, description) -> review_id
# review_list([state]) -> review_list_json
# review_view(review_id) -> review_detail_json
# review_merge(review_id) -> success

# =============================================================================
# OPTIONAL FUNCTIONS - Providers MAY implement these
# =============================================================================

# Milestone operations (optional)
# milestone_create(title, [due_date], [description]) -> milestone_id
# milestone_list([state]) -> milestone_list_json
# milestone_close(milestone_id) -> success

# Label operations (optional)
# label_create(name, [color], [description]) -> label_id
# label_list() -> label_list_json
# label_delete(name) -> success

# =============================================================================
# DEFAULT IMPLEMENTATIONS
# =============================================================================

not_implemented() {
    local func_name="$1"
    local provider="$2"
    echo "[ERROR] Function '$func_name' not implemented for provider '$provider'" >&2
    echo "[HINT] This feature may not be available on your platform" >&2
    return 1
}

# =============================================================================
# INTERFACE COMPLIANCE CHECK
# =============================================================================

check_interface_compliance() {
    local provider="$1"
    local required_funcs=(
        "issue_create" "issue_list" "issue_view" "issue_close"
    )
    local missing=()
    
    for func in "${required_funcs[@]}"; do
        if ! type "${provider}_${func}" &>/dev/null; then
            missing+=("$func")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "[WARN] Provider '$provider' missing required functions: ${missing[*]}" >&2
        return 1
    fi
    return 0
}
```

### 3.3 Provider Template

Update provider template with interface compliance:

```bash
#!/bin/bash
# template_provider.sh - Template for new providers

# Source interface definition
source "$(dirname "$0")/interface.sh"

# =============================================================================
# REQUIRED: Issue Operations
# =============================================================================

template_issue_create() {
    local title="$1"
    local description="$2"
    # Implementation here
}

template_issue_list() {
    local state="${1:-all}"
    # Implementation here
}

template_issue_view() {
    local issue_id="$1"
    # Implementation here
}

template_issue_close() {
    local issue_id="$1"
    # Implementation here
}

# =============================================================================
# OPTIONAL: Milestone Operations (use not_implemented if not supported)
# =============================================================================

template_milestone_create() {
    not_implemented "milestone_create" "template"
}
```

---

## 4. Implementation Plan

### Phase 1: Documentation (Immediate)

- [x] ARCHITECTURE.md - Add pattern sections
- [x] skills/PIPELINE.md - Document data flow
- [x] RFC-007 - This document

### Phase 2: Horizontal Enhancement

**Files:**
| File | Action |
|------|--------|
| `tools/agent/lib/pipeline.sh` | New - Pipeline functions |
| `skills/_template/SKILL.md` | Update - Add inputs/outputs |

**Estimated effort:** 2-3 days

### Phase 3: Vertical Enhancement

**Files:**
| File | Action |
|------|--------|
| `tools/pm/lib/interface.sh` | New - Interface definition |
| `tools/pm/lib/jira.sh` | Update - Add compliance check |
| `tools/pm/lib/gitlab.sh` | Update - Add compliance check |
| `tools/pm/lib/github.sh` | Update - Add compliance check |

**Estimated effort:** 2-3 days

---

## 5. Philosophy Compliance

| Enhancement | Principle | Compliance |
|-------------|-----------|------------|
| IR introduction | Artifacts as State | Yes - File-based state |
| Interface spec | Simplicity | Yes - Explicit > Implicit |
| Provider contracts | Composability | Yes - Plugin structure |

---

## 6. Future Considerations

Documented in [future-work.md](future-work.md):

- **FW-6**: VCS Abstraction Layer
- **FW-7**: Skill Executor Abstraction
- **FW-8**: AOP-style Aspects

---

## 7. References

- [ARCHITECTURE.md](../../ARCHITECTURE.md) - Design philosophy
- [skills/PIPELINE.md](../../skills/PIPELINE.md) - Pipeline documentation
- [RFC-006](006-unified-platform-abstraction.md) - Platform abstraction
- [RFC-004](004-agent-workflow-system.md) - Workflow system v2.0

---

## Test Plan

### Test Strategy

**Scope:**
- Horizontal: IR (Intermediate Representation) for pipeline state
- Vertical: Interface contracts for providers

**Levels:**
| Level | Description | Tools |
|-------|-------------|-------|
| Unit | pipeline.sh functions | bash assertions |
| Integration | Full pipeline flow | Docker |
| Contract | Provider compliance | check_interface_compliance() |

### Test Cases

#### IR Tests

| ID | Component | Test Case | Expected |
|----|-----------|-----------|----------|
| IR-1 | pipeline.sh | pipeline_init() | Creates intermediate.yaml |
| IR-2 | pipeline.sh | pipeline_set_output() | Updates stage outputs |
| IR-3 | pipeline.sh | pipeline_get_input() | Reads previous stage output |
| IR-4 | pipeline.sh | pipeline_complete_stage() | Marks stage complete |

#### Interface Tests

| ID | Component | Test Case | Expected |
|----|-----------|-----------|----------|
| IF-1 | interface.sh | check_interface_compliance(jira) | Returns success |
| IF-2 | interface.sh | check_interface_compliance(gitlab) | Returns success |
| IF-3 | interface.sh | check_interface_compliance(github) | Returns success |
| IF-4 | interface.sh | Missing function | Returns warning |

### Success Criteria

**Must Have:**
- [ ] IR file created/updated correctly
- [ ] All providers pass compliance check
- [ ] Pipeline state persists between skills

**Should Have:**
- [ ] Clear error messages for missing functions
- [ ] Documentation updated

### Validation Checklist

- [ ] Unit tests pass
- [ ] Provider compliance verified
- [ ] Philosophy compliance verified

---

## 8. Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-01-25 | Initial draft | wonseok |
