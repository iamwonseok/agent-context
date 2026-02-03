# AITL Demo - project-opentitan Scenario

## Project Goals

This demo realizes the **Agent-in-the-Loop (AITL)** concept using the project-opentitan reference scenario.

### Primary Objectives

1. **Verify Real Infrastructure Integration**: Use real Jira, GitLab, and Confluence (not mocks)
2. **Full Lifecycle Management**: Project -> Team -> Solo transitions in a single run
3. **Realistic Ticket Content**: Jira cards include context, deliverables, verification, and DoD

### What the Demo Proves

- Programmatic Epic/Task/Hotfix creation in Jira
- Status transitions via workflow rules
- Blocker link creation for dependency tracking
- Work interruption handling (hotfix scenario)
- Cross-platform coordination (Jira + Confluence + GitLab)
- **Full GitLab MR flow**: Issue -> Branch -> Commit -> MR -> Merge
- **MR Gate enforcement**: Jira Done transition blocked until MR merged
- **GitLab trace**: MR/commit info recorded as Jira comments
- Run-isolated exports and report generation

---

## Quick Start

For users who want to run the demo quickly:

```bash
# 1. Set required environment variable
export JIRA_EMAIL="your-email@example.com"

# 2. Store Atlassian API token (get from https://id.atlassian.com/manage-profile/security/api-tokens)
mkdir -p ~/.secrets && chmod 700 ~/.secrets
echo "YOUR_API_TOKEN" > ~/.secrets/atlassian-api-token
chmod 600 ~/.secrets/atlassian-api-token

# 3. Run the demo
cd demo/
./demo.sh check                                    # Verify prerequisites
./demo.sh run --jira-project YOUR_PROJECT --dry-run  # Dry run first
./demo.sh run --jira-project YOUR_PROJECT --skip-cleanup  # Full run
```

**Note**: If you see `[ERROR] Jira not configured`, make sure `JIRA_EMAIL` is set or use `--jira-email` option.

For GitLab integration, also run:
```bash
glab auth login --hostname your-gitlab-host
./demo.sh run --jira-project YOUR_PROJECT --gitlab-group your-group --skip-cleanup
```

---

## How to Run (Detailed)

### Prerequisites

```bash
# Required tools
brew install glab jq yq

# Verify tools
glab --version
jq --version
yq --version
```

### Step 1: Prepare Credentials

```bash
# Create secrets directory
mkdir -p ~/.secrets
chmod 700 ~/.secrets

# Store Atlassian API token
# Get from: https://id.atlassian.com/manage-profile/security/api-tokens
echo "YOUR_ATLASSIAN_API_TOKEN" > ~/.secrets/atlassian-api-token
chmod 600 ~/.secrets/atlassian-api-token

# (Optional) Store GitLab token
echo "YOUR_GITLAB_TOKEN" > ~/.secrets/gitlab-api-token
chmod 600 ~/.secrets/gitlab-api-token

# Login to GitLab CLI
glab auth login --hostname gitlab.fadutec.dev
```

### Step 2: Configure .project.yaml

```yaml
platforms:
  jira:
    base_url: https://fadutec.atlassian.net    # NO /jira suffix!
    project_key: SVI
    email: wonseok@fadutec.com                 # Must match Atlassian account!

  confluence:
    base_url: https://fadutec.atlassian.net/wiki  # /wiki is REQUIRED
    space_key: ~wonseok
```

### Step 3: Verify Configuration

```bash
# From project root
./tools/pm/bin/pm config show
./tools/pm/bin/pm jira me
./tools/pm/bin/pm confluence me
```

### Step 4: Run the Demo

```bash
cd demo/

# Check prerequisites
./demo.sh check

# Dry-run first
./demo.sh run --jira-project SVI --dry-run

# Full execution with GitLab (recommended)
./demo.sh run --jira-project SVI --gitlab-group soc-ip --skip-cleanup

# Full execution without GitLab
./demo.sh run --jira-project SVI --skip-gitlab --skip-cleanup
```

### Step 5: Check Results

```bash
# View dashboard
cat export/latest/DASHBOARD.md

# View full report
cat export/latest/DEMO_REPORT.md

# List created issues
./tools/pm/bin/pm jira issue list --jql "project = SVI ORDER BY created DESC"
```

### Step 6: Generate Sample Prepare/Results

```bash
# Prepare templates (no external changes)
./demo.sh sample-prepare

# Run the demo (creates Jira/GitLab/Confluence resources)
./demo.sh run --jira-project SVI --gitlab-group soc-ip/agentic-ai --confluence-space '~wonseok' --skip-cleanup --repo project-opentitan

# Generate results from the latest run
./demo.sh sample-results --run-id 20260201-220917

# Compare prepare/ vs results/ structure
./demo.sh sample-compare
```

### Manual E2E Test (Jira + GitLab Full Integration)

If you want to test the full Jira-GitLab integration manually:

```bash
# Set environment variables
export JIRA_BASE_URL="https://fadutec.atlassian.net"
export JIRA_EMAIL="your-email@example.com"
export JIRA_TOKEN=$(cat ~/.secrets/atlassian-api-token)
export JIRA_PROJECT_KEY="SVI"
export RUN_ID="test-$(date +%H%M%S)"

# 1. Create Jira Task
./tools/pm/bin/pm jira issue create "[${RUN_ID}] My feature" --type Task

# 2. Clone GitLab repo and create linked issue
cd /tmp && git clone git@gitlab.fadutec.dev:soc-ip/demo.git demo-test && cd demo-test
glab issue create --title "[JIRA-KEY] My feature" --label "aitl-demo"

# 3. Create branch, make changes, commit
git checkout -b "feat/JIRA-KEY-my-feature"
echo "# My feature" > feature.md
git add . && git commit -m "feat: [JIRA-KEY] My feature"
git push -u origin "feat/JIRA-KEY-my-feature"

# 4. Create and merge MR
glab mr create --title "[JIRA-KEY] My feature" --description "Closes #N" --yes
glab mr merge N --yes

# 5. Update Jira with GitLab trace and transition to Done
./tools/pm/bin/pm jira issue comment add JIRA-KEY "MR merged: URL"
./tools/pm/bin/pm jira issue transition JIRA-KEY "Done"
```

---

## Example Run Summary

- Scenario: project-opentitan reference project
- Issues: Epic + 3 tasks + 1 hotfix + 1 initiative (6 total)
- Jira content: Context, Deliverables, Verification, DoD in every card
- GitLab: repo reused, branch name includes run ID, MR gate enforced
- Confluence: Project Charter and Run Report pages
- Export: demo/export/runs/<RUN_ID>/ and demo/export/latest/

---

### 2026-01-30 (Earlier): Initial Verification

**Environment:**

| Platform | URL | Project/Space |
|----------|-----|---------------|
| Jira Cloud | `https://fadutec.atlassian.net` | `SVI` |
| Confluence Cloud | `https://fadutec.atlassian.net/wiki` | `~wonseok` |
| GitLab | `gitlab.fadutec.dev` | `soc-ip/demo` |
| Email | `wonseok@fadutec.com` | - |

**Execution Results:**

| Step | Description | Result |
|------|-------------|:------:|
| 0 | Environment preparation | PASS |
| 1 | Tool verification (glab, jq, yq, curl) | PASS |
| 2 | Secrets/email setup | PASS (email fixed) |
| 3 | GitLab repo | PASS (used existing) |
| 4 | agent-context installation | PASS |
| 5 | .project.yaml configuration | PASS |
| 6 | pm connectivity test | PASS |
| 7 | SVI workflow baseline | PASS |
| 8 | demo.sh check | PASS |
| 9 | Dry-run | PASS (bug fixed) |
| 10 | Full execution | PASS |
| 11 | Cleanup | PASS |

**SVI Workflow Transitions:**

```
Backlog -> Selected for Development -> In Progress -> Done
```

Note: "On Hold" status is not available in SVI. The demo handles this with a graceful fallback.

---

## Issues Found and Fixed

### Issue 1: Email Mismatch (401 Unauthorized)

- **Observed**: `pm jira me` returned "Client must be authenticated"
- **Root Cause**: Email was `wonseok@fadute.com` but should be `wonseok@fadutec.com`
- **Fix**: Updated `.project.yaml` with correct email
- **Lesson**: Email must exactly match the Atlassian account

### Issue 2: demo.sh Argument Parsing Bug

- **Observed**: `--jira-project SVI` was not being parsed
- **Root Cause**: `parse_args()` was called in a subshell, so global variables were not set
- **Fix**: Moved argument parsing directly into `main()` function
- **File Changed**: `demo/demo.sh`

### Issue 3: GitLab Project Limit

- **Observed**: `glab repo create` failed with "100 projects limit"
- **Workaround**: Used existing `soc-ip/demo` repository
- **Lesson**: Check project quotas before creating new repos

### Issue 4: demo/ Folder Not Copied

- **Observed**: `install.sh` does not copy the `demo/` folder
- **Workaround**: Manually copy `demo/` folder to target project
- **Lesson**: Document this in installation instructions

### Issue 5: GitLab Clone Fails Without Remote Setup

- **Observed**: `glab issue create` failed with "No git remotes found"
- **Root Cause**: When `git clone` fails, the fallback only did `git init` without setting up remote
- **Fix**: Added `git remote add origin` and initial commit in fallback path
- **File Changed**: `demo/demo.sh` (`setup_gitlab_repo` function)

---

## Demo Phases

### Phase 1: Project Layer

Creates the initial project structure:

- Epic in Jira representing the project
- 3 child Tasks under the Epic
- Confluence Project Charter page (if configured)

### Phase 1.5: GitLab Flow

Demonstrates full GitLab integration for a selected task:

1. Creates GitLab issue linked to Jira task
2. Creates feature branch (`feat/<JIRA-KEY>-<RUN_ID>-<slug>`)
3. Creates worklog file and commits with Jira key
4. Pushes branch to remote
5. Creates Merge Request referencing Jira
6. Attempts auto-merge (with HITL fallback if approval needed)
7. Adds GitLab trace comment to Jira
8. Transitions Jira to Done only after MR merged

### Phase 2: Team and Solo Layer

Demonstrates work management with MR gate:

1. Starts work on a Task (Backlog -> In Progress)
2. Simulates a hotfix scenario
3. Creates blocker link between Task and Hotfix
4. Attempts to put original Task on hold (fallback if not available)
5. **Runs GitLab flow for hotfix** (if enabled)
6. **Enforces MR gate**: Hotfix Jira cannot be Done until MR merged
7. Completes Hotfix after MR merge
8. Resumes original Task

### Phase 2.5: Developer Initiative

Demonstrates self-assigned task workflow:

1. Creates a "developer idea" Task assigned to current user
2. Runs full GitLab flow (issue/branch/commit/MR/merge)
3. Enforces MR gate before Jira completion
4. Shows end-to-end developer-initiated workflow

### Phase 3: Reporting and Closure

Generates comprehensive reports:

- Exports all Jira issues to Markdown
- Calculates completion metrics
- Creates `DEMO_REPORT.md` with full analysis (run-isolated)
- Creates `DASHBOARD.md` for quick overview (latest)

---

## Command Options

| Option | Description |
|--------|-------------|
| `--run-id ID` | Unique run identifier (default: YYYYMMDD-HHMMSS) |
| `--jira-project KEY` | Jira project key (required) |
| `--confluence-space KEY` | Confluence space key |
| `--gitlab-group GROUP` | GitLab group/namespace |
| `--repo NAME` | GitLab repository name |
| `--dry-run` | Show actions without executing |
| `--skip-cleanup` | Do not prompt for cleanup |
| `--cleanup-repo` | Allow cleanup to delete GitLab repo (opt-in) |
| `--skip-gitlab` | Skip GitLab operations |
| `--hitl` | Enable Human-in-the-Loop pauses |

### Run ID for Test Isolation

Each demo run generates a unique `RUN_ID` (e.g., `20260130-143052`) that prefixes all created resources:

- Jira Epic: `[20260130-143052] project-opentitan bring-up`
- Jira Tasks: `[20260130-143052] Repo bootstrap and project charter`
- GitLab branches: `feat/<JIRA-KEY>-<RUN_ID>-<slug>`

This ensures multiple test runs do not conflict with each other.

---

## Directory Structure

```
demo/
  demo.sh           # Main demo script
  cleanup.sh        # Standalone cleanup script
  README.md         # This file
  lib/
    jira_sync.sh    # Jira synchronization library
    gitlab_flow.sh  # GitLab issue/branch/MR flow library
  export/           # Generated during demo
    runs/           # Run-isolated exports
      <RUN_ID>/
        jira/       # Exported Jira issues
        DEMO_REPORT.md  # Full report
        DASHBOARD.md    # Quick overview
    latest/         # Latest run summary
      DEMO_REPORT.md
      DASHBOARD.md
```

---

## Troubleshooting

### "jq parse error" or "401 Unauthorized"

```bash
# Check your email matches Atlassian account exactly
./tools/pm/bin/pm config show

# Test with curl directly
curl -s -u "your-email:$(cat ~/.secrets/atlassian-api-token)" \
  "https://fadutec.atlassian.net/rest/api/3/myself" | jq .displayName
```

### "Jira not configured"

Ensure `.project.yaml` has all required fields:

- `platforms.jira.base_url`
- `platforms.jira.project_key`
- `platforms.jira.email`

### "Transition not available"

Check your project's actual workflow:

```bash
./tools/pm/bin/pm jira workflow transitions SVI-1
```

### "Link type not found"

Check available link types:

```bash
./tools/pm/bin/pm jira link types
```

---

## Related Documentation

- [tools/pm/README.md](../tools/pm/README.md) - PM CLI documentation
- [workflows/solo/hotfix.md](../workflows/solo/hotfix.md) - Hotfix workflow
- [workflows/project/roadmap.md](../workflows/project/roadmap.md) - Roadmap planning
