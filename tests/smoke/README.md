# Smoke Tests (Stage 1)

Basic functionality tests without external dependencies.

## Prerequisites

None - no tokens or remote connections required.

## Run

```bash
# Via Docker (recommended)
docker compose -f tests/docker-compose.test.yml run smoke

# Direct execution
./tests/smoke/test_smoke.sh
```

## Test Coverage

- `bootstrap.sh` execution
- `setup.sh` project file generation
- `setup.sh` idempotency (re-run safety)
- `agent --version`, `agent --help`
- `agent status`
- `agent dev start` (branch creation, `.context/` setup)

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All tests passed |
| 1 | Some tests failed |
