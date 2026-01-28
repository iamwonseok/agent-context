# agnt-c mgr

## NAME

agnt-c mgr - Manager commands for MR review and project oversight

## SYNOPSIS

    agnt-c mgr <COMMAND> [OPTIONS]
    agnt-c mgr pending [--limit=<n>] [--all]
    agnt-c mgr review <mr-id> [--comment <message>]
    agnt-c mgr approve <mr-id> [--force]
    agnt-c mgr status [<id>] [--verbose]

## DESCRIPTION

The `agnt-c mgr` commands help managers review merge requests, track progress, and approve changes. These commands integrate with GitLab and JIRA for comprehensive project oversight.

## COMMANDS

### agnt-c mgr pending

List pending merge requests for review.

    agnt-c mgr pending [OPTIONS]

**Options:**

    -n, --limit <n>
        Maximum number of MRs to show (default: 20).

    --all
        Show all MRs (not just opened).

    --author <username>
        Filter by author.

**Output:**

    ==================================================
    Pending Merge Requests
    ==================================================
    
    ------------------------------------------------------------------------
    IID    | State    | Author       | Title
    ------------------------------------------------------------------------
    !123   | opened   | john.doe     | feat: add authentication
    !124   | opened   | jane.smith   | fix: resolve timeout issue
    ------------------------------------------------------------------------
    Total: 2 merge requests

### agnt-c mgr review

Review merge request details.

    agnt-c mgr review <mr-id> [OPTIONS]

**Arguments:**

    <mr-id>
        Merge request ID (with or without ! prefix).

**Options:**

    -c, --comment <message>
        Add a review comment to the MR.

**Output:**

    ==================================================
    Reviewing Merge Request: !123
    ==================================================
    
    ============================================================
    Merge Request: !123
    ============================================================
    Title:  feat: add authentication
    State:  opened
    Author: john.doe
    Source: feat/TASK-123
    Target: main
    URL:    https://gitlab.example.com/project/-/merge_requests/123
    ------------------------------------------------------------
    Description:
    Implements user authentication using JWT tokens.
    ============================================================
    
    [Review Checklist]
      [ ] Code follows project conventions
      [ ] Tests are adequate and passing
      [ ] No security vulnerabilities
      [ ] Documentation updated if needed

### agnt-c mgr approve

Approve a merge request.

    agnt-c mgr approve <mr-id> [OPTIONS]

**Arguments:**

    <mr-id>
        Merge request ID to approve.

**Options:**

    -f, --force
        Skip confirmation prompt.

**Permission:**

This command is marked as `human_only` by default and cannot be executed by agents unless explicitly overridden in project configuration.

**Example:**

    $ agnt-c mgr approve 123
    ==================================================
    Approving Merge Request: !123
    ==================================================
    
    This will approve MR !123
    Continue? [y/N] y
    [OK] MR !123 approved

### agnt-c mgr status

Show status of initiative, epic, or task.

    agnt-c mgr status [<id>] [OPTIONS]

**Arguments:**

    <id>
        Optional ID to check status for:
        - INIT-* for initiatives
        - EPIC-* for epics
        - Other IDs treated as tasks

**Options:**

    -v, --verbose
        Show detailed information.

**Without ID:**

Shows overall project status including:
- Open merge requests
- Recent JIRA issues

**With ID:**

Shows specific item status from JIRA.

## CONFIGURATION

Manager commands require GitLab configuration in `.project.yaml`:

```yaml
gitlab:
  url: https://gitlab.example.com
  project: group/project-name

jira:
  url: https://jira.example.com
  project_key: PROJ
```

API tokens should be stored in:
- `.secrets/gitlab-api-token`
- `.secrets/atlassian-api-token`

Or as environment variables:
- `GITLAB_TOKEN`
- `JIRA_TOKEN`

## PERMISSIONS

Manager commands have different permission levels:

| Command | Permission | Description |
|---------|------------|-------------|
| pending | agent_allowed | Read-only, safe for automation |
| review  | agent_allowed | Read-only, safe for automation |
| approve | human_only | Requires human execution |
| status  | agent_allowed | Read-only, safe for automation |

Override in `.project.yaml`:

```yaml
permissions:
  mgr_approve: agent_allowed  # Allow agent to approve (not recommended)
```

## WORKFLOW

Typical review workflow:

    # 1. Check pending MRs
    agnt-c mgr pending

    # 2. Review specific MR
    agnt-c mgr review 123

    # 3. Add feedback if needed
    agnt-c mgr review 123 --comment "Please add more tests"

    # 4. Approve when ready
    agnt-c mgr approve 123

## SEE ALSO

[agent](agent.md), [agent-dev](agent-dev.md), [agent-init](agent-init.md)
