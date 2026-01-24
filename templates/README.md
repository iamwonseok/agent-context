# Templates

User project templates deployed during `setup.sh`.

## Contents

| Directory | Purpose |
|-----------|---------|
| `configs/` | Tool configuration files (clang-format, flake8, etc.) |
| `planning/` | Project planning templates |
| `secrets-examples/` | API token setup examples |

## Files

| File | Purpose |
|------|---------|
| `.cursorrules.template` | Agent behavior rules template |
| `.gitignore.template` | Git ignore patterns |
| `.project.yaml.example` | Project configuration example |

## Usage

Templates are automatically copied during setup:

```bash
# Run setup in your project
~/.agent/setup.sh

# Or with local installation
.agent/setup.sh
```

## Customization

After setup, customize the generated files in your project:

1. Edit `.cursorrules` for project-specific agent rules
2. Edit `.project.yaml` for JIRA/GitLab settings
3. Add API tokens to `.secrets/`
