"""Py-02-04: Two blank lines between top-level definitions - FAIL.

Tool: Black, Flake8 (E302)
"""

import os

CONSTANT = 42
def first_function():
    """First function."""
    return 1
def second_function():
    """Second function."""
    return 2
class FirstClass:
    """First class."""
    def method(self):
        """Method."""
        pass
class SecondClass:
    """Second class."""
    def method(self):
        """Method."""
        pass
