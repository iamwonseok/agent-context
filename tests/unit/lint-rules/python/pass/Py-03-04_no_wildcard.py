"""Py-03-04: No wildcard imports - PASS.

Tool: Flake8 (F401, F403)
"""

from os.path import join, dirname, basename
from collections import defaultdict, OrderedDict


def process_path(path):
    """Process a file path."""
    base = basename(path)
    parent = dirname(path)
    return join(parent, base)


def create_mapping():
    """Create a mapping."""
    data = defaultdict(list)
    ordered = OrderedDict()
    return data, ordered
