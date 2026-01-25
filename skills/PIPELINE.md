# Skills Pipeline

This document describes the horizontal data flow between skill categories.

## Pipeline Overview

```
Input (Task/Issue)
    |
    v
[analyze] -----> Requirements, Context
    |
    v
[planning] ----> Design, Work Breakdown
    |
    v
[execute] -----> Code Changes, Artifacts
    |
    v
[validate] ----> Test Results, Review Feedback
    |
    v
[integrate] ---> Commits, MR/PR, Reports
    |
    v
Output (Delivered Feature)
```

## Stage Definitions

### 1. Analyze (Input Processing)

**Purpose:** Understand the problem and gather context

**Skills:**
- `parse-requirement` - Extract requirements from issue/task
- `inspect-codebase` - Understand existing code structure
- `inspect-logs` - Analyze error logs and traces
- `assess-status` - Evaluate current state
- `evaluate-priority` - Determine task priority

**Inputs:**
- Task ID or Issue reference
- User requirements (text, images, links)
- Codebase access

**Outputs:**
- Parsed requirements (structured)
- Codebase context (relevant files, dependencies)
- Clarification questions (if needed)

### 2. Planning (Strategy Formation)

**Purpose:** Design the solution and plan the work

**Skills:**
- `design-solution` - Create technical design
- `breakdown-work` - Split into subtasks
- `estimate-effort` - Estimate time/complexity
- `allocate-resources` - Assign resources
- `schedule-timeline` - Create timeline

**Inputs:**
- Parsed requirements (from analyze)
- Codebase context (from analyze)
- Constraints (time, resources, dependencies)

**Outputs:**
- Design document
- Work breakdown structure
- Implementation plan

### 3. Execute (Implementation)

**Purpose:** Perform the actual work

**Skills:**
- `write-code` - Implement features
- `refactor-code` - Improve existing code
- `fix-defect` - Fix bugs
- `update-documentation` - Update docs
- `manage-issues` - Update issue status

**Inputs:**
- Design document (from planning)
- Implementation plan (from planning)
- Codebase access

**Outputs:**
- Code changes
- New/modified files
- Work-in-progress artifacts

### 4. Validate (Quality Assurance)

**Purpose:** Verify the work meets requirements

**Skills:**
- `run-tests` - Execute test suites
- `check-style` - Lint and format checks
- `review-code` - Code review
- `verify-requirements` - Check against requirements
- `analyze-impact` - Assess change impact
- `check-intent` - Verify agent mode compliance

**Inputs:**
- Code changes (from execute)
- Original requirements (from analyze)
- Test suites

**Outputs:**
- Test results
- Lint/style reports
- Review comments
- Verification report

### 5. Integrate (Delivery)

**Purpose:** Deliver the completed work

**Skills:**
- `commit-changes` - Create commits
- `create-merge-request` - Open MR/PR
- `merge-changes` - Merge to target branch
- `notify-stakeholders` - Send notifications
- `publish-report` - Generate reports

**Inputs:**
- Validated code changes (from validate)
- Verification report (from validate)
- Target branch information

**Outputs:**
- Git commits
- Merge request
- Published reports
- Notifications

## Data Flow Convention

### Current Implementation

Skills communicate through:

1. **Git state** - Working directory, staged changes
2. **Context files** - `.context/{task-id}/` directory
3. **Summary files** - `summary.yaml` for metadata
4. **Log files** - `.context/{task-id}/logs/`

### Planned Enhancement (RFC-007)

Intermediate Representation (IR) for explicit data passing:

```yaml
# .context/{task-id}/intermediate.yaml
version: "1.0"
task_id: TASK-123
current_stage: execute
stages:
  analyze:
    completed: true
    timestamp: "2026-01-25T10:00:00Z"
    outputs:
      requirements: [...]
      codebase_context: [...]
  planning:
    completed: true
    timestamp: "2026-01-25T10:30:00Z"
    outputs:
      design_decisions: [...]
      work_breakdown: [...]
  execute:
    completed: false
    outputs: null
```

## Workflow Composition

Workflows compose skills from different stages:

### Feature Development (Full Pipeline)

```
analyze/parse-requirement
    -> planning/design-solution
    -> planning/breakdown-work
    -> execute/write-code
    -> validate/run-tests
    -> validate/check-style
    -> validate/review-code
    -> integrate/commit-changes
    -> integrate/create-merge-request
```

### Bug Fix (Abbreviated Pipeline)

```
analyze/inspect-logs
    -> analyze/inspect-codebase
    -> execute/fix-defect
    -> validate/run-tests
    -> integrate/commit-changes
    -> integrate/create-merge-request
```

### Hotfix (Minimal Pipeline)

```
execute/fix-defect
    -> validate/run-tests (critical only)
    -> integrate/commit-changes
    -> integrate/create-merge-request
```

## Stage Transitions

### Valid Transitions

| From | To | Condition |
|------|----|-----------|
| analyze | planning | Requirements understood |
| planning | execute | Design approved |
| execute | validate | Code changes ready |
| validate | integrate | All checks pass |
| validate | execute | Fixes needed (loop back) |
| integrate | - | Delivery complete |

### Skipping Stages

Some stages can be skipped in specific scenarios:

- **Hotfix**: Skip planning (emergency)
- **Documentation**: Skip validate (no code changes)
- **Refactor**: Minimal analyze (scope known)

Always document why stages are skipped.

## Related Documents

- [ARCHITECTURE.md](../ARCHITECTURE.md) - Design philosophy
- [skills/README.md](README.md) - Skills overview
- [RFC-007](../docs/rfcs/007-architecture-improvements.md) - IR enhancement proposal
