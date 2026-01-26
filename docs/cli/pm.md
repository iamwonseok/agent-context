# pm

## NAME

pm - Project Management CLI for JIRA/GitLab/GitHub/Confluence

## SYNOPSIS

    pm <PLATFORM> <COMMAND> [OPTIONS]
    pm config <ACTION>
    pm create <TITLE> [OPTIONS]
    pm finish [OPTIONS]

## DESCRIPTION

`pm` is a command-line tool for integrating with project management platforms (JIRA, GitLab, GitHub, Confluence). It provides unified commands for issue tracking, code review, and documentation management.

## QUICK START

```bash
# 1. Initialize configuration
pm config init

# 2. Set API tokens
export JIRA_TOKEN="your-token"
export GITLAB_TOKEN="your-token"

# 3. Create a feature
pm create "Add UART driver"

# 4. Finish and create MR
pm finish
```

## COMMANDS

### Configuration

| Command | Description |
|---------|-------------|
| config init | Create `.project.yaml` |
| config show | Show current configuration |

### Platform Commands

| Platform | Commands |
|----------|----------|
| jira | me, issue (list/view/create) |
| confluence | me, space, page, search |
| gitlab | me, mr, issue |
| github | me, pr, issue |

### Workflow Commands

| Command | Description |
|---------|-------------|
| create | Create issue + branch |
| finish | Push + create MR + update status |

## EXAMPLES

```bash
# JIRA
pm jira issue list
pm jira issue view PROJ-123
pm jira issue create "New feature"

# GitLab
pm gitlab mr list
pm gitlab mr create --source feat/test --title "Test MR"

# GitHub
pm github pr list
pm github pr create --head feat/test --title "Test PR"

# Confluence
pm confluence page list
pm confluence page create --space SFP --title "New Page"
```

## SEE ALSO

- **Implementation details**: [tools/pm/README.md](../../tools/pm/README.md)
- **Related CLI**: [agent.md](agent.md), [lint.md](lint.md)
