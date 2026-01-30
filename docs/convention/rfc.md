# RFC (Request for Comments) Convention

## Philosophy

**RFCs are personal workspace, not version control artifacts.**

- Draft in `.context/rfc/` (gitignored)
- Discuss in GitHub Issues (source of truth)
- Archive to `docs/rfc/` only if needed for reference (optional)

---

## File Locations

### Draft (Personal Workspace)

```
.context/rfc/NNN-short-description.md
```

- **Tracked:** No (gitignored)
- **Purpose:** Personal design workspace
- **Lifecycle:** Draft -> Issue -> Delete/Keep locally

### Archive (Reference Material)

```
docs/rfc/NNN-short-description.md
```

- **Tracked:** Yes (committed)
- **Purpose:** Permanent reference for implemented RFCs
- **Lifecycle:** Copied from `.context/rfc/` after implementation (optional)

---

## Naming Convention

### Format

```
NNN-short-description.md
```

### Components

| Component | Rule | Example |
|-----------|------|---------|
| `NNN` | Zero-padded 3-digit sequential number | `001`, `042`, `123` |
| `-` | Hyphen separator (required) | `-` |
| `short-description` | Lowercase, hyphen-separated, descriptive | `context-management`, `git-workflow` |
| `.md` | Markdown extension (required) | `.md` |

### Valid Examples

- ✅ `001-context-management-system.md`
- ✅ `002-parallel-task-execution.md`
- ✅ `010-git-workflow-automation.md`
- ✅ `042-ci-integration.md`

### Invalid Examples

- ❌ `1-context.md` (not zero-padded)
- ❌ `001_context_management.md` (underscore instead of hyphen)
- ❌ `001-ContextManagement.md` (not lowercase)
- ❌ `RFC-001-context.md` (prefix not allowed)
- ❌ `001-context-mgmt.txt` (not .md extension)

---

## File Structure

### Required Header

```markdown
# RFC NNN: {Title}

**Status:** {Proposed|Accepted|Rejected|Implemented|Superseded}
**Author:** @{github-username}
**Created:** YYYY-MM-DD
**Updated:** YYYY-MM-DD
**Issue:** #{issue-number}
```

**Note:** Add issue number after creating GitHub issue

### Required Sections

1. **Summary**: 1-2 sentence overview
2. **Motivation**: Problem statement and inspiration
3. **Design**: Detailed technical design
4. **Implementation Plan**: Phased approach with concrete steps
5. **Expected Benefits**: Quantified benefits with Problem/Solution/Effect
6. **Risks & Mitigations**: Table format with Probability/Impact
7. **Alternatives Considered**: At least 2 alternatives with Pros/Cons/Decision
8. **References**: Links to related docs/articles
9. **Checklist**: Track RFC progress

### Optional Sections

- **Open Questions**: Unresolved issues
- **Diagrams**: Visual representations
- **Examples**: Code samples or usage examples

---

## Status Lifecycle

```
Proposed -> Accepted -> Implemented
         -> Rejected
         -> Superseded (by RFC-XXX)
```

| Status | Meaning | Location |
|--------|---------|----------|
| `Proposed` | Under review | `.context/rfc/` + Issue |
| `Accepted` | Approved | `.context/rfc/` + Issue |
| `Rejected` | Not proceeding | Issue only (closed) |
| `Implemented` | Completed | Optional: `docs/rfc/` |
| `Superseded` | Replaced | Issue (link successor) |

---

## Content Guidelines

### Language

- **Technical content**: English only
- **Code comments**: English only
- **Markdown prose**: Korean or English (project default: Korean for internal docs)

### Style

- Use tables for comparisons
- Use code blocks for examples
- Use bullet points for lists
- Keep sentences concise
- Avoid emoji and decorative Unicode

### Structure

- Each section should stand alone
- Use consistent heading levels
- Include concrete examples
- Quantify benefits where possible

---

## Workflow Integration

### Step 1: Create RFC Draft

```bash
# Find next RFC number
LAST_NUM=$(ls -1 .context/rfc/*.md docs/rfc/*.md 2>/dev/null | \
           grep -o '[0-9]\{3\}' | sort -n | tail -1)
NEXT_NUM=$(printf "%03d" $((LAST_NUM + 1)))

# Create from template
cp docs/rfc/000-template.md ".context/rfc/${NEXT_NUM}-your-description.md"

# Edit RFC (fill all required sections)
```

### Step 2: Create GitHub Issue

```bash
# Create issue with RFC content
gh issue create \
  --title "RFC-${NEXT_NUM}: Your Description" \
  --label "rfc,proposal" \
  --body-file ".context/rfc/${NEXT_NUM}-your-description.md"

# Update RFC header with issue number
# Add: **Issue:** #123
```

### Step 3: Gather Feedback

- Discuss in GitHub Issue comments
- Update `.context/rfc/NNN-*.md` based on feedback
- Keep issue description in sync (or just use comments)
- Decision: Accepted / Rejected

### Step 4: Implement (if Accepted)

```bash
# Create feature branch
git checkout -b feat/rfc-NNN-description

# Implement according to RFC plan
git commit -m "feat: implement RFC-NNN phase 1"

# Update RFC status
# In .context/rfc/NNN-*.md: Status: Accepted -> Implemented
```

### Step 5: Archive (Optional)

```bash
# Only if RFC should be permanent reference
cp .context/rfc/NNN-*.md docs/rfc/
git add docs/rfc/NNN-*.md
git commit -m "docs: archive RFC-NNN (implemented)"
```

**Archive when:**
- Significant architectural decisions
- Complex designs that need future reference
- Foundation for other features

**Don't archive when:**
- Simple feature additions
- One-time changes
- Self-explanatory implementations

---

## GitHub Issue Management

### Labels

- `rfc`: All RFC-related issues
- `proposal`: Design proposals
- `accepted`: Approved for implementation
- `implemented`: Work completed
- `rejected`: Not proceeding

### Issue Template (Optional)

Create `.github/ISSUE_TEMPLATE/rfc.md`:

```markdown
---
name: RFC
about: Propose a significant design change
labels: rfc, proposal
---

**Status:** Proposed
**Author:** @your-username
**Created:** YYYY-MM-DD

## Summary
{1-2 sentence summary}

## Motivation
{problem and inspiration}

## Design
{detailed design}

...
```

---

## Git Tracking

### Tracked (Committed)

```
docs/rfc/
├── README.md           # Process documentation
├── 000-template.md     # RFC template
└── NNN-*.md            # Archived implemented RFCs (optional)
```

### Not Tracked (Gitignored)

```
.context/rfc/
└── NNN-*.md            # RFC drafts (personal workspace)
```

---

## Cross-References

- Process details: `docs/rfc/README.md`
- Design skill: `skills/design.md`
- Architecture philosophy: `docs/ARCHITECTURE.md`

---

## Checklist for RFC Authors

- [ ] RFC number is next sequential number
- [ ] Filename follows `NNN-short-description.md` format
- [ ] All required sections present
- [ ] At least 2 alternatives considered
- [ ] Risks identified with mitigations
- [ ] Benefits quantified
- [ ] Code examples follow project conventions
- [ ] References included
- [ ] GitHub Issue created with RFC content
- [ ] Issue number added to RFC header
- [ ] (Optional) Archive to `docs/rfc/` after implementation
