# Local Git Tests (Stage 2)

Git workflow tests using a local bare repository as remote.

## Prerequisites

- Git installed
- Stage 1 (Smoke) tests passing

## Run

```bash
# Via Docker (recommended)
docker compose -f tests/docker-compose.test.yml run local-git

# Direct execution
./tests/local-git/test_local_git.sh
```

## Test Coverage

- Bare repo creation and clone
- `agent dev start` → branch creation
- `agent dev commit` → commit
- `git push` → remote push
- `agent dev sync` → rebase
- Linear history verification

## How It Works

1. Creates a temporary bare Git repository
2. Clones it as a working directory
3. Runs agent workflow commands
4. Verifies Git state after each step
5. Cleans up temporary directories
