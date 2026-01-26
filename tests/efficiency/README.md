# Efficiency Test Scenarios

## Purpose

Test scenarios for validating agent efficiency patterns documented in RFC-010.

## Scenarios

| ID | Name | Pattern | Est. Time |
|----|------|---------|-----------|
| 01 | Path Update | Batch path replacement | 5 min |
| 02 | Language Cleanup | Korean removal | 10 min |
| 03 | Doc Creation | Batch documentation | 15 min |
| 04 | Test Update | Structure change tests | 10 min |
| 05 | Batch Files | Multi-file operations | 10 min |

## Usage

### Running Scenarios

Each scenario has a markdown file with:
1. **Context**: What situation triggers this pattern
2. **Inefficient Approach**: What to avoid
3. **Efficient Approach**: Best practice
4. **Success Criteria**: How to measure efficiency

### Measuring Efficiency

```bash
# Run measurement script
bash tests/efficiency/measure-efficiency.sh <scenario-id>

# Output:
# Scenario: 01-path-update
# Tool calls: 12
# Files touched: 8
# Time: 2m 15s
# Efficiency: PASS (< 20 tool calls)
```

## Success Criteria

See `success-criteria.yaml` for detailed metrics.

## Related

- [RFC-010: Agent Efficiency Best Practices](../../docs/rfcs/010-agent-efficiency-best-practices.md)
- [skills/planning/design-test-plan](../../skills/planning/design-test-plan/SKILL.md)
