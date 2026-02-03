# Skills

Skills are **thin interfaces/templates** that define HOW to do something, without context about WHAT specifically to do.
Design concepts and philosophy are maintained in [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md).

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

Skills are never used directly. Workflows inject context.
For the full context injection flow and examples, see [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md).

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

See [workflows/README.md](../workflows/README.md) for how workflows orchestrate skills.
