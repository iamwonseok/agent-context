"""Py-10-01: Use specific exception types - FAIL (bare except).

Tool: Flake8 (E722)
"""


def unsafe_divide(a, b):
    """Unsafely divide two numbers."""
    try:
        return a / b
    except:
        return None


def parse_config(path):
    """Parse configuration file."""
    try:
        with open(path) as f:
            return json.load(f)
    except:
        return {}


def process_data(data):
    """Process data with poor exception handling."""
    try:
        value = data["key"]
    except:
        value = "default"
    return str(value)
