# CLI Documentation

Command-line interface documentation for agent-context tools.

## Tools

| Document | CLI | Description |
|----------|-----|-------------|
| [agent.md](agent.md) | `agent` | Main workflow CLI |
| [agent-dev.md](agent-dev.md) | `agent dev` | Developer commands |
| [agent-mgr.md](agent-mgr.md) | `agent mgr` | Manager commands |
| [agent-init.md](agent-init.md) | `agent init` | Project initialization |
| [lint.md](lint.md) | `lint` | Code quality checker |

## Quick Reference

### Developer Commands

```bash
agent dev start <task-id>    # Start task
agent dev check              # Run quality checks
agent dev verify             # Generate verification report
agent dev retro              # Create retrospective
agent dev submit             # Create MR/PR
```

### Manager Commands

```bash
agent mgr pending            # List pending MRs
agent mgr review <mr-id>     # Review MR details
agent mgr approve <mr-id>    # Approve MR
```

### Lint Commands

```bash
lint c file.c                # Check C/C++ file
lint python script.py        # Check Python file
lint bash script.sh          # Check Bash script
lint yaml config.yaml        # Check YAML file
lint c --check-tools         # Show tool availability
```

## Related

- [tools/pm/README.md](../../tools/pm/README.md) - PM CLI for JIRA/GitLab
- [tools/lint/README.md](../../tools/lint/README.md) - Lint CLI for code quality
