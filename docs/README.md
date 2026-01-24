# Agent CLI Documentation

Command-line interface documentation for the agent workflow system.

## Documents

| Document | Description |
|----------|-------------|
| [agent.md](agent.md) | Main CLI overview and general usage |
| [agent-dev.md](agent-dev.md) | Developer commands (start, check, submit, ...) |
| [agent-mgr.md](agent-mgr.md) | Manager commands (pending, review, approve, ...) |
| [agent-init.md](agent-init.md) | Project initialization and configuration |

## Quick Reference

### Developer Commands

```bash
agent dev start <task-id>    # Start task
agent dev check              # Run quality checks
agent dev verify             # Generate verification report
agent dev retro              # Create retrospective
agent dev submit             # Create MR
```

### Manager Commands

```bash
agent mgr pending            # List pending MRs
agent mgr review <mr-id>     # Review MR details
agent mgr approve <mr-id>    # Approve MR
```

### Common Commands

```bash
agent init                   # Initialize project
agent status                 # Show current status
agent config show            # Show configuration
```

## Related Documentation

- [skills/README.md](../skills/README.md) - Atomic skills reference
- [workflows/README.md](../workflows/README.md) - Workflow definitions
- [tools/pm/README.md](../tools/pm/README.md) - PM CLI for JIRA/GitLab
