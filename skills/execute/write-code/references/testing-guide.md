# Testing Guide

## Test Types

### Unit Test
Test single function in isolation.
```python
def test_add():
    assert add(2, 3) == 5
```

### Integration Test
Test component interaction.
```python
def test_user_flow(db):
    service = UserService(db)
    user = service.register("a@b.com", "pwd")
    assert user.id is not None
```

### E2E Test
Test full system.
```c
void test_uart_loopback(void) {
    uart_init(UART0, 115200);
    uart_write(UART0, "test", 4);
    char buf[4];
    uart_read(UART0, buf, 4);
    TEST_ASSERT_EQUAL_STRING("test", buf);
}
```

## Test Structure

### AAA Pattern

```python
def test_update():
    # Arrange
    user = User(name="Old")
    
    # Act
    user.update_name("New")
    
    # Assert
    assert user.name == "New"
```

## Naming

### Files
```
tests/
+-- unit/test_calc.py
+-- integration/test_db.py
+-- e2e/test_uart.c
```

### Functions
Format: `test_{what}_{when}_{then}`
```python
void test_uart_invalid_baud_returns_error(void);
def test_add_negative_numbers_returns_sum():
```

## Fixtures

```python
@pytest.fixture
def user():
    return User(name="Test")

@pytest.fixture
def db():
    session = create_session()
    yield session
    session.rollback()

def test_save(user, db):
    db.add(user)
    # ...
```

## Mocking

```python
from unittest.mock import Mock, patch

def test_email_sent():
    mock_email = Mock()
    service = UserService(email=mock_email)
    service.register("a@b.com", "pwd")
    mock_email.send.assert_called_once()

@patch('requests.get')
def test_api(mock_get):
    mock_get.return_value.json.return_value = {"name": "John"}
    result = fetch_user(123)
    assert result["name"] == "John"
```

## Coverage

```bash
pytest --cov=src --cov-fail-under=80
```

| Type | Target |
|------|--------|
| Business logic | 90% |
| Utils | 80% |
| API | 80% |
| UI | 70% |

## Parameterized Tests

```python
@pytest.mark.parametrize("input,expected", [
    (0, 0),
    (1, 1),
    (2, 4),
    (-1, 1),
])
def test_square(input, expected):
    assert square(input) == expected
```

## CI Integration

```yaml
test:
  script:
    - pytest --junitxml=report.xml --cov=src
  artifacts:
    reports:
      junit: report.xml
```

## Rules

**Do**:
- One assertion per test (related OK)
- Independent tests
- Clear names

**Don't**:
- Test private methods
- Test dependencies
- Use random data
- Use sleep
