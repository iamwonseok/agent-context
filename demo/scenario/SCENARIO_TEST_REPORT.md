# Demo Scenario Test Report

- Generated at: 2026-02-01 13:41:05 KST
- Host: Darwin 24.6.0 (arm64)
- Git: `main` @ `22b7c33`

## Scope

This report executes demo scenarios and captures:

- Command line used per scenario
- Exit code
- Output (full for failures, representative for passes)

Notes:

- Demo creates a workspace under `/tmp` and generates a workspace-local `.project.yaml`.
- Root `/.project.yaml` is not modified by the demo.

## Summary

| ID | Scenario | Command | Exit | Result |
|---:|---|---|---:|---|
| 1 | Prerequisites check | `cd demo && ./demo.sh check` | 0 | PASS |
| 2 | Dry-run (project-opentitan scenario) | `cd demo && ./demo.sh run --dry-run --skip-cleanup --jira-project SVI` | 0 | PASS |
| 3 | Full E2E (Jira+GitLab+Confluence) | `cd demo && ./demo.sh run --skip-cleanup --jira-project SVI --gitlab-group soc-ip/agentic-ai --confluence-space ~wonseok` | 0 | PASS |
| 4 | Export isolation check | `cd demo && ls export/runs/<RUN_ID> && ls export/latest` | 0 | PASS |
| 5 | Sample prepare/results/compare | `cd demo && ./demo.sh sample-prepare && ./demo.sh sample-results --run-id <RUN_ID> && ./demo.sh sample-compare` | 0 | PASS |

Pass rate: 5/5 (100%)

## Scenario Details

### 1) Prerequisites check

Command:

```bash
cd demo/
./demo.sh check
```

Exit code: 0

Output:

```text
============================================================
Step 1: Checking Prerequisites
============================================================

[V] glab found
[V] jq found
[V] yq found
[V] curl found
[V] pm CLI found

[i] Checking credentials...
[V] Jira credentials found
[!] JIRA_EMAIL not set (required unless configured in .project.yaml)
[i]   Demo will try: git config user.email
[i]   Set with: export JIRA_EMAIL="your-email@example.com"
[i]   Or use:   --jira-email your-email@example.com
[V] GitLab authenticated
[V] All prerequisites met
EXIT_CODE=0
```

### 2) Dry-run (project-opentitan scenario)

Command:

```bash
cd demo/
./demo.sh run --dry-run --skip-cleanup --jira-project SVI
```

Exit code: 0

Output:

```text
Run ID: 20260201-150101
Repository: project-opentitan
Jira Project: SVI
Dry Run: true

[DRY-RUN] Would use or create: soc-ip/agentic-ai/project-opentitan
[DRY-RUN] Would initialize local repo: /tmp/project-opentitan
[DRY-RUN] Would run: install.sh /tmp/project-opentitan
[DRY-RUN] Would configure .project.yaml

Demo Completed Successfully
EXIT_CODE=0
```

### 3) Full E2E (Jira+GitLab+Confluence)

Command:

```bash
cd demo/
./demo.sh run --skip-cleanup --jira-project SVI --gitlab-group soc-ip/agentic-ai --confluence-space ~wonseok
```

Exit code: 0

Key outputs (representative):

```text
Run ID: 20260201-150245
Repository: project-opentitan

[V] Using existing repository: soc-ip/agentic-ai/project-opentitan
[V] Local repo initialized and pushed: /tmp/project-opentitan

[V] Jira connection verified (project: SVI)
[V] Created Jira board: [20260201-150245] project-opentitan board (id: 1172)
[V] Created Epic: SVI-201
[V] Created Task: SVI-202
[V] Created Task: SVI-203
[V] Created Task: SVI-204

[V] Created GitLab issue #1: https://gitlab.fadutec.dev/soc-ip/agentic-ai/project-opentitan/-/issues/1
[V] Created MR !1: https://gitlab.fadutec.dev/soc-ip/agentic-ai/project-opentitan/-/merge_requests/1
[V] SVI-202 marked as Done

[V] Created Hotfix: SVI-205
[V] Created MR !2: https://gitlab.fadutec.dev/soc-ip/agentic-ai/project-opentitan/-/merge_requests/2
[V] SVI-205 -> Done

[V] Created: SVI-206
[V] Created MR !3: https://gitlab.fadutec.dev/soc-ip/agentic-ai/project-opentitan/-/merge_requests/3
[V] SVI-206 completed

[V] Report generated: /Users/wonseok/project-iamwonseok/agent-context/demo/export/runs/20260201-150245/DEMO_REPORT.md
[V] Dashboard generated: /Users/wonseok/project-iamwonseok/agent-context/demo/export/runs/20260201-150245/DASHBOARD.md

Demo Completed Successfully
EXIT_CODE=0
```

Artifacts:

- `demo/export/runs/<RUN_ID>/DASHBOARD.md`
- `demo/export/runs/<RUN_ID>/DEMO_REPORT.md`
- `demo/export/runs/<RUN_ID>/jira/index.md`
- `demo/export/latest/DASHBOARD.md`
- `demo/export/latest/DEMO_REPORT.md`

### 4) Export isolation check

Command:

```bash
cd demo/
ls export/runs/<RUN_ID>
ls export/latest
```

Exit code: 0

Output:

```text
DASHBOARD.md
DEMO_REPORT.md
jira
```

### 5) Sample prepare/results/compare

Command:

```bash
cd demo/
./demo.sh sample-prepare
./demo.sh sample-results --run-id <RUN_ID>
./demo.sh sample-compare
```

Exit code: 0

Output:

```text
[V] Sample prepare structure ready: demo/sample/opentitan/prepare
[V] Sample results generated: demo/sample/opentitan/results
[V] Sample structure matches prepare/ and results
```

## Gaps / Follow-ups

- Jira "board creation" is best-effort in `demo.sh` using filter+board APIs:
  - Jira filter created via POST `/rest/api/3/filter`
  - Board created via POST `/rest/agile/1.0/board` (requires `filterId`)
  - Reference: Atlassian Jira Software Cloud REST API - Board Create ([docs](https://developer.atlassian.com/cloud/jira/software/rest/api-group-board/#api-rest-agile-1-0-board-post))
