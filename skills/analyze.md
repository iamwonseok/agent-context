# Analyze

> Understand the problem space before solving it.

## Interface Definition

**Input (Required):**
- `context`: The situation or request to analyze
- `artifacts`: Available information sources (tickets, logs, code, docs)
- `goal`: What you want to understand or decide

**Output:**
- Clear problem statement
- Key findings and insights
- Recommendations for next steps

---

## Template

### 1. Context Summary
{context}

### 2. Available Information
| Source | Type | Key Content |
|--------|------|-------------|
| {artifact_1} | {type} | {summary} |
| {artifact_2} | {type} | {summary} |

### 3. Analysis

#### What We Know
- {fact_1}
- {fact_2}

#### What We Don't Know
- {unknown_1}
- {unknown_2}

#### Assumptions
- {assumption_1}

### 4. Key Findings
1. {finding_1}
2. {finding_2}

### 5. Recommendations
- {recommendation}

---

## Checklist

- [ ] Context is clearly understood
- [ ] All available artifacts reviewed
- [ ] Assumptions explicitly stated
- [ ] Unknowns identified (not hidden)
- [ ] Findings are fact-based
- [ ] Recommendations are actionable
