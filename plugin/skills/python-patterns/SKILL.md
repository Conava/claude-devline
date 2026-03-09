---
name: python-patterns
description: "Python development conventions, patterns, and best practices. Auto-loaded when working with .py files."
disable-model-invocation: false
user-invocable: false
---

# Python Patterns

Domain knowledge for Python development. Follow these conventions when implementing Python code.

## Project Structure

- Use `src/` layout for packages: `src/package_name/`
- Place tests in `tests/` mirroring source structure
- Use `__init__.py` for explicit package exports
- Configuration in `pyproject.toml` (preferred) or `setup.cfg`

## Code Style

- Follow PEP 8 naming: `snake_case` for functions/variables, `PascalCase` for classes, `UPPER_SNAKE_CASE` for constants
- Maximum line length: follow project config (default 88 for Black, 79 for PEP 8)
- Use type hints on all public function signatures
- Prefer `from __future__ import annotations` for forward references

## Type Hints

- Use `typing` module types: `Optional[T]`, `Union[X, Y]`, `list[T]` (3.9+), `dict[K, V]` (3.9+)
- Use `TypedDict` for structured dictionaries
- Use `Protocol` for structural subtyping instead of ABCs where appropriate
- Use `TypeAlias` for complex type definitions
- Return `None` explicitly in type hints for procedures

## Error Handling

- Use specific exception types, never bare `except:`
- Create custom exceptions inheriting from domain-specific base exceptions
- Use `raise ... from err` to preserve exception chains
- Context managers (`with` statement) for resource management
- Use `contextlib.suppress()` instead of empty except blocks

## Async Patterns

- Use `async/await` consistently — don't mix sync and async I/O
- Use `asyncio.gather()` for concurrent async operations
- Use `asyncio.TaskGroup` (3.11+) for structured concurrency
- Never call blocking I/O in async functions — use `asyncio.to_thread()` or `run_in_executor()`

## Data Classes and Models

- Use `@dataclass` for plain data containers with `frozen=True` when immutable
- Use Pydantic `BaseModel` for validated data with serialization needs
- Use `NamedTuple` for lightweight immutable records
- Use `Enum` for fixed sets of values, `StrEnum` (3.11+) when string representation matters

## Testing

### pytest Fixtures

Use fixtures for setup/teardown. Scope controls lifetime: `function` (default), `module`, `session`.

```python
@pytest.fixture
def database():
    db = Database(":memory:")
    db.create_tables()
    yield db  # provide to test
    db.close()  # teardown

@pytest.fixture(scope="module")
def shared_client():
    return create_test_client()

@pytest.fixture(scope="session")
def expensive_resource():
    resource = ExpensiveResource()
    yield resource
    resource.cleanup()
```

Share fixtures across tests via `conftest.py`:

```python
# tests/conftest.py
@pytest.fixture
def client():
    app = create_app(testing=True)
    with app.test_client() as client:
        yield client

@pytest.fixture
def auth_headers(client):
    response = client.post("/api/login", json={"username": "test", "password": "test"})
    token = response.json["token"]
    return {"Authorization": f"Bearer {token}"}
```

### Parametrize with IDs

Use `ids` for readable test output and `@pytest.mark.parametrize` for test variants.

```python
@pytest.mark.parametrize("input,expected", [
    ("valid@email.com", True),
    ("invalid", False),
    ("@no-domain.com", False),
], ids=["valid-email", "missing-at", "missing-domain"])
def test_email_validation(input, expected):
    assert is_valid_email(input) is expected
```

### Markers for Test Categorization

Register markers in `pyproject.toml` and use them to select test subsets.

```python
@pytest.mark.slow
def test_slow_operation():
    ...

@pytest.mark.integration
def test_api_integration():
    ...

@pytest.mark.unit
def test_unit_logic():
    assert calculate(2, 3) == 5
```

```bash
pytest -m "not slow"              # Skip slow tests
pytest -m "unit and not slow"     # Unit tests only
```

### Async Testing with pytest-asyncio

```python
@pytest.mark.asyncio
async def test_async_function():
    result = await async_add(2, 3)
    assert result == 5

@pytest.fixture
async def async_client():
    app = create_app()
    async with app.test_client() as client:
        yield client

@pytest.mark.asyncio
async def test_api_endpoint(async_client):
    response = await async_client.get("/api/data")
    assert response.status_code == 200
```

### Mocking at Boundaries

Use `unittest.mock.patch` and `MagicMock` to mock I/O, network, and time -- not internal functions.

```python
from unittest.mock import patch, MagicMock

@patch("mypackage.external_api_call")
def test_with_mock(api_call_mock):
    api_call_mock.return_value = {"status": "success"}
    result = my_function()
    api_call_mock.assert_called_once()
    assert result["status"] == "success"

@patch("mypackage.api_call")
def test_error_handling(api_call_mock):
    api_call_mock.side_effect = ConnectionError("Network error")
    with pytest.raises(ConnectionError):
        api_call()
```

Use `autospec=True` to catch API misuse and `MagicMock` for complex objects.

### Coverage with pytest-cov

Target 80%+ general coverage, 100% for critical paths.

```bash
pytest --cov=mypackage --cov-report=term-missing --cov-report=html
```

```toml
# pyproject.toml
[tool.pytest.ini_options]
addopts = ["--strict-markers", "--cov=mypackage", "--cov-report=term-missing"]
markers = [
    "slow: marks tests as slow",
    "integration: marks tests as integration tests",
    "unit: marks tests as unit tests",
]
```

### General Conventions

- Test file naming: `test_<module>.py`
- Use `tmp_path` fixture for filesystem tests
- Test one behavior per test function
- Use descriptive names: `test_user_login_with_invalid_credentials_fails`

## Common Anti-Patterns to Avoid

- Mutable default arguments (`def f(x=[])`): use `None` sentinel
- String concatenation in loops: use `"".join()` or f-strings
- `isinstance()` chains: consider polymorphism or `match` statement (3.10+)
- Global state mutation: prefer dependency injection
- Wildcard imports (`from module import *`)
- Nested comprehensions deeper than 2 levels
