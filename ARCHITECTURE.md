# Design Philosophy

Why we built this system the way we did.

## Core Principles

### 1. Simplicity Over Completeness

> "Avoid over-engineering. Only make changes that are directly requested or clearly necessary."
> -- Cursor Best Practices

**We believe:**
- Simple solutions that work > Complex solutions that might work better
- 100 lines of code that everyone understands > 1000 lines that only the author understands
- Warning users > Blocking users
- Progressive enhancement > Big bang implementation

**In practice:**
- Start with warnings, add enforcement later
- Implement the minimum viable feature first
- Add complexity only when pain is proven

### 2. User Autonomy

> "Let the agent find context. Keep it simple: if you know the exact file, tag it. If not, the agent will find it."
> -- Cursor Best Practices

**We believe:**
- Users and agents should have freedom to make decisions
- Hard blocking should be reserved for truly critical cases
- Override options (`--force`) should exist for edge cases
- Trust users to learn from warnings

**In practice:**
- Prefer `[WARN]` over `[BLOCK]`
- Provide `--force` flags for soft enforcement
- Show what's recommended, don't mandate it
- Let users skip steps in emergencies (hotfix)

### 3. Feedback Over Enforcement

> "After completing a task that involves tool use, provide a quick summary of the work you've done."
> -- Claude 4.x Best Practices

**We believe:**
- Clear feedback teaches better than hard blocks
- Users should understand WHY something is recommended
- Show progress and status, let users decide next steps

**In practice:**
```bash
# Good: Informative warning
[WARN] No verification found
[RECOMMEND] Run 'agent dev verify' to check requirements
Continue anyway? [y/N]

# Avoid: Hard block without context
[ERROR] Cannot submit. Run verify first.
```

### 4. Composability

> "Ralph is an autonomous AI agent loop that runs repeatedly until all PRD items are complete. Each iteration is a fresh instance with clean context."
> -- Ralph Project

**We believe:**
- Small, focused skills > Large, monolithic workflows
- Skills should be independently usable
- Workflows = Skill composition
- Each skill should have clear inputs/outputs

**In practice:**
- Skills are self-contained (`SKILL.md` has everything needed)
- Workflows reference skills, don't duplicate them
- New workflows = New skill combinations

### 5. State Through Artifacts, Not Databases

> "Memory persists via git history, progress.txt, and prd.json."
> -- Ralph Project

**We believe:**
- Git is the source of truth
- Files (YAML, Markdown) are better than complex state machines
- Human-readable > Machine-optimized
- Audit trail through commits

**In practice:**
- `.context/` directory for work-in-progress state
- `summary.yaml` instead of database
- Git commits as state transitions
- Everything can be inspected with `cat` and `grep`

---

## What We Avoid

### Over-Engineering Patterns

| Pattern | Problem | Our Approach |
|---------|---------|--------------|
| Complex State Machines | Hard to debug, maintain | Simple flags + warnings |
| Hard Blocking | Frustrates users, blocks emergencies | Soft enforcement + `--force` |
| Deep Nesting | Cognitive overhead | Flat structure, 2 levels max |
| Custom DSLs | Learning curve | Standard YAML + Markdown |
| Implicit Dependencies | Hidden failures | Explicit skill references |

### The 12-State Trap

We considered a 12-state finite state machine:
```
NOT_STARTED -> IN_PROGRESS -> CHECKING -> CHECK_FAILED -> 
CHECK_PASSED -> COMMITTED -> VERIFYING -> VERIFY_FAILED -> 
VERIFIED -> RETRO_PENDING -> RETRO_DONE -> SUBMITTED
```

**Why we rejected it:**
1. ~800 lines of code to maintain
2. Every command needs state validation wrapper
3. Debugging state transitions is painful
4. Users can't work around edge cases
5. Violates autonomy principle

**What we do instead:**
- Simple status checks at key points
- Warnings with recommended actions
- Progressive enforcement (Phase 1: warn, Phase 2: soft, Phase 3: hard)
- `--force` escape hatches

### The Gate Trap

We considered mandatory gates:
```bash
$ agent dev commit "feat: add feature"
[BLOCK] Must run 'agent dev check' first
```

**Why we softened it:**
1. Experienced users know when to skip
2. Emergencies (hotfix) need flexibility
3. Trust builds better habits than force
4. Pre-commit hooks already catch most issues

**What we do instead:**
```bash
$ agent dev commit "feat: add feature"
[WARN] 'agent dev check' not run yet
[RECOMMEND] Run check to verify quality
Continue anyway? [y/N]
```

---

## Implementation Guidelines

### Adding New Features

1. **Start with documentation** - Write the SKILL.md first
2. **Implement minimal version** - Warning only, no blocking
3. **Gather feedback** - Use it in real projects
4. **Add enforcement gradually** - Phase 1 -> 2 -> 3
5. **Keep escape hatches** - Always have `--force` option

### Code Complexity Budget

| Component | Max Lines | Max Files |
|-----------|-----------|-----------|
| Single skill | 200 | 3 (SKILL.md, script, template) |
| Workflow | 100 | 1 (WORKFLOW.md) |
| CLI command | 100 | 1 (function in lib/) |
| Helper library | 300 | 1 |

If exceeding these limits, split into smaller components.

### When to Add Complexity

Add complexity ONLY when:
- [ ] The simple solution has failed multiple times
- [ ] Users are consistently making the same mistake
- [ ] The pain is documented with real examples
- [ ] Simpler alternatives have been tried

Do NOT add complexity for:
- Theoretical edge cases
- "What if" scenarios
- Premature optimization
- Feature completeness

---

## References

### Industry Best Practices

1. **Cursor Agent Best Practices**
   - "Start simple. Add rules only when you notice the agent making the same mistake repeatedly."
   - "Let the agent find context"
   - https://cursor.com/blog/agent-best-practices

2. **Claude 4.x Prompting Best Practices**
   - "Avoid over-engineering"
   - "Please write a high-quality, general-purpose solution"
   - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-4-best-practices

3. **Gemini Prompting Strategies**
   - "Be explicit with your instructions"
   - "Provide context to improve performance"
   - https://ai.google.dev/gemini-api/docs/prompting-strategies

4. **Ralph Project**
   - Autonomous agent loop with simple bash + JSON
   - No complex state machine, just files
   - https://github.com/snarktank/ralph

5. **OpenCode**
   - "Free models included or connect any model"
   - Simplicity in design
   - https://opencode.ai/

### Key Quotes

> "The developers who get the most from agents share a few traits: They write specific prompts. They iterate on their setup. They review carefully."
> -- Cursor Team

> "Avoid creating helper scripts or workarounds. Keep solutions simple and focused."
> -- Claude 4.x Best Practices

> "Each iteration is a fresh instance with clean context. Memory persists via git history."
> -- Ralph Project

---

## Decision Log

### 2026-01-23: Simplified Intent Verification

**Context:** Planned 12-state FSM with 800+ lines of code for intent verification.

**Decision:** Replaced with simple warning system (~200 lines).

**Rationale:**
1. Best practices recommend simplicity
2. Ralph proves simple bash loops work
3. Users need flexibility, not enforcement
4. Progressive rollout allows learning

**Trade-offs:**
- Less strict enforcement (acceptable)
- Relies on user discipline (mitigated by warnings)
- May need hardening later (can add incrementally)

### 2026-01-23: Repository Structure Change

**Context:** Original structure had `.agent/` as subdirectory with intent to use as submodule.

**Problem:**
1. Submodule approach made `.agent/` read-only in user projects
2. Users couldn't fix bugs or customize without forking
3. Development documents (plan/, design/) mixed with deployable code
4. Confusion about which files belong where

**Decision:** Flatten structure - repository root = deployable unit.

**New Structure:**
```
agent-context/              # This repo = what gets deployed
├── skills/
├── workflows/
├── tools/
├── plan/                   # Framework plans
├── setup.sh
└── why.md
```

**Deployment Model (Hybrid):**
```
# Priority order for agent context resolution:
1. .agent/                  # Project local (highest priority)
2. .project.yaml            # Config file setting
3. $AGENT_CONTEXT_PATH      # Environment variable
4. ~/.agent                 # Global default
```

**Rationale:**
1. Global install (`~/.agent`) allows modifications
2. Local install (`.agent/`) allows project-specific versions
3. Docker-based testing for isolated environments
4. Simpler mental model: repo = deployable unit

**Trade-offs:**
- Requires migration (one-time effort)
- More flexible but slightly more complex path resolution

---

*Last updated: 2026-01-23*
*Maintainer: Agent Context Team*
