# RFC (Request for Comments)

## Overview

RFCs provide a structured way to document significant design decisions before implementation.

**Key Philosophy:**
- RFC drafts are **personal workspace** (not committed)
- Discussions happen in **GitHub Issues**
- Only **implemented RFCs** are archived here for reference

---

## RFC Lifecycle

```
Draft (.context/rfc/) -> Issue (GitHub) -> Implementation -> Archive (docs/rfc/)
   |                        |                    |                |
   Personal              Discussion           Execute         Reference
   Workspace              & Review              Code           Material
```

---

## Workflow

### 1. Draft RFC

Write RFC in personal workspace (not committed to git):

```bash
# Find next number (check both .context/rfc/ and docs/rfc/)
ls -1 .context/rfc/*.md docs/rfc/*.md 2>/dev/null | grep -o '[0-9]\{3\}' | sort -n | tail -1

# Create new RFC
NEXT_NUM=$(printf "%03d" $((LAST_NUM + 1)))
cp docs/rfc/000-template.md ".context/rfc/${NEXT_NUM}-short-description.md"

# Edit RFC
# Fill in all required sections
```

**Location:** `.context/rfc/NNN-short-description.md` (gitignored)

### 2. Create GitHub Issue

Once RFC draft is ready, create issue for discussion:

```bash
gh issue create \
  --title "RFC-NNN: Short Description" \
  --label "rfc,proposal" \
  --body-file .context/rfc/NNN-short-description.md
```

**Result:** Issue URL becomes the single source of truth

### 3. Discuss & Decide

- Gather feedback in issue comments
- Update `.context/rfc/NNN-*.md` based on feedback
- Edit issue description or add comments
- Update RFC status:
  - `Proposed` (initial state)
  - `Accepted` (approved for implementation)
  - `Rejected` (not proceeding)

### 4. Implement

If accepted, follow implementation plan:

```bash
# Create feature branch
git checkout -b feat/rfc-NNN-short-description

# Implement according to RFC plan
# Reference RFC in commits
git commit -m "feat: implement RFC-NNN phase 1"

# Update RFC status in .context/rfc/
# Status: Accepted -> Implemented
```

### 5. Archive (Optional)

After implementation completes, optionally archive RFC to `docs/rfc/` for reference:

```bash
# Copy implemented RFC to docs/rfc/ for permanent reference
cp .context/rfc/NNN-short-description.md docs/rfc/

# Commit as documentation
git add docs/rfc/NNN-short-description.md
git commit -m "docs: archive RFC-NNN (implemented)"

# Update index below
```

**Note:** Archiving is optional. The GitHub issue remains the primary reference.

---

## When to Write an RFC

### Write RFC for:
- Adding new major features or components
- Changing existing architecture significantly
- Introducing new workflows or conventions
- Making decisions with long-term impact

### Skip RFC for:
- Bug fixes
- Minor refactoring
- Documentation updates
- Simple feature additions

---

## Naming Convention

Format: `NNN-short-description.md`

- `NNN`: Zero-padded 3-digit number (001, 002, 003, ...)
- `short-description`: Lowercase, hyphen-separated, descriptive
- Extension: `.md`

**Examples:**
- ✅ `001-context-management-system.md`
- ✅ `002-parallel-task-execution.md`
- ✅ `010-git-workflow-automation.md`
- ❌ `1-context.md` (not zero-padded)
- ❌ `001_context_management.md` (underscore)
- ❌ `001-ContextManagement.md` (not lowercase)

See [docs/convention/rfc.md](../convention/rfc.md) for detailed conventions.

---

## Status Values

| Status | Meaning | Location |
|--------|---------|----------|
| `Proposed` | Under review | `.context/rfc/` + GitHub Issue |
| `Accepted` | Approved for implementation | `.context/rfc/` + GitHub Issue |
| `Rejected` | Not proceeding | GitHub Issue (closed) |
| `Implemented` | Completed | Optionally in `docs/rfc/` |
| `Superseded` | Replaced by newer RFC | GitHub Issue (link to successor) |

---

## Template

RFC template: `docs/rfc/000-template.md`

Copy to `.context/rfc/` when creating new RFC.

---

## Archived RFCs (Implemented)

This section lists RFCs that have been implemented and archived for reference.

| Number | Title | GitHub Issue | Implemented |
|--------|-------|--------------|-------------|
| - | No archived RFCs yet | - | - |

*(Add entries here when archiving implemented RFCs)*

---

## Related

- Convention: [docs/convention/rfc.md](../convention/rfc.md)
- Design skill: [skills/design.md](../../skills/design.md)
- Architecture: [docs/ARCHITECTURE.md](../ARCHITECTURE.md)
