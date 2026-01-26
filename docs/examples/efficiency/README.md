# Efficiency Pattern Examples

## Purpose

Real-world examples demonstrating agent efficiency patterns from RFC-010.

## Examples

| Example | Pattern | Savings |
|---------|---------|---------|
| [Path Update](pattern-1-path-update-example.md) | Batch file replacement | 70% fewer tool calls |
| [Language Cleanup](pattern-2-language-cleanup-example.md) | Batch text replacement | 60% fewer tool calls |

## Quick Reference

### When to Use These Patterns

| Situation | Pattern | Key Insight |
|-----------|---------|-------------|
| Same change to 5+ files | Batch operations | Find all → Group → Replace all |
| Path/text replacement | Single grep + batch replace | Don't read one-by-one |
| Adding sections | Parallel writes | Create all docs at once |
| Test verification | Run once at end | Not after each change |

### Anti-patterns to Avoid

| Anti-pattern | Problem | Solution |
|--------------|---------|----------|
| Sequential file reads | N tool calls | Parallel reads |
| Test after each change | N test runs | Single test at end |
| Repeated grep | Same search multiple times | Search once, use results |
| One file at a time | No batching | Group by pattern type |

## Metrics Summary

| Approach | Tool Calls | Time |
|----------|------------|------|
| Inefficient | 50+ | 30+ min |
| Efficient | 10-15 | 5-10 min |
| **Savings** | **70%** | **70%** |

## Related

- [RFC-010: Agent Efficiency Best Practices](../../rfcs/010-agent-efficiency-best-practices.md)
- [Test Scenarios](../../../tests/efficiency/)
- [.cursorrules Efficiency Section](../../../.cursorrules)
