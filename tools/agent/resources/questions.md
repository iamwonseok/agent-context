# Questions & Clarifications
# Task: {TASK_ID}
# Last Updated: {TIMESTAMP}

## Purpose

This file collects questions that need human clarification during the planning phase to reduce requirement misunderstandings.

**Workflow**:
1. Agent generates questions during `agent dev analyze`
2. Human answers questions by editing this file
3. Agent processes answers with `agent dev debrief`
4. Design documents are updated based on answers

---

## Status: {STATUS}
<!-- Possible values: pending_questions | answered | processed -->

**Generated**: {TIMESTAMP}  
**Last Updated**: {TIMESTAMP}  
**Processed**: {TIMESTAMP or N/A}

---

## High Priority Questions

### Q1: [Category] Question Title?
**Priority**: High  
**Context**: Why this question is being asked  
**Question**: Detailed question text  

**Options**:
- Option A: Description
- Option B: Description
- Option C: Description

**Answer**: <!-- Human fills this in -->

**Impact**: What parts of the design this affects

---

### Q2: [Category] Question Title?
**Priority**: High  
**Context**: Background context  
**Question**: Detailed question  

**Answer**: <!-- Human fills this in -->

**Impact**: Design impact area

---

## Medium Priority Questions

### Q3: [Category] Question Title?
**Priority**: Medium  
**Context**: Background  
**Question**: Question text  

**Answer**: <!-- Human fills this in -->

**Impact**: Impact area

---

## Low Priority Questions

### Q4: [Category] Question Title?
**Priority**: Low  
**Context**: Background  
**Question**: Question text  

**Answer**: <!-- Human fills this in -->

**Assumptions if unanswered**: Default assumption agent will make

---

## Answered Questions Log

<!-- Questions move here after processing -->

### [ANSWERED] Q1: Example Question?
**Asked**: YYYY-MM-DD  
**Answered**: YYYY-MM-DD  
**Answer**: The answer provided  
**Action Taken**: Updated design-solution.md section X

---

## Question Categories

**Common categories**:
- `[Requirements]` - Functional/non-functional requirements
- `[Architecture]` - System design, tech stack
- `[Implementation]` - How to implement specific features
- `[Testing]` - Test strategy, coverage
- `[Dependencies]` - External services, libraries
- `[Security]` - Auth, permissions, data protection
- `[Performance]` - Scalability, optimization
- `[UX]` - User experience, UI decisions
- `[Data]` - Data models, migrations
- `[DevOps]` - CI/CD, deployment

---

## Guidelines for Answering

**For Humans**:
- Be specific and concise
- Provide examples when helpful
- Link to relevant docs/issues
- Mark priority if question priority changes

**For Agent** (`agent dev debrief`):
- Process all answered questions
- Update relevant design documents
- Move answered questions to "Answered Questions Log"
- Update llm_context.md with decisions

---

## Statistics

**Total Questions**: {COUNT}  
**Answered**: {COUNT}  
**Pending**: {COUNT}  
**Processing Rate**: {PERCENTAGE}%

---

## Notes

<!-- 
This file is created by `agent dev analyze` and processed by `agent dev debrief`.

- Questions are prioritized by impact on design
- Unanswered low-priority questions get default assumptions
- All answers are recorded in llm_context.md for future reference
- This file is included in MR description for transparency
-->
