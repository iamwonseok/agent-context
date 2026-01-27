# LLM Context Cache
# Task: {TASK_ID}
# Last Updated: {TIMESTAMP}

## Purpose

This file caches key technical decisions, architecture context, and external references to reduce token usage and prevent repeated questions during the task lifecycle.

**Usage**: Agent reads this file before each design/code step to understand context without re-asking questions.

---

## Technical Decisions

### Decision 1: [Title]
**Date**: YYYY-MM-DD  
**Context**: Why this decision was needed  
**Decision**: What was decided  
**Rationale**: Why this approach was chosen  
**Alternatives**: What other options were considered  
**Impact**: What this affects  

**Example**:
```yaml
Decision: Use PostgreSQL instead of MySQL
Rationale: Better support for JSONB, existing team expertise
Impact: Requires PostgreSQL 12+ in production
```

---

## Architecture Context

### System Overview
- **Architecture Style**: [Monolith|Microservices|Serverless|etc.]
- **Key Components**: 
  - Component 1: Purpose
  - Component 2: Purpose
- **Tech Stack**:
  - Language: [Python|JavaScript|Go|etc.]
  - Framework: [Django|React|Express|etc.]
  - Database: [PostgreSQL|MySQL|MongoDB|etc.]

### Relevant Patterns
- **Design Patterns Used**: [Singleton|Factory|Repository|etc.]
- **Anti-Patterns to Avoid**: [God Object|Spaghetti Code|etc.]

### Dependencies
- **Internal Dependencies**: List of internal modules/packages used
- **External Dependencies**: List of external libraries/services
- **Version Constraints**: Specific version requirements

---

## External References

### Documentation
- **Project Docs**: Links to internal documentation
- **API Docs**: Links to API documentation
- **Style Guides**: Links to coding standards

### Related Issues/PRs
- **Related Issues**: JIRA/GitLab issue links
- **Related PRs**: Previous MR/PR links
- **Discussions**: Slack/Email threads

### Code References
- **Similar Code**: Pointers to similar implementations
- **Examples**: Reference implementations to follow

---

## Constraints & Requirements

### Hard Constraints
- **Performance**: Response time < 200ms
- **Security**: Must use HTTPS, JWT auth
- **Compatibility**: Must support Python 3.8+

### Soft Constraints
- **Code Style**: Follow PEP 8
- **Test Coverage**: Aim for 80%+
- **Documentation**: All public APIs must be documented

### Business Rules
- **Rule 1**: Description
- **Rule 2**: Description

---

## Known Issues & Workarounds

### Issue 1: [Title]
**Problem**: Description of the issue  
**Workaround**: How to work around it  
**Tracking**: Link to issue tracker  

---

## Questions & Answers

### Q1: [Question]
**A**: Answer  
**Date**: YYYY-MM-DD  
**Answered by**: [Human|Agent]  

### Q2: [Question]
**A**: Answer  
**Date**: YYYY-MM-DD  
**Answered by**: [Human|Agent]  

---

## Update Log

| Date | Section | Change | Author |
|------|---------|--------|--------|
| YYYY-MM-DD | Technical Decisions | Added decision 1 | Agent |
| YYYY-MM-DD | Constraints | Updated performance requirement | Human |

---

## Notes

<!-- 
This file is automatically created by `agent dev start` and updated throughout the task lifecycle.

- Agent MUST read this file before design/code steps
- Humans can edit this file to add context
- This file is included in MR description and then deleted
- Keep entries concise (3-5 lines each)
-->
