# Domain Policies

This directory contains domain-specific knowledge and rules for your project.

## Purpose

| Directory | Purpose | Content |
|-----------|---------|---------|
| `docs/style/` | "How to write code" | Coding conventions, formatting |
| `policies/` | "What to know" | Domain knowledge, design rules, security policies |

## Usage

1. Create policy files using the template: `_template.md`
2. Name files descriptively: `<domain>_<topic>.md`
3. Reference policies in your prompts or `.cursorrules`

## Examples

```
policies/
├── README.md
├── _template.md
├── opentitan_hw_design.md      # HW design rules
├── security_coding.md          # Security requirements
└── api_design_patterns.md      # API conventions
```

## Path Resolution Priority

When the agent looks for policies:

```
1. ./policies/              # Project local (highest priority)
2. ./.agent/policies/       # Framework rules
3. ~/.agent/policies/       # Global (if exists)
```

## Best Practices

- Keep policies focused on one domain topic
- Use concrete examples, not abstract descriptions
- Update policies when you learn from mistakes (retrospective)
- Review team policies before merging new ones

## See Also

- `.agent/skills/planning/design-solution/SKILL.md` - How to design solutions
- `.agent/docs/style/` - Coding conventions
