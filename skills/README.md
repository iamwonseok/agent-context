# Skills

> **"Skill은 멍청할수록(Generic) 좋다"**

Skills are **thin interfaces/templates** that define HOW to do something, without context about WHAT specifically to do.

## Philosophy

| Concept | Role | Developer Analogy |
|---------|------|-------------------|
| **Skill** | Interface definition, Template | Function signature, Abstract class |
| **Workflow** | Context injection, Mapping | DI Container, Implementation |

### Design Principles

1. **Parameter-driven**: Skills request inputs; workflows inject them
2. **Context-free**: No ticket IDs, project names, or specific details
3. **Reusable**: Same skill works across different workflows
4. **Focused on HOW**: Methods, checklists, principles

---

## Available Skills

| Skill | Purpose | Key Inputs |
|-------|---------|------------|
| [analyze.md](analyze.md) | Understand the problem space | context, artifacts, goal |
| [design.md](design.md) | Define the solution | problem, scope, constraints |
| [implement.md](implement.md) | Execute the solution | design, acceptance_criteria, codebase |
| [test.md](test.md) | Verify implementation | implementation, acceptance_criteria, test_scope |
| [review.md](review.md) | Validate quality | changes, context, standards |

---

## Skill Structure

Each skill follows this structure:

```markdown
# {Skill Name}

> One-line description

## Interface Definition
- **Input (Required):** Parameters the skill needs
- **Output:** What the skill produces

## Template
Fill-in-the-blank sections that workflows populate

## Checklist
Quality gates to verify before completion
```

---

## How Skills Are Called

Skills are never used directly. Workflows inject context:

```
Workflow (e.g., solo/feature.md)
    │
    │  Context Mapping:
    │  - problem = Ticket description
    │  - scope = Acceptance criteria
    │  - constraints = Sprint deadline
    │
    └──> Call Skill: skills/design.md
              │
              └──> Output: Tech Spec
```

### Same Skill, Different Context

| Workflow | How `design.md` is used |
|----------|-------------------------|
| `solo/feature.md` | Full template, all sections |
| `solo/bugfix.md` | Skip architecture section |
| `solo/hotfix.md` | Skip entirely (no time) |

---

## Creating New Skills

새 skill 생성 시 기존 파일(`analyze.md`, `design.md` 등) 참고.

---

## Relationship to Workflows

```
skills/           (Interface/Template - Generic)
    └── design.md
    
workflows/        (Context Injection - Specific)
    ├── solo/
    │   └── feature.md  ──calls──> design.md with feature context
    ├── team/
    │   └── sprint.md   ──calls──> design.md with sprint context
    └── project/
        └── quarter.md  ──calls──> design.md with OKR context
```

See [workflows/README.md](../workflows/README.md) for how workflows orchestrate skills.
