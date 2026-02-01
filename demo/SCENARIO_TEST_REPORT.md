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
| 2 | Dry-run (no side effects) | `cd demo && ./demo.sh run --dry-run --skip-cleanup` | 0 | PASS |
| 3 | Full E2E (GitLab+Jira) | `cd demo && ./demo.sh run --skip-cleanup` | 0 | PASS |

Pass rate: 3/3 (100%)

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

[OK] glab found
[OK] jq found
[OK] yq found
[OK] curl found
[OK] pm CLI found

[>>] Checking credentials...
[OK] Jira credentials found
[!!] JIRA_EMAIL not set (required unless configured in .project.yaml)
[>>]   Demo will try: git config user.email
[>>]   Set with: export JIRA_EMAIL="your-email@example.com"
[>>]   Or use:   --jira-email your-email@example.com
[OK] GitLab authenticated
[OK] All prerequisites met
EXIT_CODE=0
```

### 2) Dry-run (no side effects)

Command:

```bash
cd demo/
./demo.sh run --dry-run --skip-cleanup
```

Exit code: 0

Output:

```text
Run ID: 20260201-134106
Repository: demo-20260201-134106
Jira Project: SVI
Dry Run: true

[DRY-RUN] Would create: soc-ip/agentic-ai/demo-20260201-134106
[DRY-RUN] Would clone to: /tmp/demo-20260201-134106
[DRY-RUN] Would run: install.sh /tmp/demo-20260201-134106
[DRY-RUN] Would configure .project.yaml

Demo Completed Successfully
EXIT_CODE=0
```

### 3) Full E2E (GitLab+Jira)

Command:

```bash
cd demo/
./demo.sh run --skip-cleanup --board-type kanban
```

Exit code: 0

Key outputs (representative):

```text
Run ID: 20260201-133822
Repository: demo-20260201-133822

[OK] Repository created: soc-ip/agentic-ai/demo-20260201-133822
[OK] Cloned to: /tmp/demo-20260201-133822

[OK] Jira connection verified (project: SVI)
[OK] Created Jira board: [20260201-134634] AITL Demo Board (id: 1172)
[OK] Created Epic: SVI-121
[OK] Created Task: SVI-122
[OK] Created Task: SVI-123
[OK] Created Task: SVI-124
[OK] Created Task: SVI-125
[OK] Created Task: SVI-126

[OK] Created GitLab issue #1: https://gitlab.fadutec.dev/soc-ip/agentic-ai/demo-20260201-133822/-/issues/1
[OK] Created MR !1: https://gitlab.fadutec.dev/soc-ip/agentic-ai/demo-20260201-133822/-/merge_requests/1
[OK] SVI-122 marked as Done

[OK] Created Hotfix: SVI-127
[OK] Created MR !2: https://gitlab.fadutec.dev/soc-ip/agentic-ai/demo-20260201-133822/-/merge_requests/2
[OK] SVI-127 -> Done

[OK] Created: SVI-128
[OK] Created MR !3: https://gitlab.fadutec.dev/soc-ip/agentic-ai/demo-20260201-133822/-/merge_requests/3
[OK] SVI-128 completed

[OK] Report generated: /Users/wonseok/project-iamwonseok/agent-context/demo/export/DEMO_REPORT.md
[OK] Dashboard generated: /Users/wonseok/project-iamwonseok/agent-context/demo/export/DASHBOARD.md

Demo Completed Successfully
EXIT_CODE=0
```

Artifacts:

- `demo/export/DASHBOARD.md`
- `demo/export/DEMO_REPORT.md`
- `demo/export/jira/index.md`

## Gaps / Follow-ups

- Jira "board creation" is now best-effort in `demo.sh` using filter+board APIs:
  - Jira filter created via POST `/rest/api/3/filter`
  - Board created via POST `/rest/agile/1.0/board` (requires `filterId`)
  - Reference: Atlassian Jira Software Cloud REST API - Board Create ([docs](https://developer.atlassian.com/cloud/jira/software/rest/api-group-board/#api-rest-agile-1-0-board-post))

