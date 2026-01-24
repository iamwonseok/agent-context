# Configuration Templates

Tool configuration files for code quality and formatting.

## Files

| File | Tool | Purpose |
|------|------|---------|
| `.clang-format` | clang-format | C/C++ code formatting |
| `.clang-tidy` | clang-tidy | C/C++ static analysis |
| `.editorconfig` | EditorConfig | Editor settings |
| `.flake8` | flake8 | Python linting |
| `.hadolint.yaml` | hadolint | Dockerfile linting |
| `.pre-commit-config.yaml` | pre-commit | Git hooks |
| `.shellcheckrc` | shellcheck | Bash linting |
| `.vimrc` | Vim | Editor configuration |
| `.yamllint.yml` | yamllint | YAML linting |
| `pyproject.toml` | Python tools | Python project config |

## Usage

These files are copied to your project root during `setup.sh`.

To manually copy:

```bash
cp templates/configs/.clang-format /path/to/project/
```

## Customization

Edit the copied files in your project to match your team's coding standards.
