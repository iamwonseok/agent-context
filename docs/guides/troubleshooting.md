# Troubleshooting Guide

Common issues and solutions for agent-context framework.

---

## Installation Issues

### Bootstrap fails with "permission denied"

**Symptom:**
```
./bootstrap.sh
bash: ./bootstrap.sh: Permission denied
```

**Cause:** Script not executable.

**Solution:**
```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

### Setup fails with "API tokens not found"

**Symptom:**
```
agent init
[ERROR] No API tokens found in .secrets/
```

**Cause:** Missing API token configuration.

**Solution:**
```bash
# Option 1: Skip secrets validation (for testing)
agent init --skip-secrets

# Option 2: Configure tokens
cp templates/secrets-examples/.env.example .secrets/.env
# Edit .secrets/.env with your tokens
agent init
```

See: [templates/secrets-examples/README.md](../../templates/secrets-examples/README.md)

---

## Workflow Execution Errors

### "Skill not found: plan/design-solution"

**Symptom:**
```
[ERROR] Skill not found: plan/design-solution
```

**Cause:** Old skill path format (plan/ instead of planning/).

**Solution:**
Update workflow file to use correct path:
```yaml
# Before
skills:
  - plan/design-solution

# After
skills:
  - planning/design-solution
```

All planning skills should use `planning/` prefix.

### "No workflow found for task type"

**Symptom:**
```
[WARN] No workflow found for: refactoring
```

**Cause:** Workflow file path incorrect.

**Solution:**
Workflows are organized by role:
- Developer workflows: `workflows/developer/*.md`
- Manager workflows: `workflows/manager/*.md`

Use correct path:
```bash
# Instead of:
workflows/refactor.md

# Use:
workflows/developer/refactor.md
```

---

## Quality Gate Failures

### Linter not configured

**Symptom:**
```
agent dev check
[INFO] No linter configured
```

**Cause:** No Makefile or package.json with lint target.

**Solution:**

**Option 1: Python project**
```bash
# Add to requirements.txt
flake8
black

# Create .flake8 config
[flake8]
max-line-length = 100
```

**Option 2: JavaScript project**
```bash
# Add to package.json
{
  "scripts": {
    "lint": "eslint src/"
  }
}
```

**Option 3: Makefile**
```makefile
.PHONY: lint
lint:
    shellcheck scripts/*.sh
    yamllint .gitlab-ci.yml
```

### Tests not found

**Symptom:**
```
agent dev check
[WARN] No tests found
```

**Cause:** No test runner configured.

**Solution:**

Add tests to your project:

**Python:**
```bash
mkdir tests
touch tests/test_example.py

# Add to pyproject.toml or setup.py
[tool.pytest.ini_options]
testpaths = ["tests"]
```

**JavaScript:**
```bash
mkdir tests
touch tests/example.test.js

# Add to package.json
{
  "scripts": {
    "test": "jest"
  }
}
```

---

## Git/Branch Issues

### "Not on feature branch"

**Symptom:**
```
agent dev start TASK-123
[ERROR] Currently on main branch. Create feature branch first.
```

**Cause:** Workflow requires feature branch.

**Solution:**
```bash
# Create feature branch
git checkout -b feat/TASK-123-description

# Then start work
agent dev start TASK-123
```

### Merge conflict during sync

**Symptom:**
```
agent dev sync
[ERROR] Merge conflict in src/main.py
```

**Cause:** Rebase conflict with main branch.

**Solution:**
```bash
# Resolve conflicts manually
vim src/main.py  # Edit conflict markers

# Mark as resolved
git add src/main.py
git rebase --continue

# Verify sync completed
agent dev sync
```

---

## Platform Integration Issues

### GitLab API connection failed

**Symptom:**
```
pm mr create
[ERROR] Failed to connect to GitLab API
```

**Cause:** Missing or invalid GitLab token.

**Solution:**
```bash
# Check token configuration
cat .agent/config.yaml

# Should have:
gitlab:
  url: https://gitlab.company.com
  api_token: ${GITLAB_API_TOKEN}

# Set environment variable
export GITLAB_API_TOKEN=your-token-here

# Or store in .secrets/.env
echo "GITLAB_API_TOKEN=your-token-here" >> .secrets/.env
```

### JIRA API authentication failed

**Symptom:**
```
pm issue get PROJ-123
[ERROR] JIRA authentication failed
```

**Cause:** Invalid JIRA credentials.

**Solution:**
```bash
# Generate API token at:
# https://id.atlassian.com/manage-profile/security/api-tokens

# Configure in .agent/config.yaml:
jira:
  url: https://your-org.atlassian.net
  email: your-email@company.com
  api_token: ${JIRA_API_TOKEN}

# Set token
export JIRA_API_TOKEN=your-token-here
```

---

## Performance Issues

### Agent commands are slow

**Symptom:**
Agent CLI takes >5 seconds to respond.

**Possible Causes:**
1. Network latency to API servers
2. Large codebase inspection
3. Slow test suite

**Solutions:**

**Skip optional checks:**
```bash
# Skip verification (faster commits)
agent dev commit "feat: quick fix" --no-verify

# Skip quality gates in emergency
agent dev submit --force
```

**Optimize test runs:**
```bash
# Run only fast tests
pytest tests/unit/ -m "not slow"

# Parallel test execution
pytest -n auto
```

---

## Context/State Issues

### .context/ directory not created

**Symptom:**
```
agent dev start TASK-123
[WARN] .context/ not found
```

**Cause:** Project not initialized.

**Solution:**
```bash
# Initialize project
agent init

# Verify structure
ls -la .agent/ .context/
```

### Handoff file missing

**Symptom:**
```
agent dev resume
[ERROR] No handoff file found
```

**Cause:** No previous session to resume.

**Solution:**
```bash
# Start new session instead
agent dev start TASK-123

# Or check for archived handoffs
ls .context/archive/
```

---

## Testing Issues

### Unit tests fail after upgrade

**Symptom:**
```
./tests/unit/skills/test_skills.sh
[FAIL] Skill not found: plan/design-solution
```

**Cause:** Test suite not updated after path changes.

**Solution:**
Test suite should auto-detect skills. If not:
```bash
# Re-run from project root
cd /path/to/agent-context
bash ./tests/unit/skills/test_skills.sh

# Check SKILLS_DIR is correct
grep SKILLS_DIR tests/unit/skills/test_skills.sh
```

### Docker tests fail

**Symptom:**
```
docker compose -f tests/docker-compose.test.yml run smoke
[ERROR] Container exited with code 1
```

**Solution:**
```bash
# Rebuild image
docker compose -f tests/docker-compose.test.yml build --no-cache

# Check logs
docker compose -f tests/docker-compose.test.yml run smoke 2>&1 | less
```

---

## Getting Help

If issues persist:

1. **Check documentation:**
   - [README.md](../../README.md)
   - [docs/guides/](../guides/)
   - [workflows/README.md](../../workflows/README.md)

2. **Review recent changes:**
   ```bash
   git log --oneline -10
   ```

3. **Enable debug mode:**
   ```bash
   export DEBUG=1
   agent dev check
   ```

4. **Check issue tracker:**
   - Search existing issues
   - Create new issue with reproduction steps

5. **Use manual fallback:**
   - See [manual-fallback-guide.md](manual-fallback-guide.md)
   - All workflows have manual alternatives

---

## Common Error Messages

| Error Message | Quick Fix |
|--------------|-----------|
| `Skill not found: plan/*` | Use `planning/*` instead |
| `No linter configured` | Add Makefile or package.json with lint target |
| `API token missing` | Set environment variable or use `--skip-secrets` |
| `Not on feature branch` | `git checkout -b feat/TASK-123` |
| `Merge conflict` | Resolve manually, `git add`, `git rebase --continue` |
| `.context/ not found` | Run `agent init` |

---

## Debug Checklist

When debugging issues, verify:

- [ ] Project initialized (`agent init` run)
- [ ] On feature branch (not main)
- [ ] Git status clean (no uncommitted changes blocking operations)
- [ ] API tokens configured (if using PM features)
- [ ] Tests passing locally (`agent dev check`)
- [ ] Tools executable (`chmod +x tools/*/bin/*`)
- [ ] Correct paths used (`planning/` not `plan/`, `workflows/developer/` not `workflows/`)

---

*Last updated: 2026-01-26*
