"""Py-08-05: No mutable default arguments - FAIL.

Tool: Flake8-bugbear (B006)
"""


def process_items(items=[]):
    """Process items with unsafe default."""
    return [x * 2 for x in items]


def create_config(options={}):
    """Create config with unsafe default."""
    return {"base": True, **options}


def append_value(value, target=[]):
    """Append value to list with unsafe default."""
    target.append(value)
    return target
