"""Py-08-05: No mutable default arguments - PASS.

Tool: Flake8-bugbear (B006)
"""

from typing import Optional


def process_items(items: list | None = None) -> list:
    """Process items with safe default."""
    if items is None:
        items = []
    return [x * 2 for x in items]


def create_config(options: dict | None = None) -> dict:
    """Create config with safe default."""
    if options is None:
        options = {}
    return {"base": True, **options}


def append_value(value: int, target: Optional[list] = None) -> list:
    """Append value to list with safe default."""
    if target is None:
        target = []
    target.append(value)
    return target
