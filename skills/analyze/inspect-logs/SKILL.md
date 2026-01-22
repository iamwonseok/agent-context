---
name: inspect-logs
category: analyze
description: Analyze logs to identify issues and root causes
version: 1.0.0
role: developer
inputs:
  - Log files or log output
  - Error description (optional)
  - Time range (optional)
outputs:
  - Root cause identification
  - Error pattern analysis
  - Recommended fixes
---

# Inspect Logs

## When to Use

- Debugging production issues
- Investigating test failures
- Understanding application behavior
- Finding intermittent errors

## Prerequisites

- [ ] Access to log files or log stream
- [ ] Understanding of log format
- [ ] Context about the issue (time, symptoms)

## Workflow

### 1. Locate Logs

Common locations:

| Type | Location |
|------|----------|
| Application | `logs/`, `var/log/app/`, stdout |
| System | `/var/log/syslog`, `journalctl` |
| Container | `docker logs`, `kubectl logs` |
| CI/CD | Job artifacts, pipeline logs |

### 2. Filter by Time Range

```bash
# Find logs around specific time
grep "2026-01-23 14:" application.log

# Last N lines
tail -n 1000 application.log

# Follow live logs
tail -f application.log
```

### 3. Search for Errors

```bash
# Common error patterns
grep -i "error\|exception\|failed\|fatal" application.log

# With context (3 lines before/after)
grep -B3 -A3 -i "error" application.log

# Exclude noise
grep -i "error" application.log | grep -v "expected_error"
```

### 4. Identify Patterns

Look for:

| Pattern | Meaning |
|---------|---------|
| Repeated errors | Systematic issue |
| Timestamp gaps | Service restart/crash |
| Increasing latency | Performance degradation |
| Sudden spike | External trigger |

### 5. Trace Request Flow

For distributed systems:

```bash
# Find by request ID
grep "request-id-123" *.log

# Find by user/session
grep "user@email.com" *.log
```

### 6. Analyze Stack Traces

Key elements:
- Exception type
- Error message
- File and line number
- Call stack (bottom = root cause)

```
Traceback (most recent call last):
  File "app.py", line 45, in process    <- Called from here
    result = calculate(data)
  File "calc.py", line 12, in calculate <- Root cause here
    return data["value"] / divisor
ZeroDivisionError: division by zero     <- Error type
```

### 7. Document Findings

```markdown
## Log Analysis: {issue-description}

### Timeline
- 14:23:45 - First error occurrence
- 14:23:46 - Service restart attempt
- 14:24:00 - Service recovered

### Root Cause
Division by zero in `calc.py:12` when `divisor` is 0

### Evidence
```
[2026-01-23 14:23:45] ERROR calc.py:12 ZeroDivisionError
```

### Impact
- Affected requests: ~50
- Duration: 15 seconds

### Recommended Fix
Add validation for divisor != 0 in calculate()
```

## Outputs

| Output | Format | Description |
|--------|--------|-------------|
| Root cause | Text | Primary issue identification |
| Error patterns | List | Recurring issues found |
| Timeline | Timestamps | Sequence of events |
| Fix recommendation | Text | Suggested resolution |

## Examples

### Example 1: Application Crash

```
Input: "Application crashed at 14:23"

Analysis:
1. grep "14:23" app.log
2. Found: OutOfMemoryError
3. Traced to: Large file upload without streaming
4. Fix: Implement chunked upload
```

### Example 2: Intermittent Failure

```
Input: "Random 500 errors in production"

Analysis:
1. grep -c "500" by hour → spike at 09:00
2. Correlated with: Database connection timeout
3. Root cause: Connection pool exhaustion
4. Fix: Increase pool size, add connection timeout
```

## Log Format Reference

### Common Formats

```
# Standard
[TIMESTAMP] [LEVEL] [MODULE] Message

# JSON (structured)
{"time": "...", "level": "ERROR", "msg": "...", "error": "..."}

# Apache/Nginx
IP - - [TIMESTAMP] "METHOD /path" STATUS SIZE
```

### Log Levels

| Level | Use |
|-------|-----|
| DEBUG | Detailed debugging info |
| INFO | Normal operation |
| WARN | Potential issues |
| ERROR | Failures (recoverable) |
| FATAL | Critical failures |

## Notes

- Start with ERROR/FATAL, then expand
- Correlate with deployments/changes
- Check for patterns across time
- Save relevant snippets for documentation
- Consider log aggregation tools (ELK, Grafana)
