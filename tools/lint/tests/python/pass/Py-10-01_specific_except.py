"""Py-10-01: Use specific exception types - PASS.

Tool: Flake8 (E722)
"""


def safe_divide(a: int, b: int) -> float | None:
    """Safely divide two numbers."""
    try:
        return a / b
    except ZeroDivisionError:
        return None


def parse_config(path: str) -> dict:
    """Parse configuration file."""
    try:
        with open(path) as f:
            return json.load(f)
    except FileNotFoundError:
        return {}
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid JSON: {e}") from e


def process_data(data: dict) -> str:
    """Process data with proper exception handling."""
    try:
        value = data["key"]
    except KeyError:
        value = "default"
    except (TypeError, AttributeError) as e:
        raise ValueError("Invalid data format") from e
    return str(value)
