# Coding Style Guides

Language-specific coding conventions for the project.

## Languages

| File | Language | Key Rules |
|------|----------|-----------|
| [bash.md](bash.md) | Bash/Shell | shebang, set -e, quoting |
| [c.md](c.md) | C | tabs, braces, naming |
| [cpp.md](cpp.md) | C++ | based on C rules |
| [make.md](make.md) | Makefile | tabs for recipes, .PHONY |
| [python.md](python.md) | Python | PEP 8, 4-space indent |
| [yaml.md](yaml.md) | YAML/Dockerfile | 2-space indent, document start |

## Enforcement

These conventions are enforced by:

1. **Linting tools**: `lint c`, `lint python`, etc.
2. **Pre-commit hooks**: `.pre-commit-config.yaml`
3. **CI/CD**: GitLab CI lint stage

## Tool Configuration

Tool configs are in `templates/configs/`:

| Convention | Config File |
|------------|-------------|
| C/C++ | `.clang-format`, `.clang-tidy` |
| Python | `.flake8`, `pyproject.toml` |
| Bash | `.shellcheckrc` |
| YAML | `.yamllint.yml` |
| Dockerfile | `.hadolint.yaml` |
