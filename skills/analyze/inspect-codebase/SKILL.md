---
name: inspect-codebase
category: analyze
description: Analyze codebase structure and architecture
version: 1.0.0
role: developer
mode: research
cursor_mode: ask
inputs:
  - Repository root path
  - Specific area of interest (optional)
outputs:
  - Codebase structure overview
  - Key components identification
  - Technology stack summary
---

# Inspect Codebase

## State Assertion

**Mode**: research
**Cursor Mode**: ask
**Purpose**: Explore and understand codebase structure without making changes
**Boundaries**:
- Will: Read files, analyze structure, identify patterns, document findings
- Will NOT: Modify any files, create new files, or execute code

## When to Use

- Starting work on unfamiliar codebase
- Before making significant changes
- Understanding project architecture
- Finding relevant code for a task

## Prerequisites

- [ ] Access to repository
- [ ] Basic understanding of task context

## Workflow

### 1. Identify Project Type

Check for key files:

```bash
# Package managers / build systems
ls -la package.json pyproject.toml Cargo.toml go.mod Makefile CMakeLists.txt

# Configuration
ls -la .editorconfig .gitignore .pre-commit-config.yaml

# CI/CD
ls -la .gitlab-ci.yml .github/workflows/ Jenkinsfile
```

### 2. Map Directory Structure

```bash
# Get high-level structure (depth 2)
tree -L 2 -d --gitignore

# Or without tree
find . -type d -maxdepth 2 | grep -v '.git' | sort
```

Key directories to identify:
- `src/` or `lib/` - Main source code
- `tests/` or `test/` - Test files
- `docs/` - Documentation
- `scripts/` - Utility scripts
- `config/` or `configs/` - Configuration

### 3. Identify Entry Points

| Project Type | Entry Points |
|--------------|--------------|
| Python | `main.py`, `__main__.py`, `setup.py` |
| Node.js | `index.js`, `app.js`, `package.json:main` |
| Go | `main.go`, `cmd/*/main.go` |
| C/C++ | `main.c`, `main.cpp`, `Makefile` |
| Shell | Scripts in `bin/`, `scripts/` |

### 4. Understand Dependencies

```bash
# Python
cat requirements.txt pyproject.toml setup.py 2>/dev/null | head -50

# Node.js
cat package.json | jq '.dependencies, .devDependencies'

# Go
cat go.mod
```

### 5. Find Relevant Code

For a specific task, search for:

```bash
# Function/class definitions
grep -r "def function_name" --include="*.py"
grep -r "class ClassName" --include="*.py"

# Usage patterns
grep -rn "keyword" --include="*.{py,js,ts}"

# File patterns
find . -name "*pattern*" -type f
```

### 6. Document Findings

Create a brief summary:

```markdown
## Codebase Overview: {project-name}

### Tech Stack
- Language: Python 3.x
- Framework: FastAPI
- Database: PostgreSQL
- Testing: pytest

### Directory Structure
- `src/` - Main application code
- `tests/` - Test suite
- `docs/` - Documentation

### Key Components
- `src/api/` - REST endpoints
- `src/models/` - Database models
- `src/services/` - Business logic

### Entry Points
- `src/main.py` - Application startup
- `scripts/run.sh` - Development runner

### Relevant for Task
- Files: `src/api/users.py`, `src/models/user.py`
- Tests: `tests/test_users.py`
```

## Outputs

| Output | Format | Description |
|--------|--------|-------------|
| Structure overview | Text/Markdown | High-level directory map |
| Tech stack | List | Languages, frameworks, tools |
| Key files | List | Entry points, configs |
| Task-relevant files | List | Files to modify/read |

## Examples

### Example 1: New Feature in Python Project

```
Input: "Add user authentication feature"

Output:
- Tech Stack: Python, FastAPI, SQLAlchemy
- Relevant directories: src/api/, src/models/, src/auth/
- Existing patterns: src/api/items.py (similar endpoint structure)
- Test location: tests/api/
```

### Example 2: Bug Fix Investigation

```
Input: "Fix login timeout issue"

Output:
- Entry point: src/auth/login.py
- Related: src/auth/session.py, src/config/timeouts.py
- Logs location: logs/, or check logging config
- Tests: tests/auth/test_login.py
```

## Notes

- Focus on understanding, not memorizing
- Document findings for future reference
- Look for patterns in existing code
- Check README.md and docs/ first
- Use IDE features (Go to Definition, Find References)
