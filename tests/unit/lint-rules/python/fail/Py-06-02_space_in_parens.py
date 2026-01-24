"""Py-06-02: No space inside parentheses - FAIL.

Tool: Black, Flake8 (E201, E202)
"""


def process( data, options=None ):
    """Process data with options."""
    result = func( arg1, arg2 )
    items = [ 1, 2, 3 ]
    mapping = { "key": "value" }
    return result, items, mapping


def func( a, b ):
    """Helper function."""
    return a + b


class Example:
    """Example class."""

    def method( self, x, y ):
        """Method with parameters."""
        return ( x + y ) * 2
